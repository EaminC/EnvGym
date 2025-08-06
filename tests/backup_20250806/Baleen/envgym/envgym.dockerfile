FROM python:3.11-slim

# System setup
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        bash \
        build-essential \
        wget \
        bzip2 \
        libglib2.0-0 \
        libxext6 \
        libsm6 \
        libxrender1 \
        locales \
        tzdata && \
    rm -rf /var/lib/apt/lists/*

# Configure locale and timezone
RUN echo "en_US.UTF-8 UTF-8" > /etc/locale.gen && \
    locale-gen
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV TZ=UTC

# Set up working directory
RUN mkdir -p /home/cc/EnvGym/data/Baleen
WORKDIR /home/cc/EnvGym/data/Baleen

# Install micromamba (recommended for Docker, x86_64 only) and ensure it's available in PATH
ENV MAMBA_ROOT_PREFIX=/opt/conda
RUN curl -Ls https://micro.mamba.pm/install.sh | bash -x -s -- -b -p /opt/conda
ENV PATH="/opt/conda/bin:${PATH}"
RUN ls -al /opt/conda && ls -al /opt/conda/bin || (cat /opt/conda/.messages.txt || true)

# Copy local source code into image
COPY . .

# Upgrade pip and install dependencies via pip as fallback
RUN python3 -m pip install --upgrade pip && \
    if [ -f "BCacheSim/install/requirements.txt" ]; then \
        python3 -m pip install -r BCacheSim/install/requirements.txt ; \
    fi

# Install JupyterLab via pip
RUN python3 -m pip install jupyterlab

# Ensure required directories exist
RUN mkdir -p runs tmp notebooks/figs data

# Download dataset trace files with provided script
RUN if [ -f "data/get-tectonic.sh" ]; then \
      chmod +x data/get-tectonic.sh && \
      bash data/get-tectonic.sh; \
    fi

# Expose Jupyter port
EXPOSE 8888

# Set default shell for conda environment (if present)
SHELL ["/bin/bash", "-c"]

# Default command: start bash shell
CMD ["/bin/bash"]