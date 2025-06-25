FROM golang:1.24-bullseye

# Install build utilities
RUN apt-get update && apt-get install -y --no-install-recommends \
    git make bash ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Set build directory
WORKDIR /app

# Copy all project source code
COPY . .

# Build and install the CLI
RUN make install

# Set entrypoint to the built CLI binary
ENTRYPOINT ["/usr/local/bin/gh"]
