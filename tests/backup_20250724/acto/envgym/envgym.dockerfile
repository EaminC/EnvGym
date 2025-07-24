FROM --platform=linux/amd64 python:3.12-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    VIRTUAL_ENV=/home/cc/EnvGym/data/acto/venv \
    PATH="/home/cc/EnvGym/data/acto/venv/bin:$PATH" \
    GO_VERSION=1.21.11 \
    KIND_VERSION=v0.20.0

# Set workdir
WORKDIR /home/cc/EnvGym/data/acto

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        ca-certificates \
        openssh-client \
        libffi-dev \
        libssl-dev \
        python3-venv \
        python3-dev \
        gcc \
        make \
        unzip \
        jq \
    && rm -rf /var/lib/apt/lists/*

# Install Go (amd64)
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install kubectl (latest stable, amd64) with better error handling and diagnostics
RUN set -eux; \
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt); \
    echo "Using kubectl version: $KUBECTL_VERSION"; \
    curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl; \
    chmod +x /usr/local/bin/kubectl

# [Optional] Install Helm (latest, amd64)
RUN HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | jq -r .tag_name) && \
    curl -Lo helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -xzf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    chmod +x /usr/local/bin/helm && \
    rm -rf helm.tar.gz linux-amd64

# [Optional] Install Minikube and k3d (both amd64, not required for Kind users)
# Uncomment if needed
# RUN curl -Lo /usr/local/bin/minikube https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64 && \
#     chmod +x /usr/local/bin/minikube
# RUN curl -Lo /usr/local/bin/k3d https://github.com/k3d-io/k3d/releases/latest/download/k3d-linux-amd64 && \
#     chmod +x /usr/local/bin/k3d

# Create Python virtual environment
RUN python -m venv /home/cc/EnvGym/data/acto/venv

# Upgrade pip and install pip-tools
RUN pip install --upgrade pip setuptools wheel pip-tools

# Copy requirements files
COPY requirements.txt requirements.txt
COPY requirements-dev.txt requirements-dev.txt

# Install Python dependencies (production and dev)
RUN pip install -r requirements.txt && \
    pip install -r requirements-dev.txt

# Install Kind (v0.20.0 via go install)
RUN go install sigs.k8s.io/kind@${KIND_VERSION} && \
    cp /root/go/bin/kind /usr/local/bin/kind && \
    chmod +x /usr/local/bin/kind

# Copy project files
COPY . .

# Set permissions
RUN chown -R root:root /home/cc/EnvGym/data/acto

# Set entrypoint (optional, can be overwritten in docker-compose or CLI)
ENTRYPOINT ["/bin/bash"]