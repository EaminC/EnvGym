FROM python:3.7-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies in one layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    wget \
    curl \
    git \
    ca-certificates \
    libssl-dev \
    libbz2-dev \
    libreadline-dev \
    libsqlite3-dev \
    libffi-dev \
    zlib1g-dev \
    libncurses5-dev \
    libncursesw5-dev \
    xz-utils \
    tk-dev \
    liblzma-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory to /app (root of repo)
WORKDIR /app

# Copy existing requirements.txt and .gitignore from the context (created locally in repo)
# Since these files exist, we can copy them for better cache usage
COPY requirements.txt ./
COPY .gitignore ./

# Create and activate virtual environment
RUN python3 -m venv venv
ENV PATH="/app/venv/bin:$PATH"

# Upgrade pip in venv and install dependencies with no cache to speed up build
RUN pip install --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Verify python and pip versions
RUN python --version && pip --version

# Sanity check for torch cuda availability at build time
RUN python -c "import torch; assert not torch.cuda.is_available(), 'CUDA should not be available in CPU-only build'"

# Expose bash shell on container startup
CMD ["/bin/bash"]