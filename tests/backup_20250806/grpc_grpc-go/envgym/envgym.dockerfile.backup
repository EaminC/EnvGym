FROM --platform=linux/amd64 golang:1.24-bullseye

# Set environment variables for Go
ENV GO111MODULE=on \
    CGO_ENABLED=1 \
    GOARCH=amd64 \
    GOCACHE=/go/cache

# Set the working directory as specified
WORKDIR /home/cc/EnvGym/data/grpc_grpc-go

# Install required system packages (git, make, build-essential, openssl, ca-certificates, libssl-dev, unzip, curl, wget)
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      git \
      make \
      build-essential \
      openssl \
      ca-certificates \
      libssl-dev \
      unzip \
      curl \
      wget && \
    rm -rf /var/lib/apt/lists/*

# Install protoc (Protocol Buffers Compiler) for amd64
ENV PROTOC_VERSION=25.3
RUN wget -q https://github.com/protocolbuffers/protobuf/releases/download/v${PROTOC_VERSION}/protoc-${PROTOC_VERSION}-linux-x86_64.zip -O /tmp/protoc.zip && \
    unzip -d /tmp/protoc /tmp/protoc.zip && \
    mv /tmp/protoc/bin/protoc /usr/local/bin/protoc && \
    chmod +x /usr/local/bin/protoc && \
    cp -r /tmp/protoc/include/* /usr/local/include/ && \
    rm -rf /tmp/protoc*

# Add Go bin to PATH (for go install tools)
ENV PATH=$PATH:/go/bin:/root/go/bin:/home/cc/go/bin

# Install commonly used Go protobuf plugins and tools (for Go 1.17+; will install to /go/bin)
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest && \
    go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest && \
    go install github.com/golang/mock/mockgen@latest && \
    go install github.com/mattn/goveralls@latest && \
    go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest && \
    go install github.com/securego/gosec/v2/cmd/gosec@latest

# Copy the entire repository (excluding files ignored by .dockerignore)
COPY . .

# Download dependencies for the root module
RUN go mod download

# Download dependencies for submodules if their go.mod files exist
RUN if [ -f examples/go.mod ]; then cd examples && go mod download; fi
RUN if [ -f gcp/observability/go.mod ]; then cd gcp/observability && go mod download; fi

# Default command: print Go version and shell
CMD ["/bin/bash"]