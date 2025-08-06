FROM ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Update and install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        git \
        build-essential \
        ca-certificates \
        unzip \
        bzip2 \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        liblzma-dev \
        && rm -rf /var/lib/apt/lists/*

# Set up environment variables for conda
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH

# Install Miniconda (latest for x86_64)
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -afy

# Create working directory
RUN mkdir -p /home/cc/EnvGym/data/RelTR
WORKDIR /home/cc/EnvGym/data/RelTR

# Set conda config
RUN conda config --set always_yes yes --set changeps1 no

# (environment.yml should be added to the build context and uncommented below if present)
# ADD environment.yml .

# Create conda environment from environment.yml
# RUN conda env create -f environment.yml

# Set environment so that 'conda activate reltr' is always run
SHELL ["/bin/bash", "--login", "-c"]

ENV CONDA_DEFAULT_ENV=reltr
ENV PATH=$CONDA_DIR/envs/reltr/bin:$PATH

# Install RelTR repository
RUN git clone https://github.com/yrcong/RelTR.git . && \
    git submodule update --init --recursive

# Default command
CMD ["bash"]