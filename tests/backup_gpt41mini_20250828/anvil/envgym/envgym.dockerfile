FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    ca-certificates \
    python3 \
    python3-pip \
    pkg-config \
    libssl-dev \
    libclang-dev \
    llvm-dev \
    clang \
    cmake \
    unzip \
    iputils-ping \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir tabulate

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.88.0
RUN rustup default 1.88.0
RUN rustup component add rust-src

RUN update-ca-certificates

WORKDIR /workspace

COPY . /workspace

RUN rustup show
RUN cargo --version

RUN ls -la /workspace
RUN cat /workspace/Cargo.toml

RUN cargo clean

RUN cat /workspace/Cargo.toml

RUN ping -c 3 github.com

RUN env | grep -i proxy || true
RUN env | grep -i http_proxy || true
RUN env | grep -i https_proxy || true
RUN env | grep -i no_proxy || true

RUN curl -v https://crates.io

ENV CARGO_NET_RETRY=5
ENV CARGO_HTTP_MULTIPLEXING=false
ENV CARGO_HTTP_TIMEOUT=120
ENV RUST_LOG=cargo::ops::registry=trace,cargo::core::registry=trace

RUN cargo update -p serde --verbose || true
RUN cargo update --verbose || true

RUN cargo fetch --verbose > /workspace/cargo_fetch.log 2>&1 || (cat /workspace/cargo_fetch.log && false)

RUN cargo check --verbose

RUN cargo build --verbose

CMD ["/bin/bash"]