FROM python:3.12-slim

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    WORKDIR=/home/cc/EnvGym/data/acto \
    PATH="/root/go/bin:/go/bin:$PATH"

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        make \
        curl \
        wget \
        ca-certificates \
        build-essential \
        jq \
        python3-venv \
        python3-distutils \
        gcc \
        libffi-dev \
        libssl-dev \
        openssh-client \
        unzip \
        && rm -rf /var/lib/apt/lists/*

# Install Go (amd64)
ENV GO_VERSION=1.22.4
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz
ENV GOROOT=/usr/local/go
ENV GOPATH=/root/go
ENV PATH="${GOROOT}/bin:${GOPATH}/bin:${PATH}"

# Install Kind (v0.20.0) via go install
RUN go install sigs.k8s.io/kind@v0.20.0

# Install kubectl (latest stable)
RUN KUBECTL_VERSION=$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt) && \
    curl -Lo /usr/local/bin/kubectl https://storage.googleapis.com/kubernetes-release/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl && \
    chmod +x /usr/local/bin/kubectl

# [Optional] Install Helm (latest stable)
RUN HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep tag_name | cut -d '"' -f 4) && \
    curl -Lo helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -xzvf helm.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm.tar.gz

# [Optional] Install Kustomize (latest stable)
RUN KUSTOMIZE_VERSION=$(curl -s https://api.github.com/repos/kubernetes-sigs/kustomize/releases/latest | grep tag_name | cut -d '"' -f 4 | sed 's/kustomize\///') && \
    curl -Lo /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz && \
    tar -xzOf /usr/local/bin/kustomize https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2F${KUSTOMIZE_VERSION}/kustomize_${KUSTOMIZE_VERSION}_linux_amd64.tar.gz > /usr/local/bin/kustomize && \
    chmod +x /usr/local/bin/kustomize || true

# Create working directory
RUN mkdir -p /home/cc/EnvGym/data/acto
WORKDIR /home/cc/EnvGym/data/acto

# Copy requirements files if present (for caching)
COPY requirements.txt requirements.txt
COPY requirements-dev.txt requirements-dev.txt

# Create and activate Python virtual environment, upgrade pip/setuptools/wheel, install pip-tools, build, virtualenv, and dependencies
RUN python -m venv .venv && \
    . .venv/bin/activate && \
    pip install --upgrade pip setuptools wheel && \
    pip install pip-tools==7.3.0 build==1.0.3 virtualenv==20.25.0 && \
    if [ -f requirements.txt ]; then pip install -r requirements.txt; fi && \
    if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi && \
    pip install pre-commit==3.6.0

# Install ansible-core==2.17.5
RUN . .venv/bin/activate && pip install ansible-core==2.17.5

# Install yq (Python version)
RUN . .venv/bin/activate && pip install yq

# Set entrypoint to always use venv
ENV PATH="/home/cc/EnvGym/data/acto/.venv/bin:$PATH"

# Default command
CMD ["/bin/bash"]