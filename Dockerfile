# bump: alpine /ALPINE_VERSION=alpine:([\d.]+)/ docker:alpine|^3
# bump: alpine link "Release notes" https://alpinelinux.org/posts/Alpine-$LATEST-released.html
ARG ALPINE_VERSION=alpine:3.20.3
FROM $ALPINE_VERSION AS builder

# Alpine Package Keeper options
ARG APK_OPTS=""

RUN apk add --no-cache $APK_OPTS \
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

# bump: vvenc /VVENC_VERSION=([\d.]+)/ https://github.com/fraunhoferhhi/vvenc.git|*
# bump: vvenc after ./hashupdate Dockerfile VVENC $LATEST
# bump: vvenc link "CHANGELOG" https://github.com/fraunhoferhhi/vvenc/releases/tag/v$LATEST

RUN cat /proc/meminfo

ARG VVENC_VERSION=1.12.0
ARG VVENC_URL="https://github.com/fraunhoferhhi/vvenc/archive/refs/tags/v$VVENC_VERSION.tar.gz"
ARG VVENC_SHA256=e7311ffcc87d8fcc4b839807061cca1b89be017ae7c449a69436dc2dd07615c2
RUN \
  wget $WGET_OPTS -O vvenc.tar.gz "$VVENC_URL" && \
  echo "$VVENC_SHA256  vvenc.tar.gz" | sha256sum --status -c - && \
  tar $TAR_OPTS vvenc.tar.gz && cd vvenc-* && \
  # TODO: https://github.com/fraunhoferhhi/vvenc/pull/422
  sed -i 's/-Werror;//' source/Lib/vvenc/CMakeLists.txt && \
  cmake \
    -S . \
    -B build/release-static \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/usr/local && \
  time cmake --build build/release-static -j && \
  cmake --build build/release-static --target install

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
  FDKAAC_FLAGS=$(if [[ -n "$ENABLE_FDKAAC" ]] ;then echo " --enable-libfdk-aac --enable-nonfree " ;else echo ""; fi) && \
  sed -i 's/add_ldexeflags -fPIE -pie/add_ldexeflags -fPIE -static-pie/' configure && \
  ./configure \
  --pkg-config-flags="--static" \
  --extra-cflags="-fopenmp" \
  --extra-ldflags="-fopenmp -Wl,--allow-multiple-definition -Wl,-z,stack-size=2097152" \
  --toolchain=hardened \
  --disable-debug \
  --disable-shared \
  --disable-ffplay \
  --enable-static \
  --enable-gpl \
  --enable-version3 \
  --enable-libvvenc \
  || (cat ffbuild/config.log ; false) \
  && make -j$(nproc) install

RUN \
  EXPAT_VERSION=$(pkg-config --modversion expat) \
  FFTW_VERSION=$(pkg-config --modversion fftw3) \
  FONTCONFIG_VERSION=$(pkg-config --modversion fontconfig)  \
  FREETYPE_VERSION=$(pkg-config --modversion freetype2)  \
  FRIBIDI_VERSION=$(pkg-config --modversion fribidi)  \
  LIBSAMPLERATE_VERSION=$(pkg-config --modversion samplerate) \
  LIBVO_AMRWBENC_VERSION=$(pkg-config --modversion vo-amrwbenc) \
  LIBXML2_VERSION=$(pkg-config --modversion libxml-2.0) \
  OPENSSL_VERSION=$(pkg-config --modversion openssl) \
  SNAPPY_VERSION=$(apk info -a snappy $APK_OPTS | head -n1 | awk '{print $1}' | sed -e 's/snappy-//') \
  SOXR_VERSION=$(pkg-config --modversion soxr) \
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
  libharfbuzz: env.LIBHARFBUZZ_VERSION, \
  libjxl: env.LIBJXL_VERSION, \
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
  librsvg: env.LIBRSVG_VERSION, \
  librtmp: env.LIBRTMP_COMMIT, \
  librubberband: env.RUBBERBAND_VERSION, \
  libsamplerate: env.LIBSAMPLERATE_VERSION, \
  libshine: env.LIBSHINE_VERSION, \
  libsnappy: env.SNAPPY_VERSION, \
  libsoxr: env.SOXR_VERSION, \
  libspeex: env.SPEEX_VERSION, \
  libsrt: env.SRT_VERSION, \
  libssh: env.LIBSSH_VERSION, \
  libsvtav1: env.SVTAV1_VERSION, \
  libtheora: env.THEORA_VERSION, \
  libtwolame: env.TWOLAME_VERSION, \
  libuavs3d: env.UAVS3D_COMMIT, \
  libva: env.LIBVA_VERSION, \
  libvidstab: env.VIDSTAB_VERSION, \
  libvmaf: env.VMAF_VERSION, \
  libvo_amrwbenc: env.LIBVO_AMRWBENC_VERSION, \
  libvorbis: env.VORBIS_VERSION, \
  libvpl: env.LIBVPL_VERSION, \
  libvpx: env.VPX_VERSION, \
  libvvenc: env.VVENC_VERSION, \
  libwebp: env.LIBWEBP_VERSION, \
  libx264: env.X264_VERSION, \
  libx265: env.X265_VERSION, \
  libxavs2: env.XAVS2_VERSION, \
  libxevd: env.XEVD_VERSION, \
  libxeve: env.XEVE_VERSION, \
  libxml2: env.LIBXML2_VERSION, \
  libxvid: env.XVID_VERSION, \
  libzimg: env.ZIMG_VERSION, \
  libzmq: env.LIBZMQ_VERSION, \
  openssl: env.OPENSSL_VERSION, \
  }' > /versions.json

# make sure binaries has no dependencies, is relro, pie and stack nx
COPY checkelf /
RUN \
  /checkelf /usr/local/bin/ffmpeg && \
  /checkelf /usr/local/bin/ffprobe
# workaround for using -Wl,--allow-multiple-definition
# see comment in checkdupsym for details
COPY checkdupsym /
RUN /checkdupsym /ffmpeg-*

# some basic fonts that don't take up much space
RUN apk add $APK_OPTS font-terminus font-inconsolata font-dejavu font-awesome

FROM scratch AS final1
COPY --from=builder /usr/local/bin/ffmpeg /
COPY --from=builder /usr/local/bin/ffprobe /
COPY --from=builder /versions.json /
COPY --from=builder /usr/local/share/doc/ffmpeg/* /doc/
COPY --from=builder /etc/ssl/cert.pem /etc/ssl/cert.pem
COPY --from=builder /etc/fonts/ /etc/fonts/
COPY --from=builder /usr/share/fonts/ /usr/share/fonts/
COPY --from=builder /usr/share/consolefonts/ /usr/share/consolefonts/
COPY --from=builder /var/cache/fontconfig/ /var/cache/fontconfig/

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
# svg
RUN ["/ffprobe", "-i", "https://github.githubassets.com/favicons/favicon.svg"]
# vvenc
RUN ["/ffmpeg", "-f", "lavfi", "-i", "testsrc", "-c:v", "libvvenc", "-t", "100ms", "-f", "null", "-"]

# clamp all files into one layer
FROM scratch AS final2
COPY --from=final1 / /

FROM final2
LABEL maintainer="Mattias Wadman mattias.wadman@gmail.com"
ENTRYPOINT ["/ffmpeg"]
