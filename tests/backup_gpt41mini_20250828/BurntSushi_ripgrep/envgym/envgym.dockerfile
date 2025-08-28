FROM debian:bullseye-slim

ENV RUST_VERSION=1.88.0
ENV DEBIAN_FRONTEND=noninteractive
ENV USER=rguser
ENV HOME=/home/${USER}
ENV CARGO_HOME=${HOME}/.cargo
ENV RUSTUP_HOME=${HOME}/.rustup
ENV PATH=${CARGO_HOME}/bin:${PATH}

# Install required packages: curl, gcc, pkg-config, libpcre2-dev, musl-tools, git, bash, ca-certificates, build-essential
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        gcc \
        pkg-config \
        libpcre2-dev \
        musl-tools \
        git \
        bash \
        ca-certificates \
        build-essential \
        libssl-dev \
        && rm -rf /var/lib/apt/lists/*

# Create a non-root user to run builds and use the environment
RUN useradd -m -s /bin/bash ${USER}

USER ${USER}
WORKDIR /home/${USER}

# Install rustup and Rust toolchain version 1.88.0 or newer
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain ${RUST_VERSION}

ENV PATH=${CARGO_HOME}/bin:${PATH}

# Add MUSL target for static builds
RUN rustup target add x86_64-unknown-linux-musl

# Clone ripgrep repository
RUN git clone https://github.com/BurntSushi/ripgrep.git

WORKDIR /home/${USER}/ripgrep

# Build ripgrep with default features (no PCRE2)
RUN cargo build --release

# Verify installed version for confirmation (optional)
RUN ./target/release/rg --version

# Set shell
CMD ["/bin/bash"]