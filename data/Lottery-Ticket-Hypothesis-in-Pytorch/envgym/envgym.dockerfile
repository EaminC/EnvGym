# Dockerfile for Lottery Ticket Hypothesis in PyTorch (development environment)
#
# Usage:
#   # CPU-only image
#   docker build -t lottery-ticket -f envgym/envgym.dockerfile .
#   # GPU-enabled image (requires CUDA 10.0)
#   docker build --build-arg USE_CUDA=true -t lottery-ticket-gpu -f envgym/envgym.dockerfile .

ARG BASE_IMAGE=python:3.7-slim-buster
FROM ${BASE_IMAGE}

# Install system requirements
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl && \
    rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy and install Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# (Optional) Install GPU-enabled PyTorch if CUDA support is needed
ARG USE_CUDA=false
RUN if [ "$USE_CUDA" = "true" ]; then \
        pip install --upgrade --force-reinstall \
            torch==1.2.0 torchvision==0.4.0 \
            -f https://download.pytorch.org/whl/cu100/stable; \
    fi

# Copy application code
COPY . .

# Default command
CMD ["bash"]
