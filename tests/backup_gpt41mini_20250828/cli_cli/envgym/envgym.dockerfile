FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV GH_VERSION=2.62.0
ENV GO_VERSION=1.24.4
ENV COSIGN_VERSION=2.1.3
ENV PATH=/go/bin:/usr/local/go/bin:$PATH
ENV GOPATH=/go

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    build-essential \
    gcc \
    make \
    gnupg \
    dirmngr \
    software-properties-common \
    unzip \
    xz-utils \
    apt-transport-https \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.24.4
RUN curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz -o /tmp/go.tar.gz \
    && rm -rf /usr/local/go \
    && tar -C /usr/local -xzf /tmp/go.tar.gz \
    && rm /tmp/go.tar.gz

# Install cosign version 2.1.3 - updated URL with .sha256 checksum and .linux-amd64 suffix
RUN curl -fsSL -o /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v${COSIGN_VERSION}/cosign-linux-amd64 \
    && chmod +x /usr/local/bin/cosign

WORKDIR /

# Copy repository source
COPY . .

# Build and install gh
RUN make install

CMD ["/bin/bash"]