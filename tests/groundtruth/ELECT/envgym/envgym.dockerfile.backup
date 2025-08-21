FROM ubuntu:20.04

# Set noninteractive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-11-jdk \
        openjdk-11-jre \
        ant \
        ant-optional \
        maven \
        clang \
        llvm \
        libisal-dev \
        python3 \
        python3-minimal \
        python3-pip \
        python3-venv \
        bc \
        make \
        tar \
        curl \
        asciidoc \
        ntpdate \
        git \
        build-essential \
        ca-certificates \
        software-properties-common

# Optional: Install Python 3.7 and 3.8 via deadsnakes PPA for compatibility testing
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        python3.7-minimal \
        python3.8-minimal

# Upgrade pip and setuptools
RUN python3 -m pip install --upgrade pip setuptools

# Set JAVA_HOME for OpenJDK 11
ENV JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64
ENV PATH="$JAVA_HOME/bin:${PATH}"

# Set working directory
WORKDIR /home/cc/EnvGym/data/ELECT

# Default command
CMD ["/bin/bash"]