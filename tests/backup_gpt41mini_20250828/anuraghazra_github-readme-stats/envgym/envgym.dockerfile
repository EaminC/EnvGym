# syntax=docker/dockerfile:1.4
FROM --platform=linux/amd64 python:3.11-slim-bullseye AS builder

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    ca-certificates \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY package.json package-lock.json ./

ENV HUSKY=0
RUN npm config set ignore-scripts true

RUN npm install --verbose

COPY . .

FROM --platform=linux/amd64 python:3.11-slim-bullseye

WORKDIR /app

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    ca-certificates \
    git \
    nodejs npm \
    && rm -rf /var/lib/apt/lists/*

COPY --from=builder /app /app

ENV PATH=/usr/local/bin:$PATH

CMD ["/bin/bash"]