FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV GOPATH=/go
ENV PATH=$GOPATH/bin:/usr/local/go/bin:$PATH

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/acto

# Add deadsnakes PPA for Python 3.12 packages
RUN apt-get update && apt-get install -y --no-install-recommends software-properties-common curl ca-certificates gnupg lsb-release \
 && add-apt-repository ppa:deadsnakes/ppa \
 && apt-get update

# Install system dependencies and tools including python3.12 and python3.10 packages from deadsnakes PPA, excluding python3.12-distutils
RUN apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release \
    build-essential \
    git \
    wget \
    unzip \
    make \
    sudo \
    iproute2 \
    iputils-ping \
    netcat \
    bash-completion \
    procps \
    jq \
    python3.12 python3.12-venv python3.12-dev \
    python3.10 python3.10-venv python3.10-dev \
    python3-distutils \
    && rm -rf /var/lib/apt/lists/*

# Install pip for python3.12 explicitly using ensurepip and upgrade pip setuptools wheel
RUN python3.12 -m ensurepip --upgrade \
 && python3.12 -m pip install --no-cache-dir --upgrade pip setuptools wheel

# Set python3 to python3.12 explicitly and update alternatives
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.12 2 \
 && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 \
 && update-alternatives --set python3 /usr/bin/python3.12

# Install Go 1.20+ (latest stable) for amd64 Linux
ENV GO_VERSION=1.20.7
RUN curl -fsSL https://golang.org/dl/go${GO_VERSION}.linux-amd64.tar.gz -o go.tar.gz \
 && tar -C /usr/local -xzf go.tar.gz \
 && rm go.tar.gz

ENV PATH=/usr/local/go/bin:$PATH

# Create GOPATH directories
RUN mkdir -p $GOPATH/{bin,src,pkg}

# Install Kind v0.20.0 amd64 Linux binary via Go install
RUN go install sigs.k8s.io/kind@v0.20.0

# Install gocovmerge amd64 Linux binary via Go install
RUN go install github.com/wadey/gocovmerge@latest

# Install kubectl latest stable amd64 Linux binary
RUN curl -fsSL -o /usr/local/bin/kubectl https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl \
 && chmod +x /usr/local/bin/kubectl

# Install Helm latest stable amd64 Linux binary
RUN HELM_VERSION=$(curl -s https://api.github.com/repos/helm/helm/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/') \
 && curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz \
 && tar -xzf helm.tar.gz --strip-components=1 linux-amd64/helm -C /usr/local/bin/ \
 && rm helm.tar.gz

# Install Ansible core and required Python packages in python3.12 environment
RUN python3.12 -m pip install --no-cache-dir \
    ansible-core==2.17.5 \
    pre-commit \
    black \
    isort \
    pylint \
    mypy \
    pip-tools

# Install Ansible collections via ansible-galaxy
RUN ansible-galaxy collection install ansible.posix community.general

# Copy repository files to container
COPY . /home/cc/EnvGym/data-gpt-4.1mini/acto

# Install Python dependencies pinned with requirements.txt and requirements-dev.txt using python3.12
RUN python3.12 -m pip install --no-cache-dir -r requirements.txt \
 && python3.12 -m pip install --no-cache-dir -r requirements-dev.txt

# Install pre-commit hooks
RUN pre-commit install

# Build the Acto libraries using Makefile
RUN make lib

# Set user to cc (create user cc with home directory and sudo)
RUN useradd -m -d /home/cc -s /bin/bash cc \
 && echo "cc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER cc
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/acto

ENV PATH=/home/cc/go/bin:/usr/local/go/bin:$PATH

CMD ["/bin/bash"]