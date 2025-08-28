FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV WORKDIR=/home/cc/EnvGym/data-gpt-4.1mini/Metis

RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    python3 \
    python3-pip \
    make \
    libssl-dev \
    mtd-utils \
    xfsprogs \
    rename \
    libncurses-dev \
    bison \
    flex \
    libelf-dev \
    nfs-ganesha \
    sudo \
    ca-certificates \
    wget \
    curl \
    vim \
    bc \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN pip3 install --no-cache-dir numpy scipy matplotlib pulp ply

RUN useradd -m -s /bin/bash cc && \
    echo "cc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

RUN mkdir -p /mnt/test-ext4 /mnt/test-jffs2 /mnt/test-nfs-ganesha-export /mnt/test-nfs-client

USER cc
WORKDIR /home/cc

RUN mkdir -p EnvGym/data-gpt-4.1mini/Metis

COPY --chown=cc:cc ./ ./EnvGym/data-gpt-4.1mini/Metis/

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Metis

RUN set -ex && make clean || true

RUN set -ex && make V=1 2>&1 | tee build.log

# Switch to root user to run make install with proper permissions
USER root
RUN set -ex && ls -l && whoami && env && make install

USER cc

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Metis/fs-state
RUN if [ -f ganesha.conf ]; then sudo cp ganesha.conf /etc/ganesha.conf; fi

RUN if [ -f swarm.lib ]; then sed -i 's/^\s*hostnames.*/hostnames = ["localhost"]/' swarm.lib; fi && \
    if [ -f parameters.py ]; then sed -i '26s/open_flags = .*/open_flags = open_flags.replace(os.O_DIRECT, 0)/' parameters.py || true; fi

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Metis/python-demo/auto_ambiguity_detector
RUN pip3 install --user -r requirements.txt 2>/dev/null || true

RUN find /home/cc/EnvGym/data-gpt-4.1mini/Metis -type f -name '*.sh' -exec chmod +x {} +

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Metis
RUN wget https://cdn.kernel.org/pub/linux/kernel/v6.x/linux-6.9.4.tar.xz && \
    tar -xf linux-6.9.4.tar.xz

RUN echo '#!/bin/bash\n\
cd /home/cc/EnvGym/data-gpt-4.1mini/Metis/linux-6.9.4\n\
make oldconfig\n\
make -j$(nproc)\n\
make modules_install\n\
make install\n' > /home/cc/EnvGym/data-gpt-4.1mini/Metis/build_kernel_6.9.4.sh && chmod +x /home/cc/EnvGym/data-gpt-4.1mini/Metis/build_kernel_6.9.4.sh

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Metis

ENTRYPOINT ["/bin/bash"]