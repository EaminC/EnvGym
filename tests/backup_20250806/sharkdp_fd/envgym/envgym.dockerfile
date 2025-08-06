FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

ENV CARGO_HOME=/root/.cargo
ENV PATH=$CARGO_HOME/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Install minimal prerequisites first to debug apt-get issues
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        make \
        bash \
        curl \
        ca-certificates \
        pkg-config \
        libssl-dev \
        man-db && \
    rm -rf /var/lib/apt/lists/*

# Install rustup, Rust 1.77.2 or later, and rustfmt
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y && \
    . "$CARGO_HOME/env" && \
    rustup default stable && \
    rustup update && \
    rustup component add rustfmt

RUN . "$CARGO_HOME/env" && \
    cargo install cross

WORKDIR /opt
RUN git clone https://github.com/sharkdp/fd.git
WORKDIR /opt/fd

RUN . "$CARGO_HOME/env" && \
    cargo fetch && \
    cargo fmt -- --check

RUN . "$CARGO_HOME/env" && \
    make -j$(nproc)

# Optionally build with feature flags
# RUN . "$CARGO_HOME/env" && cargo build --no-default-features
# RUN . "$CARGO_HOME/env" && cargo build --features use-jemalloc
# RUN . "$CARGO_HOME/env" && cargo build --features completions

RUN . "$CARGO_HOME/env" && cargo test

RUN . "$CARGO_HOME/env" && make completions

RUN make install

RUN mandb

RUN if [ -x "$(command -v fdfind)" ]; then \
        mkdir -p /root/.local/bin && \
        ln -sf "$(command -v fdfind)" /root/.local/bin/fd ; \
    fi

WORKDIR /workspace
ENV PATH=/root/.local/bin:$PATH

CMD ["/bin/bash"]