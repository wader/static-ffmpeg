# bump: alpine /ALPINE_VERSION=alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
ARG ALPINE_VERSION=alpine:3.20.2
FROM $ALPINE_VERSION AS builder

# Alpine Package Keeper options
ARG APK_OPTS=""

RUN apk add --no-cache $APK_OPTS \
  coreutils \
  wget \
  rust cargo cargo-c \
  openssl-dev openssl-libs-static \
  ca-certificates \
  bash \
  tar \
  build-base \
  autoconf automake \
  libtool \
  diffutils \
  cmake meson ninja \
  git \
  yasm nasm \
  texinfo \
  jq \
  zlib-dev zlib-static \
  bzip2-dev bzip2-static \
  libxml2-dev libxml2-static \
  expat-dev expat-static \
  fontconfig-dev fontconfig-static \
  freetype freetype-dev freetype-static \
  graphite2-static \
  tiff tiff-dev \
  libjpeg-turbo libjpeg-turbo-dev \
  libpng-dev libpng-static \
  giflib giflib-dev \
  fribidi-dev fribidi-static \
  brotli-dev brotli-static \
  soxr-dev soxr-static \
  tcl \
  numactl-dev \
  cunit cunit-dev \
  fftw-dev \
  libsamplerate-dev libsamplerate-static \
  vo-amrwbenc-dev vo-amrwbenc-static \
  snappy snappy-dev snappy-static \
  xxd \
  xz-dev xz-static \
  python3 py3-packaging \
  linux-headers \
  curl

# linux-headers need by rtmpdump
# python3 py3-packaging needed by glib
  
# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG LDFLAGS="-Wl,-z,relro,-z,now"

# retry dns and some http codes that might be transient errors
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503"

# --no-same-owner as we don't care about uid/gid even if we run as root. fixes invalid gid/uid issue.
ARG TAR_OPTS="--no-same-owner --extract --file"

# own build as alpine glib links with libmount etc
# bump: glib /GLIB_VERSION=([\d.]+)/ https://gitlab.gnome.org/GNOME/glib.git|^2
# bump: glib after ./hashupdate Dockerfile GLIB $LATEST
# bump: glib link "NEWS" https://gitlab.gnome.org/GNOME/glib/-/blob/main/NEWS?ref_type=heads
ARG GLIB_VERSION=2.82.0
ARG GLIB_URL="https://download.gnome.org/sources/glib/2.82/glib-$GLIB_VERSION.tar.xz"
ARG GLIB_SHA256=f4c82ada51366bddace49d7ba54b33b4e4d6067afa3008e4847f41cb9b5c38d3
RUN \
  wget $WGET_OPTS -O glib.tar.xz "$GLIB_URL" && \
  echo "$GLIB_SHA256  glib.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS glib.tar.xz && cd glib-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static \
    -Dlibmount=disabled && \
  ninja -j$(nproc) -vC build install

# bump: harfbuzz /LIBHARFBUZZ_VERSION=([\d.]+)/ https://github.com/harfbuzz/harfbuzz.git|*
# bump: harfbuzz after ./hashupdate Dockerfile LIBHARFBUZZ $LATEST
# bump: harfbuzz link "NEWS" https://github.com/harfbuzz/harfbuzz/blob/main/NEWS
ARG LIBHARFBUZZ_VERSION=9.0.0
ARG LIBHARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/$LIBHARFBUZZ_VERSION/harfbuzz-$LIBHARFBUZZ_VERSION.tar.xz"
ARG LIBHARFBUZZ_SHA256=a41b272ceeb920c57263ec851604542d9ec85ee3030506d94662067c7b6ab89e
RUN \
  wget $WGET_OPTS -O harfbuzz.tar.xz "$LIBHARFBUZZ_URL" && \
  echo "$LIBHARFBUZZ_SHA256  harfbuzz.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS harfbuzz.tar.xz && cd harfbuzz-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static && \
  ninja -j$(nproc) -vC build install

# bump: cairo /CAIRO_VERSION=([\d.]+)/ https://gitlab.freedesktop.org/cairo/cairo.git|^1
# bump: cairo after ./hashupdate Dockerfile CAIRO $LATEST
# bump: cairo link "NEWS" https://gitlab.freedesktop.org/cairo/cairo/-/blob/master/NEWS?ref_type=heads
ARG CAIRO_VERSION=1.18.2
ARG CAIRO_URL="https://cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz"
ARG CAIRO_SHA256=a62b9bb42425e844cc3d6ddde043ff39dbabedd1542eba57a2eb79f85889d45a
RUN \
  wget $WGET_OPTS -O cairo.tar.xz "$CAIRO_URL" && \
  echo "$CAIRO_SHA256  cairo.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS cairo.tar.xz && cd cairo-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static \
    -Dtests=disabled \
    -Dquartz=disabled \
    -Dxcb=disabled \
    -Dxlib=disabled \
    -Dxlib-xcb=disabled && \
  ninja -j$(nproc) -vC build install

# TODO: there is weird "1.90" tag, skip it
# bump: pango /PANGO_VERSION=([\d.]+)/ https://github.com/GNOME/pango.git|/\d+\.\d+\.\d+/|*
# bump: pango after ./hashupdate Dockerfile PANGO $LATEST
# bump: pango link "NEWS" https://gitlab.gnome.org/GNOME/pango/-/blob/main/NEWS?ref_type=heads
ARG PANGO_VERSION=1.54.0
ARG PANGO_URL="https://download.gnome.org/sources/pango/1.54/pango-$PANGO_VERSION.tar.xz"
ARG PANGO_SHA256=8a9eed75021ee734d7fc0fdf3a65c3bba51dfefe4ae51a9b414a60c70b2d1ed8
# TODO: add -Dbuild-testsuite=false when in stable release
# TODO: -Ddefault_library=both currently to not fail building tests
RUN \
  wget $WGET_OPTS -O pango.tar.xz "$PANGO_URL" && \
  echo "$PANGO_SHA256  pango.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS pango.tar.xz && cd pango-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=both \
    -Dintrospection=disabled \
    -Dgtk_doc=false && \
  ninja -j$(nproc) -vC build install

# bump: librsvg /LIBRSVG_VERSION=([\d.]+)/ https://gitlab.gnome.org/GNOME/librsvg.git|^2
# bump: librsvg after ./hashupdate Dockerfile LIBRSVG $LATEST
# bump: librsvg link "NEWS" https://gitlab.gnome.org/GNOME/librsvg/-/blob/master/NEWS
ARG LIBRSVG_VERSION=2.58.94
ARG LIBRSVG_URL="https://download.gnome.org/sources/librsvg/2.58/librsvg-$LIBRSVG_VERSION.tar.xz"
ARG LIBRSVG_SHA256=05adf6dc58b3cfb319c2efb02b2bbdff5c75ca47cc941d48098839f20496abed
RUN \
  wget $WGET_OPTS -O librsvg.tar.xz "$LIBRSVG_URL" && \
  echo "$LIBRSVG_SHA256  librsvg.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS librsvg.tar.xz && cd librsvg-* && \
  echo -e '[profile.release]\nlto = "off"\n' >> Cargo.toml && \
  sed -i 's/default-members = ["rsvg", "rsvg_convert"]/default-members = ["rsvg"]/g' Cargo.toml && \
  sed -i "s/subdir('rsvg_convert')//g" meson.build && \
  meson setup build \
    -Dbuildtype=debug \
    -Ddefault_library=static \
    -Ddocs=disabled \
    -Dintrospection=disabled \
    -Dpixbuf=disabled \
    -Dpixbuf-loader=disabled \
    -Dvala=disabled \
    -Dtests=false \
    -Ddocs=disabled && \
  ninja -C build -t targets all && \
  RUSTFLAGS="-C target-feature=+crt-static" \
  ninja -j$(nproc) -vC build install rsvg/librsvg_2.a

# bump: rav1e /RAV1E_VERSION=([\d.]+)/ https://github.com/xiph/rav1e.git|/\d+\./|*
# bump: rav1e after ./hashupdate Dockerfile RAV1E $LATEST
# bump: rav1e link "Release notes" https://github.com/xiph/rav1e/releases/tag/v$LATEST
ARG RAV1E_VERSION=0.7.1
ARG RAV1E_URL="https://github.com/xiph/rav1e/archive/v$RAV1E_VERSION.tar.gz"
ARG RAV1E_SHA256=da7ae0df2b608e539de5d443c096e109442cdfa6c5e9b4014361211cf61d030c
RUN \
  wget $WGET_OPTS -O rav1e.tar.gz "$RAV1E_URL" && \
  echo "$RAV1E_SHA256  rav1e.tar.gz" | sha256sum -c - && \
  tar $TAR_OPTS rav1e.tar.gz && cd rav1e-* && \
  # workaround weird cargo problem when on aws (?) weirdly alpine edge seems to work
  sed -i 's/debug = true/debug = false/g' Cargo.toml && \
  sed -i 's/lto = "thin"/lto = "off"/g' Cargo.toml && \
  CARGO_REGISTRIES_CRATES_IO_PROTOCOL="sparse" \
  RUSTFLAGS="-C target-feature=+crt-static" \
  cargo cinstall --debug

# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|*
# bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=7.0.2
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=1ed250407ea8f955cca2f1139da3229fbc13032a0802e4b744be195865ff1541
ARG ENABLE_FDKAAC=
# sed changes --toolchain=hardened -pie to -static-pie
#
# ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
# more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
# large things on the stack.
#
# ldfalgs -Wl,--allow-multiple-definition is a workaround for linking with multiple rust staticlib to
# not cause collision in toolchain symbols, see comment in checkdupsym script for details.
RUN \
  wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
  echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum -c - && \
  tar $TAR_OPTS ffmpeg.tar.bz2 && cd ffmpeg* && \
  FDKAAC_FLAGS=$(if [[ -n "$ENABLE_FDKAAC" ]] ;then echo " --enable-libfdk-aac --enable-nonfree " ;else echo ""; fi) && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-cflags="-O0 -ggdb -fopenmp" \
  --extra-ldflags="-fopenmp -Wl,--allow-multiple-definition -Wl,-z,stack-size=2097152" \
  --toolchain=hardened \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-librav1e \
  --enable-librsvg \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

# RUN \
#   EXPAT_VERSION=$(pkg-config --modversion expat) \
#   FFTW_VERSION=$(pkg-config --modversion fftw3) \
#   FONTCONFIG_VERSION=$(pkg-config --modversion fontconfig)  \
#   FREETYPE_VERSION=$(pkg-config --modversion freetype2)  \
#   FRIBIDI_VERSION=$(pkg-config --modversion fribidi)  \
#   LIBSAMPLERATE_VERSION=$(pkg-config --modversion samplerate) \
#   LIBVO_AMRWBENC_VERSION=$(pkg-config --modversion vo-amrwbenc) \
#   LIBXML2_VERSION=$(pkg-config --modversion libxml-2.0) \
#   OPENSSL_VERSION=$(pkg-config --modversion openssl) \
#   SNAPPY_VERSION=$(apk info -a snappy $APK_OPTS | head -n1 | awk '{print $1}' | sed -e 's/snappy-//') \
#   SOXR_VERSION=$(pkg-config --modversion soxr) \
#   jq -n \
#   '{ \
#   expat: env.EXPAT_VERSION, \
#   "libfdk-aac": env.FDK_AAC_VERSION, \
#   ffmpeg: env.FFMPEG_VERSION, \
#   fftw: env.FFTW_VERSION, \
#   fontconfig: env.FONTCONFIG_VERSION, \
#   lcms2: env.LCMS2_VERSION, \
#   libaom: env.AOM_VERSION, \
#   libaribb24: env.LIBARIBB24_VERSION, \
#   libass: env.LIBASS_VERSION, \
#   libbluray: env.LIBBLURAY_VERSION, \
#   libdav1d: env.DAV1D_VERSION, \
#   libdavs2: env.DAVS2_VERSION, \
#   libfreetype: env.FREETYPE_VERSION, \
#   libfribidi: env.FRIBIDI_VERSION, \
#   libgme: env.LIBGME_COMMIT, \
#   libgsm: env.LIBGSM_COMMIT, \
#   libharfbuzz: env.LIBHARFBUZZ_VERSION, \
#   libjxl: env.LIBJXL_VERSION, \
#   libkvazaar: env.KVAZAAR_VERSION, \
#   libmodplug: env.LIBMODPLUG_VERSION, \
#   libmp3lame: env.MP3LAME_VERSION, \
#   libmysofa: env.LIBMYSOFA_VERSION, \
#   libogg: env.OGG_VERSION, \
#   libopencoreamr: env.OPENCOREAMR_VERSION, \
#   libopenjpeg: env.OPENJPEG_VERSION, \
#   libopus: env.OPUS_VERSION, \
#   librabbitmq: env.LIBRABBITMQ_VERSION, \
#   librav1e: env.RAV1E_VERSION, \
#   librsvg: env.LIBRSVG_VERSION, \
#   librtmp: env.LIBRTMP_COMMIT, \
#   librubberband: env.RUBBERBAND_VERSION, \
#   libsamplerate: env.LIBSAMPLERATE_VERSION, \
#   libshine: env.LIBSHINE_VERSION, \
#   libsnappy: env.SNAPPY_VERSION, \
#   libsoxr: env.SOXR_VERSION, \
#   libspeex: env.SPEEX_VERSION, \
#   libsrt: env.SRT_VERSION, \
#   libssh: env.LIBSSH_VERSION, \
#   libsvtav1: env.SVTAV1_VERSION, \
#   libtheora: env.THEORA_VERSION, \
#   libtwolame: env.TWOLAME_VERSION, \
#   libuavs3d: env.UAVS3D_COMMIT, \
#   libvidstab: env.VIDSTAB_VERSION, \
#   libvmaf: env.VMAF_VERSION, \
#   libvo_amrwbenc: env.LIBVO_AMRWBENC_VERSION, \
#   libvorbis: env.VORBIS_VERSION, \
#   libvpx: env.VPX_VERSION, \
#   libwebp: env.LIBWEBP_VERSION, \
#   libx264: env.X264_VERSION, \
#   libx265: env.X265_VERSION, \
#   libxavs2: env.XAVS2_VERSION, \
#   libxevd: env.XEVD_VERSION, \
#   libxeve: env.XEVE_VERSION, \
#   libxml2: env.LIBXML2_VERSION, \
#   libxvid: env.XVID_VERSION, \
#   libzimg: env.ZIMG_VERSION, \
#   libzmq: env.LIBZMQ_VERSION, \
#   openssl: env.OPENSSL_VERSION, \
#   }' > /versions.json

# # make sure binaries has no dependencies, is relro, pie and stack nx
# COPY checkelf /
# RUN \
#   /checkelf /usr/local/bin/ffmpeg && \
#   /checkelf /usr/local/bin/ffprobe
# # workaround for using -Wl,--allow-multiple-definition
# # see comment in checkdupsym for details
# COPY checkdupsym /
# RUN /checkdupsym /ffmpeg-*

# # some basic fonts that don't take up much space
# RUN apk add $APK_OPTS font-terminus font-inconsolata font-dejavu font-awesome

# FROM scratch AS final1
# COPY --from=builder /usr/local/bin/ffmpeg /
# COPY --from=builder /usr/local/bin/ffprobe /
# COPY --from=builder /versions.json /
# COPY --from=builder /usr/local/share/doc/ffmpeg/* /doc/
# COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem
# COPY --from=builder /etc/fonts/ /etc/fonts/
# COPY --from=builder /usr/share/fonts/ /usr/share/fonts/
# COPY --from=builder /usr/share/consolefonts/ /usr/share/consolefonts/
# COPY --from=builder /var/cache/fontconfig/ /var/cache/fontconfig/

# # sanity tests
# RUN ["/ffmpeg", "-version"]
# RUN ["/ffprobe", "-version"]
# RUN ["/ffmpeg", "-hide_banner", "-buildconf"]
# # stack size
# # RUN ["/ffmpeg", "-f", "lavfi", "-i", "testsrc", "-c:v", "libsvtav1", "-t", "100ms", "-f", "null", "-"]
# # dns
# # RUN ["/ffprobe", "-i", "https://github.com/favicon.ico"]
# # tls/https certs
# # RUN ["/ffprobe", "-tls_verify", "1", "-ca_file", "/etc/ssl/cert.pem", "-i", "https://github.com/favicon.ico"]
# # svg
# # RUN ["/ffprobe", "-i", "https://github.githubassets.com/favicons/favicon.svg"]
# # >1 static rust libs
# RUN ["/ffmpeg", "-f", "lavfi", "-i", "testsrc", "-c:v", "librav1e", "-t", "100ms", "-f", "null", "-"]

# # clamp all files into one layer
# FROM scratch AS final2
# COPY --from=final1 / /

# FROM final2
# LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
# ENTRYPOINT ["/ffmpeg"]
