FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV USER=cc
ENV HOME=/home/cc

# 1. Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        ca-certificates \
        bash \
        sed \
        grep \
        netcat \
        locales \
        hunspell \
        hunspell-en-us \
        libhunspell-dev \
        pkg-config \
        sudo \
        libssl-dev \
        libclang-dev \
        clang \
        python3 \
        python3-pip \
    && rm -rf /var/lib/apt/lists/*

# 2. Set locale (to avoid warnings in Rust/Cargo etc)
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 3. Create a non-root user (cc) and set permissions
RUN useradd -ms /bin/bash cc && \
    usermod -aG sudo cc && \
    echo "cc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

WORKDIR /home/cc/EnvGym/data/tokio-rs_tokio
RUN chown -R cc:cc /home/cc

USER cc

# 4. Install rustup, Rust toolchains, and Cargo utilities
ENV PATH="$HOME/.cargo/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable && \
    . "$HOME/.cargo/env" && \
    rustup install stable && \
    rustup install nightly && \
    rustup toolchain install nightly-2025-01-25 && \
    rustc --version

# 5. Install Cargo tools globally (cargo-deny, cross, cargo-spellcheck) in separate steps to diagnose failures
RUN . "$HOME/.cargo/env" && cargo install cargo-deny
RUN . "$HOME/.cargo/env" && cargo install cross
RUN cat /home/cc/.cargo/registry/*/cargo-spellcheck*/*/build.log || true
RUN . "$HOME/.cargo/env" && cargo install cargo-spellcheck --locked --no-default-features --features "hunspell" --verbose || (cat /home/cc/.cargo/registry/*/cargo-spellcheck*/*/build.log || true; exit 1)

# 5b. Copy project files before proceeding
COPY . /home/cc/EnvGym/data/tokio-rs_tokio

# Diagnostic: show cargo version and environment before build
RUN . "$HOME/.cargo/env" && cargo --version && env

# Ensure all dependencies are downloaded
RUN . "$HOME/.cargo/env" && cargo fetch

# Show project manifest to confirm Cargo.toml presence in context
RUN ls -l /home/cc/EnvGym/data/tokio-rs_tokio/Cargo.toml && cat /home/cc/EnvGym/data/tokio-rs_tokio/Cargo.toml

# Remove global cargo install for trybuild; rely on workspace dev-dependency and use cargo test/build to trigger
RUN . "$HOME/.cargo/env" && cargo test --workspace --no-run --verbose || (cat /home/cc/.cargo/registry/*/trybuild*/*/build.log || true; exit 1)

# 6. Set up workspace root as default
WORKDIR /home/cc/EnvGym/data/tokio-rs_tokio

# 7. Entrypoint: use bash by default
ENTRYPOINT ["/bin/bash"]