FROM --platform=linux/amd64 ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PONYUP_HOME=/root/.local/share/ponyup
ENV PATH="/root/.local/share/ponyup/bin:$PATH"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      tzdata \
    && rm -rf /var/lib/apt/lists/*

RUN ln -fs /usr/share/zoneinfo/Etc/UTC /etc/localtime && dpkg-reconfigure -f noninteractive tzdata

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      clang \
      curl \
      g++ \
      git \
      make \
      python3 \
      python3-pip \
      python3-venv \
      build-essential \
      cmake \
      tar \
      xz-utils \
      libssl3 \
      libcurl4 \
      zlib1g \
      libzstd1 \
      liblzma5 \
      libgssapi-krb5-2 \
      libkrb5-3 \
      lsb-release \
      lldb \
      bash \
      coreutils \
      file \
      gnupg \
      wget \
      locales \
      jq \
      sudo \
      dnsutils \
      iputils-ping \
      netcat-openbsd \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends libc6

RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen && \
    update-locale LANG=en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN echo "=== System diagnostics ===" && \
    lsb_release -a || true && \
    uname -a && \
    date && \
    echo "ca-certificates version:" && apt-cache policy ca-certificates && \
    echo "curl version:" && curl --version && \
    echo "clang version:" && clang --version && \
    echo "g++ version:" && g++ --version && \
    echo "tar version:" && tar --version && \
    echo "xz-utils version:" && xz --version && \
    echo "bash version:" && bash --version

ENV PONYUP_INIT_COMMIT=94adbb1b642e2a6b7c9c4eadc45e5c9e775b8115

RUN set -euxo pipefail; \
    echo "==== Downloading pinned ponyup-init.sh ===="; \
    curl --proto '=https' --tlsv1.2 -fsSL -o /tmp/ponyup-init.sh https://raw.githubusercontent.com/ponylang/ponyup/${PONYUP_INIT_COMMIT}/ponyup-init.sh; \
    echo "==== ponyup-init.sh first 40 lines ===="; head -40 /tmp/ponyup-init.sh || true; \
    echo "==== Checking file type of ponyup-init.sh ===="; file /tmp/ponyup-init.sh; \
    chmod +x /tmp/ponyup-init.sh; \
    echo "==== Checking if bash, curl, and coreutils are present ===="; \
    bash --version; \
    curl --version; \
    ls --version; \
    file --version; \
    wget --version; \
    mkdir -p /root/.local/share/ponyup; \
    ls -ld /root/.local/share/ponyup; \
    export HOME="/root"; export USER="root"; \
    echo "==== Checking network connectivity ===="; \
    nslookup github.com || (echo "nslookup failed"; exit 10); \
    ping -c 2 github.com || (echo "ping failed"; exit 11); \
    nc -zvw5 github.com 443 || (echo "nc failed"; exit 12); \
    echo "==== Running ponyup-init.sh (full output below) ===="; \
    ( /bin/bash -l /tmp/ponyup-init.sh 2>&1 | tee /tmp/ponyup-install.log ) || (cat /tmp/ponyup-install.log; exit 1); \
    cat /tmp/ponyup-install.log || true; \
    echo "==== Checking for ponyup binary ===="; \
    if [ ! -f /root/.local/share/ponyup/bin/ponyup ]; then \
      echo "ponyup binary not found after install (install failed or path changed)"; \
      ls -lR /root/.local/share/ponyup || true; \
      exit 2; \
    fi

RUN if [ -f /tmp/ponyup-install.log ]; then cat /tmp/ponyup-install.log; fi

RUN /root/.local/share/ponyup/bin/ponyup --version || (echo "ponyup failed to run"; exit 3)

ENV PATH="/root/.local/share/ponyup/bin:$PATH"

RUN python3 -m ensurepip --upgrade || true

RUN python3 -m pip install --upgrade pip setuptools wheel

RUN python3 -m pip install --no-cache-dir cloudsmith-cli
RUN python3 -m pip install --no-cache-dir mkdocs

WORKDIR /workspace
COPY . /workspace

ENV PATH="/root/.local/share/ponyup/bin:$PATH"

CMD ["/bin/bash"]