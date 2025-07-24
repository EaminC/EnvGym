FROM ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set workspace directory inside the container
WORKDIR /workspace

# Install OS packages: curl, git, build-essential, ca-certificates, pkg-config, libssl-dev, and optional tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        build-essential \
        ca-certificates \
        pkg-config \
        libssl-dev \
        sudo \
        vim \
        less \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Set locale to UTF-8
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Install Rust (rustup, cargo, rustc >=1.63.0)
ENV RUSTUP_HOME=/usr/local/rustup \
    CARGO_HOME=/usr/local/cargo \
    PATH=/usr/local/cargo/bin:$PATH

RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain 1.63.0

# Ensure rustup, cargo, rustc are available for all users
RUN chmod -R a+w ${RUSTUP_HOME} ${CARGO_HOME}

# Optionally install wasm-pack (uncomment if needed)
# RUN /usr/local/cargo/bin/cargo install wasm-pack

# Optionally install rust-analyzer for IDE/editor integration (uncomment if needed)
# RUN /usr/local/cargo/bin/cargo install rust-analyzer

# Set up recommended environment variables for Rust
ENV PATH="/usr/local/cargo/bin:${PATH}"

# Expose a volume for the host project directory
VOLUME ["/home/cc/EnvGym/data/rayon-rs_rayon"]

# Default workdir inside the container matches user project root
WORKDIR /workspace

# Copy entrypoint script if needed (not required by plan, so omitted)

# Set recommended default command (override in docker run if needed)
CMD ["/bin/bash"]

# Usage notes (not executed): 
# - Mount your project directory to /workspace, e.g.:
#   docker run --rm -it -v /home/cc/EnvGym/data/rayon-rs_rayon:/workspace <image>
# - All build/test commands should be run from within /workspace.