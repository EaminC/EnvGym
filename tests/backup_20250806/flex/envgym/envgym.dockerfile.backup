FROM ubuntu:22.04

# Set noninteractive for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/flex

# Install system-level build tools and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      wget \
      curl \
      git \
      build-essential \
      ca-certificates \
      gcc \
      g++ \
      make \
      dpkg \
      locales \
      bzip2 \
      libglib2.0-0 \
      libxext6 \
      libsm6 \
      libxrender1 \
      unzip \
      && rm -rf /var/lib/apt/lists/*

# Set locale (for R and Python compatibility)
RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Remove pre-existing miniconda directory before installation
RUN rm -rf /home/cc/miniconda3

# Download and install latest Miniconda (Linux x86_64)
ENV CONDA_DIR=/home/cc/miniconda3
ENV PATH=$CONDA_DIR/bin:$PATH

RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -afy

# Verify conda installation
RUN $CONDA_DIR/bin/conda --version

# Ensure conda is up to date and configure channels, with robust handling
RUN $CONDA_DIR/bin/conda config --add channels conda-forge && \
    $CONDA_DIR/bin/conda config --set channel_priority strict

# Optionally update conda, but do not fail build if it fails
RUN $CONDA_DIR/bin/conda update -n base -c defaults conda --yes || true

# Copy requirements.txt if it exists (to speed up builds with caching)
COPY requirements.txt ./

# (Optional) Create and activate conda environment if you have environment.yml
# COPY environment.yml ./
# RUN conda env create -f environment.yml && \
#     conda clean -afy

# Set conda environment path and activate on shell startup (example env name, adjust as needed)
ENV CONDA_DEFAULT_ENV=flex-env
ENV CONDA_PREFIX=$CONDA_DIR/envs/flex-env

# Shell initialization for conda
RUN echo ". $CONDA_DIR/etc/profile.d/conda.sh" >> /etc/profile && \
    echo "conda activate flex-env" >> /etc/profile

# Ensure directories exist with correct permissions
RUN mkdir -p /home/cc/EnvGym/data/flex/projects && \
    mkdir -p /home/cc/EnvGym/data/flex/tool/logs && \
    mkdir -p /home/cc/EnvGym/data/flex/tool/config

# Copy .gitignore
COPY .gitignore ./

# Ensure any scripts are executable (for setup)
RUN find tool/scripts/ -type f -name "*.sh" -exec chmod +x {} \; || true

# Default workdir for container
WORKDIR /home/cc/EnvGym/data/flex

# Set entrypoint to bash with conda activated for interactive use
SHELL ["/bin/bash", "-c"]
ENTRYPOINT ["/bin/bash", "--login"]