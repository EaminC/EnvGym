FROM ubuntu:22.04

# Set noninteractive frontend for apt
ENV DEBIAN_FRONTEND=noninteractive

# Set working directory
WORKDIR /home/cc/EnvGym/data/exli

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        wget \
        unzip \
        zip \
        gcc \
        mono-mcs \
        sudo \
        emacs \
        vim \
        less \
        build-essential \
        pkg-config \
        libicu-dev \
        firefox \
        ca-certificates \
        software-properties-common \
        locales \
    && rm -rf /var/lib/apt/lists/*

# Set UTF-8 locale
RUN locale-gen en_US.UTF-8 && \
    update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# Install Miniconda (latest x86_64) to /opt/conda
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    conda config --set always_yes yes --set changeps1 no && \
    conda update -q conda && \
    conda clean -afy

# Copy setup.py and prepare-conda-env.sh if present
COPY python/setup.py python/prepare-conda-env.sh ./python/
# Create Conda environment
RUN conda create -y -n exli python=3.9

# Activate conda env by default in bash
RUN echo "conda activate exli" >> ~/.bashrc

# Install SDKMAN for x86_64
ENV SDKMAN_DIR=/opt/sdkman
RUN curl -s "https://get.sdkman.io" | bash && \
    bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && sdk version"

ENV PATH=$SDKMAN_DIR/candidates/java/current/bin:$PATH
ENV PATH=$SDKMAN_DIR/candidates/maven/current/bin:$PATH

# Install Java 8.0.302 (OpenJDK) via SDKMAN
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && \
    sdk install java 8.0.302-open && \
    sdk default java 8.0.302-open"

# Install Maven via SDKMAN and set MAVEN_HOME
ENV MAVEN_VERSION=3.9.6
RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && \
    sdk install maven $MAVEN_VERSION && \
    sdk default maven $MAVEN_VERSION"
ENV MAVEN_HOME=$SDKMAN_DIR/candidates/maven/current

# Ensure MAVEN_HOME is writable
RUN chmod -R a+w $MAVEN_HOME

# Download Geckodriver v0.31.0 (x86_64)
RUN wget -q https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-linux64.tar.gz -O /tmp/geckodriver.tar.gz && \
    tar -xzf /tmp/geckodriver.tar.gz -C /usr/local/bin && \
    chmod +x /usr/local/bin/geckodriver && \
    rm /tmp/geckodriver.tar.gz

# [Optional] Download/Install UniversalMutator, EvoSuite, Randoop, itest framework (x86_64 jars/executables)
# Uncomment and adjust as needed:
# RUN wget -O /opt/evosuite.jar https://github.com/EvoSuite/evosuite/releases/download/v1.2.0/evosuite-1.2.0.jar
# RUN wget -O /opt/randoop.jar https://github.com/randoop/randoop/releases/download/v4.3.2/randoop-all-4.3.2.jar

# [Optional] Build Jacoco Maven Extension from source if needed
# (Assume jacoco-extension/ is in the repo and has a pom.xml)
# COPY jacoco-extension/ ./jacoco-extension/
# RUN bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && \
#     cd jacoco-extension && mvn clean install"

# Set permissions for MAVEN_HOME/lib/ext if needed
RUN mkdir -p $MAVEN_HOME/lib/ext && chmod -R a+w $MAVEN_HOME/lib/ext

# Set default shell to bash
SHELL ["/bin/bash", "-c"]

# Set entrypoint to bash and working directory
ENTRYPOINT ["/bin/bash"]