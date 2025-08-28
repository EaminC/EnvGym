FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    CONDA_DIR=/home/cc/miniconda3 \
    FLEX_ROOT=/home/cc/flex

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    ca-certificates \
    bzip2 \
    git \
    build-essential \
    libcurl4-openssl-dev \
    libssl-dev \
    libxml2-dev \
    dos2unix \
    bash \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -d /home/cc cc

RUN chmod 1777 /tmp

WORKDIR /home/cc

RUN wget --tries=5 --retry-connrefused --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    chmod +x /tmp/miniconda.sh && \
    /bin/bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh

ENV PATH=$CONDA_DIR/bin:$PATH

RUN conda --version && conda info

# Skip updating base conda to avoid update failure

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

RUN conda create -n flex_r_env -y r-base && \
    conda run -n flex_r_env conda install -y -c conda-forge r-eva && \
    conda clean -afy

RUN conda create -n flex_py_env python=3.8 -y && \
    conda clean -afy

COPY requirements.txt /tmp/requirements.txt
RUN conda run -n flex_py_env pip install --upgrade pip && \
    conda run -n flex_py_env pip install -r /tmp/requirements.txt && \
    conda clean -afy

ENV R_HOME=$CONDA_DIR/envs/flex_r_env/lib/R
ENV PATH=$CONDA_DIR/envs/flex_r_env/bin:$PATH

USER cc

WORKDIR $FLEX_ROOT

COPY --chown=cc:cc ./tool $FLEX_ROOT/tool
COPY --chown=cc:cc ./README.md $FLEX_ROOT/README.md
COPY --chown=cc:cc ./requirements.txt $FLEX_ROOT/requirements.txt

RUN find $FLEX_ROOT/tool/scripts -type f -name "*.sh" -exec dos2unix {} + || true
RUN chmod +x $FLEX_ROOT/tool/scripts/general_setup.sh

WORKDIR $FLEX_ROOT
ENV CONDA_DEFAULT_ENV=flex_py_env
ENV CONDA_PREFIX=$CONDA_DIR/envs/flex_py_env
ENV PATH=$CONDA_PREFIX/bin:$PATH

CMD ["/bin/bash"]