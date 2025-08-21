FROM python:3.10-slim-bullseye

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV PIP_DISABLE_PIP_VERSION_CHECK=1

WORKDIR /home/cc/EnvGym/data/RSNN

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        gcc \
        g++ \
        libsndfile1 \
        libhdf5-dev \
        libblas-dev \
        liblapack-dev \
        python3-venv \
        ca-certificates \
        curl && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN python -m pip install --upgrade pip setuptools wheel

COPY requirements.txt .

# Fix for git dependencies without #egg specifier
RUN sed -i -e 's|git+https://github.com/fmi-basel/stork.git@40c68fe$|git+https://github.com/fmi-basel/stork.git@40c68fe#egg=stork|' requirements.txt

RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cpu

RUN pip install --no-cache-dir -r requirements.txt

RUN pip install --no-cache-dir notebook

RUN mkdir -p /home/cc/EnvGym/data/RSNN/conf/data \
    /home/cc/EnvGym/data/RSNN/challenge/neurobench \
    /home/cc/EnvGym/data/RSNN/models \
    /home/cc/EnvGym/data/RSNN/results

COPY . /home/cc/EnvGym/data/RSNN/

RUN find . -name "*.py" -exec chmod +x {} \;

CMD ["bash"]