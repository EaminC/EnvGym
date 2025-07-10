FROM ubuntu:22.04

# Set non-interactive frontend for apt-get
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/RSNN

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        git \
        build-essential \
        python3.10 \
        python3.10-venv \
        python3.10-dev \
        python3-pip \
        libsndfile1 \
        libhdf5-dev \
        libatlas-base-dev \
        libblas-dev \
        liblapack-dev \
        libffi-dev \
        libssl-dev \
        libjpeg-dev \
        libpng-dev \
        ca-certificates \
        pkg-config \
        unzip \
        && \
    rm -rf /var/lib/apt/lists/*

# Ensure python3.10 is default python and pip
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1 && \
    update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1 && \
    python -m pip install --upgrade pip

# Copy requirements.txt first for Docker cache efficiency
COPY requirements.txt .

# Fix stork dependency in requirements.txt before install
RUN sed -i 's|git+https://github.com/fmi-basel/stork.git@40c68fe|git+https://github.com/fmi-basel/stork.git@40c68fe#egg=stork|' requirements.txt

# Install Python dependencies (CPU-only torch/torchaudio/torchvision)
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of the repository
COPY . .

# Create models and results directories if not present
RUN mkdir -p /home/cc/EnvGym/data/RSNN/models /home/cc/EnvGym/data/RSNN/results

# Set environment variables for Python
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Default command: open bash shell
CMD ["/bin/bash"]