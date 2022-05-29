## static-ffmpeg

Docker image with [FFmpeg/FFprobe](https://ffmpeg.org) built as hardened, static PIE binaries
with no external dependencies. Can be used with any base image even scratch.

Since version 5.0.1-3 dockerhub images are multi-arch amd64 and arm64 images.

Built with the following statically-linked libraries:

- fontconfig
- gray
- iconv
- libaom
- libass
- libbluray
- libdav1d
- libdavs2
- libfdk-aac
- libfreetype
- libfribidi
- libgme
- libgsm
- libkvazaar
- libmodplug
- libmodplug
- libmp3lame
- libmysofa
- libopencore
- libopenjpeg
- libopus
- librabbitmq
- librav1e
- librtmp
- librubberband
- libshine
- libsoxr
- libspeex
- libsrt
- libssh
- libsvtav1
- libtheora
- libtwolame
- libuavs3d
- libvidstab
- libvmaf
- libvorbis
- libvpx
- libwebp
- libx264
- libx265
- libxavs2
- libxml2
- libxvid
- libzimg
- openssl

and all native [FFmpeg](https://ffmpeg.org) codecs, formats, filters etc.

See [Dockerfile](Dockerfile) for versions used. In general, master **should** have the
latest stable version of [FFmpeg](https://ffmpeg.org) and above libraries.
Versions are kept up to date automatically using [bump](https://github.com/wader/bump).

### Usage

Use `mwader/static-ffmpeg` from Docker Hub or build image yourself.

In Dockerfile
```Dockerfile
COPY --from=mwader/static-ffmpeg:5.0.1-3 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:5.0.1-3 /ffprobe /usr/local/bin/
```

Run directly
```sh
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:5.0.1-3 -i file.wav file.mp3
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:5.0.1-3 -i file.wav
```

As a shell/Bash alias
```sh
alias ffmpeg='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:5.0.1-3'
alias ffprobe='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:5.0.1-3'
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

### Known issues and ticks

#### Quickly see what versions an image was build with

```
docker run --rm <image> -v quiet -f data -i versions.json -map 0:0 -c text -f data -
```

#### I see `Name does not resolve` errors for hosts that should resolve

This could happen if the hostname resolve to more IP-addresses than can fit in [DNS UDP packet](https://www.rfc-editor.org/rfc/rfc791)
(probably 512 bytes) causing the response to be truncated. Usually clients should then switch
to TCP and redo the query but [musl libc](https://www.musl-libc.org) does not currently support [DNS over TCP](https://wiki.musl-libc.org/functional-differences-from-glibc.html#Name-Resolver/DNS).

### TLS

Binaries are built with TLS support but, by default, [FFmpeg](https://ffmpeg.org) currently do
not do certificate verification. To enable verification you need to run
[FFmpeg](https://ffmpeg.org) with `-tls_verify 1` and `-ca_file /path/to/cert.pem`.

- Alpine Linux at `/etc/ssl/cert.pem`
- Debian/Ubuntu install the `ca-certificates` package at it will be available at `/etc/ssl/certs/ca-certificates.crt`.

### Dockerhub images

Multi-arch dockerhub images are built using [pldin601/build-multiarch-on-aws-spots](https://github.com/pldin601/build-multiarch-on-aws-spots). See [build-multiarch.yml](.github/workflows/build-multiarch.yml) for config. Thanks to [@pldin601](https://github.com/pldin601) for making this possible.

### Contribute

Feel free to create issues or PRs if you have any improvements or encounter any problems.
Please also consider making a [donation to the FFmpeg project](https://ffmpeg.org/donations.html)
or to other projects used by this image if you find it useful.

Please also be mindful of the license limitations used by libraries this project uses and your own
usage and potential distribution of such.

### TODOs and possible things to add

- Add libplacebo, chromaprint, rtmp, etc. ...
- Add lcms2 support once in stable
- Add libjxl support once in stable
- Add xeve/xevd support once in stable
- Add acceleration support (GPU, CUDA, ...)
- Add *.a *.so libraries, headers and pkg-config somehow
- Use cargo-c stable Alpine package
