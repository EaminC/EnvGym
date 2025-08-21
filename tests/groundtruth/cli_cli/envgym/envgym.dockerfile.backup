FROM mcr.microsoft.com/devcontainers/go:1.24

# Set platform explicitly for clarity (informational)
LABEL org.opencontainers.image.platform="linux/amd64"

# Set working directory
WORKDIR /home/cc/EnvGym/data/cli_cli

# Install required apt packages and clean up
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    git \
    curl \
    wget \
    jq \
    make \
    tar \
    gzip \
    zip \
    dpkg \
    rpm \
    lsb-release \
    ca-certificates \
    apt-transport-https \
    software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install GitHub CLI (gh) from official package repository
RUN type gh >/dev/null 2>&1 || ( \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | \
        dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=amd64 signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | \
        tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y gh && \
    rm -rf /var/lib/apt/lists/* \
)

# Install latest stable cosign (Linux x86_64)
RUN COSIGN_VERSION=$(curl -s https://api.github.com/repos/sigstore/cosign/releases/latest | jq -r .tag_name | sed 's/^v//') && \
    curl -L -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/latest/download/cosign-linux-amd64 && \
    chmod +x /usr/local/bin/cosign

# Install latest stable Goreleaser (Linux x86_64)
RUN GORELEASER_VERSION=$(curl -s https://api.github.com/repos/goreleaser/goreleaser/releases/latest | jq -r .tag_name | sed 's/^v//') && \
    curl -L -o /usr/local/bin/goreleaser https://github.com/goreleaser/goreleaser/releases/download/v${GORELEASER_VERSION}/goreleaser_Linux_x86_64 && \
    chmod +x /usr/local/bin/goreleaser

# Install latest stable golangci-lint (Linux x86_64)
RUN GOLANGCI_LINT_VERSION=$(curl -s https://api.github.com/repos/golangci/golangci-lint/releases/latest | jq -r .tag_name) && \
    curl -L https://github.com/golangci/golangci-lint/releases/download/${GOLANGCI_LINT_VERSION}/golangci-lint-${GOLANGCI_LINT_VERSION#v}-linux-amd64.tar.gz | \
    tar zx -C /tmp && \
    mv /tmp/golangci-lint-*/golangci-lint /usr/local/bin/golangci-lint && \
    chmod +x /usr/local/bin/golangci-lint && \
    rm -rf /tmp/golangci-lint-*

# (Optional) Install Node.js (LTS) and npm if needed for docs
# Comment out if not needed
RUN curl -fsSL https://deb.nodesource.com/setup_lts.x | bash - && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Ensure Go 1.24.x is on PATH (from base image) and up-to-date; print version for verification
RUN go version

# Add local user (cc) if running as root is not desired (optional)
# RUN useradd -m -u 1000 cc && chown -R cc:cc /home/cc
# USER cc

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Copy project files (uncomment if building with context)
# COPY . /home/cc/EnvGym/data/cli_cli

# Entrypoint for interactive development
CMD ["/bin/bash"]