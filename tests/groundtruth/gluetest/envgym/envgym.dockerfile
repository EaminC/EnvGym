# Base image: Ubuntu 22.04 for compatibility
FROM ubuntu:22.04

# Set non-interactive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Install required dependencies
RUN apt-get update && apt-get install -y \
    curl \
    zip \
    unzip \
    git \
    maven \
    python3.11 \
    python3.11-venv \
    python3.11-distutils \
    python3-pip \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Set Python 3.11 as default python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1 && \
    update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1

# Install pytest for Python tests
RUN python -m pip install --upgrade pip && \
    python -m pip install pytest

# Install SDKMAN
RUN curl -s "https://get.sdkman.io" | bash
ENV SDKMAN_DIR="/root/.sdkman"
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk install java 17.0.7-graal"

# Set GraalVM as default java
ENV PATH="$SDKMAN_DIR/candidates/java/current/bin:$PATH"

# Install GraalPython
RUN gu install python

# Copy repo into container
WORKDIR /gluetest
COPY . /gluetest

# Default command: run the full test script
CMD ["bash", "run.sh"]
