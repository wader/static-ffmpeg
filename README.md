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
libopenjpeg,
libdav1d,
libxvid
and all default native ffmpeg codecs.

### Usage
```Dockerfile
COPY --from=mwader/static-ffmpeg:4.2.2 /ffmpeg /ffprobe /usr/local/bin/
```
```sh
docker run --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.2.2 -i file.wav file.mp3
```
```sh
docker run --rm --entrypoint=/ffprobe -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:4.2.2 -i file.wav
```

### Files in the image
`/ffmpeg` ffmpeg binary  
`/ffprobe` ffprobe binary  
`/doc` Documentation  
`/versions.json` JSON file with ffmpeg and library versions  
`/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly

### Security

Binaries are built with various hardening features but it's probably still a good idea to run
them as non-root even when used inside a container, especially so if running on input files
that you don't control.

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

* Add [vmaf](https://github.com/Netflix/vmaf) support
* Add [rav1e](https://github.com/xiph/rav1e) support when in stable
* Add acceleration support (GPU, CUDA, ...)
* Add qt-faststart
* Add *.a *.so libraries, headers and pkg-config somehow
