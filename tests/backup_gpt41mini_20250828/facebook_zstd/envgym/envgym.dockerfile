FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Etc/UTC \
    SWIFT_VERSION=5.9.3 \
    SWIFT_PLATFORM=ubuntu-24.04

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-14 g++-14 \
    clang \
    make \
    cmake \
    ninja-build \
    meson \
    git \
    valgrind \
    qemu-user-static \
    qemu-system-arm \
    qemu-system-aarch64 \
    qemu-system-ppc \
    qemu-system-ppc64 \
    python3 \
    python3-pip \
    docker.io \
    bash \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-14 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-14 100 \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends swift && rm -rf /var/lib/apt/lists/*

RUN getent group docker || groupadd -g 999 docker; \
    useradd -m -u 1000 user; \
    usermod -aG docker user

WORKDIR /workspace

ARG REPO_URL=https://github.com/facebook/zstd.git
RUN git clone --recursive ${REPO_URL} . && \
    git submodule update --init --recursive

RUN make -j$(nproc)

RUN gcc --version && clang --version && cmake --version && ninja --version && meson --version && valgrind --version && qemu-arm-static --version && qemu-aarch64-static --version && swift --version && docker --version

ENV ZSTD_BIN=/workspace/zstd
ENV DATAGEN_BIN=/workspace/programs/datagen

CMD ["/bin/bash"]