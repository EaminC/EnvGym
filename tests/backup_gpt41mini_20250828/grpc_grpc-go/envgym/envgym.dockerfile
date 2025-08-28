# syntax=docker/dockerfile:1.4
FROM ubuntu:22.04 AS base

ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    git \
    bash \
    openssl \
    iproute2 \
    iputils-ping \
    net-tools \
    iputils-tracepath \
    locales \
    dnsutils \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

ENV GO_VERSION=1.21.0
ENV GO_BASE_URL=https://golang.org/dl

RUN set -eux; \
    arch=amd64; \
    curl -fsSL ${GO_BASE_URL}/go${GO_VERSION}.linux-${arch}.tar.gz -o /tmp/go.tar.gz; \
    tar -C /usr/local -xzf /tmp/go.tar.gz; \
    rm /tmp/go.tar.gz

ENV GOROOT=/usr/local/go
ENV GOPATH=/go
ENV PATH=/usr/local/go/bin:$GOPATH/bin:$PATH
ENV GO111MODULE=on

RUN go version
RUN go env

RUN useradd -m -u 1000 appuser
WORKDIR /src
COPY --chown=appuser:appuser . /src

USER appuser

RUN test -f go.mod && test -f go.sum

RUN nslookup proxy.golang.org || echo "Warning: nslookup proxy.golang.org failed"
RUN curl -v https://proxy.golang.org || echo "Warning: curl to proxy.golang.org failed"
RUN curl -v https://golang.org || echo "Warning: curl to golang.org failed"

RUN ping -c 3 proxy.golang.org || echo "Warning: Cannot reach proxy.golang.org"
RUN ping -c 3 golang.org || echo "Warning: Cannot reach golang.org"

# Attempt to download modules with direct proxy fallback and verbose logging
RUN set -eux; \
    for i in 1 2 3 4 5; do \
      GOPROXY=https://proxy.golang.org,direct go mod download -x && break || (echo "go mod download failed, attempt $$i"; go env; curl -v https://proxy.golang.org || true; sleep 5); \
    done || (echo "Retrying with GOPROXY=direct"; GOPROXY=direct go mod download -x)

RUN go mod verify
RUN go mod tidy -v || (echo "go mod tidy failed, printing go.mod and go.sum contents:"; cat go.mod; cat go.sum; false)

RUN test -f .gitignore || echo -e "vendor/\n*.exe\n*.exe~\n*.dll\n*.so\n*.dylib\n*.test\n*.out\n/bin/\n/build/\n.env\n" > .gitignore

ENV GRPC_GO_LOG_SEVERITY_LEVEL=info
ENV GRPC_GO_LOG_VERBOSITY_LEVEL=99
ENV GRPC_GO_LOG_TRACE=api

WORKDIR /
ENTRYPOINT ["/bin/bash"]
CMD []