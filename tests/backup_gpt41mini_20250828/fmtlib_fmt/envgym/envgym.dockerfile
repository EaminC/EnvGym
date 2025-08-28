FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        ca-certificates \
        gnupg \
        lsb-release \
        git \
        curl \
        build-essential \
        g++-11 \
        cmake \
        python3.10 \
        python3-pip \
        ninja-build \
        locales \
        bash \
        procps && \
    # Set GCC alternatives to gcc-11/g++-11
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 && \
    # Install Clang 18 from LLVM repo (clang-tidy v18+)
    wget -O - https://apt.llvm.org/llvm-snapshot.gpg.key | apt-key add - && \
    echo "deb http://apt.llvm.org/jammy/ llvm-toolchain-jammy-18 main" > /etc/apt/sources.list.d/llvm-18.list && \
    apt-get update && \
    apt-get install -y clang-18 clang-tidy-18 && \
    # Install Bazel
    curl -fsSL https://bazel.build/bazel-release.pub.gpg | gpg --dearmor > /usr/share/keyrings/bazel-archive-keyring.gpg && \
    echo "deb [signed-by=/usr/share/keyrings/bazel-archive-keyring.gpg] https://storage.googleapis.com/bazel-apt stable jdk1.8" > /etc/apt/sources.list.d/bazel.list && \
    apt-get update && \
    apt-get install -y bazel && \
    # Clean up apt caches to reduce image size
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN python3 -m pip install --upgrade pip setuptools wheel && \
    pip3 install mkdocs mkdocs-material mkdocstrings pymdown-extensions mike

# Set locale for unicode support
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/fmtlib_fmt

# Clone fmt repository with submodules
RUN git clone --recursive https://github.com/fmtlib/fmt.git . && \
    # Copy support/bazel files to root if exist (optional)
    if [ -d support/bazel ]; then \
      cp support/bazel/BUILD.bazel . 2>/dev/null || true; \
      cp support/bazel/MODULE.bazel . 2>/dev/null || true; \
      cp support/bazel/WORKSPACE.bazel . 2>/dev/null || true; \
      cp support/bazel/.bazelversion . 2>/dev/null || true; \
    fi

# Configure and build fmt library with CMake
RUN mkdir -p build && cd build && \
    cmake .. -DFMT_HEADER_ONLY=ON -G Ninja && \
    ninja -j$(nproc)

# Run tests to verify build success
RUN cd build && ctest --output-on-failure

ENV CC=gcc
ENV CXX=g++

ENV PATH="/root/.local/bin:${PATH}"

CMD ["/bin/bash"]