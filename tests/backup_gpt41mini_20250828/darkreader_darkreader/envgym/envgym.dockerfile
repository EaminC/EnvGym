FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=18.17.1
ENV DENO_VERSION=1.42.3
ENV PYTHON_VERSION=3.10

WORKDIR /darkreader_darkreader

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    git \
    python3 python3-distutils python3-venv python3-pip \
    build-essential \
    software-properties-common \
    gnupg2 \
    unzip \
    wget \
    xz-utils \
    locales \
    bash-completion \
    dumb-init \
    procps \
    fontconfig \
    chromium-browser \
    firefox \
    thunderbird \
    && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

RUN curl -fsSL https://deb.nodesource.com/setup_18.x -o nodesource_setup.sh && \
    bash nodesource_setup.sh && \
    rm nodesource_setup.sh

RUN apt-get update && apt-get install -y nodejs && \
    node -v && npm -v

# Removed npm global update step due to build failure

RUN npm install -g typescript && tsc -v
RUN npm install -g ts-node && ts-node --version
RUN npm install -g yarn && yarn --version

RUN curl -fsSL https://deno.land/install.sh | DENO_INSTALL=/usr/local sh
RUN ln -s /usr/local/bin/deno /usr/bin/deno
RUN deno --version

RUN echo "fs.file-max = 65535" >> /etc/sysctl.conf

COPY . /darkreader_darkreader

RUN chown -R root:root /darkreader_darkreader \
    && chmod -R u+rwX /darkreader_darkreader

WORKDIR /darkreader_darkreader

RUN npm ci --max-old-space-size=4096

ENV NODE_OPTIONS="--max-old-space-size=4096"

ENTRYPOINT ["dumb-init", "--"]

CMD ["/bin/bash"]