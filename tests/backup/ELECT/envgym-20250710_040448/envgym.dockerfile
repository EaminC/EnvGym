FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV USER=cc
ENV HOME=/home/cc
ENV WORKDIR=/home/cc/EnvGym/data/ELECT

# Create user and home directory
RUN useradd -ms /bin/bash cc && \
    mkdir -p $WORKDIR && \
    chown -R cc:cc /home/cc

# Fix for broken/missing OpenJDK 11 in Ubuntu 22.04 minimal images
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        software-properties-common && \
    add-apt-repository universe && \
    apt-get update

# Install Java first to isolate potential issues
RUN apt-get install -y --no-install-recommends openjdk-11-jdk && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Install system dependencies one by one to isolate failures
RUN apt-get update && apt-get install -y --no-install-recommends ant && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends maven && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends clang && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends llvm && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends libisal-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends python3 && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends python3-pip && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends python3-dev && apt-get clean && rm -rf /var/lib/apt/lists/*
# Combine cython install with update to ensure latest package lists
RUN apt-get update && apt-get install -y --no-install-recommends cython3 && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends ansible && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends bc && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends make && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends ssh && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends tar && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends git && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y --no-install-recommends asciidoc && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends curl && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends build-essential && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends npm && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends sudo && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends chrony && apt-get clean && rm -rf /var/lib/apt/lists/*
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install Antora CLI and site generator for documentation
RUN npm install -g @antora/cli @antora/site-generator-default

# Set up passwordless sudo for user cc
RUN echo "cc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cc && chmod 0440 /etc/sudoers.d/cc

USER cc
WORKDIR $WORKDIR

# Copy requirements file if it exists (to leverage Docker cache)
COPY --chown=cc:cc src/elect/pylib/requirements.txt $WORKDIR/src/elect/pylib/requirements.txt

# Upgrade pip and install Python dependencies
RUN python3 -m pip install --upgrade pip && \
    if [ -f src/elect/pylib/requirements.txt ]; then pip install -r src/elect/pylib/requirements.txt; fi && \
    pip install coverage pytest numpy scipy cython wheel

# Install cassandra-driver from PyPI and ccm from GitHub
RUN pip install --no-cache-dir --upgrade cassandra-driver && \
    pip install --no-cache-dir --upgrade git+https://github.com/pcmanus/ccm.git@master

# (Optional) Install Sphinx for documentation if needed
RUN pip install sphinx

# Set up SSH keys for user cc (for key-free access, optional)
RUN [ ! -d "$HOME/.ssh" ] && mkdir -p $HOME/.ssh && chmod 700 $HOME/.ssh || true

# Ensure .m2 directory exists for Maven configuration
RUN mkdir -p $HOME/.m2

# Set up environment variables for all future shells
RUN echo "export JAVA_HOME=$JAVA_HOME" >> $HOME/.bashrc && \
    echo "export PATH=$JAVA_HOME/bin:\$PATH" >> $HOME/.bashrc

# Default command
CMD ["/bin/bash"]