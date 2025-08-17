FROM docker.io/ubuntu:rolling
LABEL org.opencontainers.image.title="Swift main snapshot on ubuntu:latest"
LABEL org.opencontainers.image.description="Base image for esp-swift. Includes the latest swift main snapshot + ubuntu latest"
LABEL org.opencontainers.image.source=https://github.com/TheNightmanCodeth/esp-swift
LABEL org.opencontainers.image.licenses=Apache-2.0

# The number of submodules fetched at the same time
## NOTE: If you're using container on macOS instead of docker or you have < 8G
## memory, you should lower this to something closer to 2.
ARG GIT_CLONE_JOBS=24

# Install ESP-IDF dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends \
  binutils cmake curl git gnupg2 libc6-dev libcurl4-openssl-dev \
  libncurses5-dev libedit2 libgcc-13-dev libpython3-dev libsqlite3-0 \
  libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev wget \
  flex bison gperf python3 python3-pip python3-venv ninja-build ccache \
  libffi-dev libssl-dev build-essential python3-dev dfu-util libusb-1.0-0 \
  && rm -rf /var/lib/apt/lists/*

# Install swift
ARG SWIFT_SIGNING_KEY=E813C892820A6FA13755B268F167DF1ACF9CE069

ARG SWIFT_PLATFORM=ubuntu
ARG OS_MAJOR_VER=24
ARG OS_MIN_VER=04
ARG SWIFT_WEBROOT=https://download.swift.org/development

ENV SWIFT_SIGNING_KEY=$SWIFT_SIGNING_KEY \
  SWIFT_PLATFORM=$SWIFT_PLATFORM \
  OS_MAJOR_VER=$OS_MAJOR_VER \
  OS_MIN_VER=$OS_MIN_VER

RUN echo "${SWIFT_WEBROOT}/latest-build.yml"

RUN set -e; \
  # - Set arch suffix based on $TARGETARCH (should be set by BuildKit)
  export TARGETARCH=$(uname -m) \
  && export OS_ARCH_SUFFIX=$([ "$TARGETARCH" = "aarch64" ] && echo "-aarch64" || echo "") \
  && export OS_VER=$SWIFT_PLATFORM$OS_MAJOR_VER.$OS_MIN_VER$OS_ARCH_SUFFIX \
  && export PLATFORM_WEBROOT="$SWIFT_WEBROOT/$SWIFT_PLATFORM$OS_MAJOR_VER$OS_MIN_VER$OS_ARCH_SUFFIX" \
  && export SWIFT_WEBROOT=$PLATFORM_WEBROOT \
  && echo $SWIFT_WEBROOT && sleep 4s \
  # - Get the latest build info from swift.org
  && export $(curl -s ${SWIFT_WEBROOT}/latest-build.yml | grep 'download:' | sed 's/:[^:\/\/]/=/g')  \
  && export $(curl -s ${SWIFT_WEBROOT}/latest-build.yml | grep 'download_signature:' | sed 's/:[^:\/\/]/=/g')  \
  && export DOWNLOAD_DIR=$(echo $download | sed "s/-${OS_VER}.tar.gz//g") \
  && echo $DOWNLOAD_DIR > .swift_tag \
  # - Download the Swift toolchain
  && curl -fsSL ${SWIFT_WEBROOT}/${DOWNLOAD_DIR}/${download} -o latest_toolchain.tar.gz \
  # - Unpack the toolchain, set libs permissions, and clean up.
  && tar -xzf latest_toolchain.tar.gz --directory / --strip-components=1 \
  && chmod -R o+r /usr/lib/swift \
  && rm -rf latest_toolchain.tar.gz \
  && apt-get purge --auto-remove -y curl
