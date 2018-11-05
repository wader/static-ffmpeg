## static-ffmpeg

Docker image with static x86 64bit ffmpeg and ffprobe binaries.
Binaries are built as hardened PIE binaries with no external dependencies
(uses musl from alpine instead of glibc).

Built with
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
libkvazaar
and all default native ffmpeg codecs.

#### Usage
```Dockerfile
COPY --from=mwader/static-ffmpeg:4.0.3 /ffmpeg /ffprobe /usr/local/bin/
```
```sh
docker run --rm -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg -i file.wav file.mp3
```
```sh
docker run --rm --entrypoint=/ffprobe -v "$PWD:$PWD" -w "$PWD" mwader/static-ffmpeg -i file.wav
```

#### Files in the image
`/ffmpeg` ffmpeg binary  
`/ffprobe` ffprobe binary  
`/doc/*` ffmpeg documentation  
`/versions.json` JSON file with ffmpeg and library versions
