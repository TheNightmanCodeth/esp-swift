FROM thenightmancodeth/esp-swift:swift-latest

# Make Python stfu
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

RUN echo '. ~/esp/esp-idf/export.sh > /dev/null' >> ~/.bashrc
