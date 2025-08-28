FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    build-essential \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    bash \
    ripgrep \
    && rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable

RUN rustc_version=$(rustc --version | awk '{print $2}') && \
    required_version="1.74.0" && \
    dpkg --compare-versions "$rustc_version" "ge" "$required_version" || (echo "Rust version is less than 1.74.0" && exit 1)

RUN cargo install cargo-deny

RUN pip3 install --no-cache-dir pre-commit

WORKDIR /usr/src/app

COPY . .

RUN chmod +x .git/hooks/pre-commit || true

RUN cargo build --release

RUN pre-commit install || true

CMD ["/bin/bash"]