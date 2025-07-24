FROM python:3.8-slim

SHELL ["/bin/bash", "-c"]

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8 LC_ALL=C.UTF-8

WORKDIR /home/cc/EnvGym/data/probfuzz

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        wget \
        curl \
        ca-certificates \
        bash \
        make \
        g++ \
        jq \
        python3-venv \
        dos2unix \
        python3-pip \
        && rm -rf /var/lib/apt/lists/*

RUN ln -sf /usr/local/bin/python3 /usr/local/bin/python && \
    ln -sf /usr/local/bin/pip3 /usr/local/bin/pip

COPY . /home/cc/EnvGym/data/probfuzz

# Fix install.sh: Unix line endings, valid shebang, executable; print content for debug
RUN if [ ! -f install.sh ]; then echo "install.sh missing!"; exit 1; fi && \
    dos2unix install.sh && \
    (head -n 1 install.sh | grep -q '^#!' || sed -i '1i #!/bin/bash' install.sh) && \
    chmod +x install.sh && \
    echo "===== install.sh content below =====" && cat install.sh

RUN which pip && pip --version

# Enhanced debug: capture install.sh output and always print on failure
RUN set -e; \
    { /bin/bash -x ./install.sh 2>&1 | tee install.log; } || { \
      echo "===== install.sh failed, printing its content ====="; \
      cat ./install.sh; \
      echo "===== install.log output below ====="; \
      cat install.log; \
      exit 1; \
    }

RUN pip install notebook

ENV CMDSTAN_VERSION=2.33.1
RUN mkdir -p /opt && \
    cd /opt && \
    wget https://github.com/stan-dev/cmdstan/releases/download/v${CMDSTAN_VERSION}/cmdstan-${CMDSTAN_VERSION}.tar.gz && \
    tar -xzf cmdstan-${CMDSTAN_VERSION}.tar.gz && \
    rm cmdstan-${CMDSTAN_VERSION}.tar.gz && \
    cd cmdstan-${CMDSTAN_VERSION} && \
    make build -j"$(nproc)"
ENV PATH="/opt/cmdstan-${CMDSTAN_VERSION}:${PATH}"

ENTRYPOINT ["/bin/bash"]