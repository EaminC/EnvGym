FROM ubuntu:22.04

# Set environment variables for non-interactive apt installs
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        cmake \
        git \
        curl \
        wget \
        python3 \
        python3-pip \
        python3-venv \
        python3-setuptools \
        python3-wheel \
        pkg-config \
        libssl-dev \
        libffi-dev \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Set the working directory
WORKDIR /home/cc/EnvGym/data/rfuse

# Optionally copy requirements and source code; adjust as needed
COPY requirements.txt ./

# Install Python dependencies in a virtual environment for isolation
RUN python3 -m venv venv && \
    . venv/bin/activate && \
    pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy the rest of the application source code
COPY . .

# Set PATH to use the virtualenv by default
ENV PATH="/home/cc/EnvGym/data/rfuse/venv/bin:$PATH"

# Default command (adjust as needed)
CMD ["/bin/bash"]