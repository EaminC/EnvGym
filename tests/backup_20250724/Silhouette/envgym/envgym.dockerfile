FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PYTHON_VERSION=3.10

WORKDIR /home/cc/EnvGym/data/Silhouette

RUN mkdir -p /home/cc/EnvGym/data/Silhouette/qemu_imgs

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        curl \
        python3.10 \
        python3.10-venv \
        python3.10-dev \
        qemu-kvm \
        qemu-utils \
        libvirt-daemon-system \
        libvirt-clients \
        bridge-utils \
        memcached \
        clang \
        clang-tools \
        llvm \
        build-essential \
        make \
        linux-headers-generic \
        ca-certificates \
        lsb-release \
        sudo \
        openssh-client \
        unzip \
        pkg-config \
        libssl-dev \
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        zlib1g-dev \
        tmux \
        vim \
        gpg \
        && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

RUN mkdir -p /home/cc/EnvGym/data/Silhouette/Silhouette/codebase/scripts/fs_conf && \
    touch /home/cc/EnvGym/data/Silhouette/Silhouette/codebase/scripts/fs_conf/sshkey && \
    chmod 600 /home/cc/EnvGym/data/Silhouette/Silhouette/codebase/scripts/fs_conf/sshkey

# Project source, repo clones, pip install, and build steps should be run at runtime, not build time.
# See README or run the provided entrypoint script in the container.

COPY install_dep.sh /home/cc/EnvGym/data/Silhouette/
COPY prepare.sh /home/cc/EnvGym/data/Silhouette/

# Optionally, you can provide a post-build setup script for the user to run at runtime.
COPY README.md /home/cc/EnvGym/data/Silhouette/

CMD ["/bin/bash"]