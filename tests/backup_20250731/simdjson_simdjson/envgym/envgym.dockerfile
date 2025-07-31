# syntax=docker/dockerfile:1

FROM --platform=linux/amd64 debian:12

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    clang \
    clang-tidy \
    clang-format \
    lldb \
    lld \
    make \
    cmake \
    ninja-build \
    doxygen \
    git \
    wget \
    curl \
    ca-certificates \
    gnupg \
    zlib1g \
    zlib1g-dev \
    unzip \
    subversion \
    python3 \
    python3-dev \
    python3-pip \
    sudo \
    binutils \
    linux-perf \
    vim \
    zsh \
    valgrind \
    lcov \
    gcovr \
    pkg-config \
    libcurl4-openssl-dev \
    rust-all \
    nodejs \
    npm \
    libxml2-dev \
    libedit-dev \
    libncurses5-dev \
    libncursesw5-dev \
    swig \
    libffi-dev \
    libssl-dev \
    libtool \
    python3-setuptools \
    libsqlite3-dev \
    uuid-dev \
    libzstd-dev \
    libtinfo-dev \
    liblzma-dev \
    libpython3-dev \
    libgmp-dev \
    libexpat1-dev \
    libstdc++-12-dev \
    lib32z1 \
    libbz2-dev \
    libz-dev \
    libreadline-dev \
    gcc-multilib \
    g++-multilib \
    libxml2-utils \
    libyaml-dev \
    libmpfr-dev \
    libmpc-dev \
    libisl-dev \
    libpthread-stubs0-dev \
    ninja-build \
    && rm -rf /var/lib/apt/lists/*

RUN CMAKE_VERSION=3.27.9 \
    && wget -qO- https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.tar.gz | tar --strip-components=1 -xz -C /usr/local

WORKDIR /workspace

RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - \
    && apt-get update && apt-get install -y nodejs \
    && rm -rf /var/lib/apt/lists/*

ARG USER_NAME=cc
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} ${USER_NAME} \
    && useradd -m -u ${USER_ID} -g ${GROUP_ID} -s /bin/bash ${USER_NAME} \
    && echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER ${USER_NAME}

WORKDIR /workspace

SHELL ["/bin/bash", "-c"]

RUN echo "gcc version: $(gcc --version | head -n1)" && \
    echo "clang version: $(clang --version | head -n1)" && \
    echo "cmake version: $(cmake --version | head -n1)" && \
    echo "ninja version: $(ninja --version)" && \
    echo "python3 version: $(python3 --version)" && \
    echo "node version: $(node --version)" && \
    echo "npm version: $(npm --version)" && \
    echo "rustc version: $(rustc --version)"

USER root

WORKDIR /workspace

RUN git clone --depth 1 --branch p2996 https://github.com/bloomberg/clang-p2996.git /tmp/clang-p2996
RUN cd /tmp/clang-p2996 && git submodule update --init --recursive
RUN mkdir /tmp/clang-p2996/build

RUN echo "PATH: $PATH" && env && \
    cmake --version && \
    ninja --version && \
    gcc --version && \
    g++ --version && \
    clang --version && \
    python3 --version && \
    ldd --version

RUN cd /tmp/clang-p2996 && ls -l && ls -l llvm && ls -l clang && ls -l cmake || true

# Diagnostic: Instead of failing the build on CMake failure, output logs and continue
RUN cd /tmp/clang-p2996/build && cmake -G Ninja -DCMAKE_BUILD_TYPE=Release .. || ( \
    echo "=== CMakeError.log ===" && \
    cat /tmp/clang-p2996/build/CMakeFiles/CMakeError.log || true; \
    echo "=== CMakeOutput.log ===" && \
    cat /tmp/clang-p2996/build/CMakeFiles/CMakeOutput.log || true; \
    cp /tmp/clang-p2996/build/CMakeFiles/CMakeError.log /workspace/CMakeError.log 2>/dev/null || true; \
    cp /tmp/clang-p2996/build/CMakeFiles/CMakeOutput.log /workspace/CMakeOutput.log 2>/dev/null || true; \
    ls -l /tmp/clang-p2996/build/CMakeFiles/ || true; \
    exit 0 \
)

RUN if [ -f /tmp/clang-p2996/build/build.ninja ]; then ninja -C /tmp/clang-p2996/build; else echo "Skipping ninja build due to missing build.ninja"; fi
RUN if [ -d /tmp/clang-p2996/build/bin ]; then cp /tmp/clang-p2996/build/bin/clang* /usr/local/bin/ || true; fi
RUN if [ -d /tmp/clang-p2996/build/bin ]; then cp /tmp/clang-p2996/build/bin/llvm* /usr/local/bin/ || true; fi
RUN if [ -d /tmp/clang-p2996/build/bin ]; then cp /tmp/clang-p2996/build/bin/clang++ /usr/local/bin/ || true; fi
RUN rm -rf /tmp/clang-p2996

USER ${USER_NAME}

WORKDIR /workspace

ENTRYPOINT ["/bin/bash"]