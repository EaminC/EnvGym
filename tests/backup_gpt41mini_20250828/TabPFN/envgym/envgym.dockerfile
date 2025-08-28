FROM python:3.11-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PYTHONUNBUFFERED=1 \
    PYTHONDONTWRITEBYTECODE=1 \
    PIP_NO_CACHE_DIR=off \
    PIP_DISABLE_PIP_VERSION_CHECK=on \
    PIP_DEFAULT_TIMEOUT=100

# Set working directory to the project root inside the container
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/TabPFN

# Install system dependencies: git, build tools, and dependencies for python packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    build-essential \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Create a virtual environment inside the project folder
RUN python -m venv /home/cc/EnvGym/data-gpt-4.1mini/TabPFN/venv

# Ensure venv binaries are in PATH
ENV PATH="/home/cc/EnvGym/data-gpt-4.1mini/TabPFN/venv/bin:$PATH"

# Upgrade pip, setuptools, wheel inside venv
RUN pip install --upgrade pip setuptools wheel

# Copy project files to container (including pyproject.toml, requirements.txt, .pre-commit-config.yaml, etc.)
COPY . /home/cc/EnvGym/data-gpt-4.1mini/TabPFN

# Install PyTorch CPU-only (>=2.1,<3), torchvision, torchaudio
RUN pip install torch torchvision torchaudio

# Determine if eval-type-backport needed (only for Python 3.9). Since we use 3.11, skip it.

# Install TabPFN 2.1.3 specifically
RUN pip install tabpfn==2.1.3

# Install pre-commit 3.3.3 and dev dependencies ruff 0.8.6, mypy 1.17.0, types-pyyaml, types-psutil
RUN pip install pre-commit==3.3.3 ruff==0.8.6 mypy==1.17.0 types-pyyaml types-psutil

# Install all other python dependencies as per pyproject.toml or requirements.txt
# Prefer pyproject.toml if it exists; fallback to requirements.txt
RUN if [ -f pyproject.toml ]; then \
        pip install .[dev]; \
    elif [ -f requirements.txt ]; then \
        pip install -r requirements.txt; \
    fi

# Install pre-commit git hooks
RUN pre-commit install

# Download pre-trained models for offline use
RUN python scripts/download_all_models.py || true

# Set environment variables recommended in .env as default environment variables
ENV TABPFN_MODEL_CACHE_DIR=/home/cc/EnvGym/data-gpt-4.1mini/TabPFN/model_cache \
    TABPFN_ALLOW_CPU_LARGE_DATASET=true \
    PYTORCH_CUDA_ALLOC_CONF=max_split_size_mb:512

# Expose working directory and start bash shell on container start
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/TabPFN
CMD ["/bin/bash"]