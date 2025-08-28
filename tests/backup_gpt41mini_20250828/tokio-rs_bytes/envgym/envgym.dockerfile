FROM ubuntu:22.04

ARG DEBIAN_FRONTEND=noninteractive

ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    WORKDIR=/home/cc/tokio-rs_bytes

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    git \
    build-essential \
    ca-certificates \
    pkg-config \
    libssl-dev \
    llvm \
    clang \
    cmake \
    iproute2 \
    dnsutils \
    net-tools \
    && rm -rf /var/lib/apt/lists/*

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable

RUN rustup install nightly

RUN rustc --version && cargo --version && rustc +nightly --version

RUN useradd -m cc
WORKDIR $WORKDIR
RUN chown -R cc:cc /home/cc

USER cc

SHELL ["/bin/bash", "-c"]

WORKDIR $WORKDIR

COPY --chown=cc:cc Cargo.toml Cargo.toml
COPY --chown=cc:cc src src
COPY --chown=cc:cc benches benches
COPY --chown=cc:cc ci ci
COPY --chown=cc:cc tests tests
COPY --chown=cc:cc clippy.toml clippy.toml
COPY --chown=cc:cc CHANGELOG.md CHANGELOG.md
COPY --chown=cc:cc LICENSE LICENSE
COPY --chown=cc:cc README.md README.md
COPY --chown=cc:cc SECURITY.md SECURITY.md

RUN echo 'msrv = "1.57"' > clippy.toml

RUN mkdir -p .cargo && echo -e '[build]\nrustflags = ["--cfg", "docsrs"]' > .cargo/config.toml

RUN cargo clean

RUN echo "Network interfaces:" && ip addr show
RUN echo "DNS configuration:" && cat /etc/resolv.conf
RUN echo "Testing connectivity to crates.io:" && curl -v https://crates.io || true

RUN set -eux; cargo generate-lockfile

RUN echo "===== Cargo.toml =====" && head -40 Cargo.toml
RUN if [ -f Cargo.lock ]; then echo "===== Cargo.lock =====" && head -40 Cargo.lock; fi
RUN cargo metadata --no-deps

RUN set -eux; cargo update

RUN set -eux; \
    cargo fetch --verbose || (echo "cargo fetch failed, showing target/cargo-fetch.log:" && cat target/cargo-fetch.log || true; false)

RUN cargo check --verbose 2>&1 | tee target/cargo-check.log

RUN cargo build --verbose 2>&1 | tee target/cargo-build.log

RUN cargo test --verbose 2>&1 | tee target/cargo-test.log

RUN cargo clippy -- -D warnings

CMD ["bash"]