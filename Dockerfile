FROM alpine:3.10 AS builder

ARG FFMPEG_VERSION=4.1.3
ARG MP3LAME_VERSION=3.100
ARG FDK_AAC_VERSION=2.0.0
ARG OGG_VERSION=1.3.3
ARG VORBIS_VERSION=1.3.6
ARG OPUS_VERSION=1.3.1
ARG THEORA_VERSION=1.1.1
ARG VPX_VERSION=1.8.0
# x264 only have a stable branch no tags
ARG X264_VERSION=72db437770fd1ce3961f624dd57a8e75ff65ae0b
ARG X265_VERSION=3.0
ARG WEBP_VERSION=1.0.2
ARG WAVPACK_VERSION=5.1.0
ARG SPEEX_VERSION=1.2.0
ARG AOM_VERSION=1.0.0
ARG VIDSTAB_VERSION=1.1.0
ARG KVAZAAR_VERSION=1.2.0
ARG ASS_VERSION=0.14.0
ARG ZIMG_VERSION=2.8
ARG OPENJPEG_VERSION=2.3.1

# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE -fopenmp"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-Wl,-z,relro,-z,now -fPIE -pie"

RUN apk add --no-cache \
  coreutils \
  openssl \
  openssl-dev \
  bash \
  tar \
  xz \
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
  zlib \
  zlib-dev \
  libxml2 \
  libxml2-dev \
  fontconfig \
  fontconfig-dev \
  freetype \
  freetype-dev \
  freetype-static \
  graphite2-static \
  glib-static \
  libpng-static \
  harfbuzz \
  harfbuzz-dev \
  harfbuzz-static \
  fribidi \
  fribidi-dev \
  fribidi-static \
  soxr \
  soxr-dev \
  soxr-static

RUN \
  OPENSSL_VERSION=$(pkg-config --modversion openssl) \
  LIBXML2_VERSION=$(pkg-config --modversion libxml-2.0) \
  FREETYPE_VERSION=$(pkg-config --modversion freetype2)  \
  FONTCONFIG_VERSION=$(pkg-config --modversion fontconfig)  \
  FRIBIDI_VERSION=$(pkg-config --modversion fribidi)  \
  SOXR_VERSION=$(pkg-config --modversion soxr) \
  jq -n '{ \
  ffmpeg: env.FFMPEG_VERSION, \
  openssl: env.OPENSSL_VERSION, \
  libxml2: env.LIBXML2_VERSION, \
  libmp3lame: env.MP3LAME_VERSION, \
  "libfdk-aac": env.FDK_AAC_VERSION, \
  libogg: env.OGG_VERSION, \
  libvorbis: env.VORBIS_VERSION, \
  libopus: env.OPUS_VERSION, \
  libtheora: env.THEORA_VERSION, \
  libvpx: env.VPX_VERSION, \
  libx264: env.X264_VERSION, \
  libx265: env.X265_VERSION, \
  libwebp: env.WEBP_VERSION, \
  libwavpack: env.WAVPACK_VERSION, \
  libspeex: env.SPEEX_VERSION, \
  libaom: env.AOM_VERSION, \
  libvidstab: env.VIDSTAB_VERSION, \
  libkvazaar: env.KVAZAAR_VERSION, \
  libfreetype: env.FREETYPE_VERSION, \
  fontconfig: env.FONTCONFIG_VERSION, \
  libfribidi: env.FRIBIDI_VERSION, \
  libass: env.ASS_VERSION, \
  libzimg: env.ZIMG_VERSION, \
  libsoxr: env.SOXR_VERSION, \
  libopenjpeg: env.OPENJPEG_VERSION, \
  }' > /versions.json

RUN \
  wget -O - "https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download" | tar xz && \
  cd lame-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz" | tar xz && \
  cd fdk-aac-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "http://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz" | tar xz && \
  cd libogg-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

# require libogg to build
RUN \
  wget -O - "https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz" | tar xz && \
  cd libvorbis-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz" | tar xz && \
  cd opus-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2" | tar xj && \
  cd libtheora-* && ./configure --disable-examples --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz" | tar xz && \
  cd libvpx-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  git clone git://git.videolan.org/x264.git && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static && make -j$(nproc) install

RUN \
  wget -O - "https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VERSION.tar.gz" | tar xz && \
  cd x265_*/build/linux && \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j$(nproc) install

RUN \
  wget -O - "https://github.com/webmproject/libwebp/archive/v$WEBP_VERSION.tar.gz" | tar xz && \
  cd libwebp-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/dbry/WavPack/archive/$WAVPACK_VERSION.tar.gz" | tar xz && \
  cd WavPack-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz" | tar xz && \
  cd speex-Speex-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  git clone --branch v$AOM_VERSION --depth 1 "https://aomedia.googlesource.com/aom" && \
  cd aom && mkdir build_tmp && cd build_tmp && \
  cmake -DENABLE_SHARED=OFF -DENABLE_TESTS=0 .. && \
  make -j$(nproc) install

RUN \
  wget -O - "https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz" | tar xz && \
  cd vid.stab-* && cmake -DBUILD_SHARED_LIBS=OFF . && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz" | tar xz && \
  cd kvazaar-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/libass/libass/releases/download/$ASS_VERSION/libass-$ASS_VERSION.tar.gz" | tar xz && \
  cd libass-* && ./configure --enable-static --disable-shared && make -j$(nproc) && make install

RUN \
  wget -O - "https://github.com/sekrit-twc/zimg/archive/release-$ZIMG_VERSION.tar.gz" | tar xz && \
  cd zimg-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz" | tar xz && \
  cd openjpeg-* && \
  cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF && \
  make -j$(nproc) install

RUN \
  git clone --branch n$FFMPEG_VERSION --depth 1 https://github.com/FFmpeg/FFmpeg.git && \
  cd FFmpeg && \
  ./configure \
  --pkg-config-flags=--static \
  --extra-ldflags="-static -fopenmp" \
  --toolchain=hardened \
  --disable-debug \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-nonfree \
  --enable-openssl \
  --enable-iconv \
  --enable-libxml2 \
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
  --enable-libfreetype \
  --enable-fontconfig \
  --enable-libfribidi \
  --enable-libass \
  --enable-libzimg \
  --enable-libsoxr \
  --enable-libopenjpeg \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

# make sure binaries have no dependencies
RUN \
  test $(ldd /usr/local/bin/ffmpeg | wc -l) -eq 1 && \
  test $(ldd /usr/local/bin/ffprobe | wc -l) -eq 1

FROM scratch
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
COPY --from=builder /versions.json /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
COPY --from=builder /usr/local/share/doc/ffmpeg/* /doc/
# sanity tests
RUN ["/ffmpeg", "-version"]
RUN ["/ffprobe", "-version"]
RUN ["/ffprobe", "-i", "https://github.com/favicon.ico"]
ENTRYPOINT ["/ffmpeg"]
