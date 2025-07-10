FROM ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/SymMC

# Install required packages
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        openjdk-8-jdk \
        ant \
        git \
        cmake \
        build-essential \
        libgmp-dev \
        zlib1g-dev \
        python3 \
        wget \
        ca-certificates \
        unzip \
        curl \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set JAVA_HOME and update PATH
ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Optionally: clone the SymMC repository if not using build context
# ARG SYMMC_REPO_URL
# RUN git clone $SYMMC_REPO_URL /home/cc/EnvGym/data/SymMC

# Ensure scripts are executable if present in context
RUN find . -type f -name "*.sh" -exec chmod +x {} \; || true

# Default command: bash shell
CMD ["/bin/bash"]