FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

WORKDIR /home/cc/EnvGym/data/Lottory

# Step 1: Install software-properties-common, ca-certificates, lsb-release, and gnupg to enable add-apt-repository
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common \
        ca-certificates \
        lsb-release \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

# Step 2: Add deadsnakes PPA for Python 3.7
RUN add-apt-repository ppa:deadsnakes/ppa && \
    apt-get update

# Step 3: Install remaining dependencies and Python 3.7
RUN apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        wget \
        git \
        libssl-dev \
        libffi-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        zlib1g-dev \
        libncurses5-dev \
        libgdbm-dev \
        libnss3-dev \
        liblzma-dev \
        python3-pip \
        python3-setuptools \
        python3-distutils \
        python3-venv \
        python3.7 \
        python3.7-venv \
        python3.7-dev && \
    rm -rf /var/lib/apt/lists/*

# Install pip for Python 3.7
RUN curl https://bootstrap.pypa.io/pip/3.7/get-pip.py -o /tmp/get-pip.py && \
    python3.7 /tmp/get-pip.py && \
    rm /tmp/get-pip.py

RUN python3.7 -m pip install --upgrade pip setuptools wheel

# Clone the repository
RUN git clone https://github.com/rahulvigneswaran/Lottery-Ticket-Hypothesis-in-Pytorch.git /home/cc/EnvGym/data/Lottory

# Use requirements.txt from the cloned repo (since it exists in directory tree)
RUN python3.7 -m venv /home/cc/EnvGym/data/Lottory/venv

RUN . /home/cc/EnvGym/data/Lottory/venv/bin/activate && \
    python --version && \
    pip install --upgrade pip && \
    pip install torch==1.2.0+cpu torchvision==0.4.0+cpu -f https://download.pytorch.org/whl/torch_stable.html && \
    pip install -r requirements.txt

ENV VIRTUAL_ENV=/home/cc/EnvGym/data/Lottory/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

CMD ["/bin/bash"]