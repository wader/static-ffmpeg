FROM alpine:3.8 AS ffmpeg-builder

RUN apk add --no-cache \
  coreutils \
  openssl \
  bash \
  build-base \
  autoconf \
  automake \
  libtool \
  diffutils \
  cmake \
  git \
  yasm \
  nasm \
  texinfo \
  jq \
  zlib-dev \
  openssl-dev

ARG FFMPEG_VERSION=4.1
ARG MP3LAME_VERSION=3.100
ARG FDK_AAC_VERSION=0.1.6
ARG OGG_VERSION=1.3.3
ARG VORBIS_VERSION=1.3.6
ARG OPUS_VERSION=1.3
ARG THEORA_VERSION=1.1.1
ARG VPX_VERSION=1.7.0
# x264 only have a stable branch no tags
ARG X264_VERSION=0a84d986e7020f8344f00752e3600b9769cc1e85
ARG X265_VERSION=2.9
ARG WEBP_VERSION=1.0.0
ARG WAVPACK_VERSION=5.1.0
ARG SPEEX_VERSION=1.2.0
ARG AOM_VERSION=1.0.0
ARG VIDSTAB_VERSION=1.1.0
ARG KVAZAAR_VERSION=1.2.0

# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ENV CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ENV CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ENV LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie"

RUN cat /proc/cpuinfo | grep ^processor | wc -l > /build_concurrency

RUN \
  echo \
  "{" \
  "\"ffmpeg\": \"$FFMPEG_VERSION\"," \
  "\"libmp3lame\": \"$MP3LAME_VERSION\"," \
  "\"libfdk-aac\": \"$FDK_AAC_VERSION\"," \
  "\"libogg\": \"$OGG_VERSION\"," \
  "\"libvorbis\": \"$VORBIS_VERSION\"," \
  "\"libopus\": \"$OPUS_VERSION\"," \
  "\"libtheora\": \"$THEORA_VERSION\"," \
  "\"libvpx\": \"$VPX_VERSION\"," \
  "\"libx264\": \"$X264_VERSION\"," \
  "\"libx265\": \"$X265_VERSION\"," \
  "\"libwebp\": \"$WEBP_VERSION\"," \
  "\"libwavpack\": \"$WAVPACK_VERSION\"," \
  "\"libspeex\": \"$SPEEX_VERSION\"," \
  "\"libaom\": \"$AOM_VERSION\"," \
  "\"libvidstab\": \"$VIDSTAB_VERSION\"," \
  "\"libkvazaar\": \"$KVAZAAR_VERSION\"" \
  "}" \
  | jq . > /versions.json

RUN \
  wget -O - "https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download" | tar xz && \
  cd lame-$MP3LAME_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz" | tar xz && \
  cd fdk-aac-$FDK_AAC_VERSION && \
  ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "http://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz" | tar xz && \
  cd libogg-$OGG_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

# require libogg to build
RUN \
  wget -O - "https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz" | tar xz && \
  cd libvorbis-$VORBIS_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz" | tar xz && \
  cd opus-$OPUS_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2" | tar xj && \
  cd libtheora-$THEORA_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz" | tar xz && \
  cd libvpx-$VPX_VERSION && \
  ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  git clone git://git.videolan.org/x264.git && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VERSION.tar.gz" | tar xz && \
  cd x265_$X265_VERSION/build/linux && \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/webmproject/libwebp/archive/v$WEBP_VERSION.tar.gz" | tar xz && \
  cd libwebp-$WEBP_VERSION && \
  ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/dbry/WavPack/archive/$WAVPACK_VERSION.tar.gz" | tar xz && \
  cd WavPack-$WAVPACK_VERSION && \
  ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz" | tar xz && \
  cd speex-Speex-$SPEEX_VERSION && \
  ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  git clone --branch v$AOM_VERSION --depth 1 "https://aomedia.googlesource.com/aom" && \
  cd aom && \
  mkdir build_tmp && cd build_tmp && \
  cmake -DENABLE_SHARED=OFF -DENABLE_TESTS=0 .. && \
  make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz" | tar xz && \
  cd vid.stab-$VIDSTAB_VERSION && \
  cmake -DBUILD_SHARED_LIBS=OFF . && \
  make -j$(cat /build_concurrency) install

RUN \
  wget -O - "https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz" | tar xz && \
  cd kvazaar-$KVAZAAR_VERSION && \
  ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(cat /build_concurrency) install

RUN \
  git clone --branch n$FFMPEG_VERSION --depth 1 https://github.com/FFmpeg/FFmpeg.git && \
  cd FFmpeg && \
  ./configure \
  --pkg-config-flags=--static \
  --extra-ldflags=-static \
  --toolchain=hardened \
  --disable-debug \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-nonfree \
  --enable-openssl \
  --enable-iconv \
  --enable-libmp3lame \
  --enable-libfdk-aac \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libwebp \
  --enable-libwavpack \
  --enable-libspeex \
  --enable-libaom \
  --enable-libvidstab \
  --enable-libkvazaar \
  && \
  make -j$(cat /build_concurrency) install

FROM scratch
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
COPY --from=ffmpeg-builder /versions.json /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
COPY --from=ffmpeg-builder /usr/local/share/doc/ffmpeg/* /doc/
# sanity tests
RUN ["/ffmpeg", "-version"]
RUN ["/ffprobe", "-version"]
RUN ["/ffprobe", "https://github.com/favicon.ico"]
ENTRYPOINT ["/ffmpeg"]
