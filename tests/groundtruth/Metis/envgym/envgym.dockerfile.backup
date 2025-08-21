FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV HOME=/home/cc
ENV METIS_ROOT=/home/cc/EnvGym/data/Metis
ENV PATH=$HOME/.local/bin:$PATH

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    sudo \
    git \
    wget \
    curl \
    build-essential \
    python3 \
    python3-pip \
    python3-venv \
    python3-setuptools \
    python3-dev \
    openssh-client \
    openssh-server \
    vim \
    ca-certificates \
    pkg-config \
    libssl-dev \
    libffi-dev \
    libxml2-dev \
    libxslt1-dev \
    zlib1g-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    linux-headers-$(uname -r) \
    bison \
    flex \
    autoconf \
    automake \
    libtool \
    gawk \
    cmake \
    unzip \
    tar \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Create user cc and set up home directory structure
RUN useradd -ms /bin/bash cc && \
    mkdir -p /home/cc/.ssh && \
    mkdir -p /home/cc/EnvGym/data/Metis && \
    chown -R cc:cc /home/cc

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

USER cc
WORKDIR /home/cc/EnvGym/data/Metis

# Set up Python venv and upgrade pip
RUN python3 -m venv /home/cc/EnvGym/data/Metis/venv && \
    /home/cc/EnvGym/data/Metis/venv/bin/pip install --upgrade pip setuptools wheel

# No requirements.txt in build context; skipping Python package install

# Set venv as default python/pip for user cc in this Dockerfile
ENV VIRTUAL_ENV=/home/cc/EnvGym/data/Metis/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

# SSH key generation (user cc)
RUN ssh-keygen -t rsa -N "" -f /home/cc/.ssh/id_rsa && \
    cat /home/cc/.ssh/id_rsa.pub >> /home/cc/.ssh/authorized_keys && \
    chmod 600 /home/cc/.ssh/authorized_keys && \
    chmod 700 /home/cc/.ssh

# Example: Prepare directories for build outputs, images, logs, etc.
RUN mkdir -p /home/cc/EnvGym/data/Metis/build \
    /home/cc/EnvGym/data/Metis/images \
    /home/cc/EnvGym/data/Metis/logs \
    /home/cc/EnvGym/data/Metis/fs_bugs/jfs/kernel_hang

# (Optional) Copy scripts, configs, or patch files into the container (adjust as needed)
# COPY --chown=cc:cc scripts/ /home/cc/EnvGym/data/Metis/scripts/
# COPY --chown=cc:cc configs/ /home/cc/EnvGym/data/Metis/configs/

# Set permissions for all EnvGym data
RUN chown -R cc:cc /home/cc/EnvGym/data/Metis

# (Optional) Set up entrypoint or default command
CMD ["/bin/bash"]