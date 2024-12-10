# bump: alpine /ALPINE_VERSION=alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
ARG ALPINE_VERSION=alpine:3.21.0
FROM $ALPINE_VERSION AS builder

# Alpine Package Keeper options
ARG APK_OPTS=""

RUN apk add --no-cache $APK_OPTS \
  coreutils \
  pkgconfig \
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
  tiff tiff-dev \
  libjpeg-turbo libjpeg-turbo-dev \
  libpng-dev libpng-static \
  giflib giflib-dev \
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
  python3 py3-packaging \
  linux-headers \
  curl \
  libdrm-dev

# linux-headers need by rtmpdump
# python3 py3-packaging needed by glib

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


# own build as alpine glib links with libmount etc
# bump: glib /GLIB_VERSION=([\d.]+)/ https://gitlab.gnome.org/GNOME/glib.git|^2
# bump: glib after ./hashupdate Dockerfile GLIB $LATEST
# bump: glib link "NEWS" https://gitlab.gnome.org/GNOME/glib/-/blob/main/NEWS?ref_type=heads
ARG GLIB_VERSION=2.82.2
ARG GLIB_URL="https://download.gnome.org/sources/glib/2.82/glib-$GLIB_VERSION.tar.xz"
ARG GLIB_SHA256=ab45f5a323048b1659ee0fbda5cecd94b099ab3e4b9abf26ae06aeb3e781fd63
RUN \
  wget $WGET_OPTS -O glib.tar.xz "$GLIB_URL" && \
  echo "$GLIB_SHA256  glib.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS glib.tar.xz && cd glib-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static \
    -Dlibmount=disabled && \
  ninja -j$(nproc) -vC build install

# bump: cairo /CAIRO_VERSION=([\d.]+)/ https://gitlab.freedesktop.org/cairo/cairo.git|^1
# bump: cairo after ./hashupdate Dockerfile CAIRO $LATEST
# bump: cairo link "NEWS" https://gitlab.freedesktop.org/cairo/cairo/-/blob/master/NEWS?ref_type=heads
ARG CAIRO_VERSION=1.18.2
ARG CAIRO_URL="https://cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz"
ARG CAIRO_SHA256=a62b9bb42425e844cc3d6ddde043ff39dbabedd1542eba57a2eb79f85889d45a
RUN \
  wget $WGET_OPTS -O cairo.tar.xz "$CAIRO_URL" && \
  echo "$CAIRO_SHA256  cairo.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS cairo.tar.xz && cd cairo-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static \
    -Dtests=disabled \
    -Dquartz=disabled \
    -Dxcb=disabled \
    -Dxlib=disabled \
    -Dxlib-xcb=disabled && \
  ninja -j$(nproc) -vC build install

# TODO: there is weird "1.90" tag, skip it
# bump: pango /PANGO_VERSION=([\d.]+)/ https://github.com/GNOME/pango.git|/\d+\.\d+\.\d+/|*
# bump: pango after ./hashupdate Dockerfile PANGO $LATEST
# bump: pango link "NEWS" https://gitlab.gnome.org/GNOME/pango/-/blob/main/NEWS?ref_type=heads
ARG PANGO_VERSION=1.55.0
ARG PANGO_URL="https://download.gnome.org/sources/pango/1.55/pango-$PANGO_VERSION.tar.xz"
ARG PANGO_SHA256=a2c17a8dc459a7267b8b167bb149d23ff473b6ff9d5972bee047807ee2220ccf
# TODO: add -Dbuild-testsuite=false when in stable release
# TODO: -Ddefault_library=both currently to not fail building tests
RUN \
  wget $WGET_OPTS -O pango.tar.xz "$PANGO_URL" && \
  echo "$PANGO_SHA256  pango.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS pango.tar.xz && cd pango-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=both \
    -Dintrospection=disabled \
    -Dgtk_doc=false && \
  ninja -j$(nproc) -vC build install

# bump: librsvg /LIBRSVG_VERSION=([\d.]+)/ https://gitlab.gnome.org/GNOME/librsvg.git|^2
# bump: librsvg after ./hashupdate Dockerfile LIBRSVG $LATEST
# bump: librsvg link "NEWS" https://gitlab.gnome.org/GNOME/librsvg/-/blob/master/NEWS
ARG LIBRSVG_VERSION=2.59.2
ARG LIBRSVG_URL="https://download.gnome.org/sources/librsvg/2.59/librsvg-$LIBRSVG_VERSION.tar.xz"
ARG LIBRSVG_SHA256=ecd293fb0cc338c170171bbc7bcfbea6725d041c95f31385dc935409933e4597
RUN \
  wget $WGET_OPTS -O librsvg.tar.xz "$LIBRSVG_URL" && \
  echo "$LIBRSVG_SHA256  librsvg.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS librsvg.tar.xz && cd librsvg-* && \
  meson setup build \
    -Dbuildtype=debug \
    -Ddefault_library=static \
    -Ddocs=disabled \
    -Dintrospection=disabled \
    -Dpixbuf=disabled \
    -Dpixbuf-loader=disabled \
    -Dvala=disabled \
    -Dtests=false && \
  ninja -j$(nproc) -vC build install


# bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|*
# bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
ARG FFMPEG_VERSION=7.1
ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
ARG FFMPEG_SHA256=fd59e6160476095082e94150ada5a6032d7dcc282fe38ce682a00c18e7820528
ARG ENABLE_FDKAAC=
# sed changes --toolchain=hardened -pie to -static-pie
#
# ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
# more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
# large things on the stack.
#
# ldfalgs -Wl,--allow-multiple-definition is a workaround for linking with multiple rust staticlib to
# not cause collision in toolchain symbols, see comment in checkdupsym script for details.
RUN \
  wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
  echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum -c - && \
  tar $TAR_OPTS ffmpeg.tar.bz2 && cd ffmpeg* && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-cflags="-fopenmp -O0 -ggdb" \
  --extra-ldflags="-fopenmp -Wl,-z,stack-size=2097152" \
  --toolchain=hardened \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-version3 \
  --enable-librsvg \
  --enable-openssl \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

RUN apk add gdb
RUN cd ffmpeg* && RUST_BACKTRACE=full gdb -ex="set confirm off" -ex=r -ex="bt full" --args ./ffprobe_g -i 'https://github.githubassets.com/favicons/favicon.svg'
RUN cd ffmpeg* && RUST_BACKTRACE=full ./ffprobe_g -i 'https://github.githubassets.com/favicons/favicon.svg'

# svg
# RUN ["/ffprobe", "-i", "https://github.githubassets.com/favicons/favicon.svg"]

