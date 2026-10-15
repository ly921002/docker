FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# x86_64 运行库（amd64 多架构）：让 box64 能运行【动态链接】的 x86_64 程序（如 SteamCMD）。
# 关键坑：arm64 默认源 ports.ubuntu.com 【不提供 binary-amd64 索引】（会 404）。
#         加 amd64 架构后，必须为 amd64 单独配 archive.ubuntu.com 源，否则 apt 找不到 :amd64 包。
#         这里重写为带 arch 限定的多架构源（arm64->ports，amd64->archive），并清掉默认源避免 404。
RUN dpkg --add-architecture amd64 \
    && rm -f /etc/apt/sources.list /etc/apt/sources.list.d/*.list /etc/apt/sources.list.d/*.sources \
    && printf '%s\n' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy main restricted universe multiverse' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-updates main restricted universe multiverse' \
        'deb [arch=arm64] http://ports.ubuntu.com/ubuntu-ports jammy-security main restricted universe multiverse' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy main restricted universe multiverse' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-updates main restricted universe multiverse' \
        'deb [arch=amd64] http://archive.ubuntu.com/ubuntu jammy-security main restricted universe multiverse' \
        > /etc/apt/sources.list.d/multiarch.list \
    && apt update && apt install -y \
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
    libc6:amd64 \
    libstdc++6:amd64 \
    libgcc-s1:amd64 \
    libcurl4:amd64 \
    libssl3:amd64 \
    zlib1g:amd64 \
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
