FROM python:3.7-slim-buster

# Set environment variables to avoid Python buffering and set locale
ENV PYTHONUNBUFFERED=1 \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        build-essential \
        libglib2.0-0 \
        libsm6 \
        libxrender1 \
        libxext6 \
        ca-certificates \
        wget \
        && \
    rm -rf /var/lib/apt/lists/*

# Create the working directory
RUN mkdir -p /home/cc/EnvGym/data/Lottory
WORKDIR /home/cc/EnvGym/data/Lottory

# Copy requirements.txt first for Docker cache efficiency
COPY requirements.txt .

# Upgrade pip to latest version compatible with Python 3.7
RUN pip install --upgrade "pip<22.0"

# Install CPU-only PyTorch and torchvision
RUN pip install torch==1.2.0+cpu torchvision==0.4.0+cpu \
    -f https://download.pytorch.org/whl/torch_stable.html

# Install other Python dependencies
RUN pip install -r requirements.txt

# (Optional) Install Jupyter Notebook for interactive development
# Uncomment the following line if you want Jupyter installed by default
# RUN pip install jupyter

# (Optional) Install development tools for linting/formatting
# Uncomment the following lines if you want these tools installed
# RUN pip install pre-commit flake8 black

# Copy the rest of the repository files
COPY . .

# Set permissions (optional, useful if running as non-root)
# RUN chown -R 1000:1000 /home/cc/EnvGym/data/Lottory

# Default command (can be overridden)
CMD ["/bin/bash"]