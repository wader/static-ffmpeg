## static-ffmpeg

Docker image with [FFmpeg/FFprobe](https://ffmpeg.org) built as hardened, static PIE binaries
with no external dependencies. Can be used with any base image even scratch.

Built with the following statically-linked libraries:

- gray
- OpenSSL
- iconv
- libxml2
- libmp3lame
- libtwolame
- libfdk-aac
- libvorbis
- libopus
- libmodplug
- libtheora
- libvpx
- libx264
- libx265
- libwebp
- libspeex
- libvmaf
- libaom
- libvidstab
- libkvazaar
- libfreetype
- fontconfig
- libfribidi
- libass
- libzimg
- libsoxr
- libopenjpeg
- libdav1d
- libxvid
- librav1e
- libsrt
- libsvtav1
- libdavs2
- libxavs2
- libmodplug
- libuavs3d
- libmysofa
- librubberband
- libgme
- libopencore
- libssh
- libshine

and all native [FFmpeg](https://ffmpeg.org) codecs, formats, filters etc.

See [Dockerfile](Dockerfile) for versions used. In general, master **should** have the
latest stable version of [FFmpeg](https://ffmpeg.org) and above libraries.
Versions are kept up to date automatically using [bump](https://github.com/wader/bump).

### Usage

Use `mwader/static-ffmpeg` from Docker Hub or build image yourself.

In Dockerfile
```Dockerfile
COPY --from=mwader/static-ffmpeg:5.0 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:5.0 /ffprobe /usr/local/bin/
```

Run directly
```sh
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:5.0 -i file.wav file.mp3
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:5.0 -i file.wav
```

As a shell/Bash alias
```sh
alias ffmpeg='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:5.0'
alias ffprobe='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:5.0'
```

### Files in the image

- `/ffmpeg` [FFmpeg](https://ffmpeg.org) binary
- `/ffprobe` [FFprobe](https://ffmpeg.org/ffprobe.html) binary
- `/doc` Documentation
- `/versions.json` JSON file with [FFmpeg](https://ffmpeg.org) and library versions used at compilation
- `/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly

### Tags

`latest` Latest master build.

`MAJOR.MINOR.PATCH[-BUILD]` Specific version of FFmpeg with the features that was in master at the time of tagging.
`-BUILD` means that was an additional build with that version to add of fix something.

### Security

Binaries are built with various hardening features but it's *still a good idea to run them
as non-root even when used inside a container*, especially so if running on input files that
you don't control.

### Known issues

#### I see `Name does not resolve` errors for hosts that should resolve

This could happen if the hostname resolve to more IP-addresses than can fit in [DNS UDP packet](https://www.rfc-editor.org/rfc/rfc791)
(probably 512 bytes) causing the response to be truncated. Usually clients should then switch
to TCP and redo the query but [musl libc](https://www.musl-libc.org) does not currently support [DNS over TCP](https://wiki.musl-libc.org/functional-differences-from-glibc.html#Name-Resolver/DNS).

### TLS

Binaries are built with TLS support but, by default, [FFmpeg](https://ffmpeg.org) currently do
not do certificate verification. To enable verification you need to run
[FFmpeg](https://ffmpeg.org) with `-tls_verify 1` and `-ca_file /path/to/cert.pem`. For Alpine Linux
the CA file is included by default at `/etc/ssl/cert.pem` and for Debian/Ubuntu
you have to install the `ca-certificates` package which will install the file at
`/etc/ssl/certs/ca-certificates.crt`.

### Contribute

Feel free to create issues or PRs if you have any improvements or encounter any problems.
Please also consider making a [donation to the FFmpeg project](https://ffmpeg.org/donations.html)
or to other projects used by this image if you find it useful.

Please also be mindful of the license limitations used by libraries this project uses and your own
usage and potential distribution of such.

### TODOs and possible things to add

* Add libplacebo, shiny, chromaprint, gsm, rtmp, etc. ...
* Add acceleration support (GPU, CUDA, ...)
* Add *.a *.so libraries, headers and pkg-config somehow
* Use cargo-c stable Alpine package
