FROM --platform=linux/amd64 ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory to project root
WORKDIR /home/cc/EnvGym/data/anvil/anvil

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        python3 \
        python3-pip \
        python3-venv \
        python3-dev \
        build-essential \
        git \
        curl \
        ca-certificates \
        pkg-config \
        libssl-dev \
        libffi-dev \
        libgmp-dev \
        libtool \
        automake \
        autoconf \
        make \
        wget \
        unzip \
        sudo \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and setuptools
RUN python3 -m pip install --upgrade pip setuptools wheel

# Copy project source code from build context (assumes context is /home/cc/EnvGym/data/anvil/anvil)
COPY . ./

# (Optional) Copy local dependencies if any, e.g.:
# COPY ../verus/source/builtin ./verus/source/builtin

# Install Python dependencies if requirements.txt exists
RUN if [ -f requirements.txt ]; then pip install --no-cache-dir -r requirements.txt; fi

# (Optional) Install additional development tools or test dependencies if needed
# RUN if [ -f dev-requirements.txt ]; then pip install --no-cache-dir -r dev-requirements.txt; fi

# (Optional) Set up entrypoint or default command
# CMD ["python3", "main.py"]

# Metadata
LABEL org.opencontainers.image.title="EnvGym Anvil Environment"
LABEL org.opencontainers.image.description="CPU-only, x86_64/amd64, Ubuntu 22.04 environment for EnvGym/Anvil. No ARM or GPU support."
LABEL org.opencontainers.image.authors="Your Name <your.email@example.com>"
LABEL org.opencontainers.image.version="1.0.0"

# Note: This environment is designed for x86_64/amd64 architecture on Ubuntu 22.04. No ARM or GPU (CUDA) support is provided. All Docker images and builds use the amd64 architecture.