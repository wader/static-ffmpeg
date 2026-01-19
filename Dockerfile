# bump: alpine /ALPINE_VERSION=alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
ARG ALPINE_VERSION=alpine:3.23.2
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
  fftw-dev fftw-static \
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
ARG GLIB_VERSION=2.84.1
ARG GLIB_URL="https://download.gnome.org/sources/glib/2.84/glib-$GLIB_VERSION.tar.xz"
ARG GLIB_SHA256=2b4bc2ec49611a5fc35f86aca855f2ed0196e69e53092bab6bb73396bf30789a
RUN \
  wget $WGET_OPTS -O glib.tar.xz "$GLIB_URL" && \
  echo "$GLIB_SHA256  glib.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS glib.tar.xz && cd glib-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static \
    -Dlibmount=disabled && \
  ninja -j$(nproc) -vC build install

# bump: harfbuzz /LIBHARFBUZZ_VERSION=([\d.]+)/ https://github.com/harfbuzz/harfbuzz.git|*
# bump: harfbuzz after ./hashupdate Dockerfile LIBHARFBUZZ $LATEST
# bump: harfbuzz link "NEWS" https://github.com/harfbuzz/harfbuzz/blob/main/NEWS
ARG LIBHARFBUZZ_VERSION=12.3.0
ARG LIBHARFBUZZ_URL="https://github.com/harfbuzz/harfbuzz/releases/download/$LIBHARFBUZZ_VERSION/harfbuzz-$LIBHARFBUZZ_VERSION.tar.xz"
ARG LIBHARFBUZZ_SHA256=8660ebd3c27d9407fc8433b5d172bafba5f0317cb0bb4339f28e5370c93d42b7
RUN \
  wget $WGET_OPTS -O harfbuzz.tar.xz "$LIBHARFBUZZ_URL" && \
  echo "$LIBHARFBUZZ_SHA256  harfbuzz.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS harfbuzz.tar.xz && cd harfbuzz-* && \
  meson setup build \
    -Dbuildtype=release \
    -Ddefault_library=static && \
  ninja -j$(nproc) -vC build install

# bump: cairo /CAIRO_VERSION=([\d.]+)/ https://gitlab.freedesktop.org/cairo/cairo.git|^1
# bump: cairo after ./hashupdate Dockerfile CAIRO $LATEST
# bump: cairo link "NEWS" https://gitlab.freedesktop.org/cairo/cairo/-/blob/master/NEWS?ref_type=heads
ARG CAIRO_VERSION=1.18.4
ARG CAIRO_URL="https://cairographics.org/releases/cairo-$CAIRO_VERSION.tar.xz"
ARG CAIRO_SHA256=445ed8208a6e4823de1226a74ca319d3600e83f6369f99b14265006599c32ccb
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
ARG PANGO_VERSION=1.56.4
ARG PANGO_URL="https://download.gnome.org/sources/pango/1.56/pango-$PANGO_VERSION.tar.xz"
ARG PANGO_SHA256=17065e2fcc5f5a5bdbffc884c956bfc7c451a96e8c4fb2f8ad837c6413cb5a01
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
ARG LIBRSVG_VERSION=2.60.0
ARG LIBRSVG_URL="https://download.gnome.org/sources/librsvg/2.60/librsvg-$LIBRSVG_VERSION.tar.xz"
ARG LIBRSVG_SHA256=0b6ffccdf6e70afc9876882f5d2ce9ffcf2c713cbaaf1ad90170daa752e1eec3
RUN \
  wget $WGET_OPTS -O librsvg.tar.xz "$LIBRSVG_URL" && \
  echo "$LIBRSVG_SHA256  librsvg.tar.xz" | sha256sum --status -c - && \
  tar $TAR_OPTS librsvg.tar.xz && cd librsvg-* && \
  # workaround for https://gitlab.gnome.org/GNOME/librsvg/-/issues/1158
  sed -i "/^if host_system in \['windows'/s/, 'linux'//" meson.build && \
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

RUN apk add gdb valgrind

COPY test.c /test.c

RUN gcc -o /test /test.c $(pkg-config --libs --cflags --static librsvg-2.0) -fPIE -static-pie
RUN RUST_BACKTRACE=full gdb -ex="set confirm off" -ex=r -ex="bt full" --args /test


# RUN RUST_BACKTRACE=full gdb -ex="set confirm off" -ex=r -ex="bt full" --args /usr/local/bin/rsvg-convert -o bla.png /favicon.svg

# # bump: ffmpeg /FFMPEG_VERSION=([\d.]+)/ https://github.com/FFmpeg/FFmpeg.git|*
# # bump: ffmpeg after ./hashupdate Dockerfile FFMPEG $LATEST
# # bump: ffmpeg link "Changelog" https://github.com/FFmpeg/FFmpeg/blob/n$LATEST/Changelog
# # bump: ffmpeg link "Source diff $CURRENT..$LATEST" https://github.com/FFmpeg/FFmpeg/compare/n$CURRENT..n$LATEST
# ARG FFMPEG_VERSION=8.0.1
# ARG FFMPEG_URL="https://ffmpeg.org/releases/ffmpeg-$FFMPEG_VERSION.tar.bz2"
# ARG FFMPEG_SHA256=65ff433fab5727fb2dc41f1d508dc60e6192fea44cab2e0301194feee4bcf1d7
# ARG ENABLE_FDKAAC=
# # sed changes --toolchain=hardened -pie to -static-pie
# #
# # ldflags stack-size=2097152 is to increase default stack size from 128KB (musl default) to something
# # more similar to glibc (2MB). This fixing segfault with libaom-av1 and libsvtav1 as they seems to pass
# # large things on the stack.
# #
# # ldfalgs -Wl,--allow-multiple-definition is a workaround for linking with multiple rust staticlib to
# # not cause collision in toolchain symbols, see comment in checkdupsym script for details.
# RUN \
#   wget $WGET_OPTS -O ffmpeg.tar.bz2 "$FFMPEG_URL" && \
#   echo "$FFMPEG_SHA256  ffmpeg.tar.bz2" | sha256sum -c - && \
#   tar $TAR_OPTS ffmpeg.tar.bz2 && cd ffmpeg* && \
#   FDKAAC_FLAGS=$(if [[ -n "$ENABLE_FDKAAC" ]] ;then echo " --enable-libfdk-aac --enable-nonfree " ;else echo ""; fi) && \
#   sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
#   ./configure \
#   --pkg-config-flags="--static" \
#   --extra-cflags="-O0 -ggdb -fopenmp" \
#   --extra-ldflags="-fopenmp -Wl,-z,stack-size=2097152" \
#   --toolchain=hardened \
#   --disable-shared \
#   --disable-ffplay \
#   --enable-static \
#   --enable-gpl \
#   --enable-version3 \
#   --enable-librsvg \
#   || (cat ffbuild/config.log ; false) \
#   && make -j$(nproc) install



# RUN wget 'https://github.githubassets.com/favicons/favicon.svg'
# RUN cd ffmpeg* && RUST_BACKTRACE=full gdb -ex="set confirm off" -ex=r -ex="bt full" --args ./ffprobe_g -i /favicon.svg
# RUN cd ffmpeg* && RUST_BACKTRACE=full valgrind ./ffprobe_g -i /favicon.svg
# RUN cd ffmpeg* && RUST_BACKTRACE=full ./ffprobe_g -i /favicon.svg
