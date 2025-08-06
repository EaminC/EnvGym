FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# 1. Install basic build tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      wget \
      curl \
      gnupg2 \
      lsb-release \
      ca-certificates

# 2. Install GCC (11) and Clang (13)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      build-essential \
      gcc-11 g++-11 \
      clang-13 lldb-13 lld-13 \
      libstdc++-11-dev libstdc++-11-doc

# 3. Set GCC-11 and G++-11 as default alternatives
RUN update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100

# 4. Set Clang-13 as default clang/clang++
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-13 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-13 100

# 5. Install latest CMake (from Kitware repo, 3.25+)
RUN apt-get remove -y cmake && \
    wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | apt-key add - && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' && \
    apt-get update && \
    apt-get install -y --no-install-recommends cmake

# 6. Install Meson and Ninja
RUN apt-get install -y --no-install-recommends \
      python3 python3-pip python3-setuptools python3-wheel \
      meson \
      ninja-build

# 7. Upgrade pip, install Meson (ensure >=0.54.1), Conan (>=1.53,<2.0), and codecov (optional)
RUN pip3 install --upgrade pip && \
    pip3 install "meson>=0.54.1" "conan>=1.53.0,<2.0" codecov

# 8. Install Git, lcov (gcov), llvm (for llvm-cov), and other useful tools
RUN apt-get install -y --no-install-recommends \
      git \
      lcov \
      llvm \
      llvm-13 \
      clang-tools-13 \
      pkg-config \
      doxygen \
      zip unzip \
      jq

# 9. Install Bazelisk (recommended Bazel launcher) and Buildifier
ENV BAZELISK_VERSION=v1.19.0
ENV BUILDIFIER_VERSION=6.4.0
RUN wget -O /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/${BAZELISK_VERSION}/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazelisk && \
    ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel && \
    wget -O /usr/local/bin/buildifier https://github.com/bazelbuild/buildtools/releases/download/v${BUILDIFIER_VERSION}/buildifier-linux-amd64 && \
    chmod +x /usr/local/bin/buildifier

# 10. Install Bazel >=6.0.0 using Bazelisk
# (Bazelisk will auto-download the version declared in .bazelversion, MODULE.bazel, or ENV)
# No additional step needed; bazelisk will do it at 'bazel' invocation.

# 11. Set up working directory and copy project
WORKDIR /home/cc/EnvGym/data/catchorg_Catch2
COPY . .

# 12. Set environment variables for PATH and locale (for Python, Meson, Bazel, etc.)
ENV PATH="/home/cc/.local/bin:${PATH}"
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# 13. Show versions for debug and reproducibility
RUN gcc --version && \
    g++ --version && \
    clang --version && \
    cmake --version && \
    meson --version && \
    ninja --version && \
    git --version && \
    python3 --version && \
    pip3 --version && \
    conan --version && \
    lcov --version && \
    llvm-cov --version && \
    bazel --version && \
    buildifier --version

# 14. Default shell
SHELL ["/bin/bash", "-c"]

# 15. Optionally set up a non-root user (uncomment if desired)
# RUN useradd -ms /bin/bash cc && chown -R cc:cc /home/cc
# USER cc

# 16. Default command (interactive shell)
CMD ["/bin/bash"]