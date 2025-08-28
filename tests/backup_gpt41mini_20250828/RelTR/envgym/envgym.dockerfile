FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    git \
    build-essential \
    ca-certificates \
    curl \
    unzip \
    python3-dev \
    python3-pip \
    python3-setuptools \
    libffi-dev \
    libssl-dev \
    pkg-config \
    cython3 \
    bzip2 \
    gcc \
    g++ \
    make \
    libpython3-dev \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ENV CONDA_DIR=/opt/conda
RUN set -ex; \
    wget --tries=5 --waitretry=5 -O /tmp/miniconda.sh https://repo.anaconda.com/miniconda/Miniconda3-py38_4.12.0-Linux-x86_64.sh; \
    chmod +x /tmp/miniconda.sh; \
    /tmp/miniconda.sh -b -p $CONDA_DIR; \
    rm /tmp/miniconda.sh; \
    $CONDA_DIR/bin/conda clean -tipsy

ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda create -n reltr python=3.6 -y

SHELL ["/bin/bash", "-c"]

RUN source $CONDA_DIR/etc/profile.d/conda.sh && conda activate reltr && \
    conda install -y cython setuptools wheel && \
    conda install pytorch==1.6.0 torchvision==0.7.0 cpuonly -c pytorch -y && \
    conda install matplotlib scipy numpy -y && \
    conda install -c conda-forge gcc_linux-64 gxx_linux-64 libffi -y && \
    pip install --upgrade pip

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini

RUN git clone https://github.com/yrcong/RelTR.git RelTR

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/RelTR

RUN conda run -n reltr pip install --no-cache-dir -v -U 'git+https://github.com/cocodataset/cocoapi.git#subdirectory=PythonAPI'

RUN conda run -n reltr bash -c "cd lib/fpn && sh make.sh && python setup.py build_ext --inplace"

ENV CONDA_DEFAULT_ENV=reltr
ENV PATH=$CONDA_DIR/envs/reltr/bin:$PATH

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/RelTR

CMD ["bash"]