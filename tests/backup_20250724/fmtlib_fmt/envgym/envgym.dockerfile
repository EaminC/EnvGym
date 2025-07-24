FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Install basic system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      software-properties-common \
      wget \
      ca-certificates \
      gnupg \
      lsb-release \
      curl \
      build-essential \
      cmake \
      git \
      python3 \
      ninja-build \
      doxygen \
      valgrind \
      bash \
      unzip && \
    rm -rf /var/lib/apt/lists/*

# Install Clang/LLVM 18 and clang-tidy-18 from official LLVM repo
RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh 18 && \
    rm llvm.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
      clang-18 \
      clang-tidy-18 \
      lldb-18 \
      lld-18 && \
    rm -rf /var/lib/apt/lists/*

# Set clang/clang++ and clang-tidy symlinks to version 18 for convenience
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-18 100 && \
    update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++-18 100 && \
    update-alternatives --install /usr/bin/clang-tidy clang-tidy /usr/bin/clang-tidy-18 100

# Install Bazelisk (recommended Bazel version manager)
RUN curl -L https://github.com/bazelbuild/bazelisk/releases/latest/download/bazelisk-linux-amd64 -o /usr/local/bin/bazel && \
    chmod +x /usr/local/bin/bazel

# Set working directory to project root as per environment specification
WORKDIR /home/cc/EnvGym/data/fmtlib_fmt

# Clone fmtlib/fmt into the working directory
RUN git clone --recursive https://github.com/fmtlib/fmt.git . 

# Optionally: clone format-benchmark (commented out; uncomment if benchmarks needed)
# RUN git clone --recursive https://github.com/fmtlib/format-benchmark.git /home/cc/EnvGym/data/format-benchmark

# Ensure all files in support/ are executable and use Linux paths
RUN if [ -d support ]; then find support -type f -name "*.sh" -exec chmod +x {} \;; fi

# Default entrypoint: print help and bash
CMD ["/bin/bash"]