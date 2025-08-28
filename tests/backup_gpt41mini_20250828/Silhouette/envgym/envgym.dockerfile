FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV PATH=/root/.local/bin:$PATH

# Install core packages and dependencies
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    git \
    bash \
    openssh-client \
    procps \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    python3-pip \
    qemu-system-x86 \
    build-essential \
    clang-15 \
    llvm-15 \
    llvm-15-dev \
    llvm-15-tools \
    pkg-config \
    ca-certificates \
    curl \
    unzip \
    sudo \
    && rm -rf /var/lib/apt/lists/*

# Set python3.10 as default python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1

# Upgrade pip and install python packages if needed (none explicitly mentioned)
RUN python3 -m pip install --upgrade pip setuptools wheel

# Verify python modules ctypes and readline
RUN python3 -c "import ctypes, readline"

# Create working directory and clone Silhouette repository and pmfs repo
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini
RUN mkdir -p /home/cc/EnvGym/data-gpt-4.1mini && \
    git clone https://github.com/iaoing/Silhouette.git && \
    git clone https://github.com/linux-pmfs/pmfs.git pmfs

# Set working directory to Silhouette repository root
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/Silhouette

# Set executable permissions on key scripts if they exist
RUN chmod +x install_dep.sh prepare.sh reproduce_all.sh run.sh run_all.sh plot.sh || true

# Defer running install_dep.sh and prepare.sh to container runtime to avoid build timeout
RUN echo "To complete setup, run 'bash install_dep.sh' and 'bash prepare.sh' after container start."

# Defer building tools to runtime to avoid build timeout
RUN echo "To build tools, run 'make -j$(nproc)' in the 'codebase/tools' directory after container start."

# Provide instructions for downloading large guest VM image outside Docker build
RUN echo "NOTE: Please download the guest VM image (~30GB) manually and mount it outside the Docker container."

# Default command to run bash shell in Silhouette root directory
CMD ["/bin/bash"]