FROM rust:latest

# Install essential system packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      build-essential \
      ca-certificates \
      curl \
      pkg-config \
      libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Set the working directory to match the host project directory
WORKDIR /home/cc/EnvGym/data/serde-rs_serde

# Copy only Cargo.toml files and source trees first for caching dependencies
COPY Cargo.toml ./
# COPY Cargo.lock ./   # Removed due to missing file in context
# Copy workspace member manifests if any (adjust as necessary)
COPY serde_derive/Cargo.toml serde_derive/Cargo.toml
COPY serde_derive_internals/Cargo.toml serde_derive_internals/Cargo.toml
COPY test_suite/Cargo.toml test_suite/Cargo.toml
# Add sub-member manifests if present (add more as needed)

# Copy source code
COPY . .

# Install optional Rust components
RUN rustup component add clippy rustfmt

# Build the entire workspace in release mode to verify dependencies
RUN cargo build --workspace --release

# Default command: open an interactive shell
CMD ["/bin/bash"]