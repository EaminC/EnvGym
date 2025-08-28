FROM --platform=linux/amd64 golang:1.20

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    ca-certificates \
    git \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/zeromicro_go-zero

COPY go.mod go.sum ./
RUN go mod download

COPY . .

RUN go version && ls -la && go mod verify && go clean -modcache && go mod tidy -v

CMD ["/bin/bash"]