FROM --platform=linux/amd64 python:3.10-slim

# Set environment variables to prevent Python from writing .pyc files and to force unbuffered output
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/TabPFN

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        curl \
        ca-certificates \
        libopenblas-dev \
        liblapack-dev \
        gcc \
        g++ \
        make \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip, setuptools, wheel to latest versions
RUN pip install --upgrade pip setuptools wheel

# Clone TabPFN repository (shallow clone)
RUN git clone https://github.com/PriorLabs/TabPFN.git --depth 1 . 

# Optionally clone tabpfn-extensions (uncomment to enable)
# RUN git clone https://github.com/priorlabs/tabpfn-extensions.git

# Install main dependencies and dev dependencies (editable install + [dev])
RUN pip install -e ".[dev]"

# Additional development tools and typing stubs
RUN pip install \
    types-pyyaml \
    types-psutil \
    commitizen \
    check-jsonschema

# Optionally install tabpfn-extensions (uncomment to enable)
# RUN pip install -e tabpfn-extensions

# Ensure pre-commit is installed and install hooks if config exists
RUN if [ -f .pre-commit-config.yaml ]; then pre-commit install; fi

# Copy all project files (if building with build context outside, adjust as needed)
COPY . .

# Set environment variable for model cache (optional, override at runtime if needed)
# ENV TABPFN_MODEL_CACHE_DIR=/home/cc/EnvGym/data/TabPFN/model_cache

# Default command: show Python and pip version, then open bash
CMD python --version && pip --version && bash