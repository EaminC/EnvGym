FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        apt-transport-https \
        ca-certificates \
        lsb-release \
        gnupg \
        dirmngr && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update --allow-releaseinfo-change && \
    add-apt-repository -y ppa:ubuntu-toolchain-r/test && \
    apt-get update

RUN apt-get install -y --no-install-recommends \
        g++-13 \
        build-essential \
        -o Debug::pkgProblemResolver=yes && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Split apt-get install for easier debugging and to isolate potential problematic packages

# Core build tools and Python
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        cmake \
        meson \
        ninja-build \
        make \
        git \
        curl \
        wget \
        pkg-config \
        python3 \
        python3-pip \
        python3-wheel \
        clang-format && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Remaining libraries/utilities (excluding problematic packages for Ubuntu 22.04)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libssl-dev \
        openssl \
        zlib1g-dev \
        libbrotli-dev \
        libzstd-dev \
        libcurl4-openssl-dev \
        netcat-openbsd \
        libgtest-dev \
        squid \
        tzdata && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Install setuptools via pip (since python3-setuptools package name may cause issues)
RUN python3 -m pip install --no-cache-dir --upgrade setuptools

# Set GCC/G++ 13 as default
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-13 120 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-13 120

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Install/Upgrade meson (if newer needed) and pre-commit via pip
RUN python3 -m pip install --no-cache-dir --upgrade meson pre-commit

WORKDIR /home/cc/EnvGym/data/yhirose_cpp-httplib

ENV PATH="/usr/local/bin:${PATH}"
RUN ln -sf /usr/bin/python3 /usr/bin/python

RUN g++ --version && \
    cmake --version && \
    meson --version && \
    ninja --version && \
    clang-format --version && \
    python3 --version && \
    openssl version && \
    pre-commit --version

CMD ["/bin/bash"]