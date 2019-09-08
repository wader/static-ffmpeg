FROM alpine:3.10.2 AS builder

ARG FFMPEG_VERSION=4.2.1
ARG FFMPEG_URL="https://github.com/FFmpeg/FFmpeg/archive/n$FFMPEG_VERSION.tar.gz"
ARG FFMPEG_SHA256=0c610efe7f8ca1c652595ad76589eb9374d9be053ad0c01de86530e03929d83c
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_URL="https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download"
ARG MP3LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
ARG FDK_AAC_VERSION=2.0.0
ARG FDK_AAC_URL="https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz"
ARG FDK_AAC_SHA256=6e6c7921713788e31df655911e1d42620b057180b00bf16874f5d630e1d5b9a2
ARG OGG_VERSION=1.3.4
ARG OGG_URL="https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz"
ARG OGG_SHA256=fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e
ARG VORBIS_VERSION=1.3.6
ARG VORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz"
ARG VORBIS_SHA256=6ed40e0241089a42c48604dc00e362beee00036af2d8b3f46338031c9e0351cb
ARG OPUS_VERSION=1.3.1
ARG OPUS_URL="https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz"
ARG OPUS_SHA256=65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d
ARG THEORA_VERSION=1.1.1
ARG THEORA_URL="https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2"
ARG THEORA_SHA256=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc
ARG VPX_VERSION=1.8.1
ARG VPX_URL="https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz"
ARG VPX_SHA256=df19b8f24758e90640e1ab228ab4a4676ec3df19d23e4593375e6f3847dee03e
# x264 only have a stable branch no tags and we checkout commit so no hash is needed
ARG X264_URL="git://git.videolan.org/x264.git"
ARG X264_VERSION=72db437770fd1ce3961f624dd57a8e75ff65ae0b
ARG X265_VERSION=3.1.2
ARG X265_URL="https://bitbucket.org/multicoreware/x265/downloads/x265_$X265_VERSION.tar.gz"
ARG X265_SHA256=6f785f1c9a42e00a56402da88463bb861c49d9af108be53eb3ef10295f2a59aa
ARG WEBP_VERSION=1.0.3
ARG WEBP_URL="https://github.com/webmproject/libwebp/archive/v$WEBP_VERSION.tar.gz"
ARG WEBP_SHA256=082d114bcb18a0e2aafc3148d43367c39304f86bf18ba0b2e766447e111a4a91
ARG WAVPACK_VERSION=5.1.0
ARG WAVPACK_URL="https://github.com/dbry/WavPack/archive/$WAVPACK_VERSION.tar.gz"
ARG WAVPACK_SHA256=1af7eaccbf560271013d4179d98ef6fc681a2bb3603382577eeba73d438785f4
ARG SPEEX_VERSION=1.2.0
ARG SPEEX_URL="https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz"
ARG SPEEX_SHA256=4781a30d3a501abc59a4266f9bbf8b1da66fd509bef014697dc3f61e406b990c
ARG AOM_VERSION=1.0.0
ARG AOM_URL="https://aomedia.googlesource.com/aom"
ARG AOM_COMMIT=d14c5bb4f336ef1842046089849dee4a301fbbf0
ARG VIDSTAB_VERSION=1.1.0
ARG VIDSTAB_URL="https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz"
ARG VIDSTAB_SHA256=14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb
ARG KVAZAAR_VERSION=1.3.0
ARG KVAZAAR_URL="https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz"
ARG KVAZAAR_SHA256=f694fe71cc6e3e6f583a9faf380825ea93b2635c4db8d1d3121b9ebcf736ac1c
ARG ASS_VERSION=0.14.0
ARG ASS_URL="https://github.com/libass/libass/releases/download/$ASS_VERSION/libass-$ASS_VERSION.tar.gz"
ARG ASS_SHA256=8d5a5c920b90b70a108007ffcd2289ac652c0e03fc88e6eecefa37df0f2e7fdf
ARG ZIMG_VERSION=2.9.2
ARG ZIMG_URL="https://github.com/sekrit-twc/zimg/archive/release-$ZIMG_VERSION.tar.gz"
ARG ZIMG_SHA256=10403c2964fe11b559a7ec5e081c358348fb787e26b91ec0d1f9dd7c01d1cd7b
ARG OPENJPEG_VERSION=2.3.1
ARG OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz"
ARG OPENJPEG_SHA256=63f5a4713ecafc86de51bfad89cc07bb788e9bba24ebbf0c4ca637621aadb6a9
ARG LIBDAV1D_VERSION=0.4.0
ARG LIBDAV1D_URL="https://code.videolan.org/videolan/dav1d/-/archive/$LIBDAV1D_VERSION/dav1d-$LIBDAV1D_VERSION.tar.gz"
ARG LIBDAV1D_SHA256=f3a825bce590778b4959807470cd853bbcbd0d3c10d98958a3a1eea09ce64544

# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIE"
ARG LDFLAGS="-Wl,-z,relro,-z,now"

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
  meson \
  ninja \
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
  libdav1d: env.LIBDAV1D_VERSION, \
  }' > /versions.json

RUN \
  wget -O lame.tar.gz "$MP3LAME_URL" && \
  sha256sum --status -c $(echo "$MP3LAME_SHA256  lame.tar.gz" > hash ; echo hash) && \
  tar xfz lame.tar.gz && \
  cd lame-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O fdk-aac.tar.gz "$FDK_AAC_URL" && \
  sha256sum --status -c $(echo "$FDK_AAC_SHA256  fdk-aac.tar.gz" > hash ; echo hash) && \
  tar xfz fdk-aac.tar.gz && \
  cd fdk-aac-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libogg.tar.gz "$OGG_URL" && \
  sha256sum --status -c $(echo "$OGG_SHA256  libogg.tar.gz" > hash ; echo hash) && \
  tar xfz libogg.tar.gz && \
  cd libogg-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

# require libogg to build
RUN \
  wget -O libvorbis.tar.gz "$VORBIS_URL" && \
  sha256sum --status -c $(echo "$VORBIS_SHA256  libvorbis.tar.gz" > hash ; echo hash) && \
  tar xfz libvorbis.tar.gz && \
  cd libvorbis-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O opus.tar.gz "$OPUS_URL" && \
  sha256sum --status -c $(echo "$OPUS_SHA256  opus.tar.gz" > hash ; echo hash) && \
  tar xfz opus.tar.gz && \
  cd opus-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libtheora.tar.gz "$THEORA_URL" && \
  sha256sum --status -c $(echo "$THEORA_SHA256  libtheora.tar.gz" > hash ; echo hash) && \
  tar xfj libtheora.tar.gz && \
  cd libtheora-* && ./configure --disable-examples --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libvpx.tar.gz "$VPX_URL" && \
  sha256sum --status -c $(echo "$VPX_SHA256  libvpx.tar.gz" > hash ; echo hash) && \
  tar xfz libvpx.tar.gz && \
  cd libvpx-* && ./configure --enable-static --disable-shared --disable-unit-tests --disable-examples && make -j$(nproc) install

RUN \
  git clone "$X264_URL" && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static && make -j$(nproc) install

RUN \
  wget -O x265.tar.gz "$X265_URL" && \
  sha256sum --status -c $(echo "$X265_SHA256  x265.tar.gz" > hash ; echo hash) && \
  tar xfz x265.tar.gz && \
  cd x265_*/build/linux && \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j$(nproc) install

RUN \
  wget -O libwebp.tar.gz "$WEBP_URL" && \
  sha256sum --status -c $(echo "$WEBP_SHA256  libwebp.tar.gz" > hash ; echo hash) && \
  tar xfz libwebp.tar.gz && \
  cd libwebp-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O wavpack.tar.gz "$WAVPACK_URL" && \
  sha256sum --status -c $(echo "$WAVPACK_SHA256  wavpack.tar.gz" > hash ; echo hash) && \
  tar xfz wavpack.tar.gz && \
  cd WavPack-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O speex.tar.gz "$SPEEX_URL" && \
  sha256sum --status -c $(echo "$SPEEX_SHA256  speex.tar.gz" > hash ; echo hash) && \
  tar xfz speex.tar.gz && \
  cd speex-Speex-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  git clone --depth 1 --branch v$AOM_VERSION "$AOM_URL" && \
  cd aom && test $(git rev-parse HEAD) = $AOM_COMMIT && \
  mkdir build_tmp && cd build_tmp && cmake -DENABLE_SHARED=OFF -DENABLE_TESTS=0 .. && make -j$(nproc) install

RUN \
  wget -O vid.stab.tar.gz "$VIDSTAB_URL" && \
  sha256sum --status -c $(echo "$VIDSTAB_SHA256  vid.stab.tar.gz" > hash ; echo hash) && \
  tar xfz vid.stab.tar.gz && \
  cd vid.stab-* && cmake -DBUILD_SHARED_LIBS=OFF . && make -j$(nproc) install

RUN \
  wget -O kvazaar.tar.gz "$KVAZAAR_URL" && \
  sha256sum --status -c $(echo "$KVAZAAR_SHA256  kvazaar.tar.gz" > hash ; echo hash) && \
  tar xfz kvazaar.tar.gz && \
  cd kvazaar-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libass.tar.gz "$ASS_URL" && \
  sha256sum --status -c $(echo "$ASS_SHA256  libass.tar.gz" > hash ; echo hash) && \
  tar xfz libass.tar.gz && \
  cd libass-* && ./configure --enable-static --disable-shared && make -j$(nproc) && make install

RUN \
  wget -O zimg.tar.gz "$ZIMG_URL" && \
  sha256sum --status -c $(echo "$ZIMG_SHA256  zimg.tar.gz" > hash ; echo hash) && \
  tar xfz zimg.tar.gz && \
  cd zimg-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O openjpeg.tar.gz "$OPENJPEG_URL" && \
  sha256sum --status -c $(echo "$OPENJPEG_SHA256  openjpeg.tar.gz" > hash ; echo hash) && \
  tar xfz openjpeg.tar.gz && \
  cd openjpeg-* && cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF && make -j$(nproc) install

RUN \
  wget -O dav1d.tar.gz "$LIBDAV1D_URL" && \
  sha256sum --status -c $(echo "$LIBDAV1D_SHA256  dav1d.tar.gz" > hash ; echo hash) && \
  tar xfz dav1d.tar.gz && \
  cd dav1d-* && meson build --buildtype release -Ddefault_library=static && ninja -C build install

RUN \
  wget -O ffmpeg.tar.gz "$FFMPEG_URL" && \
  sha256sum --status -c $(echo "$FFMPEG_SHA256  ffmpeg.tar.gz" > hash ; echo hash) && \
  tar xfz ffmpeg.tar.gz && \
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
  --enable-libdav1d \
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
