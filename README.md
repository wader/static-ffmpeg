## static-ffmpeg

Docker image with
[ffmpeg](https://ffmpeg.org/ffmpeg.html) and
[ffprobe](https://ffmpeg.org/ffprobe.html)
built as hardened static PIE binaries with no external dependencies that can be
used with any base image.

See [Dockerfile](Dockerfile) for versions used. In general, master **should** have the
latest stable version of ffmpeg and below libraries.
Versions are kept up to date automatically using [bump](https://github.com/wader/bump).

### Usage

Use `mwader/static-ffmpeg` from Docker Hub or build image yourself.

In Dockerfile
```Dockerfile
COPY --from=mwader/static-ffmpeg:6.1.1 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:6.1.1 /ffprobe /usr/local/bin/
```

Run directly
```sh
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:6.1.1 -i file.wav file.mp3
docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:6.1.1 -i file.wav
```

As shell alias
```sh
alias ffmpeg='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:6.1.1'
alias ffprobe='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:6.1.1'
```

### Libraries

- fontconfig
- gray
- iconv
- lcms2
- libaom
- libaribb24
- libass
- libbluray
- libdav1d
- libdavs2
- libfdk-aac (only if explicitly enabled during build, [see below](#libfdk-aac))
- libfreetype
- libfribidi
- libgme
- libgsm
- libkvazaar
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
- libsnappy
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
- libvo-amrwbenc
- libvorbis
- libvpx
- libwebp
- libx264
- libx265 (multilib with support for 10 and 12 bits)
- libxavs2
- libxml2
- libxvid
- libzimg
- openssl
- and all native ffmpeg codecs, formats, filters etc.

### Files in the image

- `/ffmpeg` ffmpeg binary
- `/ffprobe` ffprobe binary
- `/doc` Documentation
- `/versions.json` JSON file with build versions of ffmpeg and libraries.
- `/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly

### Tags

`latest` Latest master build.

`MAJOR.MINOR.PATCH[-BUILD]` Specific version of FFmpeg with the features that was in master at the time of tagging.
`-BUILD` means that was an additional build with that version to add of fix something.

### Security

Binaries are built with various hardening features but it's *still a good idea to run them
as non-root even when used inside a container*, especially so if running on input files that
you don't control.

### libfdk-aac
Due to license issues the docker image does not include libfdk-aac by default. A docker image including libfdk-aac can be built by passing a non empty value to the build-arg `ENABLE_FDKAAC`, example below.
```
docker build --build-arg ENABLE_FDKAAC=1 . -t my-ffmpeg-static:latest
```

### Known issues and tricks

#### Multi-arch and arm64

Since version 5.0.1-3 dockerhub images are multi-arch amd64 and arm64 images.

#### Copy out binaries from image

This will copy `ffmpeg` and `ffprobe` to the current directory:
```
docker run --rm -v "$PWD:/out" $(echo -e 'FROM alpine\nCOPY --from=mwader/static-ffmpeg:latest /ff* /\nENTRYPOINT cp /ff* /out' | docker build -q -)
```

#### Quickly see what versions an image was built with

```
docker run --rm mwader/static-ffmpeg -v quiet -f data -i versions.json -map 0:0 -c text -f data -
```

#### I see `Name does not resolve` errors for hosts that should resolve

This could happen if the hostname resolve to more IP-addresses than can fit in [DNS UDP packet](https://www.rfc-editor.org/rfc/rfc791) (probably 512 bytes) causing the response to be truncated. Usually clients should then switch to TCP and redo the query.
This should only be a problem with version 6.0-1 or earlier of this image that uses [musl libc](https://www.musl-libc.org) 1.2.3 or older.

### TLS

Binaries are built with TLS support but, by default, ffmpeg currently do
not do certificate verification. To enable verification you need to run
ffmpeg with `-tls_verify 1` and `-ca_file /path/to/cert.pem`.

- Alpine Linux at `/etc/ssl/cert.pem`
- Debian/Ubuntu install the `ca-certificates` package at it will be available at `/etc/ssl/certs/ca-certificates.crt`.

### Docker Hub images

Multi-arch dockerhub images are built using [pldin601/build-multiarch-on-aws-spots](https://github.com/pldin601/build-multiarch-on-aws-spots). See [build-multiarch.yml](.github/workflows/build-multiarch.yml) for config. Thanks to [@pldin601](https://github.com/pldin601) for making this possible.

### Contribute

Feel free to create issues or PRs if you have any improvements or encounter any problems.
Please also consider making a [donation to the FFmpeg project](https://ffmpeg.org/donations.html)
or to other projects used by this image if you find it useful.

Please also be mindful of the license limitations used by libraries this project uses and your own
usage and potential distribution of such.

### TODOs and possible things to add

- Add libplacebo, chromaprint, etc. ...
- Add libjxl support once in stable
- Add xeve/xevd support once in stable
- Add acceleration support (GPU, CUDA, ...)
- Add *.a *.so libraries, headers and pkg-config somehow
