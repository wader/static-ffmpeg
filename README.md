## static-ffmpeg

Docker image with ffmpeg, ffprobe and qt-faststart binaries built as hardened static PIE
binaries with no external dependencies. Can be used with any base image even
scratch.

Built with
gray,
openssl,
iconv,
libxml2,
libmp3lame,
libfdk-aac,
libvorbis,
libopus,
libtheora,
libvpx,
libx264,
libx265,
libwebp,
libwavpack,
libspeex,
libaom,
libvidstab,
libkvazaar,
libfreetype,
fontconfig,
libfribidi,
libass,
libzimg,
libsoxr,
libopenjpeg,
libdav1d,
libxvid
and all default native ffmpeg codecs.

### Usage

Use `mwader/static-ffmpeg` from docker hub or build image yourself.

In Dockerfile
```Dockerfile
COPY --from=mwader/static-ffmpeg:4.3.1-1 /ffmpeg /usr/local/bin/
COPY --from=mwader/static-ffmpeg:4.3.1-1 /ffprobe /usr/local/bin/
COPY --from=mwader/static-ffmpeg:4.3.1-1 /qt-faststart /usr/local/bin/
```
Run directly
```sh
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.3.1-1 -i file.wav file.mp3
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:4.3.1-1 -i file.wav
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/qt-faststart mwader/static-ffmpeg:4.3.1-1 file.mov out.mov
```
Bash alias
```sh
alias ffmpeg='docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.3.1-1'
alias ffprobe='docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:4.3.1-1'
alias qt-faststart='docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/qt-faststart mwader/static-ffmpeg:4.3.1-1'
```

### Files in the image
`/ffmpeg` ffmpeg binary  
`/ffprobe` ffprobe binary  
`/qt-faststart` qt-faststart binary  
`/doc` Documentation  
`/versions.json` JSON file with ffmpeg and library versions  
`/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly

### Security

Binaries are built with various hardening features but it's probably still a good idea to run
them as non-root even when used inside a container, especially so if running on input files
that you don't control.

### Known issues

#### I see `Name does not resolve` errors for hosts that should resolve

This could happen if the hostname resolve to more IP-addresses than can fit in DNS UDP packet
(probably 512 bytes) causing the response to be truncated. Usually clients should then switch
to TCP and redo the query but musl libc does currently not support DNS over TCP.

### TLS

Binaries are built with TLS support but by default ffmpeg currently do
not do certificate verifications. To enable verification you need to run
ffmpeg with `-tls_verify 1` and `-ca_file /path/to/cert.pem`. For alpine
the ca file is included by default at `/etc/ssl/cert.pem` and for debian/ubuntu
you have to install the `ca-certificates` package which will install the file at
`/etc/ssl/certs/ca-certificates.crt`.

### Contribute

Feel free to create issues or PRs if you have any improvements or problems.
Please also consider making a [donation](https://ffmpeg.org/donations.html) to
the FFmpeg project or to other projects used by this image if you find it useful.

### TODOs and possible things to add

* Add [SVT-AV1]support when in stable
* Add [vmaf](https://github.com/Netflix/vmaf) support
* Add [rav1e](https://github.com/xiph/rav1e) support [#29](https://github.com/wader/static-ffmpeg/pull/29)
* Add acceleration support (GPU, CUDA, ...)
* Add *.a *.so libraries, headers and pkg-config somehow
