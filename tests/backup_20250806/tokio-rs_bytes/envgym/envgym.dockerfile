FROM rust:latest

# Set environment variables for non-interactive apt and locale
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Install system dependencies and tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        ca-certificates \
        build-essential \
        curl \
        make \
    && rm -rf /var/lib/apt/lists/*

# Set work directory to the project root (nested directory)
WORKDIR /home/cc/EnvGym/data/tokio-rs_bytes

# Copy only the minimal files needed for dependency fetching and toolchain setup
COPY Cargo.toml clippy.toml ./
COPY src ./src
COPY tests ./tests
COPY README.md LICENSE CHANGELOG.md ./
COPY .gitignore ./

# Install stable Rust toolchain, ensure msrv >= 1.57, and set default target
RUN rustup update stable && \
    rustup default stable && \
    rustup component add clippy rustfmt --toolchain stable-x86_64-unknown-linux-gnu && \
    rustup toolchain install nightly-x86_64-unknown-linux-gnu && \
    rustup target add x86_64-unknown-linux-gnu && \
    rustup component add clippy rustfmt --toolchain nightly-x86_64-unknown-linux-gnu

# Verify Rust, Cargo, and Clippy versions
RUN rustc --version && cargo --version && cargo clippy --version

# Fetch and cache dependencies for faster builds
RUN cargo fetch

# Set the default command to just run bash (customize as needed)
CMD ["/bin/bash"]