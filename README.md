## static-ffmpeg

Image with ffmpeg and ffprobe binaries built as hardened static PIE binaries with no
external dependencies. Can be used with any base image even scratch.

Built with
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
libopenjpeg
and all default native ffmpeg codecs.

### Usage
```Dockerfile
COPY --from=mwader/static-ffmpeg:4.1.4 /ffmpeg /ffprobe /usr/local/bin/
```
```sh
docker run --rm -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.1.4 -i file.wav file.mp3
```
```sh
docker run --rm --entrypoint=/ffprobe -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.1.4 -i file.wav
```

### Files in the image
`/ffmpeg` ffmpeg binary  
`/ffprobe` ffprobe binary  
`/doc/*` ffmpeg documentation  
`/versions.json` JSON file with ffmpeg and library versions

### TLS

Binaries are built with TLS support but by default ffmpeg currently do
not do certificate verifications. To enable verification you need to run
ffmpeg with `-tls_verify 1` and `-ca_file /path/to/cert.pem`. For alpine
the ca file is included by default at `/etc/ssl/cert.pem` and for debian/ubuntu
you have to install the `ca-certificates` package which will install the file at
`/etc/ssl/certs/ca-certificates.crt`.
