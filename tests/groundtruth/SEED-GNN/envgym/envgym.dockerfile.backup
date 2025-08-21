FROM python:3.9-slim-bullseye

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies: git, wget, bash, build-essential (for pip builds)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        wget \
        bash \
        build-essential \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /home/cc/EnvGym/data/SEED-GNN

# Copy only requirements.txt first to leverage Docker cache
COPY requirements.txt ./requirements.txt

# Upgrade pip
RUN pip install --upgrade pip

# Install PyTorch 2.0.0 CPU-only
RUN pip install torch==2.0.0+cpu -f https://download.pytorch.org/whl/torch_stable.html

# Install PyG CPU-only extensions (torch-scatter, torch-cluster, torch-spline-conv, torch-sparse) via official wheel index
RUN pip install \
    torch-scatter==2.1.1 \
    torch-cluster==1.6.1 \
    torch-spline-conv==1.2.2 \
    torch-sparse==0.6.17 \
    -f https://data.pyg.org/whl/torch-2.0.0+cpu.html

# Install all remaining Python dependencies from requirements.txt
RUN pip install -r requirements.txt

# Copy rest of the source code and scripts
COPY . .

# Make sure all shell scripts in scripts/ are executable
RUN find scripts -type f -name "*.sh" -exec chmod +x {} \;

# Default command: show Python, pip, torch versions and check CPU-only
CMD python -c "import sys; import torch; print('Python', sys.version); print('PyTorch', torch.__version__); print('CUDA available:', torch.cuda.is_available())"