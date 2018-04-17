FROM alpine:3.7 AS ffmpeg-builder

RUN apk add --no-cache \
  coreutils \
  openssl \
  bash \
  build-base \
  autoconf \
  automake \
  libtool \
  cmake \
  git \
  yasm \
  zlib-dev \
  openssl-dev \
  lame-dev \
  libogg-dev \
  libvpx-dev

# some -dev alpine packages lack .a files in 3.6 (some fixed in edge)
RUN \
  FDK_AAC_VERSION=0.1.5 && \
  wget -O - https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz | tar xz && \
  cd fdk-aac-$FDK_AAC_VERSION && \
  ./autogen.sh && \
  ./configure --enable-static && \
  make -j4 install

RUN \
  VORBIS_VERSION=1.3.5 && \
  wget -O - https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz | tar xz && \
  cd libvorbis-$VORBIS_VERSION && \
  CFLAGS="-fno-strict-overflow -fstack-protector-all -fPIE" LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie" \
  ./configure --enable-static && \
  make -j4 install

RUN \
  OPUS_VERSION=1.2.1 && \
  wget -O - https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz | tar xz && \
  cd opus-$OPUS_VERSION && \
  CFLAGS="-fno-strict-overflow -fstack-protector-all -fPIE" LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie" \
  ./configure --enable-static && \
  make -j4 install

# require libogg to build
RUN \
  THEORA_VERSION=1.1.1 && \
  wget -O - https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2 | tar xj && \
  cd libtheora-$THEORA_VERSION && \
  CFLAGS="-fno-strict-overflow -fstack-protector-all -fPIE" LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie" \
  ./configure --enable-pic --enable-static && \
  make -j4 install

# x264 only has a stable branch no tags
RUN \
  X264_VERSION=aaa9aa83a111ed6f1db253d5afa91c5fc844583f && \
  git clone git://git.videolan.org/x264.git && \
  cd x264 && \
  git checkout $X264_VERSION && \
  CFLAGS="-fno-strict-overflow -fstack-protector-all -fPIE" LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie" \
  ./configure --enable-pic --enable-static && make -j4 install

# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library
RUN \
  X265_VERSION=2.7 && \
  wget -O - "https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VERSION.tar.gz" | tar xz && \
  cd x265_$X265_VERSION/build/linux && \
  CFLAGS="-static-libgcc -fno-strict-overflow -fPIE" \
  CXXFLAGS="-static-libgcc -fno-strict-overflow -fPIE" \
  LDFLAGS="-Wl,-z,relro -Wl,-z,now -fPIE -pie" \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j4 install

# note that this will produce a "static" PIE binary with no dynamic lib deps
ENV FFMPEG_VERSION=3.4.2
RUN \
  git clone --branch n$FFMPEG_VERSION --depth 1 https://github.com/FFmpeg/FFmpeg.git && \
  cd FFmpeg && \
  ./configure \
  --toolchain=hardened \
  --disable-shared \
  --enable-static \
  --pkg-config-flags=--static \
  --extra-ldflags=-static \
  --enable-gpl \
  --enable-nonfree \
  --enable-openssl \
  --disable-ffserver \
  --disable-doc \
  --disable-ffplay \
  --enable-libmp3lame \
  --enable-libfdk-aac \
  --enable-libvorbis \
  --enable-libopus \
  --enable-libtheora \
  --enable-libvpx \
  --enable-libx264 \
  --enable-libx265 \
  && \
  make -j4 install

# sanity tests
RUN \
  ldd /usr/local/bin/ffmpeg | grep -vq lib && \
  ldd /usr/local/bin/ffprobe | grep -vq lib && \
  /usr/local/bin/ffmpeg -version && \
  /usr/local/bin/ffprobe -version && \
  /usr/local/bin/ffmpeg -i https://www.google.com 2>&1 | grep -q "Invalid data found when processing input"

FROM scratch
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
COPY --from=ffmpeg-builder /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
ENTRYPOINT ["/ffmpeg"]
