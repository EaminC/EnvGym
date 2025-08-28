FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUST_MIN_STACK=16777216
ENV RUSTUP_HOME=/usr/local/rustup
ENV CARGO_HOME=/usr/local/cargo
ENV PATH=/usr/local/cargo/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    build-essential \
    gcc-multilib \
    jq \
    bash \
    pkg-config \
    libssl-dev \
    python3 \
    python3-distutils \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.80.0

RUN rustup default 1.80.0 && rustup update 1.80.0 \
    && rustup component add rustfmt clippy

RUN cargo --version && rustc --version && git --version && jq --version && curl --version

WORKDIR /rayon

CMD ["/bin/bash"]