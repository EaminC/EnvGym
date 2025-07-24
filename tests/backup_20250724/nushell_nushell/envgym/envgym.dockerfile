# syntax=docker/dockerfile:1.4

FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        libssl-dev \
        pkg-config \
        perl \
        clang \
        dpkg \
        git \
        wget \
        ca-certificates \
        curl \
        software-properties-common \
        bash \
        locales \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV NUSHELL_VERSION=0.92.1
RUN ARCH=x86_64-unknown-linux-gnu && \
    wget -q https://github.com/nushell/nushell/releases/download/${NUSHELL_VERSION}/nu-${NUSHELL_VERSION}-${ARCH}.tar.gz && \
    tar -xzf nu-${NUSHELL_VERSION}-${ARCH}.tar.gz && \
    mv nu-${NUSHELL_VERSION}-${ARCH}/nu /usr/local/bin/ && \
    chmod +x /usr/local/bin/nu && \
    rm -rf nu-${NUSHELL_VERSION}-${ARCH}*

RUN nu --version

ENV CARGO_HOME=/usr/local/cargo
ENV RUSTUP_HOME=/usr/local/rustup
ENV PATH="/usr/local/cargo/bin:${PATH}"

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
RUN [ -f /usr/local/cargo/env ] && echo "Rust env exists" && ls -l /usr/local/cargo/env && echo $PATH
RUN rustup toolchain install 1.86.0 && rustup default 1.86.0

RUN rustc --version && cargo --version

RUN cargo install cross typos-cli

WORKDIR /home/cc/EnvGym/data/nushell_nushell

COPY scripts/ ./scripts/
RUN if [ -d "./scripts" ]; then find ./scripts -type f -name "*.sh" -exec chmod +x {} \;; fi

COPY . .

SHELL ["/bin/bash", "-c"]

# ENTRYPOINT ["/bin/bash"]
# CMD ["nu"]