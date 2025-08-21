# syntax=docker/dockerfile:1.5

FROM amd64/ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

WORKDIR /home/cc/EnvGym/data/Fairify

RUN --mount=type=cache,target=/var/cache/apt \
    apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
        git \
        bzip2 \
        ca-certificates \
        libgomp1 \
        libc++1 \
        curl \
        bash && \
    wget --progress=dot:giga https://repo.anaconda.com/miniconda/Miniconda3-py37_4.9.2-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm -f /tmp/miniconda.sh && \
    /opt/conda/bin/conda init bash && \
    /opt/conda/bin/conda clean -afy && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/conda/bin:$PATH

RUN conda info --all && conda config --show

RUN conda config --add channels conda-forge && \
    conda config --set channel_priority strict

COPY requirements.txt /tmp/requirements.txt

RUN conda create -y -n fairify python=3.7 && \
    conda clean -afy

SHELL ["/bin/bash", "-c"]

RUN source /opt/conda/etc/profile.d/conda.sh && \
    conda activate fairify && \
    python -m pip install --upgrade pip && \
    pip install -r /tmp/requirements.txt

COPY . /home/cc/EnvGym/data/Fairify

ENTRYPOINT ["/bin/bash", "-c", "source /opt/conda/etc/profile.d/conda.sh && conda activate fairify && exec bash"]