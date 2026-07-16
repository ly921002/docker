FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    git \
    cmake \
    build-essential \
    gcc \
    g++ \
    gcc-arm-linux-gnueabihf \
    libc6-dev-armhf-cross \
    libc6-dev \
    binutils \
    pkg-config \
    python3 \
    file \
    binfmt-support \
    qemu-user-static \
    wget \
    curl \
    ca-certificates \
    iproute2 \
    net-tools \
    procps \
    && rm -rf /var/lib/apt/lists/*


WORKDIR /tmp

# 下载box64源码
RUN git clone https://github.com/ptitSeb/box64.git


WORKDIR /tmp/box64

RUN mkdir build && cd build && \
    cmake .. \
    -D ARM_DYNAREC=ON \
    -D CMAKE_BUILD_TYPE=RelWithDebInfo \
    -D BOX32=ON \
    -D BOX32_BINFMT=ON \
    && make -j$(nproc) \
    && make install


# 注册binfmt
RUN update-binfmts --enable box64 || true


# 清理源码
RUN rm -rf /tmp/box64


WORKDIR /root


CMD ["/bin/bash"]
