FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH
ENV PROJECT_ROOT=/home/cc/EnvGym/data-gpt-4.1mini/ELECT

RUN apt-get update && apt-get install -y --no-install-recommends \
    openjdk-11-jdk openjdk-11-jre \
    clang llvm libisal-dev \
    python3 python3-pip python3-setuptools python3-wheel \
    bc iproute2 rsync curl jq ssh sshpass \
    maven ant git sudo systemd systemd-sysv \
    && rm -rf /var/lib/apt/lists/*

# Create user cc with home directory and sudo privileges
RUN useradd -m -s /bin/bash cc && \
    echo "cc ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/cc && \
    chmod 0440 /etc/sudoers.d/cc

USER cc
WORKDIR $PROJECT_ROOT

# Copy project files into container (assumes build context includes project files)
COPY --chown=cc:cc . $PROJECT_ROOT

# Ensure scripts have executable permissions
RUN find $PROJECT_ROOT/scripts -type f -name "*.sh" -exec chmod +x {} \;

# Install Python dependencies if requirements.txt exists
RUN if [ -f "$PROJECT_ROOT/requirements.txt" ]; then pip3 install --user -r $PROJECT_ROOT/requirements.txt; fi

# Set up JAVA_HOME and python3 alternatives explicitly
RUN sudo update-alternatives --install /usr/bin/java java $JAVA_HOME/bin/java 1100 && \
    sudo update-alternatives --install /usr/bin/javac javac $JAVA_HOME/bin/javac 1100 && \
    sudo update-alternatives --install /usr/bin/python python /usr/bin/python3 1 && \
    sudo update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1

# Create necessary directories with correct ownership and permissions
RUN mkdir -p \
    /home/cc/.ssh \
    $PROJECT_ROOT/artifacts \
    $PROJECT_ROOT/scripts \
    $PROJECT_ROOT/src/coldTier/data \
    $PROJECT_ROOT/experiment_backup \
    $PROJECT_ROOT/logs \
    $PROJECT_ROOT/results && \
    chmod 700 /home/cc/.ssh && \
    chmod -R u+rwX $PROJECT_ROOT

# Provide entrypoint to get interactive bash shell at project root
ENTRYPOINT ["/bin/bash"]
WORKDIR $PROJECT_ROOT