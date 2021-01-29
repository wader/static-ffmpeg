# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.13.1 AS builder

# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|^4
# bump: ffmpeg after ./hashupdate FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=4.3.1
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=f4a4ac63946b6eee3bbdde523e298fca6019d048d6e1db0d1439a62cea65f0d9
# bump: mp3lame /MP3LAME_VERSION=([\d.]+)/ svn:http://svn.code.sf.net/p/lame/svn|/^RELEASE__(.*)$/|/_/./|*
# bump: mp3lame after ./hashupdate MP3LAME $LATEST
# bump: mp3lame link "ChangeLog" http://svn.code.sf.net/p/lame/svn/trunk/lame/ChangeLog
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_URL="https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download"
ARG MP3LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
# bump: fdk-aac /FDK_AAC_VERSION=([\d.]+)/ https://github.com/mstorsjo/fdk-aac.git|*
# bump: fdk-aac after ./hashupdate Dockerfile FDK_AAC $LATEST
# bump: fdk-aac link "ChangeLog" https://github.com/mstorsjo/fdk-aac/blob/master/ChangeLog
# bump: fdk-aac link "Source diff $CURRENT..$LATEST" https://github.com/mstorsjo/fdk-aac/compare/v$CURRENT..v$LATEST
ARG FDK_AAC_VERSION=2.0.1
ARG FDK_AAC_URL="https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz"
ARG FDK_AAC_SHA256=a4142815d8d52d0e798212a5adea54ecf42bcd4eec8092b37a8cb615ace91dc6
# bump: ogg /OGG_VERSION=([\d.]+)/ https://github.com/xiph/ogg.git|*
# bump: ogg after ./hashupdate Dockerfile OGG $LATEST
# bump: ogg link "CHANGES" https://github.com/xiph/ogg/blob/master/CHANGES
# bump: ogg link "Source diff $CURRENT..$LATEST" https://github.com/xiph/ogg/compare/v$CURRENT..v$LATEST
ARG OGG_VERSION=1.3.4
ARG OGG_URL="https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz"
ARG OGG_SHA256=fe5670640bd49e828d64d2879c31cb4dde9758681bb664f9bdbf159a01b0c76e
# bump: vorbis /VORBIS_VERSION=([\d.]+)/ https://github.com/xiph/vorbis.git|*
# bump: vorbis after ./hashupdate Dockerfile VORBIS $LATEST
# bump: vorbis link "CHANGES" https://github.com/xiph/vorbis/blob/master/CHANGES
# bump: vorbis link "Source diff $CURRENT..$LATEST" https://github.com/xiph/vorbis/compare/v$CURRENT..v$LATEST
ARG VORBIS_VERSION=1.3.7
ARG VORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz"
ARG VORBIS_SHA256=0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab
# bump: opus /OPUS_VERSION=([\d.]+)/ https://github.com/xiph/opus.git|^1
# bump: opus after ./hashupdate Dockerfile OPUS $LATEST
# bump: opus link "Release notes" https://github.com/xiph/opus/releases/tag/v$LATEST
# bump: opus link "Source diff $CURRENT..$LATEST" https://github.com/xiph/opus/compare/v$CURRENT..v$LATEST
ARG OPUS_VERSION=1.3.1
ARG OPUS_URL="https://archive.mozilla.org/pub/opus/opus-$OPUS_VERSION.tar.gz"
ARG OPUS_SHA256=65b58e1e25b2a114157014736a3d9dfeaad8d41be1c8179866f144a2fb44ff9d
# bump: theora /THEORA_VERSION=([\d.]+)/ https://github.com/xiph/theora.git|*
# bump: theora after ./hashupdate Dockerfile THEORA $LATEST
# bump: theora link "Release notes" https://github.com/xiph/theora/releases/tag/v$LATEST
# bump: theora link "Source diff $CURRENT..$LATEST" https://github.com/xiph/theora/compare/v$CURRENT..v$LATEST
ARG THEORA_VERSION=1.1.1
ARG THEORA_URL="https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2"
ARG THEORA_SHA256=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc
# bump: libvpx /VPX_VERSION=([\d.]+)/ https://github.com/webmproject/libvpx.git|*
# bump: libvpx after ./hashupdate Dockerfile VPX $LATEST
# bump: libvpx link "CHANGELOG" https://github.com/webmproject/libvpx/blob/master/CHANGELOG
# bump: libvpx link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libvpx/compare/v$CURRENT..v$LATEST
ARG VPX_VERSION=1.9.0
ARG VPX_URL="https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz"
ARG VPX_SHA256=d279c10e4b9316bf11a570ba16c3d55791e1ad6faa4404c67422eb631782c80a
# x264 only have a stable branch no tags and we checkout commit so no hash is needed
# bump: x264 /X264_VERSION=([[:xdigit:]]+)/ gitrefs:https://code.videolan.org/videolan/x264.git|re:#^refs/heads/stable$#|@commit
# bump: x264 after ./hashupdate Dockerfile X264 $LATEST
# bump: x264 link "Source diff $CURRENT..$LATEST" https://code.videolan.org/videolan/x264/-/compare/$CURRENT...$LATEST
ARG X264_URL="https://code.videolan.org/videolan/x264.git"
ARG X264_VERSION=544c61f082194728d0391fb280a6e138ba320a96
# bump: x265 /X265_VERSION=([\d.]+)/ https://bitbucket.org/multicoreware/x265_git.git|^3
# bump: x265 after ./hashupdate Dockerfile X265 $LATEST
# bump: x265 link "releasenotes" https://bitbucket.org/multicoreware/x265_git/src/master/doc/reST/releasenotes.rst
ARG X265_VERSION=3.4
ARG X265_URL="https://bitbucket.org/multicoreware/x265_git/get/$X265_VERSION.tar.bz2"
ARG X265_SHA256=1a430f3a793982d4e0762d67dc2d49f308bf28a8bba4f2d42fea3340e33e9e31
# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.1.0
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=424faab60a14cb92c2a062733b6977b4cc1e875a6398887c5911b3a1a6c56c51
# bump: wavpack /WAVPACK_VERSION=([\d.]+)/ https://github.com/dbry/WavPack.git|*
# bump: wavpack after ./hashupdate Dockerfile WAVPACK $LATEST
# bump: wavpack link "Release notes" https://github.com/dbry/WavPack/releases/tag/$LATEST
# bump: wavpack link "Source diff $CURRENT..$LATEST" https://github.com/dbry/WavPack/compare/$CURRENT..$LATEST
ARG WAVPACK_VERSION=5.4.0
ARG WAVPACK_URL="https://github.com/dbry/WavPack/archive/$WAVPACK_VERSION.tar.gz"
ARG WAVPACK_SHA256=abbe5ca3fc918fdd64ef216200a5c896243ea803a059a0662cd362d0fa827cd2
# bump: speex /SPEEX_VERSION=([\d.]+)/ https://github.com/xiph/speex.git|*
# bump: speex after ./hashupdate Dockerfile SPEEX $LATEST
# bump: speex link "ChangeLog" https://github.com/dbry/WavPack/blob/master/ChangeLog
# bump: speex link "Source diff $CURRENT..$LATEST" https://github.com/xiph/speex/compare/$CURRENT..$LATEST
ARG SPEEX_VERSION=1.2.0
ARG SPEEX_URL="https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz"
ARG SPEEX_SHA256=4781a30d3a501abc59a4266f9bbf8b1da66fd509bef014697dc3f61e406b990c
# bump: aom /AOM_VERSION=([\d.]+)/ git:https://aomedia.googlesource.com/aom|*
# bump: aom after ./hashupdate Dockerfile aom $LATEST
# bump: aom link "CHANGELOG" https://aomedia.googlesource.com/aom/+/refs/tags/v$LATEST/CHANGELOG
# Remember to update commit hash
ARG AOM_VERSION=2.0.1
ARG AOM_URL="https://aomedia.googlesource.com/aom"
ARG AOM_COMMIT=b52ee6d44adaef8a08f6984390de050d64df9faa
# bump: vid.stab /VIDSTAB_VERSION=([\d.]+)/ https://github.com/georgmartius/vid.stab.git|*
# bump: vid.stab after ./hashupdate Dockerfile VIDSTAB $LATEST
ARG VIDSTAB_VERSION=1.1.0
ARG VIDSTAB_URL="https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz"
ARG VIDSTAB_SHA256=14d2a053e56edad4f397be0cb3ef8eb1ec3150404ce99a426c4eb641861dc0bb
# bump: kvazaar /KVAZAAR_VERSION=([\d.]+)/ https://github.com/ultravideo/kvazaar.git|^1
# bump: kvazaar after ./hashupdate Dockerfile KVAZAAR $LATEST
ARG KVAZAAR_VERSION=1.3.0
ARG KVAZAAR_URL="https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz"
ARG KVAZAAR_SHA256=f694fe71cc6e3e6f583a9faf380825ea93b2635c4db8d1d3121b9ebcf736ac1c
# bump: libass /LIBASS_VERSION=([\d.]+)/ https://github.com/libass/libass.git|*
# bump: libass after ./hashupdate Dockerfile LIBASS $LATEST
ARG LIBASS_VERSION=0.15.0
ARG LIBASS_URL="https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz"
ARG LIBASS_SHA256=9cbddee5e8c87e43a5fe627a19cd2aa4c36552156eb4edcf6c5a30bd4934fe58
# bump: zimg /ZIMG_VERSION=([\d.]+)/ https://github.com/sekrit-twc/zimg.git|*
# bump: zimg after ./hashupdate Dockerfile ZIMG $LATEST
ARG ZIMG_VERSION=3.0.1
ARG ZIMG_URL="https://github.com/sekrit-twc/zimg/archive/release-$ZIMG_VERSION.tar.gz"
ARG ZIMG_SHA256=c50a0922f4adac4efad77427d13520ed89b8366eef0ef2fa379572951afcc73f
# bump: openjpeg /OPENJPEG_VERSION=([\d.]+)/ https://github.com/uclouvain/openjpeg.git|*
# bump: openjpeg after ./hashupdate Dockerfile OPENJPEG $LATEST
ARG OPENJPEG_VERSION=2.4.0
ARG OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz"
ARG OPENJPEG_SHA256=8702ba68b442657f11aaeb2b338443ca8d5fb95b0d845757968a7be31ef7f16d
# bump: dav1d /DAV1D_VERSION=([\d.]+)/ https://code.videolan.org/videolan/dav1d.git|^0
# bump: dav1d after ./hashupdate Dockerfile DAV1D $LATEST
# bump: dav1d link "Release notes" https://code.videolan.org/videolan/dav1d/-/tags/$LATEST
ARG DAV1D_VERSION=0.8.1
ARG DAV1D_URL="https://code.videolan.org/videolan/dav1d/-/archive/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.gz"
ARG DAV1D_SHA256=39f52cccc31180c7180ebe8f223de6d12351c0407de0dfac087e8a9cc3feb8da
# bump: xvid /XVID_VERSION=([\d.]+)/ svn:http://anonymous:@svn.xvid.org|/^release-(.*)$/|/_/./|^1
# bump: xvid after ./hashupdate Dockerfile LIBXVID $LATEST
ARG XVID_VERSION=1.3.7
ARG XVID_URL="https://downloads.xvid.com/downloads/xvidcore-$XVID_VERSION.tar.gz"
ARG XVID_SHA256=abbdcbd39555691dd1c9b4d08f0a031376a3b211652c0d8b3b8aa9be1303ce2d
# bump: rav1e /RAV1E_VERSION=([\d.]+)/ https://github.com/xiph/rav1e.git|^0
# bump: rav1e after ./hashupdate Dockerfile RAV1E $LATEST
# bump: rav1e link "Release notes" https://github.com/xiph/rav1e/releases/tag/v$LATEST
ARG RAV1E_VERSION=0.4.0
ARG RAV1E_URL="https://github.com/xiph/rav1e/archive/v$RAV1E_VERSION.tar.gz"
ARG RAV1E_SHA256=c3ea1a2275f09c8a8964084c094d81f01c07fb405930633164ba69d0613a9003
# bump: srt /SRT_VERSION=([\d.]+)/ https://github.com/Haivision/srt.git|^1
# bump: srt after ./hashupdate Dockerfile SRT $LATEST
# bump: srt link "Release notes" https://github.com/Haivision/srt/releases/tag/v$LATEST
ARG SRT_VERSION=1.4.1
ARG SRT_URL="https://github.com/Haivision/srt/archive/v${SRT_VERSION}.tar.gz"
ARG SRT_SHA256=e80ca1cd0711b9c70882c12ec365cda1ba852e1ce8acd43161a21a04de0cbf14

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
  openssl-libs-static \
  bash \
  tar \
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
  rust \
  cargo \
  texinfo \
  jq \
  zlib \
  zlib-dev \
  zlib-static \
  libbz2 \
  bzip2-dev \
  bzip2-static \
  libxml2 \
  libxml2-dev \
  expat \
  expat-dev \
  expat-static \
  fontconfig \
  fontconfig-dev \
  fontconfig-static \
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
  brotli \
  brotli-dev \
  brotli-static \
  soxr \
  soxr-dev \
  soxr-static \
  tcl
 
# workaround for https://github.com/google/brotli/issues/795
# pkgconfig --static can't have different name than .so
RUN \
  ln -s /usr/lib/libbrotlicommon-static.a /usr/lib/libbrotlicommon.a && \
  ln -s /usr/lib/libbrotlidec-static.a /usr/lib/libbrotlidec.a

RUN \
  OPENSSL_VERSION=$(pkg-config --modversion openssl) \
  LIBXML2_VERSION=$(pkg-config --modversion libxml-2.0) \
  EXPAT_VERSION=$(pkg-config --modversion expat) \
  FREETYPE_VERSION=$(pkg-config --modversion freetype2)  \
  FONTCONFIG_VERSION=$(pkg-config --modversion fontconfig)  \
  FRIBIDI_VERSION=$(pkg-config --modversion fribidi)  \
  SOXR_VERSION=$(pkg-config --modversion soxr) \
  jq -n \
  '{ \
  ffmpeg: env.FFMPEG_VERSION, \
  openssl: env.OPENSSL_VERSION, \
  libxml2: env.LIBXML2_VERSION, \
  expat: env.EXPAT_VERSION, \
  libmp3lame: env.MP3LAME_VERSION, \
  "libfdk-aac": env.FDK_AAC_VERSION, \
  libogg: env.OGG_VERSION, \
  libvorbis: env.VORBIS_VERSION, \
  libopus: env.OPUS_VERSION, \
  libtheora: env.THEORA_VERSION, \
  libvpx: env.VPX_VERSION, \
  libx264: env.X264_VERSION, \
  libx265: env.X265_VERSION, \
  libwebp: env.LIBWEBP_VERSION, \
  libwavpack: env.WAVPACK_VERSION, \
  libspeex: env.SPEEX_VERSION, \
  libaom: env.AOM_VERSION, \
  libvidstab: env.VIDSTAB_VERSION, \
  libkvazaar: env.KVAZAAR_VERSION, \
  libfreetype: env.FREETYPE_VERSION, \
  fontconfig: env.FONTCONFIG_VERSION, \
  libfribidi: env.FRIBIDI_VERSION, \
  libass: env.LIBASS_VERSION, \
  libzimg: env.ZIMG_VERSION, \
  libsoxr: env.SOXR_VERSION, \
  libopenjpeg: env.OPENJPEG_VERSION, \
  libdav1d: env.DAV1D_VERSION, \
  libxvid: env.XVID_VERSION, \
  librav1e: env.RAV1E_VERSION, \
  libsrt: env.SRT_VERSION, \
  }' > /versions.json

RUN \
  wget -O lame.tar.gz "$MP3LAME_URL" && \
  echo "$MP3LAME_SHA256  lame.tar.gz" | sha256sum --status -c - && \
  tar xf lame.tar.gz && \
  cd lame-* && ./configure --enable-static --enable-nasm --disable-shared && make -j$(nproc) install

RUN \
  wget -O fdk-aac.tar.gz "$FDK_AAC_URL" && \
  echo "$FDK_AAC_SHA256  fdk-aac.tar.gz" | sha256sum --status -c - && \
  tar xf fdk-aac.tar.gz && \
  cd fdk-aac-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libogg.tar.gz "$OGG_URL" && \
  echo "$OGG_SHA256  libogg.tar.gz" | sha256sum --status -c - && \
  tar xf libogg.tar.gz && \
  cd libogg-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

# require libogg to build
RUN \
  wget -O libvorbis.tar.gz "$VORBIS_URL" && \
  echo "$VORBIS_SHA256  libvorbis.tar.gz" | sha256sum --status -c - && \
  tar xf libvorbis.tar.gz && \
  cd libvorbis-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O opus.tar.gz "$OPUS_URL" && \
  echo "$OPUS_SHA256  opus.tar.gz" | sha256sum --status -c - && \
  tar xf opus.tar.gz && \
  cd opus-* && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libtheora.tar.gz "$THEORA_URL" && \
  echo "$THEORA_SHA256  libtheora.tar.gz" | sha256sum --status -c - && \
  tar xf libtheora.tar.gz && \
  cd libtheora-* && ./configure --disable-examples --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libvpx.tar.gz "$VPX_URL" && \
  echo "$VPX_SHA256  libvpx.tar.gz" | sha256sum --status -c - && \
  tar xf libvpx.tar.gz && \
  cd libvpx-* && ./configure --enable-static --enable-vp9-highbitdepth --disable-shared --disable-unit-tests --disable-examples && \
  make -j$(nproc) install

RUN \
  git clone "$X264_URL" && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static && make -j$(nproc) install

RUN \
  wget -O x265.tar.gz "$X265_URL" && \
  echo "$X265_SHA256  x265.tar.gz" | sha256sum --status -c - && \
  tar xf x265.tar.gz && \
  cd multicoreware-x265_git-*/build/linux && \
  cmake -G "Unix Makefiles" -DENABLE_SHARED=OFF -DENABLE_AGGRESSIVE_CHECKS=ON ../../source && \
  make -j$(nproc) install

RUN \
  wget -O libwebp.tar.gz "$LIBWEBP_URL" && \
  echo "$LIBWEBP_SHA256  libwebp.tar.gz" | sha256sum --status -c - && \
  tar xf libwebp.tar.gz && \
  cd libwebp-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O wavpack.tar.gz "$WAVPACK_URL" && \
  echo "$WAVPACK_SHA256  wavpack.tar.gz" | sha256sum --status -c - && \
  tar xf wavpack.tar.gz && \
  cd WavPack-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O speex.tar.gz "$SPEEX_URL" && \
  echo "$SPEEX_SHA256  speex.tar.gz" | sha256sum --status -c - && \
  tar xf speex.tar.gz && \
  cd speex-Speex-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  git clone --depth 1 --branch v$AOM_VERSION "$AOM_URL" && \
  cd aom && test $(git rev-parse HEAD) = $AOM_COMMIT && \
  mkdir build_tmp && cd build_tmp && cmake -DBUILD_SHARED_LIBS=0 -DENABLE_TESTS=0 -DENABLE_NASM=on -DCMAKE_INSTALL_LIBDIR=lib .. && make -j$(nproc) install

RUN \
  wget -O vid.stab.tar.gz "$VIDSTAB_URL" && \
  echo "$VIDSTAB_SHA256  vid.stab.tar.gz" | sha256sum --status -c - && \
  tar xf vid.stab.tar.gz && \
  cd vid.stab-* && cmake -DBUILD_SHARED_LIBS=OFF . && make -j$(nproc) install

RUN \
  wget -O kvazaar.tar.gz "$KVAZAAR_URL" && \
  echo "$KVAZAAR_SHA256  kvazaar.tar.gz" | sha256sum --status -c - && \
  tar xf kvazaar.tar.gz && \
  cd kvazaar-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O libass.tar.gz "$LIBASS_URL" && \
  echo "$LIBASS_SHA256  libass.tar.gz" | sha256sum --status -c - && \
  tar xf libass.tar.gz && \
  cd libass-* && ./configure --enable-static --disable-shared && make -j$(nproc) && make install

RUN \
  wget -O zimg.tar.gz "$ZIMG_URL" && \
  echo "$ZIMG_SHA256  zimg.tar.gz" | sha256sum --status -c - && \
  tar xf zimg.tar.gz && \
  cd zimg-* && ./autogen.sh && ./configure --enable-static --disable-shared && make -j$(nproc) install

RUN \
  wget -O openjpeg.tar.gz "$OPENJPEG_URL" && \
  echo "$OPENJPEG_SHA256  openjpeg.tar.gz" | sha256sum --status -c - && \
  tar xf openjpeg.tar.gz && \
  cd openjpeg-* && cmake -G "Unix Makefiles" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTS=OFF && make -j$(nproc) install

RUN \
  wget -O dav1d.tar.gz "$DAV1D_URL" && \
  echo "$DAV1D_SHA256  dav1d.tar.gz" | sha256sum --status -c - && \
  tar xf dav1d.tar.gz && \
  cd dav1d-* && meson build --buildtype release -Ddefault_library=static && ninja -C build install

# add extra CFLAGS that are not enabled by -O3
# http://websvn.xvid.org/cvs/viewvc.cgi/trunk/xvidcore/build/generic/configure.in?revision=2146&view=markup
RUN \
  wget -O libxvid.tar.gz "$XVID_URL" && \
  echo "$XVID_SHA256  libxvid.tar.gz" | sha256sum --status -c - && \
  tar xf libxvid.tar.gz && \
  cd xvidcore/build/generic && \
  CFLAGS="$CLFAGS -fstrength-reduce -ffast-math" \
  ./configure && make -j$(nproc) && make install

RUN cargo install cargo-c
RUN \
  wget -O rav1e.tar.gz "$RAV1E_URL" && \
  tar xf rav1e.tar.gz && \
  cd rav1e-* && \
  cargo cinstall --release
# cargo-c/alpine rustc results in Libs.private depend on gcc_s
# https://gitlab.alpinelinux.org/alpine/aports/-/issues/11806
RUN sed -i 's/-lgcc_s//' /usr/local/lib/pkgconfig/rav1e.pc

RUN \
  wget -O libsrt.tar.gz "$SRT_URL" && \
  echo "$SRT_SHA256  libsrt.tar.gz" | sha256sum --status -c - && \
  tar xf libsrt.tar.gz && \
  cd srt-* && ./configure --enable-shared=0 --cmake-install-libdir=lib --cmake-install-includedir=include --cmake-install-bindir=bin && \
  make -j$(nproc) && make install

# sed changes --toolchain=hardened -pie to -static-pie
RUN \
  wget -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
  echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum --status -c - && \
  tar xf ffmpeg.tar.bz2 && \
  cd ffmpeg-* && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags=--static \
  --extra-cflags="-fopenmp" \
  --extra-ldflags="-fopenmp" \
  --toolchain=hardened \
  --disable-debug \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-gray \
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
  --enable-libxvid \
  --enable-librav1e \
  --enable-libsrt \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install tools/qt-faststart \
  && cp tools/qt-faststart /usr/local/bin

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN \
  /checkelf /usr/local/bin/ffmpeg && \
  /checkelf /usr/local/bin/ffprobe && \
  /checkelf /usr/local/bin/qt-faststart

FROM scratch
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
COPY --from=builder /versions.json /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /usr/local/bin/qt-faststart /
COPY --from=builder /usr/local/share/doc/ffmpeg/* /doc/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem
# sanity tests
RUN ["/ffmpeg", "-version"]
RUN ["/ffprobe", "-version"]
RUN ["/qt-faststart", "-version"]
RUN ["/ffprobe", "-i", "https://github.com/favicon.ico"]
RUN ["/ffprobe", "-tls_verify", "1", "-ca_file", "/etc/ssl/cert.pem", "-i", "https://github.com/favicon.ico"]
ENTRYPOINT ["/ffmpeg"]
