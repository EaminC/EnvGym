FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Set working directory to project root (as per plan)
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini

# Install essential packages and dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-11 g++-11 \
    clang-13 \
    cmake \
    python3 python3-pip python3-setuptools python3-venv \
    git \
    curl \
    lcov \
    ninja-build \
    ca-certificates \
    unzip \
    wget \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Use gcc-11 and g++-11 as default gcc/g++
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

# Install Meson and Ninja via pip3 for required versions
RUN pip3 install --no-cache-dir --upgrade pip \
 && pip3 install --no-cache-dir meson>=0.54.1 ninja

# Install Conan >=1.53.0 via pip3
RUN pip3 install --no-cache-dir --upgrade "conan>=1.53.0"

# Install Bazel latest stable for Linux x86_64
# Download Bazel installer script from official source and install
RUN BAZEL_VERSION=6.3.2 \
 && wget https://github.com/bazelbuild/bazel/releases/download/${BAZEL_VERSION}/bazel-${BAZEL_VERSION}-linux-x86_64 \
    -O /usr/local/bin/bazel \
 && chmod +x /usr/local/bin/bazel

# Verify Bazel version (optional)
RUN bazel version

# Create repository directory structure
RUN mkdir -p /home/cc/EnvGym/data-gpt-4.1mini/catchorg_Catch2

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/catchorg_Catch2

# Clone Catch2 repository - default branch devel as per plan
RUN git clone --branch devel https://github.com/catchorg/Catch2.git . 

# Set environment variables for CMake and compilers
ENV CC=/usr/bin/gcc-11 \
    CXX=/usr/bin/g++-11 \
    PATH=/home/cc/.local/bin:$PATH

# Ensure python3 is findable by CMake
RUN ln -sf /usr/bin/python3 /usr/bin/python

# Expose bash shell entrypoint, default to bash prompt
CMD ["/bin/bash"]