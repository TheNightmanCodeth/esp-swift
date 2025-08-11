# Start from the latest Swift nightly main toolchain
FROM ubuntu:25.10
# The number of submodules fetched at the same time
ARG GIT_CLONE_JOBS=24
# Install ESP-IDF dependencies
RUN apt-get update && apt-get install --yes --no-install-recommends binutils cmake curl git gnupg2 libc6-dev libcurl4-openssl-dev libncurses5-dev libedit2 libgcc-13-dev libpython3-dev libsqlite3-0 libstdc++-13-dev libxml2-dev libz3-dev pkg-config tzdata zlib1g-dev wget flex bison gperf python3 python3-pip python3-venv ninja-build ccache libffi-dev libssl-dev build-essential python3-dev dfu-util libusb-1.0-0 && rm -rf /var/lib/apt/lists/*

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
  # - Download the GPG keys, Swift toolchain, and toolchain signature, and verify.
  && export GNUPGHOME="$(mktemp -d)" \
  && curl -fsSL ${SWIFT_WEBROOT}/${DOWNLOAD_DIR}/${download} -o latest_toolchain.tar.gz \
  ${SWIFT_WEBROOT}/${DOWNLOAD_DIR}/${download_signature} -o latest_toolchain.tar.gz.sig \
  && curl -fSsL https://swift.org/keys/all-keys.asc | gpg --import -  \
  && gpg --batch --verify latest_toolchain.tar.gz.sig latest_toolchain.tar.gz \
  # - Unpack the toolchain, set libs permissions, and clean up.
  && tar -xzf latest_toolchain.tar.gz --directory / --strip-components=1 \
  && chmod -R o+r /usr/lib/swift \
  && rm -rf "$GNUPGHOME" latest_toolchain.tar.gz.sig latest_toolchain.tar.gz \
  && apt-get purge --auto-remove -y curl

# Make Python stfu
# echo "[global]\nbreak-system-packages = true" > ~/.config/pip/pip.conf
RUN python3 -m pip config set global.break-system-packages true

# Download ESP-IDF
RUN mkdir -p ~/esp \
  && cd ~/esp \
  && git clone \
  --branch master \ 
  --depth 1 \
  --shallow-submodules \
  --recursive https://github.com/espressif/esp-idf.git \
  --jobs $GIT_CLONE_JOBS

# Install ESP-IDF
RUN cd ~/esp/esp-idf \
  && ./install.sh esp32c6

# Install ESP-Matter dependencies (TODO: Check for duplicates. Though apt should ignore them iirc)
RUN apt-get update \
  && apt-get install --yes --no-install-recommends \
  git gcc g++ pkg-config libssl-dev libdbus-1-dev \
  libglib2.0-dev libavahi-client-dev ninja-build python3-venv python3-dev \
  python3-pip unzip libgirepository1.0-dev libcairo2-dev libreadline-dev \
  && rm -rf /var/lib/apt/lists/*

# Download ESP-Matter
RUN mkdir -p ~/esp \
  && cd ~/esp \
  && git clone \
  --branch main \ 
  --depth 1 \
  --shallow-submodules \
  --recursive https://github.com/espressif/esp-matter.git \
  --jobs $GIT_CLONE_JOBS

# Download ESP-Matter
RUN mkdir -p ~/esp \
  && cd ~/esp/esp-matter/connectedhomeip/connectedhomeip \
  && ./scripts/checkout_submodules.py --platform esp32 linux --shallow

# Install ESP-Matter
RUN cd ~/esp/esp-matter \
  && ./install.sh

# Setup shell environment
RUN echo '. ~/esp/esp-idf/export.sh > /dev/null' >> ~/.bashrc \
  && echo '. ~/esp/esp-matter/export.sh > /dev/null' >> ~/.bashrc
