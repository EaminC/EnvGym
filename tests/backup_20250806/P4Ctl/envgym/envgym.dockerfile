FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Ensure all Ubuntu repositories are enabled for package availability
RUN apt-get update && \
    apt-get install -y --no-install-recommends software-properties-common gnupg2
RUN add-apt-repository main
RUN add-apt-repository universe
RUN add-apt-repository multiverse
RUN add-apt-repository restricted
RUN add-apt-repository ppa:deadsnakes/ppa
RUN apt-get update --allow-releaseinfo-change

# Install core system dependencies in small groups to help isolate failures
RUN apt-get install -y --no-install-recommends \
    build-essential \
    make \
    git \
    wget \
    curl \
    ca-certificates

RUN apt-get install -y --no-install-recommends \
    clang \
    llvm \
    libelf-dev

RUN apt-get install -y --no-install-recommends \
    flex \
    bison

RUN apt-get install -y --no-install-recommends ncat

# Install linux-headers-generic and linux-headers-$(uname -r) BEFORE BCC-related packages
RUN apt-get install -y --no-install-recommends linux-headers-generic && \
    apt-get install -y --no-install-recommends linux-headers-$(uname -r) || true

# Diagnostic: Check availability and versions of BCC-related packages before installation
RUN apt-get update && \
    apt-cache policy python3-bcc bpfcc-tools libbpfcc-dev

# Debugging: Print sources list and update again
RUN cat /etc/apt/sources.list && ls /etc/apt/sources.list.d && apt-get update

# (Optional, for repository key issues)
RUN apt-get install -y --no-install-recommends ubuntu-cloud-keyring || true

# Install BCC and related packages from Ubuntu repositories, fail gracefully if unavailable
RUN apt-get update && \
    (apt-get install -y --no-install-recommends \
    python3-bcc \
    bpfcc-tools \
    libbpfcc-dev || \
    (echo "WARNING: BCC packages not available in this build environment." && true)) && \
    rm -rf /var/lib/apt/lists/*

# Install Python 3.7 from deadsnakes
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3.7 \
      python3.7-venv \
      python3.7-distutils && \
    rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.7 (use legacy script for 3.7)
RUN wget https://bootstrap.pypa.io/pip/3.7/get-pip.py && \
    python3.7 get-pip.py && \
    rm get-pip.py

# Install scapy==2.4.5 for Python 3.7
RUN python3.7 -m pip install --no-cache-dir scapy==2.4.5

# Set up working directory
RUN mkdir -p /home/cc/EnvGym/data/P4Ctl
WORKDIR /home/cc/EnvGym/data/P4Ctl

# Set up .env file for environment variables
RUN echo "SDE=/home/cc/bf-sde-9.7.0/" > .env && \
    echo "SDE_INSTALL=/home/cc/bf-sde-9.7.0/install" >> .env && \
    echo "PYTHONPATH=\$SDE_INSTALL/lib/python3.7/site-packages:\$PYTHONPATH" >> .env

# Placeholder for SDE directory
RUN mkdir -p /home/cc/bf-sde-9.7.0 && \
    mkdir -p /home/cc/bf-sde-9.7.0/install

# Environment variables for SDE
ENV SDE=/home/cc/bf-sde-9.7.0/
ENV SDE_INSTALL=/home/cc/bf-sde-9.7.0/install
ENV PYTHONPATH=$SDE_INSTALL/lib/python3.7/site-packages:$PYTHONPATH

# Default to bash shell
SHELL ["/bin/bash", "-c"]

# Copy project source files into the working directory
COPY compiler ./compiler
COPY host_agent ./host_agent
COPY switch ./switch
COPY custom-recieve.py .
COPY custom-send.py .
COPY README.md .

# Final message for user (comment only)
# To complete setup:
# 1. Download and extract Tofino SDE 9.7.0 to /home/cc/bf-sde-9.7.0
# 2. Follow project instructions for build and operation

CMD ["/bin/bash"]