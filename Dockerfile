# bump: alpine /FROM alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
FROM alpine:3.19.1 AS builder

RUN apk add --no-cache \
  coreutils \
  wget \
  rust cargo cargo-c \
  openssl-dev openssl-libs-static \
  ca-certificates \
  bash \
  tar \
  build-base \
  autoconf automake \
  libtool \
  diffutils \
  cmake meson ninja \
  git \
  yasm nasm \
  texinfo \
  jq \
  zlib-dev zlib-static \
  bzip2-dev bzip2-static \
  libxml2-dev libxml2-static \
  expat-dev expat-static \
  fontconfig-dev fontconfig-static \
  freetype freetype-dev freetype-static \
  graphite2-static \
  glib-static \
  tiff tiff-dev \
  libjpeg-turbo libjpeg-turbo-dev \
  libpng-dev libpng-static \
  giflib giflib-dev \
  harfbuzz-dev harfbuzz-static \
  fribidi-dev fribidi-static \
  brotli-dev brotli-static \
  soxr-dev soxr-static \
  tcl \
  numactl-dev \
  cunit cunit-dev \
  fftw-dev \
  libsamplerate-dev libsamplerate-static \
  vo-amrwbenc-dev vo-amrwbenc-static \
  snappy snappy-dev snappy-static \
  xxd \
  xz-dev xz-static \
  curl
  
# -O3 makes sure we compile with optimization. setting CFLAGS/CXXFLAGS seems to override
# default automake cflags.
# -static-libgcc is needed to make gcc not include gcc_s as "as-needed" shared library which
# cmake will include as a implicit library.
# other options to get hardened build (same as ffmpeg hardened)
ARG CFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG CXXFLAGS="-O3 -static-libgcc -fno-strict-overflow -fstack-protector-all -fPIC"
ARG LDFLAGS="-Wl,-z,relro,-z,now"

# retry dns and some http codes that might be transient errors
ARG WGET_OPTS="--retry-on-host-error --retry-on-http-error=429,500,502,503"

# --no-same-owner as we don't care about uid/gid even if we run as root. fixes invalid gid/uid issue.
ARG TAR_OPTS="--no-same-owner --extract --file"

# before aom as libvmaf uses it
# bump: vmaf /VMAF_VERSION=([\d.]+)/ https://github.com/Netflix/vmaf.git|*
# bump: vmaf after ./hashupdate Dockerfile VMAF $LATEST
# bump: vmaf link "Release" https://github.com/Netflix/vmaf/releases/tag/v$LATEST
# bump: vmaf link "Source diff $CURRENT..$LATEST" https://github.com/Netflix/vmaf/compare/v$CURRENT..v$LATEST
ARG VMAF_VERSION=3.0.0
ARG VMAF_URL="https://github.com/Netflix/vmaf/archive/refs/tags/v$VMAF_VERSION.tar.gz"
ARG VMAF_SHA256=7178c4833639e6b989ecae73131d02f70735fdb3fc2c7d84bc36c9c3461d93b1
RUN wget $WGET_OPTS -O vmaf.tar.gz "$VMAF_URL"
RUN echo "$VMAF_SHA256  vmaf.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS vmaf.tar.gz && \
  cd vmaf-*/libvmaf && meson build --buildtype=release -Ddefault_library=static -Dbuilt_in_models=true -Denable_tests=false -Denable_docs=false -Denable_avx512=true -Denable_float=true && \
  ninja -j$(nproc) -vC build install
# extra libs stdc++ is for vmaf https://github.com/Netflix/vmaf/issues/788
RUN sed -i 's/-lvmaf /-lvmaf -lstdc++ /' /usr/local/lib/pkgconfig/libvmaf.pc

# build after libvmaf
# bump: aom /AOM_VERSION=([\d.]+)/ git:https://aomedia.googlesource.com/aom|*
# bump: aom after ./hashupdate Dockerfile AOM $LATEST
# bump: aom after COMMIT=$(git ls-remote https://aomedia.googlesource.com/aom v$LATEST^{} | awk '{print $1}') && sed -i -E "s/^ARG AOM_COMMIT=.*/ARG AOM_COMMIT=$COMMIT/" Dockerfile
# bump: aom link "CHANGELOG" https://aomedia.googlesource.com/aom/+/refs/tags/v$LATEST/CHANGELOG
ARG AOM_VERSION=3.8.2
ARG AOM_URL="https://aomedia.googlesource.com/aom"
ARG AOM_COMMIT=615b5f541e4434aebd993036bc97ebc1a77ebc25
RUN git clone --depth 1 --branch v$AOM_VERSION "$AOM_URL"
RUN cd aom && test $(git rev-parse HEAD) = $AOM_COMMIT
RUN \
  cd aom && \
  mkdir build_tmp && cd build_tmp && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_EXAMPLES=NO \
    -DENABLE_DOCS=NO \
    -DENABLE_TESTS=NO \
    -DENABLE_TOOLS=NO \
    -DCONFIG_TUNE_VMAF=1 \
    -DENABLE_NASM=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    .. && \
  make -j$(nproc) install

# bump: libaribb24 /LIBARIBB24_VERSION=([\d.]+)/ https://github.com/nkoriyama/aribb24.git|*
# bump: libaribb24 after ./hashupdate Dockerfile LIBARIBB24 $LATEST
# bump: libaribb24 link "Release notes" https://github.com/nkoriyama/aribb24/releases/tag/$LATEST
ARG LIBARIBB24_VERSION=1.0.3
ARG LIBARIBB24_URL="https://github.com/nkoriyama/aribb24/archive/v$LIBARIBB24_VERSION.tar.gz"
ARG LIBARIBB24_SHA256=f61560738926e57f9173510389634d8c06cabedfa857db4b28fb7704707ff128
RUN wget $WGET_OPTS -O libaribb24.tar.gz "$LIBARIBB24_URL"
RUN echo "$LIBARIBB24_SHA256  libaribb24.tar.gz" | sha256sum --status -c -
RUN \
  mkdir libaribb24 && \
  tar $TAR_OPTS libaribb24.tar.gz -C libaribb24 --strip-components=1 && \
  cd libaribb24 && \
  autoreconf -fiv && \
  ./configure --enable-static --disable-shared && \
  make -j$(nproc) && make install

# bump: libass /LIBASS_VERSION=([\d.]+)/ https://github.com/libass/libass.git|*
# bump: libass after ./hashupdate Dockerfile LIBASS $LATEST
# bump: libass link "Release notes" https://github.com/libass/libass/releases/tag/$LATEST
ARG LIBASS_VERSION=0.17.1
ARG LIBASS_URL="https://github.com/libass/libass/releases/download/$LIBASS_VERSION/libass-$LIBASS_VERSION.tar.gz"
ARG LIBASS_SHA256=d653be97198a0543c69111122173c41a99e0b91426f9e17f06a858982c2fb03d
RUN wget $WGET_OPTS -O libass.tar.gz "$LIBASS_URL"
RUN echo "$LIBASS_SHA256  libass.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libass.tar.gz && \
  cd libass-* && ./configure --disable-shared --enable-static && \
  make -j$(nproc) && make install

# bump: libbluray /LIBBLURAY_VERSION=([\d.]+)/ https://code.videolan.org/videolan/libbluray.git|*
# bump: libbluray after ./hashupdate Dockerfile LIBBLURAY $LATEST
# bump: libbluray link "ChangeLog" https://code.videolan.org/videolan/libbluray/-/blob/master/ChangeLog
ARG LIBBLURAY_VERSION=1.3.4
ARG LIBBLURAY_URL="https://code.videolan.org/videolan/libbluray/-/archive/$LIBBLURAY_VERSION/libbluray-$LIBBLURAY_VERSION.tar.gz"
ARG LIBBLURAY_SHA256=9820df5c3e87777be116ca225ad7ee026a3ff42b2447c7fe641910fb23aad3c2
RUN wget $WGET_OPTS -O libbluray.tar.gz "$LIBBLURAY_URL"
RUN echo "$LIBBLURAY_SHA256  libbluray.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libbluray.tar.gz &&  cd libbluray-* && git clone https://code.videolan.org/videolan/libudfread.git contrib/libudfread && \
  autoreconf -fiv && ./configure --with-pic --disable-doxygen-doc --disable-doxygen-dot --enable-static --disable-shared --disable-examples --disable-bdjava-jar && \
  make -j$(nproc) install

# bump: dav1d /DAV1D_VERSION=([\d.]+)/ https://code.videolan.org/videolan/dav1d.git|*
# bump: dav1d after ./hashupdate Dockerfile DAV1D $LATEST
# bump: dav1d link "Release notes" https://code.videolan.org/videolan/dav1d/-/tags/$LATEST
ARG DAV1D_VERSION=1.4.0
ARG DAV1D_URL="https://code.videolan.org/videolan/dav1d/-/archive/$DAV1D_VERSION/dav1d-$DAV1D_VERSION.tar.gz"
ARG DAV1D_SHA256=0b6d484fc3d20541a21403812499530b72875dee0ec88f682cb1d73943dfc156
RUN wget $WGET_OPTS -O dav1d.tar.gz "$DAV1D_URL"
RUN echo "$DAV1D_SHA256  dav1d.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS dav1d.tar.gz && \
  cd dav1d-* && meson build --buildtype release -Ddefault_library=static && \
  ninja -j$(nproc) -C build install

# bump: davs2 /DAVS2_VERSION=([\d.]+)/ https://github.com/pkuvcl/davs2.git|^1
# bump: davs2 after ./hashupdate Dockerfile DAVS2 $LATEST
# bump: davs2 link "Release" https://github.com/pkuvcl/davs2/releases/tag/$LATEST
# bump: davs2 link "Source diff $CURRENT..$LATEST" https://github.com/pkuvcl/davs2/compare/v$CURRENT..v$LATEST
ARG DAVS2_VERSION=1.7
ARG DAVS2_URL="https://github.com/pkuvcl/davs2/archive/refs/tags/$DAVS2_VERSION.tar.gz"
ARG DAVS2_SHA256=b697d0b376a1c7f7eda3a4cc6d29707c8154c4774358303653f0a9727f923cc8
# TODO: seems to be issues with asm on musl
RUN wget $WGET_OPTS -O davs2.tar.gz "$DAVS2_URL"
RUN echo "$DAVS2_SHA256  davs2.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS davs2.tar.gz && \
  cd davs2-*/build/linux && ./configure --disable-asm --enable-pic --enable-strip --disable-cli && \
  make -j$(nproc) install

# bump: fdk-aac /FDK_AAC_VERSION=([\d.]+)/ https://github.com/mstorsjo/fdk-aac.git|*
# bump: fdk-aac after ./hashupdate Dockerfile FDK_AAC $LATEST
# bump: fdk-aac link "ChangeLog" https://github.com/mstorsjo/fdk-aac/blob/master/ChangeLog
# bump: fdk-aac link "Source diff $CURRENT..$LATEST" https://github.com/mstorsjo/fdk-aac/compare/v$CURRENT..v$LATEST
ARG FDK_AAC_VERSION=2.0.3
ARG FDK_AAC_URL="https://github.com/mstorsjo/fdk-aac/archive/v$FDK_AAC_VERSION.tar.gz"
ARG FDK_AAC_SHA256=e25671cd96b10bad896aa42ab91a695a9e573395262baed4e4a2ff178d6a3a78
RUN wget $WGET_OPTS -O fdk-aac.tar.gz "$FDK_AAC_URL"
RUN echo "$FDK_AAC_SHA256  fdk-aac.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS fdk-aac.tar.gz && \
  cd fdk-aac-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: libgme /LIBGME_COMMIT=([[:xdigit:]]+)/ gitrefs:https://github.com/libgme/game-music-emu.git|re:#^refs/heads/master$#|@commit
# bump: libgme after ./hashupdate Dockerfile LIBGME $LATEST
# bump: libgme link "Source diff $CURRENT..$LATEST" https://github.com/libgme/game-music-emu/compare/$CURRENT..v$LATEST
ARG LIBGME_URL="https://github.com/libgme/game-music-emu.git"
ARG LIBGME_COMMIT=6b676192d98302e698ac78fe3c00833eae6a74e5
RUN \
  git clone "$LIBGME_URL" && \
  cd game-music-emu && git checkout $LIBGME_COMMIT && \
  mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DENABLE_UBSAN=OFF \
    .. && \
  make -j$(nproc) install

# bump: libgsm /LIBGSM_COMMIT=([[:xdigit:]]+)/ gitrefs:https://github.com/timothytylee/libgsm.git|re:#^refs/heads/master$#|@commit
# bump: libgsm after ./hashupdate Dockerfile LIBGSM $LATEST
# bump: libgsm link "Changelog" https://github.com/timothytylee/libgsm/blob/master/ChangeLog
ARG LIBGSM_URL="https://github.com/timothytylee/libgsm.git"
ARG LIBGSM_COMMIT=98f1708fb5e06a0dfebd58a3b40d610823db9715
RUN \
  git clone "$LIBGSM_URL" && \
  cd libgsm && git checkout $LIBGSM_COMMIT && \
  # Makefile is hard to use, hence use specific compile arguments and flags
  # no need to build toast cli tool \
  rm src/toast* && \
  SRC=$(echo src/*.c) && \
  gcc ${CFLAGS} -c -ansi -pedantic -s -DNeedFunctionPrototypes=1 -Wall -Wno-comment -DSASR -DWAV49 -DNDEBUG -I./inc ${SRC} && \
  ar cr libgsm.a *.o && ranlib libgsm.a && \
  mkdir -p /usr/local/include/gsm && \
  cp inc/*.h /usr/local/include/gsm && \
  cp libgsm.a /usr/local/lib

# bump: kvazaar /KVAZAAR_VERSION=([\d.]+)/ https://github.com/ultravideo/kvazaar.git|^2
# bump: kvazaar after ./hashupdate Dockerfile KVAZAAR $LATEST
# bump: kvazaar link "Release notes" https://github.com/ultravideo/kvazaar/releases/tag/v$LATEST
ARG KVAZAAR_VERSION=2.2.0
ARG KVAZAAR_URL="https://github.com/ultravideo/kvazaar/archive/v$KVAZAAR_VERSION.tar.gz"
ARG KVAZAAR_SHA256=df21f327318d530fe7f2ec65ccabf400690791ebad726d8b785c243506f0e446
RUN wget $WGET_OPTS -O kvazaar.tar.gz "$KVAZAAR_URL"
RUN echo "$KVAZAAR_SHA256  kvazaar.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS kvazaar.tar.gz && \
  cd kvazaar-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: libmodplug /LIBMODPLUG_VERSION=([\d.]+)/ fetch:https://sourceforge.net/projects/modplug-xmms/files/|/libmodplug-([\d.]+).tar.gz/
# bump: libmodplug after ./hashupdate Dockerfile LIBMODPLUG $LATEST
# bump: libmodplug link "NEWS" https://sourceforge.net/p/modplug-xmms/git/ci/master/tree/libmodplug/NEWS
ARG LIBMODPLUG_VERSION=0.8.9.0
ARG LIBMODPLUG_URL="https://downloads.sourceforge.net/modplug-xmms/libmodplug-$LIBMODPLUG_VERSION.tar.gz"
ARG LIBMODPLUG_SHA256=457ca5a6c179656d66c01505c0d95fafaead4329b9dbaa0f997d00a3508ad9de
RUN wget $WGET_OPTS -O libmodplug.tar.gz "$LIBMODPLUG_URL"
RUN echo "$LIBMODPLUG_SHA256  libmodplug.tar.gz" | sha256sum --status -c
RUN \
  tar $TAR_OPTS libmodplug.tar.gz && \
  cd libmodplug-* && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: mp3lame /MP3LAME_VERSION=([\d.]+)/ svn:http://svn.code.sf.net/p/lame/svn|/^RELEASE__(.*)$/|/_/./|*
# bump: mp3lame after ./hashupdate Dockerfile MP3LAME $LATEST
# bump: mp3lame link "ChangeLog" http://svn.code.sf.net/p/lame/svn/trunk/lame/ChangeLog
ARG MP3LAME_VERSION=3.100
ARG MP3LAME_URL="https://sourceforge.net/projects/lame/files/lame/$MP3LAME_VERSION/lame-$MP3LAME_VERSION.tar.gz/download"
ARG MP3LAME_SHA256=ddfe36cab873794038ae2c1210557ad34857a4b6bdc515785d1da9e175b1da1e
RUN wget $WGET_OPTS -O lame.tar.gz "$MP3LAME_URL"
RUN echo "$MP3LAME_SHA256  lame.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS lame.tar.gz && \
  cd lame-* && ./configure --disable-shared --enable-static --enable-nasm --disable-gtktest --disable-cpml --disable-frontend && \
  make -j$(nproc) install

# bump: lcms2 /LCMS2_VERSION=([\d.]+)/ https://github.com/mm2/Little-CMS.git|^2
# bump: lcms2 after ./hashupdate Dockerfile LCMS2 $LATEST
# bump: lcms2 link "Release" https://github.com/mm2/Little-CMS/releases/tag/lcms$LATEST
ARG LCMS2_VERSION=2.16
ARG LCMS2_URL="https://github.com/mm2/Little-CMS/releases/download/lcms$LCMS2_VERSION/lcms2-$LCMS2_VERSION.tar.gz"
ARG LCMS2_SHA256=d873d34ad8b9b4cea010631f1a6228d2087475e4dc5e763eb81acc23d9d45a51
RUN wget -O lcms2.tar.gz "$LCMS2_URL"
RUN echo "$LCMS2_SHA256  lcms2.tar.gz" | sha256sum --status -c -
RUN \
  tar xfz lcms2.tar.gz && \
  cd lcms2-* && \
  ./autogen.sh && ./configure --enable-static --disable-shared && \
  make -j$(nproc) install

# bump: libmysofa /LIBMYSOFA_VERSION=([\d.]+)/ https://github.com/hoene/libmysofa.git|^1
# bump: libmysofa after ./hashupdate Dockerfile LIBMYSOFA $LATEST
# bump: libmysofa link "Release" https://github.com/hoene/libmysofa/releases/tag/v$LATEST
# bump: libmysofa link "Source diff $CURRENT..$LATEST" https://github.com/hoene/libmysofa/compare/v$CURRENT..v$LATEST
ARG LIBMYSOFA_VERSION=1.3.2
ARG LIBMYSOFA_URL="https://github.com/hoene/libmysofa/archive/refs/tags/v$LIBMYSOFA_VERSION.tar.gz"
ARG LIBMYSOFA_SHA256=6c5224562895977e87698a64cb7031361803d136057bba35ed4979b69ab4ba76
RUN wget $WGET_OPTS -O libmysofa.tar.gz "$LIBMYSOFA_URL"
RUN echo "$LIBMYSOFA_SHA256  libmysofa.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libmysofa.tar.gz && \
  cd libmysofa-*/build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    .. && \
  make -j$(nproc) install

# bump: opencoreamr /OPENCOREAMR_VERSION=([\d.]+)/ fetch:https://sourceforge.net/projects/opencore-amr/files/opencore-amr/|/opencore-amr-([\d.]+).tar.gz/
# bump: opencoreamr after ./hashupdate Dockerfile OPENCOREAMR $LATEST
# bump: opencoreamr link "ChangeLog" https://sourceforge.net/p/opencore-amr/code/ci/master/tree/ChangeLog
ARG OPENCOREAMR_VERSION=0.1.6
ARG OPENCOREAMR_URL="https://sourceforge.net/projects/opencore-amr/files/opencore-amr/opencore-amr-$OPENCOREAMR_VERSION.tar.gz"
ARG OPENCOREAMR_SHA256=483eb4061088e2b34b358e47540b5d495a96cd468e361050fae615b1809dc4a1
RUN wget $WGET_OPTS -O opencoreamr.tar.gz "$OPENCOREAMR_URL"
RUN echo "$OPENCOREAMR_SHA256  opencoreamr.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS opencoreamr.tar.gz && \
  cd opencore-amr-* && ./configure --enable-static --disable-shared && \
  make -j$(nproc) install

# bump: openjpeg /OPENJPEG_VERSION=([\d.]+)/ https://github.com/uclouvain/openjpeg.git|*
# bump: openjpeg after ./hashupdate Dockerfile OPENJPEG $LATEST
# bump: openjpeg link "CHANGELOG" https://github.com/uclouvain/openjpeg/blob/master/CHANGELOG.md
ARG OPENJPEG_VERSION=2.5.2
ARG OPENJPEG_URL="https://github.com/uclouvain/openjpeg/archive/v$OPENJPEG_VERSION.tar.gz"
ARG OPENJPEG_SHA256=90e3896fed910c376aaf79cdd98bdfdaf98c6472efd8e1debf0a854938cbda6a
RUN wget $WGET_OPTS -O openjpeg.tar.gz "$OPENJPEG_URL"
RUN echo "$OPENJPEG_SHA256  openjpeg.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS openjpeg.tar.gz && \
  cd openjpeg-* && mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_PKGCONFIG_FILES=ON \
    -DBUILD_CODEC=OFF \
    -DWITH_ASTYLE=OFF \
    -DBUILD_TESTING=OFF \
    .. && \
  make -j$(nproc) install

# bump: opus /OPUS_VERSION=([\d.]+)/ https://github.com/xiph/opus.git|^1
# bump: opus after ./hashupdate Dockerfile OPUS $LATEST
# bump: opus link "Release notes" https://github.com/xiph/opus/releases/tag/v$LATEST
# bump: opus link "Source diff $CURRENT..$LATEST" https://github.com/xiph/opus/compare/v$CURRENT..v$LATEST
ARG OPUS_VERSION=1.5.1
ARG OPUS_URL="https://downloads.xiph.org/releases/opus/opus-$OPUS_VERSION.tar.gz"
ARG OPUS_SHA256=b84610959b8d417b611aa12a22565e0a3732097c6389d19098d844543e340f85
RUN wget $WGET_OPTS -O opus.tar.gz "$OPUS_URL"
RUN echo "$OPUS_SHA256  opus.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS opus.tar.gz && \
  cd opus-* && ./configure --disable-shared --enable-static --disable-extra-programs --disable-doc && \
  make -j$(nproc) install

# bump: librabbitmq /LIBRABBITMQ_VERSION=([\d.]+)/ https://github.com/alanxz/rabbitmq-c.git|*
# bump: librabbitmq after ./hashupdate Dockerfile LIBRABBITMQ $LATEST
# bump: librabbitmq link "ChangeLog" https://github.com/alanxz/rabbitmq-c/blob/master/ChangeLog.md
ARG LIBRABBITMQ_VERSION=0.13.0
ARG LIBRABBITMQ_URL="https://github.com/alanxz/rabbitmq-c/archive/refs/tags/v$LIBRABBITMQ_VERSION.tar.gz"
ARG LIBRABBITMQ_SHA256=8b224e41bba504fc52b02f918d8df7e4bf5359d493cbbff36c06078655c676e6
RUN wget $WGET_OPTS -O rabbitmq-c.tar.gz "$LIBRABBITMQ_URL"
RUN echo "$LIBRABBITMQ_SHA256  rabbitmq-c.tar.gz" | sha256sum --status -c -
RUN \
  tar xfz rabbitmq-c.tar.gz && \
  cd rabbitmq-c-* && mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DBUILD_EXAMPLES=OFF \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_STATIC_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_TESTS=OFF \
    -DBUILD_TOOLS=OFF \
    -DBUILD_TOOLS_DOCS=OFF \
    -DRUN_SYSTEM_TESTS=OFF \
    .. && \
  make -j$(nproc) install

# bump: rav1e /RAV1E_VERSION=([\d.]+)/ https://github.com/xiph/rav1e.git|/\d+\./|*
# bump: rav1e after ./hashupdate Dockerfile RAV1E $LATEST
# bump: rav1e link "Release notes" https://github.com/xiph/rav1e/releases/tag/v$LATEST
ARG RAV1E_VERSION=0.7.1
ARG RAV1E_URL="https://github.com/xiph/rav1e/archive/v$RAV1E_VERSION.tar.gz"
ARG RAV1E_SHA256=da7ae0df2b608e539de5d443c096e109442cdfa6c5e9b4014361211cf61d030c
RUN wget $WGET_OPTS -O rav1e.tar.gz "$RAV1E_URL"
RUN echo "$RAV1E_SHA256  rav1e.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS rav1e.tar.gz && \
  cd rav1e-* && \
  # workaround weird cargo problem when on aws (?) weirdly alpine edge seems to work
  CARGO_REGISTRIES_CRATES_IO_PROTOCOL="sparse" \
  RUSTFLAGS="-C target-feature=+crt-static" cargo cinstall --release

# bump: librtmp /LIBRTMP_COMMIT=([[:xdigit:]]+)/ gitrefs:https://git.ffmpeg.org/rtmpdump.git|re:#^refs/heads/master$#|@commit
# bump: librtmp after ./hashupdate Dockerfile LIBRTMP $LATEST
# bump: librtmp link "Commit diff $CURRENT..$LATEST" https://git.ffmpeg.org/gitweb/rtmpdump.git/commitdiff/$LATEST?ds=sidebyside
ARG LIBRTMP_URL="https://git.ffmpeg.org/rtmpdump.git"
ARG LIBRTMP_COMMIT=b59c7926aff3271ff0fe85ac46c6ca390dc81000
RUN \
  git clone "$LIBRTMP_URL" && \
  cd rtmpdump && git checkout $LIBRTMP_COMMIT && \
  # Patch/port librtmp to openssl 1.1
  for _dlp in dh.h handshake.h hashswf.c; do \
    wget $WGET_OPTS https://raw.githubusercontent.com/microsoft/vcpkg/38bb87c5571555f1a4f64cb4ed9d2be0017f9fc1/ports/librtmp/${_dlp%.*}.patch; \
    patch librtmp/${_dlp} < ${_dlp%.*}.patch; \
  done && \
  make SYS=posix SHARED=off -j$(nproc) install

# bump: rubberband /RUBBERBAND_VERSION=([\d.]+)/ https://github.com/breakfastquay/rubberband.git|^2
# bump: rubberband after ./hashupdate Dockerfile RUBBERBAND $LATEST
# bump: rubberband link "CHANGELOG" https://github.com/breakfastquay/rubberband/blob/default/CHANGELOG
# bump: rubberband link "Source diff $CURRENT..$LATEST" https://github.com/breakfastquay/rubberband/compare/$CURRENT..$LATEST
ARG RUBBERBAND_VERSION=2.0.2
ARG RUBBERBAND_URL="https://breakfastquay.com/files/releases/rubberband-$RUBBERBAND_VERSION.tar.bz2"
ARG RUBBERBAND_SHA256=b9eac027e797789ae99611c9eaeaf1c3a44cc804f9c8a0441a0d1d26f3d6bdf9
RUN wget $WGET_OPTS -O rubberband.tar.bz2 "$RUBBERBAND_URL"
RUN echo "$RUBBERBAND_SHA256  rubberband.tar.bz2" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS rubberband.tar.bz2 && \
  cd rubberband-* && \
  meson -Ddefault_library=static -Dfft=fftw -Dresampler=libsamplerate build && \
  ninja -j$(nproc) -vC build install && \
  echo "Requires.private: fftw3 samplerate" >> /usr/local/lib/pkgconfig/rubberband.pc

# bump: libshine /LIBSHINE_VERSION=([\d.]+)/ https://github.com/toots/shine.git|*
# bump: libshine after ./hashupdate Dockerfile LIBSHINE $LATEST
# bump: libshine link "CHANGELOG" https://github.com/toots/shine/blob/master/ChangeLog
# bump: libshine link "Source diff $CURRENT..$LATEST" https://github.com/toots/shine/compare/$CURRENT..$LATEST
ARG LIBSHINE_VERSION=3.1.1
ARG LIBSHINE_URL="https://github.com/toots/shine/releases/download/$LIBSHINE_VERSION/shine-$LIBSHINE_VERSION.tar.gz"
ARG LIBSHINE_SHA256=58e61e70128cf73f88635db495bfc17f0dde3ce9c9ac070d505a0cd75b93d384
RUN wget $WGET_OPTS -O libshine.tar.gz "$LIBSHINE_URL"
RUN echo "$LIBSHINE_SHA256  libshine.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libshine.tar.gz && cd shine* && \
  ./configure --with-pic --enable-static --disable-shared --disable-fast-install && \
  make -j$(nproc) install

# bump: speex /SPEEX_VERSION=([\d.]+)/ https://github.com/xiph/speex.git|*
# bump: speex after ./hashupdate Dockerfile SPEEX $LATEST
# bump: speex link "ChangeLog" https://github.com/xiph/speex//blob/master/ChangeLog
# bump: speex link "Source diff $CURRENT..$LATEST" https://github.com/xiph/speex/compare/$CURRENT..$LATEST
ARG SPEEX_VERSION=1.2.1
ARG SPEEX_URL="https://github.com/xiph/speex/archive/Speex-$SPEEX_VERSION.tar.gz"
ARG SPEEX_SHA256=beaf2642e81a822eaade4d9ebf92e1678f301abfc74a29159c4e721ee70fdce0
RUN wget $WGET_OPTS -O speex.tar.gz "$SPEEX_URL"
RUN echo "$SPEEX_SHA256  speex.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS speex.tar.gz && \
  cd speex-Speex-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: srt /SRT_VERSION=([\d.]+)/ https://github.com/Haivision/srt.git|^1
# bump: srt after ./hashupdate Dockerfile SRT $LATEST
# bump: srt link "Release notes" https://github.com/Haivision/srt/releases/tag/v$LATEST
ARG SRT_VERSION=1.5.3
ARG SRT_URL="https://github.com/Haivision/srt/archive/v$SRT_VERSION.tar.gz"
ARG SRT_SHA256=befaeb16f628c46387b898df02bc6fba84868e86a6f6d8294755375b9932d777
RUN wget $WGET_OPTS -O libsrt.tar.gz "$SRT_URL"
RUN echo "$SRT_SHA256  libsrt.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libsrt.tar.gz && cd srt-* && mkdir build && cd build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DENABLE_SHARED=OFF \
    -DENABLE_APPS=OFF \
    -DENABLE_CXX11=ON \
    -DUSE_STATIC_LIBSTDCXX=ON \
    -DOPENSSL_USE_STATIC_LIBS=ON \
    -DENABLE_LOGGING=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_INCLUDEDIR=include \
    -DCMAKE_INSTALL_BINDIR=bin \
    .. && \
  make -j$(nproc) && make install

# bump: libssh /LIBSSH_VERSION=([\d.]+)/ https://gitlab.com/libssh/libssh-mirror.git|*
# bump: libssh after ./hashupdate Dockerfile LIBSSH $LATEST
# bump: libssh link "Source diff $CURRENT..$LATEST" https://gitlab.com/libssh/libssh-mirror/-/compare/libssh-$CURRENT...libssh-$LATEST
# bump: libssh link "Release notes" https://gitlab.com/libssh/libssh-mirror/-/tags/libssh-$LATEST
ARG LIBSSH_VERSION=0.10.6
ARG LIBSSH_URL="https://gitlab.com/libssh/libssh-mirror/-/archive/libssh-$LIBSSH_VERSION/libssh-mirror-libssh-$LIBSSH_VERSION.tar.gz"
ARG LIBSSH_SHA256=3a29ee78cbe0305459fc8a337b3b0dc3335b7724299dc69ab2657607746a1d82
# LIBSSH_STATIC=1 is REQUIRED to link statically against libssh.a so add to pkg-config file
# make does not -j as it seems to be shaky, libssh.a used before created
RUN wget $WGET_OPTS -O libssh.tar.gz "$LIBSSH_URL"
RUN echo "$LIBSSH_SHA256  libssh.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libssh.tar.gz && cd libssh* && mkdir build && cd build && \
  echo -e 'Requires.private: libssl libcrypto zlib \nLibs.private: -DLIBSSH_STATIC=1 -lssh\nCflags.private: -DLIBSSH_STATIC=1 -I${CMAKE_INSTALL_FULL_INCLUDEDIR}' >> ../libssh.pc.cmake && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_SYSTEM_ARCH=$(arch) \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DPICKY_DEVELOPER=ON \
    -DBUILD_STATIC_LIB=ON \
    -DBUILD_SHARED_LIBS=OFF \
    -DWITH_GSSAPI=OFF \
    -DWITH_BLOWFISH_CIPHER=ON \
    -DWITH_SFTP=ON \
    -DWITH_SERVER=OFF \
    -DWITH_ZLIB=ON \
    -DWITH_PCAP=ON \
    -DWITH_DEBUG_CRYPTO=OFF \
    -DWITH_DEBUG_PACKET=OFF \
    -DWITH_DEBUG_CALLTRACE=OFF \
    -DUNIT_TESTING=OFF \
    -DCLIENT_TESTING=OFF \
    -DSERVER_TESTING=OFF \
    -DWITH_EXAMPLES=OFF \
    -DWITH_INTERNAL_DOC=OFF \
    .. && \
  make install

# bump: svtav1 /SVTAV1_VERSION=([\d.]+)/ https://gitlab.com/AOMediaCodec/SVT-AV1.git|*
# bump: svtav1 after ./hashupdate Dockerfile SVTAV1 $LATEST
# bump: svtav1 link "Release notes" https://gitlab.com/AOMediaCodec/SVT-AV1/-/releases/v$LATEST
ARG SVTAV1_VERSION=1.8.0
ARG SVTAV1_URL="https://gitlab.com/AOMediaCodec/SVT-AV1/-/archive/v$SVTAV1_VERSION/SVT-AV1-v$SVTAV1_VERSION.tar.bz2"
ARG SVTAV1_SHA256=41c7183be99a2c72656b15fba4005e46c998cd346418503ed296c5abe6482e47
RUN wget $WGET_OPTS -O svtav1.tar.bz2 "$SVTAV1_URL"
RUN echo "$SVTAV1_SHA256  svtav1.tar.bz2" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS svtav1.tar.bz2 && \
  cd SVT-AV1-*/Build && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DBUILD_SHARED_LIBS=OFF \
    -DCMAKE_BUILD_TYPE=Release \
    .. && \
  make -j$(nproc) install

# has to be before theora
# bump: ogg /OGG_VERSION=([\d.]+)/ https://github.com/xiph/ogg.git|*
# bump: ogg after ./hashupdate Dockerfile OGG $LATEST
# bump: ogg link "CHANGES" https://github.com/xiph/ogg/blob/master/CHANGES
# bump: ogg link "Source diff $CURRENT..$LATEST" https://github.com/xiph/ogg/compare/v$CURRENT..v$LATEST
ARG OGG_VERSION=1.3.5
ARG OGG_URL="https://downloads.xiph.org/releases/ogg/libogg-$OGG_VERSION.tar.gz"
ARG OGG_SHA256=0eb4b4b9420a0f51db142ba3f9c64b333f826532dc0f48c6410ae51f4799b664
RUN wget $WGET_OPTS -O libogg.tar.gz "$OGG_URL"
RUN echo "$OGG_SHA256  libogg.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libogg.tar.gz && \
  cd libogg-* && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: theora /THEORA_VERSION=([\d.]+)/ https://github.com/xiph/theora.git|*
# bump: theora after ./hashupdate Dockerfile THEORA $LATEST
# bump: theora link "Release notes" https://github.com/xiph/theora/releases/tag/v$LATEST
# bump: theora link "Source diff $CURRENT..$LATEST" https://github.com/xiph/theora/compare/v$CURRENT..v$LATEST
ARG THEORA_VERSION=1.1.1
ARG THEORA_URL="https://downloads.xiph.org/releases/theora/libtheora-$THEORA_VERSION.tar.bz2"
ARG THEORA_SHA256=b6ae1ee2fa3d42ac489287d3ec34c5885730b1296f0801ae577a35193d3affbc
RUN wget $WGET_OPTS -O libtheora.tar.bz2 "$THEORA_URL"
RUN echo "$THEORA_SHA256  libtheora.tar.bz2" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libtheora.tar.bz2 && \
  # --build=$(arch)-unknown-linux-gnu helps with guessing the correct build. For some reason,
  # build script can't guess the build type in arm64 (hardware and emulated) environment.
  cd libtheora-* && ./configure --build=$(arch)-unknown-linux-gnu --disable-examples --disable-oggtest --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: twolame /TWOLAME_VERSION=([\d.]+)/ https://github.com/njh/twolame.git|*
# bump: twolame after ./hashupdate Dockerfile TWOLAME $LATEST
# bump: twolame link "Source diff $CURRENT..$LATEST" https://github.com/njh/twolame/compare/v$CURRENT..v$LATEST
ARG TWOLAME_VERSION=0.4.0
ARG TWOLAME_URL="https://github.com/njh/twolame/releases/download/$TWOLAME_VERSION/twolame-$TWOLAME_VERSION.tar.gz"
ARG TWOLAME_SHA256=cc35424f6019a88c6f52570b63e1baf50f62963a3eac52a03a800bb070d7c87d
RUN wget $WGET_OPTS -O twolame.tar.gz "$TWOLAME_URL"
RUN echo "$TWOLAME_SHA256  twolame.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS twolame.tar.gz && \
  cd twolame-* && ./configure --disable-shared --enable-static --disable-sndfile --with-pic && \
  make -j$(nproc) install

# bump: uavs3d /UAVS3D_COMMIT=([[:xdigit:]]+)/ gitrefs:https://github.com/uavs3/uavs3d.git|re:#^refs/heads/master$#|@commit
# bump: uavs3d after ./hashupdate Dockerfile UAVS3D $LATEST
# bump: uavs3d link "Source diff $CURRENT..$LATEST" https://github.com/uavs3/uavs3d/compare/$CURRENT..$LATEST
ARG UAVS3D_URL="https://github.com/uavs3/uavs3d.git"
ARG UAVS3D_COMMIT=1fd04917cff50fac72ae23e45f82ca6fd9130bd8
# Removes BIT_DEPTH 10 to be able to build on other platforms. 10 was overkill anyways.
RUN \
  git clone "$UAVS3D_URL" && \
  cd uavs3d && git checkout $UAVS3D_COMMIT && \
  mkdir build/linux && cd build/linux && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    ../.. && \
  make -j$(nproc) install

# bump: vid.stab /VIDSTAB_VERSION=([\d.]+)/ https://github.com/georgmartius/vid.stab.git|*
# bump: vid.stab after ./hashupdate Dockerfile VIDSTAB $LATEST
# bump: vid.stab link "Changelog" https://github.com/georgmartius/vid.stab/blob/master/Changelog
ARG VIDSTAB_VERSION=1.1.1
ARG VIDSTAB_URL="https://github.com/georgmartius/vid.stab/archive/v$VIDSTAB_VERSION.tar.gz"
ARG VIDSTAB_SHA256=9001b6df73933555e56deac19a0f225aae152abbc0e97dc70034814a1943f3d4
RUN wget $WGET_OPTS -O vid.stab.tar.gz "$VIDSTAB_URL"
RUN echo "$VIDSTAB_SHA256  vid.stab.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS vid.stab.tar.gz && \
  cd vid.stab-* && mkdir build && cd build && \
  # This line workarounds the issue that happens when the image builds in emulated (buildx) arm64 environment.
  # Since in emulated container the /proc is mounted from the host, the cmake not able to detect CPU features correctly.
  sed -i 's/include (FindSSE)/if(CMAKE_SYSTEM_ARCH MATCHES "amd64")\ninclude (FindSSE)\nendif()/' ../CMakeLists.txt && \
  cmake \
    -G"Unix Makefiles" \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_SYSTEM_ARCH=$(arch) \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DUSE_OMP=ON \
    .. && \
  make -j$(nproc) install
RUN echo "Libs.private: -ldl" >> /usr/local/lib/pkgconfig/vidstab.pc

# bump: vorbis /VORBIS_VERSION=([\d.]+)/ https://github.com/xiph/vorbis.git|*
# bump: vorbis after ./hashupdate Dockerfile VORBIS $LATEST
# bump: vorbis link "CHANGES" https://github.com/xiph/vorbis/blob/master/CHANGES
# bump: vorbis link "Source diff $CURRENT..$LATEST" https://github.com/xiph/vorbis/compare/v$CURRENT..v$LATEST
ARG VORBIS_VERSION=1.3.7
ARG VORBIS_URL="https://downloads.xiph.org/releases/vorbis/libvorbis-$VORBIS_VERSION.tar.gz"
ARG VORBIS_SHA256=0e982409a9c3fc82ee06e08205b1355e5c6aa4c36bca58146ef399621b0ce5ab
RUN wget $WGET_OPTS -O libvorbis.tar.gz "$VORBIS_URL"
RUN echo "$VORBIS_SHA256  libvorbis.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libvorbis.tar.gz && \
  cd libvorbis-* && ./configure --disable-shared --enable-static --disable-oggtest && \
  make -j$(nproc) install

# bump: libvpx /VPX_VERSION=([\d.]+)/ https://github.com/webmproject/libvpx.git|*
# bump: libvpx after ./hashupdate Dockerfile VPX $LATEST
# bump: libvpx link "CHANGELOG" https://github.com/webmproject/libvpx/blob/master/CHANGELOG
# bump: libvpx link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libvpx/compare/v$CURRENT..v$LATEST
ARG VPX_VERSION=1.14.0
ARG VPX_URL="https://github.com/webmproject/libvpx/archive/v$VPX_VERSION.tar.gz"
ARG VPX_SHA256=5f21d2db27071c8a46f1725928a10227ae45c5cd1cad3727e4aafbe476e321fa
RUN wget $WGET_OPTS -O libvpx.tar.gz "$VPX_URL"
RUN echo "$VPX_SHA256  libvpx.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libvpx.tar.gz && \
  cd libvpx-* && ./configure --enable-static --enable-vp9-highbitdepth --disable-shared --disable-unit-tests --disable-examples && \
  make -j$(nproc) install

# bump: libwebp /LIBWEBP_VERSION=([\d.]+)/ https://github.com/webmproject/libwebp.git|*
# bump: libwebp after ./hashupdate Dockerfile LIBWEBP $LATEST
# bump: libwebp link "Release notes" https://github.com/webmproject/libwebp/releases/tag/v$LATEST
# bump: libwebp link "Source diff $CURRENT..$LATEST" https://github.com/webmproject/libwebp/compare/v$CURRENT..v$LATEST
ARG LIBWEBP_VERSION=1.3.2
ARG LIBWEBP_URL="https://github.com/webmproject/libwebp/archive/v$LIBWEBP_VERSION.tar.gz"
ARG LIBWEBP_SHA256=c2c2f521fa468e3c5949ab698c2da410f5dce1c5e99f5ad9e70e0e8446b86505
RUN wget $WGET_OPTS -O libwebp.tar.gz "$LIBWEBP_URL"
RUN echo "$LIBWEBP_SHA256  libwebp.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libwebp.tar.gz && \
  cd libwebp-* && ./autogen.sh && ./configure --disable-shared --enable-static --with-pic --enable-libwebpmux --disable-libwebpextras --disable-libwebpdemux --disable-sdl --disable-gl --disable-png --disable-jpeg --disable-tiff --disable-gif && \
  make -j$(nproc) install

# x264 only have a stable branch no tags and we checkout commit so no hash is needed
# bump: x264 /X264_VERSION=([[:xdigit:]]+)/ gitrefs:https://code.videolan.org/videolan/x264.git|re:#^refs/heads/stable$#|@commit
# bump: x264 after ./hashupdate Dockerfile X264 $LATEST
# bump: x264 link "Source diff $CURRENT..$LATEST" https://code.videolan.org/videolan/x264/-/compare/$CURRENT...$LATEST
ARG X264_URL="https://code.videolan.org/videolan/x264.git"
ARG X264_VERSION=31e19f92f00c7003fa115047ce50978bc98c3a0d
RUN \
  git clone "$X264_URL" && \
  cd x264 && \
  git checkout $X264_VERSION && \
  ./configure --enable-pic --enable-static --disable-cli --disable-lavf --disable-swscale && \
  make -j$(nproc) install

# x265 release is over 1 years old and master branch has a lot of fixes and improvements, so we checkout commit so no hash is needed
# bump: x265 /X265_VERSION=([[:xdigit:]]+)/ gitrefs:https://bitbucket.org/multicoreware/x265_git.git|re:#^refs/heads/master$#|@commit
# bump: x265 after ./hashupdate Dockerfile X265 $LATEST
# bump: x265 link "Source diff $CURRENT..$LATEST" https://bitbucket.org/multicoreware/x265_git/branches/compare/$LATEST..$CURRENT#diff
ARG X265_VERSION=74abf80c70a3969fca2e112691cecfb50c0c2259
ARG X265_SHA256=872a29c240bdd1eb9df429538913e2166840b48b0eff88099148c40a6479b380
ARG X265_URL="https://bitbucket.org/multicoreware/x265_git/get/$X265_VERSION.tar.bz2"
# CMAKEFLAGS issue
# https://bitbucket.org/multicoreware/x265_git/issues/620/support-passing-cmake-flags-to-multilibsh
RUN wget $WGET_OPTS -O x265_git.tar.bz2 "$X265_URL"
RUN echo "$X265_SHA256  x265_git.tar.bz2" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS x265_git.tar.bz2 && \
  cd multicoreware-x265_git-*/build/linux && \
  sed -i '/^cmake / s/$/ -G "Unix Makefiles" ${CMAKEFLAGS}/' ./multilib.sh && \
  sed -i 's/ -DENABLE_SHARED=OFF//g' ./multilib.sh && \
  MAKEFLAGS="-j$(nproc)" \
  CMAKEFLAGS="-DENABLE_SHARED=OFF -DCMAKE_VERBOSE_MAKEFILE=ON -DENABLE_AGGRESSIVE_CHECKS=ON -DENABLE_NASM=ON -DCMAKE_BUILD_TYPE=Release" \
  ./multilib.sh && \
  make -C 8bit -j$(nproc) install

# bump: xavs2 /XAVS2_VERSION=([\d.]+)/ https://github.com/pkuvcl/xavs2.git|^1
# bump: xavs2 after ./hashupdate Dockerfile XAVS2 $LATEST
# bump: xavs2 link "Release" https://github.com/pkuvcl/xavs2/releases/tag/$LATEST
# bump: xavs2 link "Source diff $CURRENT..$LATEST" https://github.com/pkuvcl/xavs2/compare/v$CURRENT..v$LATEST
ARG XAVS2_VERSION=1.4
ARG XAVS2_URL="https://github.com/pkuvcl/xavs2/archive/refs/tags/$XAVS2_VERSION.tar.gz"
ARG XAVS2_SHA256=1e6d731cd64cb2a8940a0a3fd24f9c2ac3bb39357d802432a47bc20bad52c6ce
# TODO: seems to be issues with asm on musl
RUN wget $WGET_OPTS -O xavs2.tar.gz "$XAVS2_URL"
RUN echo "$XAVS2_SHA256  xavs2.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS xavs2.tar.gz && \
  cd xavs2-*/build/linux && ./configure --disable-asm --enable-pic --disable-cli && \
  make -j$(nproc) install

# http://websvn.xvid.org/cvs/viewvc.cgi/trunk/xvidcore/build/generic/configure.in?revision=2146&view=markup
# bump: xvid /XVID_VERSION=([\d.]+)/ svn:http://anonymous:@svn.xvid.org|/^release-(.*)$/|/_/./|^1
# bump: xvid after ./hashupdate Dockerfile XVID $LATEST
# add extra CFLAGS that are not enabled by -O3
ARG XVID_VERSION=1.3.7
ARG XVID_URL="https://downloads.xvid.com/downloads/xvidcore-$XVID_VERSION.tar.gz"
ARG XVID_SHA256=abbdcbd39555691dd1c9b4d08f0a031376a3b211652c0d8b3b8aa9be1303ce2d
RUN wget $WGET_OPTS -O libxvid.tar.gz "$XVID_URL"
RUN echo "$XVID_SHA256  libxvid.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libxvid.tar.gz && \
  cd xvidcore/build/generic && \
  CFLAGS="$CFLAGS -fstrength-reduce -ffast-math" ./configure && \
  make -j$(nproc) && make install

# bump: zimg /ZIMG_VERSION=([\d.]+)/ https://github.com/sekrit-twc/zimg.git|*
# bump: zimg after ./hashupdate Dockerfile ZIMG $LATEST
# bump: zimg link "ChangeLog" https://github.com/sekrit-twc/zimg/blob/master/ChangeLog
ARG ZIMG_VERSION=3.0.5
ARG ZIMG_URL="https://github.com/sekrit-twc/zimg/archive/release-$ZIMG_VERSION.tar.gz"
ARG ZIMG_SHA256=a9a0226bf85e0d83c41a8ebe4e3e690e1348682f6a2a7838f1b8cbff1b799bcf
RUN wget $WGET_OPTS -O zimg.tar.gz "$ZIMG_URL"
RUN echo "$ZIMG_SHA256  zimg.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS zimg.tar.gz && \
  cd zimg-* && ./autogen.sh && ./configure --disable-shared --enable-static && \
  make -j$(nproc) install

# bump: libjxl /LIBJXL_VERSION=([\d.]+)/ https://github.com/libjxl/libjxl.git|^0
# bump: libjxl after ./hashupdate Dockerfile LIBJXL $LATEST
# bump: libjxl link "Changelog" https://github.com/libjxl/libjxl/blob/main/CHANGELOG.md
# use bundled highway library as its static build is not available in alpine
ARG LIBJXL_VERSION=0.10.2
ARG LIBJXL_URL="https://github.com/libjxl/libjxl/archive/refs/tags/v${LIBJXL_VERSION}.tar.gz"
ARG LIBJXL_SHA256=95e807f63143856dc4d161c071cca01115d2c6405b3d3209854ac6989dc6bb91
RUN wget $WGET_OPTS -O libjxl.tar.gz "$LIBJXL_URL"
RUN echo "$LIBJXL_SHA256  libjxl.tar.gz" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS libjxl.tar.gz && \
  cd libjxl-* && \
  ./deps.sh && \
  cmake -B build \
    -G"Unix Makefiles" \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_VERBOSE_MAKEFILE=ON \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_INSTALL_PREFIX=/usr/local \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTING=OFF \
    -DJPEGXL_ENABLE_PLUGINS=OFF \
    -DJPEGXL_ENABLE_BENCHMARK=OFF \
    -DJPEGXL_ENABLE_COVERAGE=OFF \
    -DJPEGXL_ENABLE_EXAMPLES=OFF \
    -DJPEGXL_ENABLE_FUZZERS=OFF \
    -DJPEGXL_ENABLE_SJPEG=OFF \
    -DJPEGXL_ENABLE_SKCMS=OFF \
    -DJPEGXL_ENABLE_VIEWERS=OFF \
    -DJPEGXL_FORCE_SYSTEM_GTEST=ON \
    -DJPEGXL_FORCE_SYSTEM_BROTLI=ON \
    -DJPEGXL_FORCE_SYSTEM_HWY=OFF && \
  cmake --build build -j$(nproc) && \
  cmake --install build
# workaround for ffmpeg configure script
RUN sed -i 's/-ljxl/-ljxl -lstdc++ /' /usr/local/lib/pkgconfig/libjxl.pc
RUN sed -i 's/-ljxl_cms/-ljxl_cms -lstdc++ /' /usr/local/lib/pkgconfig/libjxl_cms.pc
RUN sed -i 's/-ljxl_threads/-ljxl_threads -lstdc++ /' /usr/local/lib/pkgconfig/libjxl_threads.pc

# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|^6
# bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=6.1.1
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=5e3133939a61ef64ac9b47ffd29a5ea6e337a4023ef0ad972094b4da844e3a20
ARG ENABLE_FDKAAC=
# sed changes --toolchain=hardened -pie to -static-pie
# extra ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
# more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
# large things on the stack.
RUN wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL"
RUN echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum --status -c -
RUN \
  tar $TAR_OPTS ffmpeg.tar.bz2 && \
  FDKAAC_FLAGS=$(if [[ -n "$ENABLE_FDKAAC" ]] ;then echo " --enable-libfdk-aac --enable-nonfree " ;else echo ""; fi) && \
  cd ffmpeg-* && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-cflags="-fopenmp" \
  --extra-ldflags="-fopenmp -Wl,-z,stack-size=2097152" \
  --toolchain=hardened \
  --disable-debug \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-version3 \
  $FDKAAC_FLAGS \
  --enable-fontconfig \
  --enable-gray \
  --enable-iconv \
  --enable-lcms2 \
  --enable-libaom \
  --enable-libaribb24 \
  --enable-libass \
  --enable-libbluray \
  --enable-libdav1d \
  --enable-libdavs2 \
  --enable-libfreetype \
  --enable-libfribidi \
  --enable-libgme \
  --enable-libgsm \
  --enable-libkvazaar \
  --enable-libmodplug \
  --enable-libmp3lame \
  --enable-libmysofa \
  --enable-libopencore-amrnb \
  --enable-libopencore-amrwb \
  --enable-libopenjpeg \
  --enable-libopus \
  --enable-librabbitmq \
  --enable-librav1e \
  --enable-librtmp \
  --enable-librubberband \
  --enable-libshine \
  --enable-libsnappy \
  --enable-libsoxr \
  --enable-libspeex \
  --enable-libsrt \
  --enable-libssh \
  --enable-libsvtav1 \
  --enable-libtheora \
  --enable-libtwolame \
  --enable-libuavs3d \
  --enable-libvidstab \
  --enable-libvmaf \
  --enable-libvo-amrwbenc \
  --enable-libvorbis \
  --enable-libvpx \
  --enable-libwebp \
  --enable-libx264 \
  --enable-libx265 \
  --enable-libxavs2 \
  --enable-libxml2 \
  --enable-libxvid \
  --enable-libzimg \
  --enable-openssl \
  --enable-libjxl \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

RUN \
  EXPAT_VERSION=$(pkg-config --modversion expat) \
  FFTW_VERSION=$(pkg-config --modversion fftw3) \
  FONTCONFIG_VERSION=$(pkg-config --modversion fontconfig)  \
  FREETYPE_VERSION=$(pkg-config --modversion freetype2)  \
  FRIBIDI_VERSION=$(pkg-config --modversion fribidi)  \
  LIBSAMPLERATE_VERSION=$(pkg-config --modversion samplerate) \
  LIBXML2_VERSION=$(pkg-config --modversion libxml-2.0) \
  OPENSSL_VERSION=$(pkg-config --modversion openssl) \
  SOXR_VERSION=$(pkg-config --modversion soxr) \
  LIBVO_AMRWBENC_VERSION=$(pkg-config --modversion vo-amrwbenc) \
  SNAPPY_VERSION=$(apk info -a snappy | head -n1 | awk '{print $1}' | sed -e 's/snappy-//') \
  jq -n \
  '{ \
  expat: env.EXPAT_VERSION, \
  "libfdk-aac": env.FDK_AAC_VERSION, \
  ffmpeg: env.FFMPEG_VERSION, \
  fftw: env.FFTW_VERSION, \
  fontconfig: env.FONTCONFIG_VERSION, \
  lcms2: env.LCMS2_VERSION, \
  libaom: env.AOM_VERSION, \
  libaribb24: env.LIBARIBB24_VERSION, \
  libass: env.LIBASS_VERSION, \
  libbluray: env.LIBBLURAY_VERSION, \
  libdav1d: env.DAV1D_VERSION, \
  libdavs2: env.DAVS2_VERSION, \
  libfreetype: env.FREETYPE_VERSION, \
  libfribidi: env.FRIBIDI_VERSION, \
  libgme: env.LIBGME_COMMIT, \
  libgsm: env.LIBGSM_COMMIT, \
  libkvazaar: env.KVAZAAR_VERSION, \
  libmodplug: env.LIBMODPLUG_VERSION, \
  libmp3lame: env.MP3LAME_VERSION, \
  libmysofa: env.LIBMYSOFA_VERSION, \
  libogg: env.OGG_VERSION, \
  libopencoreamr: env.OPENCOREAMR_VERSION, \
  libopenjpeg: env.OPENJPEG_VERSION, \
  libopus: env.OPUS_VERSION, \
  librabbitmq: env.LIBRABBITMQ_VERSION, \
  librav1e: env.RAV1E_VERSION, \
  librtmp: env.LIBRTMP_COMMIT, \
  librubberband: env.RUBBERBAND_VERSION, \
  libsamplerate: env.LIBSAMPLERATE_VERSION, \
  libshine: env.LIBSHINE_VERSION, \
  libsoxr: env.SOXR_VERSION, \
  libsnappy: env.SNAPPY_VERSION, \
  libspeex: env.SPEEX_VERSION, \
  libsrt: env.SRT_VERSION, \
  libssh: env.LIBSSH_VERSION, \
  libsvtav1: env.SVTAV1_VERSION, \
  libtheora: env.THEORA_VERSION, \
  libtwolame: env.TWOLAME_VERSION, \
  libuavs3d: env.UAVS3D_COMMIT, \
  libvidstab: env.VIDSTAB_VERSION, \
  libvmaf: env.VMAF_VERSION, \
  libvo_amrwbenc: env.LIBVO_AMRWBENC_VERSION, \
  libvorbis: env.VORBIS_VERSION, \
  libvpx: env.VPX_VERSION, \
  libwebp: env.LIBWEBP_VERSION, \
  libx264: env.X264_VERSION, \
  libx265: env.X265_VERSION, \
  libxavs2: env.XAVS2_VERSION, \
  libxml2: env.LIBXML2_VERSION, \
  libxvid: env.XVID_VERSION, \
  libzimg: env.ZIMG_VERSION, \
  libjxl: env.LIBJXL_VERSION, \
  openssl: env.OPENSSL_VERSION, \
  }' > /versions.json

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN \
  /checkelf /usr/local/bin/ffmpeg && \
  /checkelf /usr/local/bin/ffprobe

FROM scratch AS final1
COPY --from=builder /versions.json /usr/local/bin/ffmpeg /usr/local/bin/ffprobe /
COPY --from=builder /usr/local/share/doc/ffmpeg/* /doc/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem

# sanity tests
RUN ["/ffmpeg", "-version"]
RUN ["/ffprobe", "-version"]
RUN ["/ffmpeg", "-hide_banner", "-buildconf"]
# stack size
RUN ["/ffmpeg", "-f", "lavfi", "-i", "testsrc", "-c:v", "libsvtav1", "-t", "100ms", "-f", "null", "-"]
# dns
RUN ["/ffprobe", "-i", "https://github.com/favicon.ico"]
# tls/https certs
RUN ["/ffprobe", "-tls_verify", "1", "-ca_file", "/etc/ssl/cert.pem", "-i", "https://github.com/favicon.ico"]

# clamp all files into one layer
FROM scratch AS final2
COPY --from=final1 / /

FROM final2
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
ENTRYPOINT ["/ffmpeg"]
