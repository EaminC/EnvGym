FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    build-essential \
    ca-certificates \
    curl \
    git \
    python3 \
    python3-pip \
    python3-setuptools \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/collected_stats

COPY . /home/cc/EnvGym/data-gpt-4.1mini/collected_stats

RUN python3 -m venv /home/cc/EnvGym/venv && \
    /home/cc/EnvGym/venv/bin/pip install --upgrade pip setuptools wheel

ENV PATH="/home/cc/EnvGym/venv/bin:$PATH"

CMD ["/bin/bash"]