FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH \
    RUST_BACKTRACE=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    ca-certificates \
    bash \
    hunspell \
    hunspell-en-us \
    pkg-config \
    libssl-dev \
    libgit2-dev \
    cmake \
    llvm-dev \
    libclang-dev \
    clang \
    libssh-dev \
    libcurl4-openssl-dev \
    libssl3 \
    libsqlite3-dev \
    libz-dev \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain 1.70

ENV PATH=/usr/local/cargo/bin:$PATH

RUN rustup update && rustup install nightly-2025-01-25 --profile minimal && \
    rustup target add i686-unknown-freebsd x86_64-unknown-freebsd

# Temporarily disable RUSTFLAGS to avoid build failures during cargo install
ENV RUSTFLAGS=""

# Upgrade cargo to latest stable to avoid potential installation issues
RUN rustup component add cargo

# Retry cargo-deny installation with increased verbosity and retries
RUN set -eux; \
    for i in 1 2 3; do \
      /usr/local/cargo/bin/cargo install cargo-deny --verbose --jobs 1 && break || sleep 5; \
    done

# Install spellcheck with RUSTFLAGS disabled to avoid build failures
RUN /usr/local/cargo/bin/cargo install --locked spellcheck --verbose --jobs 1

# Restore RUSTFLAGS with warnings denied for build
ENV RUSTFLAGS="-D warnings"
ENV RUSTDOCFLAGS="-D warnings"

WORKDIR /workspace

COPY . /workspace

RUN mkdir -p /workspace/.cargo
RUN echo '[build]\nrustflags = ["-D", "warnings"]' > /workspace/.cargo/config.toml

ENV CROSS_BUILD_ENV_PASS="RUSTFLAGS,RUST_BACKTRACE"

CMD ["/bin/bash"]