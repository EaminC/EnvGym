FROM golang:1.21-alpine3.18 AS builder

# Set build-time environment variables
ENV CGO_ENABLED=0 \
    GO111MODULE=on \
    GOPROXY=https://proxy.golang.org,direct

WORKDIR /home/cc/EnvGym/data/zeromicro_go-zero

# Install required build dependencies
RUN apk add --no-cache \
    git \
    make \
    curl \
    tzdata \
    ca-certificates \
    protobuf \
    gcc \
    libc-dev

# Diagnostic: Output Go version and environment
RUN go version && go env

# Install goctl and protoc plugins separately for easier error diagnosis
ENV PATH="/go/bin:${PATH}"
RUN go install github.com/zeromicro/go-zero/tools/goctl@latest
RUN go env
RUN GO111MODULE=on go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
RUN GO111MODULE=on go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0

# Copy go.mod and go.sum first for dependency caching
COPY go.mod go.sum ./
RUN go mod download

# Copy the entire project (excluding files in .dockerignore)
COPY . .

# Ensure all Go dependencies are present and tidy the module
RUN go mod tidy

# Build the main application binaries as needed (example: gateway, mcp)
RUN go build -o bin/gateway ./gateway
RUN go build -o bin/mcp ./mcp

# --- Runtime Image ---
FROM alpine:3.18

SHELL ["/bin/sh", "-c"]

# Install runtime dependencies (bash, tzdata, ca-certificates, curl) in a single layer
RUN apk add --no-cache \
    bash \
    tzdata \
    ca-certificates \
    curl

ENV TZ=Asia/Shanghai \
    LANG=C.UTF-8 \
    PATH=/usr/local/bin:/usr/bin:/bin

WORKDIR /home/cc/EnvGym/data/zeromicro_go-zero

# Copy timezone data
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo

# Copy goctl binary for code generation/testing if needed in container (optional)
COPY --from=builder /go/bin/goctl /usr/local/bin/goctl

# Copy built binaries
COPY --from=builder /home/cc/EnvGym/data/zeromicro_go-zero/bin/gateway ./bin/gateway
COPY --from=builder /home/cc/EnvGym/data/zeromicro_go-zero/bin/mcp ./bin/mcp

# Copy configuration, static files, etc.
COPY --from=builder /home/cc/EnvGym/data/zeromicro_go-zero ./

# Expose typical go-zero ports (adjust as needed)
# EXPOSE 8888 8889 8890 9090

# Default entrypoint (adjust as needed; for multi-service images, override in docker-compose/k8s)
# ENTRYPOINT ["./bin/gateway"]
# CMD ["-f", "etc/gateway.yaml"]