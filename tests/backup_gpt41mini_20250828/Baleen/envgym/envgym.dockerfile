FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8
ENV PATH=/opt/micromamba/bin:$PATH
ENV MAMBA_ROOT_PREFIX=/opt/micromamba

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    wget \
    git \
    bash \
    bzip2 \
    unzip \
    build-essential \
    locales \
    && locale-gen en_US.UTF-8 \
    && rm -rf /var/lib/apt/lists/*

# Install micromamba v1.4.1
RUN curl -L https://micromamba.snakepit.net/api/micromamba/linux-64/1.4.1 -o /tmp/micromamba.tar.bz2 \
    && mkdir -p /opt/micromamba \
    && tar -xjf /tmp/micromamba.tar.bz2 -C /opt/micromamba --strip-components=1 bin/micromamba \
    && rm /tmp/micromamba.tar.bz2 \
    && chmod +x /opt/micromamba/micromamba

RUN useradd -m cc
WORKDIR /home/cc

# Clone repository with submodules as root to avoid permission/network issues
RUN git clone --recurse-submodules https://github.com/wonglkd/Baleen-FAST24.git Baleen-FAST24 && \
    chown -R cc:cc /home/cc/Baleen-FAST24

USER cc
WORKDIR /home/cc/Baleen-FAST24

SHELL ["/bin/bash", "-c"]

# Verify the environment yaml file exists and list its content
RUN ls -l BCacheSim/install/env_cachelib-py-3.11.yaml && cat BCacheSim/install/env_cachelib-py-3.11.yaml

# Append channel config separately with debugging
RUN bash -c "source /opt/micromamba/etc/profile.d/micromamba.sh && micromamba config append channels conda-forge && micromamba config list"

# Create environment with debugging and explicit bash shell
RUN bash -c "source /opt/micromamba/etc/profile.d/micromamba.sh && micromamba create -n cachelib-py-3.11 -f BCacheSim/install/env_cachelib-py-3.11.yaml -y --verbose --debug"

# Clean micromamba caches
RUN bash -c "source /opt/micromamba/etc/profile.d/micromamba.sh && micromamba clean --all --yes"

# Activate environment on login for user cc
RUN echo "source /opt/micromamba/etc/profile.d/micromamba.sh" >> /home/cc/.bashrc && \
    echo "micromamba activate cachelib-py-3.11" >> /home/cc/.bashrc

ENV MAMBA_DOCKERFILE_ACTIVATE=1

# Download trace data by running get-tectonic.sh
WORKDIR /home/cc/Baleen-FAST24/data
RUN bash get-tectonic.sh

WORKDIR /home/cc/Baleen-FAST24

CMD ["/bin/bash"]