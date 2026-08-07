# Adding NVIDIA CUDA / NVENC / NVDEC support to `static-ffmpeg`

**Date:** 2026-04-24 → 2026-05-03
**Tracking issue:** [#480 — Support for CUDA](https://github.com/wader/static-ffmpeg/issues/480)
**Outcome:** Separate `:<tag>-cuda` image variant; default `:<tag>` remains a fully static-pie binary.

---

## TL;DR

| | Default `:8.1` | CUDA `:8.1-cuda` |
|---|---|---|
| Linkage | static-pie musl | musl **dynamic-PIE** (libc only) |
| `readelf -d` NEEDED | (none) | exactly one: `libc.musl-x86_64.so.1` |
| GPU | ❌ | ✅ NVENC / NVDEC / CUVID |
| Arch | amd64 + arm64 | amd64 only |
| Base image | scratch | alpine |
| ffmpeg exit codes | upstream | identical to upstream |

The CUDA variant works on Alpine + musl by combining six independently-essential
layers (link-time + runtime). Each layer fixes one specific failure mode that
appeared during development. The layers are summarized below; full
problem → cause → fix sections follow.

| # | Layer | Stage | Fixes |
|---|---|---|---|
| 1 | Absolute-path link of `/lib/ld-musl-x86_64.so.1` | builder | dlopen returning NULL silently (P1) |
| 2 | Dynamic-PIE link mode (`-fPIE -pie`, not `-static-pie`) | builder | dlopen impossible on static-pie (P1) |
| 3 | `/etc/ld-musl-x86_64.path` listing toolkit injection dirs | runtime | musl can't find `/usr/lib64`, `/usr/lib/wsl/lib` (P3) |
| 4 | `gcompat` package + `libdl.so.2 → libgcompat.so.0` symlink | runtime | NVIDIA driver libs need `libc.so.6` / `libdl.so.2` (P4) |
| 5 | `libnvshim.so` LD_PRELOAD (ABI-shim symbols only) | runtime | glibc-internal symbols missing from gcompat (P4) |
| 6 | Bash entrypoint wrapper (139 → 0 only) | runtime | benign teardown SIGSEGV from libcuda dtors (P5) |

---

## 1. Architecture decision

### Two separate variants, not one

- The default `mwader/static-ffmpeg` is a fully static-pie musl binary that drops into `FROM scratch`. We must not silently break that for existing users.
- CUDA requires `dlopen()` of host driver libraries → fundamentally incompatible with `static-pie` on musl (no dynamic loader).
- CUDA users need the NVIDIA Container Toolkit and a GPU host — different deployment.
- → Different tag = explicit user opt-in + clear support boundary.

### Build-arg `ENABLE_CUDA`

A single `ARG ENABLE_CUDA=` controls everything:

- Adds `nv-codec-headers` (header-only, no CUDA toolkit at build time).
- Adds `--enable-ffnvcodec --enable-cuvid --enable-nvenc --enable-nvdec`.
- Switches link mode from `static-pie` to musl dynamic-PIE.
- Sets `NVIDIA_VISIBLE_DEVICES=all` and `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`.
- Writes `/etc/ld-musl-x86_64.path` so musl's loader can find toolkit-injected libs.
- Switches `checkelf` to `--cuda` mode (allows libc as the only NEEDED entry).

CI builds two images per release: default (no arg) and `final-cuda` target with `ENABLE_CUDA=1`.

### Explicitly NOT supported

| Feature | Reason |
|---|---|
| `--enable-cuda-nvcc` | Requires the full ~3 GB glibc-based CUDA toolkit at build time |
| `--enable-libnpp` / `scale_npp` | Same — glibc-only; use `scale_cuda` instead |
| `arm64` | NVIDIA Container Toolkit on arm64 is server-class only (Jetson uses a different stack) |
| `FROM scratch` / distroless target images | No musl loader available |

---

## 2. Problem → Root cause → Fix

Each subsection records one failure mode encountered during development.

---

### P1. `[h264_nvenc] Cannot load libcuda.so.1` — `dlopen()` silently returns NULL

**Symptom.** Binary builds, `checkelf --cuda` passes, but at runtime
`dlopen("libcuda.so.1")` returns NULL. `strace -e openat` shows ffmpeg never
even attempts to open any libcuda file — no syscall fires at all.

**Root cause.** Two independent musl traps stacked together:

1. **`-static-pie` has no dynamic loader.** A static-pie musl binary cannot
   `dlopen()` anything by definition.
2. **musl's static `libc.a` ships a 25-byte `dlopen` stub** that always returns
   `NULL` with `errno=ENOSYS`. Even after switching to dynamic-PIE, gcc's
   `--toolchain=hardened` spec file kept emitting late references that pulled
   `libc.a` back in, restoring the stub inside the binary. The bug was
   invisible to standard checks: `BIND_NOW`, `RELRO`, `PIE`, NX stack all
   passed; `ldd` still showed only one extra NEEDED entry. Only
   `readelf -s --dyn-syms /ffmpeg | grep dlopen` revealed:
   ```
   21987: 000000000338c50e   25 FUNC WEAK DEFAULT 14 dlopen
   ```
   — `dlopen` defined inside `.text` at 25 bytes, not `UND`.

   Variants tried that did NOT fix it:
   - `--extra-libs=' -lgomp -Wl,-Bdynamic -lc '` reorder — gcc spec file re-pulled `libc.a`.
   - Hiding `/usr/lib/libc.a` during link — broke libgme configure-time symbol checks.

**Fix (Layers 1 + 2).**

1. Link mode: replace `add_ldexeflags -fPIE -static-pie` with `-fPIE -pie`.
2. Link the musl combined loader/libc by **absolute path** in
   `--extra-ldflags`, so the linker resolution is immune to `-Bstatic` /
   `-Bdynamic` toggles and gcc spec-file re-emissions:
   ```sh
   --extra-ldflags='-fopenmp -Wl,--allow-multiple-definition \
       -Wl,-z,stack-size=2097152 \
       -Wl,--no-as-needed,/lib/ld-musl-x86_64.so.1,--as-needed \
       -Wl,--as-needed -Wl,-Bstatic \
       -static-libstdc++ -static-libgcc'
   --extra-libs='-lgomp -Wl,-Bdynamic -lc'
   ```

   On Alpine, `/lib/ld-musl-x86_64.so.1` is *both* the dynamic loader and libc;
   one absolute filename covers everything we needed `-lc` for. An absolute
   filename is opened literally regardless of `-Bstatic` mode and cannot be
   re-resolved against `libc.a`.

**Verification.**
```sh
readelf -s --dyn-syms /ffmpeg | grep -E 'dlopen|dlsym|dlerror|dlclose'
# Each must be 0-size UND, OR not exported (resolved internally against
# the absolute-path libc — both work). The functional NVENC encode is
# the ground truth; readelf is the cheap pre-flight.
```

**Lesson.** Never link musl `libc.a` into a binary that calls `dlopen` — it
will silently use the stub. The `-Bdynamic -lc -Bstatic` reorder is fragile
under `--toolchain=hardened`; prefer the absolute-path form.

---

### P2. `checkelf` rejects the dynamic-PIE binary

**Symptom.** The CUDA build's hardening check rejects the binary because it
has a `NEEDED` entry (libc), whereas the default build has zero.

**Fix.** Add `--cuda` flag to `checkelf`. In `--cuda` mode it allows the
musl loader/libc entry from `ldd` output (everything else still rejected).
All other hardening checks (RELRO, BIND_NOW, PIE, NX stack) preserved.

---

### P3. `dlopen("libcuda.so.1")` reports "Library not found"

**Symptom.** With driver libs actually mounted by the toolkit,
`dlopen("libcuda.so.1")` still fails with "Library not found".

**Root cause.** musl's default loader search path is
`/lib:/usr/local/lib:/usr/lib`. The NVIDIA Container Toolkit injects driver
libs to `/usr/lib64` (RHEL/Fedora/WSL convention) or
`/usr/lib/x86_64-linux-gnu` (Debian/Ubuntu). musl also doesn't read
`/etc/ld.so.cache`, so the toolkit's `ldconfig` post-start hook is silently
ignored.

**Fix (Layer 3).** Ship a static `/etc/ld-musl-x86_64.path`:
```
/usr/lib/x86_64-linux-gnu
/usr/lib64
/usr/lib/wsl/lib
/usr/lib
/usr/local/lib
/lib
```
Listing all is safe — musl silently skips paths that don't exist.

---

### P4. NVIDIA driver libs reference glibc-internal symbols missing from musl

**Symptom.** Even with libs found, `dlopen("libcuda.so.1.1")` (the WSL2
backend) fails with `Error relocating: <sym>: symbol not found`. Iteratively
discovered missing symbols: `gnu_get_libc_version`, `__register_atfork`,
`dlmopen`, `dlvsym`, etc.

**Root cause.** NVIDIA driver libs are built against glibc.
`gcompat` provides `libc.so.6` / `libm.so.6` / `libpthread.so.0` /
`librt.so.1` as musl wrappers, but is missing `libdl.so.2` (musl folds
`dlopen` into libc) and a number of glibc-internal helpers used by recent
drivers.

**Fix (Layers 4 + 5).**

- Install `gcompat` package.
- Symlink `libdl.so.2 → libgcompat.so.0` (driver's `DT_NEEDED libdl.so.2`).
- Build a small `libnvshim.so` exporting the missing glibc-internal symbols
  and `LD_PRELOAD` it. Final shim payload:

  | Symbol | Implementation |
  |---|---|
  | `gnu_get_libc_version` | return `"2.35"` |
  | `gnu_get_libc_release` | return `"stable"` |
  | `__libc_current_sigrtmin` / `__libc_current_sigrtmax` | musl macros exposed as functions |
  | `__register_atfork` | redirect to `pthread_atfork` |
  | `__cxa_thread_atexit_impl` | no-op |
  | `__libc_single_threaded` | data symbol, value 0 |
  | `secure_getenv` | redirect to `getenv` |
  | `dlmopen` | redirect to `dlopen` (ignore Lmid_t) |
  | `dlvsym` | redirect to `dlsym` (ignore version) |
  | `__libc_dlopen_mode` / `__libc_dlsym` / `__libc_dlclose` | wrappers |

  > **Critical: `libnvshim.so` must NOT export `exit` / `_exit` / `_Exit`.**
  > See P6 — interposing those swallows ffmpeg's real exit status.

**Maintenance note.** Each new NVIDIA driver release may reference one more
glibc-internal symbol. Diagnostic recipe in §3 finds it in <5 minutes; fix
is a one-line addition to `libnvshim.so`.

---

### P5. NVENC encode succeeds but exits 139 (SIGSEGV) at process teardown

**Symptom.** Encode completes successfully (`frame= 60 ... muxing overhead`,
output bytes fully written), then ffmpeg exits with 139.

**Root cause.** libcuda's `__cxa_finalize` / `DT_FINI` destructors run during
`avcodec_close → nvenc_free → cuCtxDestroy` while still inside `main()`.
Those destructors call into glibc-internal state (TLS-destructor unwinding,
pthread_atfork handlers) that musl + gcompat don't fully provide, and crash.

Because the crash is inside `main()` (not after `exit()` is called), no
in-process hook — atexit, `LD_PRELOAD` signal handlers, etc. — can suppress
it cleanly. Attempts at in-process suppression all failed:

| Attempt | Result |
|---|---|
| `nvshim` `exit()` interpose + atexit `_exit()` | SIGSEGV happens *before* `main()` returns; atexit never runs |
| In-process signal handler | Same — crash is in destructor before signal can dispatch |

**Fix (Layer 6).** Out-of-process bash entrypoint wrapper that captures the
real exit code via `${PIPESTATUS[0]}` and downgrades **only** `139 → 0`,
gated on stderr containing no recognized error keyword. Real failures
(mid-encode CUDA OOM, init failures, etc.) propagate unchanged because they
always print an identifiable error first.

```bash
#!/bin/bash
errfile=$(mktemp)
shellerr=$(mktemp)
trap "rm -f \"$errfile\" \"$shellerr\"" EXIT
exec 3>&1
exec 4>&2
exec 2>"$shellerr"
{ /ffmpeg "$@" 2>&1 1>&3 3>&-; } | tee "$errfile" >&4
rc=${PIPESTATUS[0]}
exec 3>&-
exec 2>&4 4>&-
# Filter the bash job-control "Segmentation fault (core dumped)" line.
grep -vE "Segmentation fault.*core dumped.*/ffmpeg" "$shellerr" >&2 || true
# Suppress *only* the known-benign teardown SIGSEGV.
if [ "$rc" = "139" ] && ! grep -qiE "(^|[^a-z])(error|cannot load|conversion failed|not found|invalid|failed|no such)" "$errfile"; then
    exit 0
fi
exit "$rc"
```

ffprobe doesn't need the wrapper — it doesn't open NVENC encoders, so the
crashing destructor path isn't reached.

---

### P6. ffmpeg silently exits 0 on every error path

**Symptom.** Every fatal-error invocation of the CUDA build returned exit
code `0` to the shell, despite ffmpeg printing the correct error messages.
Verified against the non-CUDA `:8.1` baseline:

| Scenario | non-CUDA `:8.1` | CUDA (broken) | CUDA (fixed) |
|---|---|---|---|
| `-c:v this_codec_does_not_exist` | `8` | `0` ❌ | `8` ✅ |
| `-i /no/such/file.mp4` | `254` | `0` ❌ | `254` ✅ |
| `-vf this_filter_does_not_exist` | `8` | `0` ❌ | `8` ✅ |
| Successful encode | `0` | `0` ✅ | `0` ✅ |
| Successful encode (post-teardown SEGV) | n/a | `139` (raw) | `0` (wrapped) |

This was masked at first by an "upgrade exit 0 → 1 when stderr matches a
fatal-error keyword" branch in the wrapper. That made tests pass with a
plausible-looking exit `1`, but it was a workaround, not a fix — the wrong
exit code (`1` instead of `8`/`254`) broke any caller that switched on the
specific code.

**Root-cause discovery.** An `LD_PRELOAD` `dladdr` tracer interposing `_exit`
revealed that on every code path — bad-codec, bad-input, even successful
`-version` — the call to `_exit` came from `libnvshim.so`:
```
[exittrace] _exit(0) ra=0x...  dso=/usr/local/lib/libnvshim.so
```

`libnvshim.so` had been given an `_exit` interposer (and at one point an
`exit` interposer too) as part of the abandoned in-process attempt to
suppress the teardown SIGSEGV (P5). The interposer always invoked
`syscall(SYS_exit_group, 0)` — i.e. it dropped ffmpeg's real exit status
and hard-coded `0`. None of the standard ELF / readelf / `nm` checks flag
this: the interposer is in a separately-loaded DSO, not in `/ffmpeg`, and
musl's PLT happily binds `_exit` to whichever DSO comes first in symbol
search order — `LD_PRELOAD` always wins.

**Fix.** Drop the `_exit` (and `exit`) overrides from `libnvshim.so`
entirely. They were never needed for any glibc→musl ABI gap (those are all
the symbols in P4). Process-lifecycle suppression belongs in the
out-of-process bash wrapper (P5), where it can read the real exit status via
`${PIPESTATUS[0]}` and pattern-match on actual error keywords.

After removing the interposers, all standard ffmpeg exit codes match the
non-CUDA build byte-for-byte.

**Lesson (now baked into Layer 5).** `LD_PRELOAD` shims should be the
*minimum* symbol set that closes the glibc→musl ABI gap. Any
process-lifecycle hook (exit, signal, atexit) added to such a shim will
silently apply to *every* call from the host program, not just the one
CUDA-driver call you were trying to fix. **Keep lifecycle policy
out-of-process.**

---

### P7. Other small issues encountered (one-line each)

| # | Issue | Fix |
|---|---|---|
| 1 | `nv-codec-headers` checksum mismatch | Recompute SHA256 against actual GitHub release tarball |
| 2 | ffmpeg link failed because `LDFLAGS` was set unconditionally and conflicted with `-static-pie` in non-CUDA branch | Gate the `LDFLAGS` export on `ENABLE_CUDA` only |
| 3 | Spurious dynamic deps (`libgomp`, `libdrm`, …) | Pre-link with `-Wl,-Bstatic` + `-static-libgcc -static-libstdc++` |
| 4 | Toolkit only mounted 180 KB stub `libcuda.so.1` (no `libnvcuvid` / `libnvidia-encode`) | Bake `ENV NVIDIA_DRIVER_CAPABILITIES=compute,video,utility` into image |
| 5 | WSL2 + nvidia-container-toolkit 1.19 SIGSEGV during prestart hook | Host-side regression unrelated to image; `wsl --shutdown` + restart |

---

## 3. Diagnostics

### 3a. Quick image probe (link state, env, driver libs, dlopen, encode)

```sh
IMG=mwader/static-ffmpeg:8.1-cuda
docker run --rm --gpus all --entrypoint sh "$IMG" -c '
  apk add --no-cache gcc musl-dev binutils strace >/dev/null

  echo "=== 1. Linkage ==="
  ldd /ffmpeg
  readelf -d /ffmpeg | grep -E "NEEDED|BIND_NOW"

  echo "=== 2. musl loader path ==="
  cat /etc/ld-musl-x86_64.path

  echo "=== 3. Driver libs mounted ==="
  ls -lh /usr/lib64/libcuda.so.1 /usr/lib64/libnv*.so.1 \
         /usr/lib/wsl/drivers/nv_dispi.inf_amd64_*/libcuda.so.1.1 2>/dev/null

  echo "=== 4. Standalone dlopen + cuInit ==="
  cat > /t.c <<EOF
#include <dlfcn.h>
#include <stdio.h>
int main(void){
  void *h = dlopen("libcuda.so.1", RTLD_LAZY);
  if(!h){fprintf(stderr,"FAIL: %s\n",dlerror());return 1;}
  int (*ci)(unsigned)=(int(*)(unsigned))dlsym(h,"cuInit");
  fprintf(stderr,"cuInit=%d\n", ci?ci(0):-99);
  return 0;
}
EOF
  gcc /t.c -o /t && /t

  echo "=== 5. ffmpeg openat trace for h264_nvenc ==="
  strace -e trace=openat,access -f -o /tmp/ff.strace /ffmpeg \
      -hide_banner -loglevel error \
      -f lavfi -i testsrc=size=320x240:rate=30 -t 1 \
      -c:v h264_nvenc -f null - 2>&1 | tail -3
  grep -E "cuda|nvidia|nvcuvid|libnv|/dev/dxg|/dev/nvidia" /tmp/ff.strace | head -40
'
```

### 3b. "Wrong exit code" regression check (guards against P6)

```sh
docker run --rm --gpus all --entrypoint sh "$IMG" -c '
  apk add --no-cache gcc musl-dev >/dev/null
  cat > /tmp/t.c <<EOF
#define _GNU_SOURCE
#include <dlfcn.h>
#include <stdio.h>
#include <unistd.h>
#include <sys/syscall.h>
__attribute__((noreturn)) void _exit(int s){
  void *ra=__builtin_return_address(0); Dl_info i={0}; dladdr(ra,&i);
  dprintf(2,"[trace] _exit(%d) dso=%s\n",s,i.dli_fname?i.dli_fname:"?");
  syscall(SYS_exit_group,s); __builtin_unreachable();
}
EOF
  gcc -O0 -fPIC -shared -o /tmp/t.so /tmp/t.c -ldl
  LD_PRELOAD="/tmp/t.so:${LD_PRELOAD}" /ffmpeg -hide_banner -loglevel error \
    -f lavfi -i testsrc=duration=1:size=320x240:rate=30 \
    -c:v this_codec_does_not_exist -f null -
'
# The traced _exit MUST show dso=/lib/ld-musl-x86_64.so.1 (i.e. real libc).
# If it shows dso=/usr/local/lib/libnvshim.so → P6 regression is back.
```

### 3c. dlopen-stub regression check (guards against P1)

```sh
docker run --gpus all --rm --entrypoint sh "$IMG" -c '
  apk add --no-cache binutils >/dev/null 2>&1
  readelf -s --dyn-syms /ffmpeg | grep -E "dlopen|dlsym|dlerror|dlclose"
'
# Each must be 0-size UND (or not exported at all). A non-zero size in .text
# (e.g. " 25 FUNC ... 14 dlopen") means the static stub bug is back.
```

---

## 4. Build & verify

### Build

```sh
cd /path/to/static-ffmpeg

docker build --no-cache \
    --build-arg ENABLE_CUDA=1 \
    --target final-cuda \
    -t mwader/static-ffmpeg:8.1-cuda .
```

> Use `--no-cache` if you previously built `:8.1-cuda` with broken link
> flags — Docker will otherwise reuse the cached ffmpeg layer that contains
> the static `dlopen` stub. Full rebuild ~45–75 min (libaom, libvmaf, x265,
> svt-av1, vvenc dominate).

If you only changed the `final-cuda` stage (env, ld-musl path, wrapper),
`--no-cache` is unnecessary.

### Final verification recipe (all five must pass)

```sh
IMG=mwader/static-ffmpeg:8.1-cuda

# 1. Static-ness check (exactly one NEEDED entry: musl libc)
docker run --rm --entrypoint sh "$IMG" -c '
  apk add --no-cache binutils >/dev/null 2>&1
  readelf -d /ffmpeg | grep -E "NEEDED|BIND_NOW"
'

# 2. NVENC encode end-to-end
docker run --rm --gpus all "$IMG" \
    -hide_banner -loglevel error \
    -f lavfi -i testsrc=duration=2:size=1280x720:rate=30 \
    -c:v h264_nvenc -f null - ; echo "exit=$? (must be 0)"

# 3. MP4-to-stdout byte-exactness (wrapper passthrough)
docker run --rm --gpus all "$IMG" \
    -hide_banner -loglevel error \
    -f lavfi -i testsrc=duration=1:size=320x240:rate=30 \
    -c:v h264_nvenc -f mp4 -movflags frag_keyframe+empty_moov - 2>/dev/null \
    | wc -c   # must print > 0

# 4. ffprobe sanity (no wrapper)
docker run --rm --gpus all --entrypoint /ffprobe "$IMG" -version >/dev/null
echo "exit=$? (must be 0)"

# 5. Exit-code parity vs non-CUDA :8.1 (regression guard for P6)
docker run --rm --gpus all "$IMG" -hide_banner -loglevel error \
    -f lavfi -i testsrc=duration=1:size=320x240:rate=30 \
    -c:v this_codec_does_not_exist -f null - ; echo "exit=$? (must be 8)"
docker run --rm --gpus all "$IMG" -hide_banner -loglevel error \
    -i /no/such/file.mp4 -f null - ; echo "exit=$? (must be 254)"
```

---

## 5. Runtime requirements

### Host
- NVIDIA driver installed.
- [NVIDIA Container Toolkit](https://github.com/NVIDIA/nvidia-container-toolkit) installed and configured for Docker.
- Run with `--gpus all` (or `--runtime=nvidia` + `NVIDIA_VISIBLE_DEVICES`).

### Image-side env (set by Dockerfile)
- `NVIDIA_VISIBLE_DEVICES=all`
- `NVIDIA_DRIVER_CAPABILITIES=compute,utility,video`
  - `compute` → `libcuda.so.1`
  - `video` → `libnvcuvid.so`, `libnvidia-encode.so`
  - Dropping `video` makes `nvidia-smi` work but breaks `h264_nvenc` with `Cannot load libcuda.so.1`.

### Toolkit driver-injection layouts covered by `/etc/ld-musl-x86_64.path`
- Debian/Ubuntu hosts → `/usr/lib/x86_64-linux-gnu`
- RHEL/Fedora hosts   → `/usr/lib64`
- WSL2                → `/usr/lib/wsl/lib`

---

## 6. Runtime call chain (six layers in action)

```
docker run --gpus all  ⇒  toolkit injects libcuda.so.1 → /usr/lib64
                          + sets NVIDIA_DRIVER_CAPABILITIES from image ENV
       │
       ▼
ffmpeg-cuda-entrypoint (bash)               ← Layer 6 (P5)
       │ exec
       ▼
/ffmpeg  (musl dynamic-PIE, libc-only NEEDED)               ← Layer 2 (P1)
       │ ld.so loads libc.musl-x86_64.so.1
       │   (search path includes /usr/lib64 from /etc/ld-musl-x86_64.path)   ← Layer 3 (P3)
       │ LD_PRELOAD → /usr/local/lib/libnvshim.so                            ← Layer 5 (P4)
       ▼
ffnvcodec dynlink_loader.h:
       dlopen("libcuda.so.1", RTLD_LAZY)    ← needs Layer 1 (real PLT entry, P1)
       │
       ▼ ld.so loads libcuda.so.1 (WSL stub)
       │   resolves DT_NEEDED libdl.so.2 → libgcompat.so.0                   ← Layer 4 (P4)
       │
       ▼ libcuda dlopens its WSL backend libcuda.so.1.1
       │   resolves glibc-internals via libnvshim.so                         ← Layer 5 (P4)
       │
       ▼ encode runs successfully, frames produced, output flushed
       │
       ▼ ffmpeg main() → avcodec_close → cuCtxDestroy
       │   libcuda __cxa_finalize crashes during teardown          ☠ SIGSEGV (P5)
       │
       ▼ wrapper sees exit=139, no error keyword in stderr → exit 0         ← Layer 6 (P5)
```

---

## 7. Comparison with other static ffmpeg + nvenc projects

| Project | Static? | NVENC? | Approach |
|---|---|---|---|
| `mwader/static-ffmpeg:8.1` | ✅ static-pie musl | ❌ | Pure static, no dlopen |
| `mwader/static-ffmpeg:8.1-cuda` | ⚠️ musl dynamic-PIE (libc only) | ✅ | Hybrid — only libc dynamic; `dlopen()` works |
| BtbN/FFmpeg-Builds (LGPL/GPL) | ⚠️ glibc dynamic + runtime ldconfig | ✅ | Tarball, glibc-linked |
| HiWay-Media/ffmpeg-nvenc-static | ⚠️ glibc dynamic | ✅ | Bundled libs |
| markus-perl/ffmpeg-build-script | ⚠️ glibc dynamic | optional | Script, not container |

Of these, only `:8.1-cuda` keeps every codec/lib statically linked — every
other "static + nvenc" build is glibc-dynamic. The trade-off vs the default
`:8.1` is exactly one libc.so dependency.

---

## 8. CI / publishing notes

- Default tag: built for `linux/amd64,linux/arm64` as before.
- CUDA tag: built for `linux/amd64` only.
  - Pushed as `<tag>-cuda` (and re-tagged manifest-style as `<tag>-cuda-amd64` for clarity).
  - `latest-cuda` follows latest stable.
- Use `--target final-cuda` and `--build-arg ENABLE_CUDA=1` in the CI matrix.

