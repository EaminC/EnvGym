FROM --platform=linux/amd64 python:3.12-slim

# Set working directory
WORKDIR /home/cc/EnvGym/data/acto

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        make \
        gcc \
        wget \
        ca-certificates \
        openssh-client \
        gnupg2 \
        unzip \
        libffi-dev \
        libssl-dev \
        software-properties-common \
    && rm -rf /var/lib/apt/lists/*

# Install Go (latest stable)
ENV GO_VERSION=1.22.4
RUN wget -q https://go.dev/dl/go${GO_VERSION}.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go${GO_VERSION}.linux-amd64.tar.gz && \
    rm go${GO_VERSION}.linux-amd64.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

# Install kubectl (latest stable)
RUN curl -sSL "https://storage.googleapis.com/kubernetes-release/release/$(curl -sSL https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" -o /usr/local/bin/kubectl && \
    chmod +x /usr/local/bin/kubectl

# Install Helm (latest stable)
ENV HELM_VERSION=v3.14.4
RUN wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    tar -zxvf helm-${HELM_VERSION}-linux-amd64.tar.gz && \
    mv linux-amd64/helm /usr/local/bin/helm && \
    rm -rf linux-amd64 helm-${HELM_VERSION}-linux-amd64.tar.gz

# Install kind (Kubernetes in Docker)
ENV KIND_VERSION=v0.22.0
RUN curl -Lo /usr/local/bin/kind https://kind.sigs.k8s.io/dl/${KIND_VERSION}/kind-linux-amd64 && \
    chmod +x /usr/local/bin/kind

# Install Python build dependencies and pip-tools, pre-commit
RUN pip install --upgrade pip && \
    pip install pip-tools pre-commit

# Copy requirements files first for cache efficiency
COPY requirements.txt requirements.txt
COPY requirements-dev.txt requirements-dev.txt

# Install python dependencies
RUN pip install -r requirements.txt && \
    if [ -f requirements-dev.txt ]; then pip install -r requirements-dev.txt; fi

# Copy rest of the repository
COPY . .

# Set environment variables (adjust as needed)
ENV ACTO_HOME=/home/cc/EnvGym/data/acto
ENV PYTHONPATH=/home/cc/EnvGym/data/acto
ENV KUBECONFIG=/home/cc/EnvGym/data/acto/.kube/config

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Set default command: drop into bash at repo root
CMD ["/bin/bash"]