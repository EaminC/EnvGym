FROM ubuntu:22.04 AS build

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /yhirose_cpp-httplib

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-11 g++-11 \
    cmake \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libbrotli-dev \
    libzstd-dev \
    python3 python3-pip \
    clang-format-14 \
    ca-certificates \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 \
 && pip3 install --no-cache-dir pre-commit \
 && rm -rf /var/lib/apt/lists/*

COPY . .

RUN set -ex \
 && mkdir -p build \
 && cd build \
 && cmake .. -DCMAKE_BUILD_TYPE=Release -DCMAKE_CXX_STANDARD=23 -DCMAKE_VERBOSE_MAKEFILE=ON \
 && make VERBOSE=1

FROM ubuntu:22.04 AS dev

WORKDIR /yhirose_cpp-httplib

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc-11 g++-11 \
    cmake \
    pkg-config \
    libssl-dev \
    zlib1g-dev \
    libbrotli-dev \
    libzstd-dev \
    python3 python3-pip \
    clang-format-14 \
    ca-certificates \
 && update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-11 100 \
 && update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-11 100 \
 && pip3 install --no-cache-dir pre-commit \
 && rm -rf /var/lib/apt/lists/*

COPY --from=build /yhirose_cpp-httplib /yhirose_cpp-httplib

WORKDIR /yhirose_cpp-httplib

CMD ["/bin/bash"]