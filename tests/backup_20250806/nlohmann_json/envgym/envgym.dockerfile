FROM ubuntu:22.04

# Set non-interactive frontend
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    wget \
    curl \
    ca-certificates \
    build-essential \
    git \
    unzip \
    python3.10 \
    python3.10-venv \
    python3-pip \
    python3-setuptools \
    python3-wheel \
    python3-distutils \
    python3-dev \
    make \
    cmake \
    meson \
    ninja-build \
    lcov \
    valgrind \
    gdb \
    astyle \
    cppcheck \
    clang-tidy \
    clang-format \
    clang \
    pkg-config \
    nodejs \
    npm \
    xz-utils \
    && rm -rf /var/lib/apt/lists/*

# Set default python3 to python3.10
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

# Install Bazelisk (for Bazel version management)
RUN curl -L -o /usr/local/bin/bazelisk https://github.com/bazelbuild/bazelisk/releases/download/v1.19.0/bazelisk-linux-amd64 && \
    chmod +x /usr/local/bin/bazelisk && \
    ln -s /usr/local/bin/bazelisk /usr/local/bin/bazel

# Install latest CMake (>=3.28) from Kitware APT repo for C++ modules if needed
RUN wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null && \
    apt-add-repository 'deb https://apt.kitware.com/ubuntu/ jammy main' && \
    apt-get update && \
    apt-get install -y --no-install-recommends cmake=3.28.* || true

# Install mkcert
RUN apt-get update && apt-get install -y --no-install-recommends mkcert libnss3-tools && rm -rf /var/lib/apt/lists/*

# Install Python user packages for project tooling (MkDocs, etc.)
RUN pip3 install --upgrade pip setuptools wheel
RUN pip3 install --no-cache-dir \
    mkdocs \
    mkdocs-material \
    mkdocs-redirects \
    mkdocs-static-i18n \
    mkdocs-gen-files \
    mkdocs-literate-nav \
    mkdocs-minify-plugin \
    mkdocs-section-index \
    mkdocs-git-revision-date-localized-plugin \
    mkdocs-git-authors-plugin \
    mkdocs-autorefs \
    mkdocs-macros-plugin \
    markdown-include \
    markdown-exec \
    markdownify \
    pygments \
    lxml \
    cpplint \
    pytest \
    coverage \
    black \
    flake8 \
    mypy \
    reuse \
    pyyaml \
    requests

# Create user and set up working directory
RUN useradd -m cc
RUN mkdir -p /home/cc/EnvGym/data/nlohmann_json
WORKDIR /home/cc/EnvGym/data/nlohmann_json
RUN chown -R cc:cc /home/cc/EnvGym

USER cc

# Set up Python venv for the project
RUN python3 -m venv /home/cc/EnvGym/data/nlohmann_json/.venv
ENV PATH="/home/cc/EnvGym/data/nlohmann_json/.venv/bin:$PATH"

# Copy rest of the repo if building with context
COPY --chown=cc:cc . /home/cc/EnvGym/data/nlohmann_json

# Set entrypoint to bash shell at repo root
ENTRYPOINT ["/bin/bash"]