FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /home/cc/EnvGym/data/facebook_zstd

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        python3 \
        python3-pip \
        git \
        ninja-build \
        make \
        g++ \
        libgtest-dev \
        liblz4-tool \
        brotli \
        zlib1g-dev \
        libsnappy-dev \
        liblzo2-dev \
        docker.io \
        docker-compose \
        ca-certificates \
        curl \
        file \
    && rm -rf /var/lib/apt/lists/*

# Optional tools: meson (Python 3), conan (C++ package manager), vcpkg (C++ package manager)
RUN pip3 install --no-cache-dir meson conan

# Optional: vcpkg install (if needed for extended builds)
# RUN git clone https://github.com/Microsoft/vcpkg.git /opt/vcpkg && \
#     /opt/vcpkg/bootstrap-vcpkg.sh

# Copy project files (assume full context is the repo root)
COPY . .

# Build zstd (make, cmake, meson/Ninja builds available)
RUN make

# Optionally, run tests (uncomment if you want tests to run at build time)
# RUN make check

# Default command: print zstd version (ensure build puts binary in PATH or adjust CMD)
CMD ["./zstd", "--version"]
