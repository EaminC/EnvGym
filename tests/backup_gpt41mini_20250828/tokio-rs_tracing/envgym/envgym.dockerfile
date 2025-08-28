FROM rust:latest

# Set working directory to the project root
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/tokio-rs_tracing

# Install git and necessary tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends git procps curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install inferno tool for flamegraph visualization
RUN cargo install inferno

# Copy the entire project into the container
COPY . .

# Set environment variable for logging
ENV RUST_LOG=info

# Build the project with parallel jobs using all available CPUs
RUN cargo build --release

# Provide a non-root user to avoid permission issues with cgroupns and apparmor
ARG USER=rustuser
ARG UID=1000
ARG GID=1000

RUN groupadd -g ${GID} ${USER} && \
    useradd -m -u ${UID} -g ${GID} -s /bin/bash ${USER} && \
    chown -R ${USER}:${USER} /home/cc/EnvGym/data-gpt-4.1mini/tokio-rs_tracing

USER ${USER}
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/tokio-rs_tracing

# Default command to start bash shell in the project root
CMD ["/bin/bash"]