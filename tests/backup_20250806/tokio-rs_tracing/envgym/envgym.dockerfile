FROM rust:1.65

WORKDIR /home/cc/EnvGym/data/tokio-rs_tracing

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        pkg-config \
        libssl-dev \
        systemd \
        ca-certificates \
        clang \
        curl \
        build-essential \
        libclang-dev \
        perl \
    && rm -rf /var/lib/apt/lists/*

RUN rustup update && \
    rustup component add clippy rustfmt

RUN cargo install cargo-nextest --locked --verbose || (cat ~/.cargo/registry/index/*/*/config.json || true)
RUN cargo install cargo-hack --locked --verbose || (cat ~/.cargo/registry/index/*/*/config.json || true)
RUN cargo install cargo-audit --locked --verbose || (cat ~/.cargo/registry/index/*/*/config.json || true)
RUN cargo install cargo-minimal-versions --locked --verbose || (cat ~/.cargo/registry/index/*/*/config.json || true)
RUN cargo install inferno --verbose || true

RUN cargo install --list

CMD ["/bin/bash"]