FROM alpine:3.10 AS builder

ARG FFMPEG_VERSION=4.1.4
ARG FFMPEG_SHA256=3531fc11d1323aa727d76dbdbbb542d2d9899e06a7c047eeb7312cba7ea49eda
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_SHA256=434ad37e8b9d19c94ee23f55a2cb3e4fd98d688ce1b1e840a73bcfeec9a2f430
ARG FDK_AAC_VERSION=2.0.0
ARG FDK_AAC_SHA256=0c2e6e4febc3ce6c658fe6a5215ec9f7a6d13499bf3b0b43820acf0f177123ee
ARG OGG_VERSION=1.3.3
ARG OGG_SHA256=d49fdbb682cb3e3fb2085ce9e02a6fd6453db6248134d0fe05155cc9afc48071
ARG VORBIS_VERSION=1.3.6
ARG VORBIS_SHA256=d1bb3c0e9c9252e0664e55eb426ffe23be15cdac97c623a92158ab5afdff5ba4
ARG OPUS_VERSION=1.3.1
ARG OPUS_SHA256=3280f20fbc97b09d6c3ab1411f1ef91fde251796f35e8940cb20ffe469682ca4
ARG THEORA_VERSION=1.1.1
ARG THEORA_SHA256=e004cca2d7ca7ab80a8eaeaf05ebd474d602edcc4f8543eb201f0ec91bd33c80
ARG VPX_VERSION=1.8.0
ARG VPX_SHA256=cddaaa03808d1da312ce0f46c15114892727cfc9db25c7059a02ee571969994d
# x264 only have a stable branch no tags and we checkout commit so no hash is needed
ARG X264_VERSION=72db437770fd1ce3961f624dd57a8e75ff65ae0b
ARG X265_VERSION=3.1.1
ARG X265_SHA256=c08540075e6642ba65c49715543bbcbfaf5ae11be3757b4140e4dab91c18e220
ARG WEBP_VERSION=1.0.2
ARG WEBP_SHA256=44d11b8ef89c7bf5fc25c49ed6c94329667075c10731f3d89a4c6cf6502397df
ARG WAVPACK_VERSION=5.1.0
ARG WAVPACK_SHA256=52e5d297a7d4f6081c8275c24ae8320173596b9b6635387da13ffa5139c706b9
ARG SPEEX_VERSION=1.2.0
ARG SPEEX_SHA256=fc432d5e7eba05b02260b94085c10f0923cf90a06547e4adc8dcf80cab395c1d
ARG AOM_VERSION=1.0.0
ARG AOM_SHA256=4ee26e130e272fa17bddb86d91c1993a3015ddf122ecc74ca428fc4e3b494c9b
ARG VIDSTAB_VERSION=1.1.0
ARG VIDSTAB_SHA256=d22746cce4eb3399e17560448b8e4e95c515d19efec9990e232396b441f277ac
ARG KVAZAAR_VERSION=1.2.0
ARG KVAZAAR_SHA256=38081a3d4d0653fc3cd222814c08a387cd2e379dc54ee475392bafa5a1fc2feb
ARG ASS_VERSION=0.14.0
ARG ASS_SHA256=18beb776e70fd2fe436e41e5e1b5982e9faaba6e2da2441bdddc80c8ff923ee8
ARG ZIMG_VERSION=2.9.1
ARG ZIMG_SHA256=0683e6d8a31036f5006f916fc4c892b5f783adba508e2b9215ea4da9038d9802
ARG OPENJPEG_VERSION=2.3.1
ARG OPENJPEG_SHA256=5ff4faadb2a6651930a650b64bcfc32b4ff774fe5f01ad342545c56a4de6731a

# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
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
  tar --mtime=0 -c lame-* | sha256sum --status -c $(echo "$MP3LAME_SHA256  -" > hash ; echo hash) && \
  cd lame-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c fdk-aac-* | sha256sum --status -c $(echo "$FDK_AAC_SHA256  -" > hash ; echo hash) && \
  cd fdk-aac-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "http://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c libogg-* | sha256sum --status -c $(echo "$OGG_SHA256  -" > hash ; echo hash) && \
  cd libogg-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

# require libogg to build
RUN \
  wget -O - "https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c libvorbis-* | sha256sum --status -c $(echo "$VORBIS_SHA256  -" > hash ; echo hash) && \
  cd libvorbis-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c opus-* | sha256sum --status -c $(echo "$OPUS_SHA256  -" > hash ; echo hash) && \
  cd opus-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2" | tar xj && \
  tar --mtime=0 -c libtheora-* | sha256sum --status -c $(echo "$THEORA_SHA256  -" > hash ; echo hash) && \
  cd libtheora-* && ./configure --disable-examples --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c libvpx-* | sha256sum --status -c $(echo "$VPX_SHA256  -" > hash ; echo hash) && \
  cd libvpx-* && ./configure --enable-static --disable-shared --disable-unit-tests --disable-examples && make -j$(nproc) install

RUN \
  git clone git://git.videolan.org/x264.git && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static && make -j$(nproc) install

RUN \
  wget -O - "https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c x265_* | sha256sum --status -c $(echo "$X265_SHA256  -" > hash ; echo hash) && \
  cd x265_*/build/linux && \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j$(nproc) install

RUN \
  wget -O - "https://github.com/webmproject/libwebp/archive/v$WEBP_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c libwebp-* | sha256sum --status -c $(echo "$WEBP_SHA256  -" > hash ; echo hash) && \
  cd libwebp-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/dbry/WavPack/archive/$WAVPACK_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c WavPack-* | sha256sum --status -c $(echo "$WAVPACK_SHA256  -" > hash ; echo hash) && \
  cd WavPack-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c speex-Speex-* | sha256sum --status -c $(echo "$SPEEX_SHA256  -" > hash ; echo hash) && \
  cd speex-Speex-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  git clone --branch v$AOM_VERSION --depth 1 "https://aomedia.googlesource.com/aom" && \
  tar --exclude .git --mtime=0 -c aom | sha256sum --status -c $(echo "$AOM_SHA256  -" > hash ; echo hash) && \
  cd aom && mkdir build_tmp && cd build_tmp && \
  cmake -DENABLE_SHARED=OFF -DENABLE_TESTS=0 .. && \
  make -j$(nproc) install

RUN \
  wget -O - "https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c vid.stab-* | sha256sum --status -c $(echo "$VIDSTAB_SHA256  -" > hash ; echo hash) && \
  cd vid.stab-* && cmake -DBUILD_SHARED_LIBS=OFF . && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c kvazaar-* | sha256sum --status -c $(echo "$KVAZAAR_SHA256  -" > hash ; echo hash) && \
  cd kvazaar-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/libass/libass/releases/download/$ASS_VERSION/libass-$ASS_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c libass-* | sha256sum --status -c $(echo "$ASS_SHA256  -" > hash ; echo hash) && \
  cd libass-* && ./configure --enable-static --disable-shared && make -j$(nproc) && make install

RUN \
  wget -O - "https://github.com/sekrit-twc/zimg/archive/release-$ZIMG_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c zimg-* | sha256sum --status -c $(echo "$ZIMG_SHA256  -" > hash ; echo hash) && \
  cd zimg-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O - "https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c openjpeg-* | sha256sum --status -c $(echo "$OPENJPEG_SHA256  -" > hash ; echo hash) && \
  cd openjpeg-* && \
  cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF && \
  make -j$(nproc) install

RUN \
  wget -O - "https://github.com/FFmpeg/FFmpeg/archive/n$FFMPEG_VERSION.tar.gz" | tar xz && \
  tar --mtime=0 -c FFmpeg-* | sha256sum --status -c $(echo "$FFMPEG_SHA256  -" > hash ; echo hash) && \
  cd FFmpeg-* && \
  ./configure \
  --pkg-config-flags=--static \
  --extra-cflags="-fopenmp" \
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
