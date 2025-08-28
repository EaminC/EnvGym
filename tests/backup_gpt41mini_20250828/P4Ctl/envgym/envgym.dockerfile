FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TZ=Etc/UTC

WORKDIR /home/cc/P4Ctl

RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        wget \
        curl \
        ca-certificates \
        build-essential \
        python3.8 \
        python3-pip \
        python3-setuptools \
        python3-wheel \
        git \
        bison \
        flex \
        nmap \
        llvm-10 \
        clang-10 \
        libelf-dev \
        libclang-10-dev \
        linux-headers-generic \
        make \
        sudo \
        iproute2 \
        pkg-config \
        cmake \
        unzip && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.8 1 && \
    update-alternatives --set python3 /usr/bin/python3.8 && \
    python3 -m pip install --upgrade pip setuptools wheel

RUN python3 -m pip install scapy==2.4.5

# Add user cc with home directory and set permissions
RUN useradd -m -s /bin/bash cc

USER cc
WORKDIR /home/cc/P4Ctl

# Copy repository content into container (assuming build context includes repo files)
COPY --chown=cc:cc . /home/cc/P4Ctl

# Ensure scripts are executable
RUN find . -type f -name "*.sh" -exec chmod +x {} \;

CMD ["/bin/bash", "-l"]