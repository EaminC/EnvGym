FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=UTC

# Install system dependencies and Python packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        gcc \
        g++ \
        make \
        cmake \
        automake \
        autoconf \
        libtool \
        pkg-config \
        libaio-dev \
        libsnappy-dev \
        libfuse-dev \
        libnuma-dev \
        libssl-dev \
        zlib1g-dev \
        uuid-dev \
        python3 \
        python3-pip \
        python3-numpy \
        python3-pandas \
        openjdk-8-jdk \
        maven \
        f2fs-tools \
        nvme-cli \
        sudo \
        wget \
        curl \
        ca-certificates \
        locales \
        unzip \
        vim \
    && rm -rf /var/lib/apt/lists/*

# Set locale
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Create user 'cc' and set up home directory
RUN useradd -m -s /bin/bash cc && \
    echo "cc ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER cc
WORKDIR /home/cc

# Create working directories
RUN mkdir -p /home/cc/EnvGym/data/CrossPrefetch && \
    mkdir -p /home/cc/ssd

# Set up environment variables for repository location
ENV BASE=/home/cc/EnvGym/data/CrossPrefetch/crossprefetch-asplos24-artifacts

# Clone the repository (can be overridden by mounting host volume)
RUN git clone https://github.com/RutgersCSSystems/crossprefetch-asplos24-artifacts $BASE

WORKDIR $BASE

# Copy install_packages.sh and setvars.sh for later use
COPY --chown=cc:cc scripts/install_packages.sh scripts/setvars.sh $BASE/scripts/

# Install additional dependencies via install_packages.sh
RUN chmod +x $BASE/scripts/install_packages.sh && \
    $BASE/scripts/install_packages.sh

# Install Python requirements if requirements.txt exists
RUN if [ -f "$BASE/requirements.txt" ]; then pip3 install --user -r $BASE/requirements.txt; fi

# Compile shared library: simple_prefetcher
RUN cd $BASE/shared_libs/simple_prefetcher && \
    chmod +x compile.sh && \
    ./compile.sh

# Compile all application workloads (RocksDB, YCSB, snappy-c, mmap_exp, scalability, multi_read)
RUN for app in rocksdb-ycsb rocksdb snappy-c mmap_exp scalability multi_read; do \
        if [ -d "$BASE/appbench/apps/$app" ]; then \
            cd $BASE/appbench/apps/$app && \
            chmod +x compile.sh && \
            ./compile.sh; \
        fi \
    done

# Set up environment variable sourcing for interactive shells
RUN echo "source $BASE/scripts/setvars.sh" >> /home/cc/.bashrc

# Set working directory for user
WORKDIR $BASE

# Set default command
CMD ["/bin/bash"]