### static-ffmpeg

Docker image with static x86 64bit ffmpeg and ffprobe binaries. To be run as is or used in
multi-stage built as e.g. `COPY --from=mwader/static-ffmpeg:4.0 /ffmpeg /ffprobe /usr/local/bin/`
when ffmpeg is needed.

Binaries are built as hardened PIE binaries with no external dependencies (uses musl from alpine
instead of glibc).

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
