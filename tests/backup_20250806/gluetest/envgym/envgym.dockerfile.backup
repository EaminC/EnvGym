FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV WORKDIR=/home/cc/EnvGym/data/gluetest

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        curl \
        git \
        unzip \
        zip \
        wget \
        ca-certificates \
        bash \
        openssl \
        libssl-dev \
        zlib1g-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        llvm \
        libncursesw5-dev \
        xz-utils \
        tk-dev \
        libxml2-dev \
        libxmlsec1-dev \
        libffi-dev \
        liblzma-dev \
        software-properties-common \
        maven \
        python3-venv \
        python3-pip \
        python3-setuptools \
        python3-distutils \
    && rm -rf /var/lib/apt/lists/*

# Create workdir
RUN mkdir -p $WORKDIR
WORKDIR $WORKDIR

# Install GraalVM Community Edition Java 17 (with Python support) directly from GitHub releases
ENV GRAALVM_VERSION=22.3.2
ENV GRAALVM_DIST=graalvm-ce-java17-22.3.2
ENV GRAALVM_URL=https://github.com/graalvm/graalvm-ce-builds/releases/download/vm-$GRAALVM_VERSION/graalvm-ce-java17-linux-amd64-$GRAALVM_VERSION.tar.gz

RUN wget -q $GRAALVM_URL && \
    tar -xzf graalvm-ce-java17-linux-amd64-$GRAALVM_VERSION.tar.gz -C /opt && \
    rm graalvm-ce-java17-linux-amd64-$GRAALVM_VERSION.tar.gz && \
    ln -s /opt/$GRAALVM_DIST /opt/graalvm

# Debug: List extracted GraalVM directory to verify structure
RUN ls -l /opt && ls -lR /opt/$GRAALVM_DIST || (echo "Directory /opt/$GRAALVM_DIST does not exist. Listing /opt:" && ls -l /opt && false)

ENV JAVA_HOME=/opt/$GRAALVM_DIST
ENV PATH=$JAVA_HOME/bin:$PATH

# Ensure gu is executable if present
RUN if [ -f "$JAVA_HOME/bin/gu" ]; then chmod +x $JAVA_HOME/bin/gu; fi

# Extra debug: Check gu existence, permissions, and version
RUN ls -l $JAVA_HOME/bin/gu && $JAVA_HOME/bin/gu --version

# Extra debug: Show available components before install and output to file
RUN $JAVA_HOME/bin/gu list | tee /tmp/graalvm_components.txt

# Install additional GraalVM Python dependencies
RUN apt-get update && apt-get install -y --no-install-recommends libz-dev libexpat1 && rm -rf /var/lib/apt/lists/*

# Print contents of graalvm_components.txt for build log clarity
RUN cat /tmp/graalvm_components.txt

# Try to install GraalVM Python component, output error if fails but do NOT stop build
RUN $JAVA_HOME/bin/gu install python || (echo "gu install python failed, showing help:" && $JAVA_HOME/bin/gu --help)

# Verify graalpython is available if installed
RUN if [ -f "$JAVA_HOME/bin/graalpython" ]; then $JAVA_HOME/bin/graalpython --version; else echo "graalpython not available"; fi

# Install pyenv
ENV PYENV_ROOT=/root/.pyenv
ENV PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH
RUN curl https://pyenv.run | bash

# Install Python 3.11.4 via pyenv
RUN bash -c "export PATH=$PYENV_ROOT/bin:$PYENV_ROOT/shims:$PATH && \
    pyenv install 3.11.4 && \
    pyenv global 3.11.4"

# Set python3 and pip3 symlinks to pyenv Python
RUN ln -sf /root/.pyenv/versions/3.11.4/bin/python3 /usr/local/bin/python3 && \
    ln -sf /root/.pyenv/versions/3.11.4/bin/pip3 /usr/local/bin/pip3

# Upgrade pip
RUN python3 -m pip install --upgrade pip

# Set up Python virtual environment in the repo
RUN python3 -m venv venv

# Install pytest explicitly (redundant if in requirements.txt, but ensures availability)
RUN . venv/bin/activate && pip install pytest

# Copy all project files into the workdir
COPY . $WORKDIR

# Ensure run.sh is executable if present
RUN if [ -f run.sh ]; then chmod +x run.sh; fi

# Default to bash shell
SHELL ["/bin/bash", "-c"]

# Entrypoint to interactive shell in workdir
CMD ["/bin/bash"]