FROM debian:bookworm-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:/usr/local/bin:$PATH \
    NUSHELL_WORKDIR=/work \
    SHELL=/bin/bash

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    bash \
    git \
    python3 \
    python3-venv \
    python3-pip \
    build-essential \
    pkg-config \
    libssl-dev \
    llvm \
    clang \
    libclang-dev \
    cmake \
    file \
    && rm -rf /var/lib/apt/lists/*

# Install Rust 1.87.0 stable via rustup
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.87.0 --profile default \
    && rustc --version

# Install cargo-llvm-cov for coverage tooling
RUN cargo install cargo-llvm-cov

WORKDIR $NUSHELL_WORKDIR

# Copy repository contents
COPY . $NUSHELL_WORKDIR

# Verify Cargo.lock presence
RUN test -f Cargo.lock

# Fix line endings and set permissions on install script
RUN sed -i 's/\r$//' ./scripts/install-all.sh \
    && sed -i '1i set -euxo pipefail' ./scripts/install-all.sh \
    && chmod +x ./scripts/install-all.sh

# Build Nushell release binary
RUN cargo build --release

# Debug: List files and environment before install
RUN ls -alh ./scripts && env

# Run install-all.sh dry-run with debugging, allow failure but show logs if present
RUN bash -x ./scripts/install-all.sh --dry-run || (echo "Install dry-run failed, showing install_error.log:" && cat ./install_error.log || echo "No install_error.log found") || true

# Run install script with tracing
RUN bash -x ./scripts/install-all.sh

CMD ["/bin/bash"]