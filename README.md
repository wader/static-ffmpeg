## static-ffmpeg

Docker image with ffmpeg/ffprobe built as hardened static PIE binaries
with no external dependencies. Can be used with any base image even scratch.

Built with
gray,
openssl,
iconv,
libxml2,
libmp3lame,
libtwolame,
libfdk-aac,
libvorbis,
libopus,
libmodplug,
libtheora,
libvpx,
libx264,
libx265,
libwebp,
libspeex,
libvmaf
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
libxvid,
librav1e,
libsrt,
libsvtav1,
libdavs2,
libxavs2,
libmodplug,
libuavs3d,
libmysofa,
librubberband,
libgme,
libopencore
and all native ffmpeg codecs, formats, filters etc.

See [Dockerfile](Dockerfile) for versions used. In general master will have the latest stable version
of ffmpeg and all libraries. Versions are kept up to date automatically using [bump](https://github.com/wader/bump).

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
Bash alias
```sh
alias ffmpeg='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg:5.0'
alias ffprobe='docker run -i --rm -u $UID:$GROUPS -v "$PWD:$PWD" -w "$PWD" --entrypoint=/ffprobe mwader/static-ffmpeg:5.0'
```

### Files in the image
`/ffmpeg` ffmpeg binary<br>
`/ffprobe` ffprobe binary<br>
`/doc` Documentation<br>
`/versions.json` JSON file with ffmpeg and library versions<br>
`/etc/ssl/cert.pem` CA certs to make `-tls_verify 1 -ca_file /etc/ssl/cert.pem` work if running image directly<br>

### Tags

`latest` Latest master build.

`MAJOR.MINOR.PATCH[-BUILD]` Specific version of ffmpeg with the features that was in master at the time of tagging.
`-BUILD` means that was an additional build with that version to add of fix something.

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
ffmpeg with `-tls_verify 1` and `-ca_file /path/to/cert.pem`. For Alpine
the CA file is included by default at `/etc/ssl/cert.pem` and for Debian/Ubuntu
you have to install the `ca-certificates` package which will install the file at
`/etc/ssl/certs/ca-certificates.crt`.

### Contribute

Feel free to create issues or PRs if you have any improvements or problems.
Please also consider making a [donation](https://ffmpeg.org/donations.html) to
the FFmpeg project or to other projects used by this image if you find it useful.

### TODOs and possible things to add

* Add libplacebo
* Add acceleration support (GPU, CUDA, ...)
* Add *.a *.so libraries, headers and pkg-config somehow
* Use cargo-c stable alpine package
