FROM ubuntu:22.04

# Set noninteractive frontend for apt to avoid prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8

# Update and install dependencies (sudo removed)
RUN apt-get update --fix-missing && \
    apt-get install -y --no-install-recommends \
        wget \
        curl \
        git \
        ca-certificates \
        build-essential \
        software-properties-common \
        unzip \
        zip \
        tar \
        locales \
        python3-pip \
        python3-dev \
        python3-venv \
        firefox \
        xvfb \
        default-jre \
        default-jdk \
        libgtk-3-0 \
        libdbus-glib-1-2 \
        fonts-liberation \
        libasound2 \
        libnss3 \
        libxss1 \
        libxtst6 \
        libxrandr2 \
        libxcomposite1 \
        libxdamage1 \
        libxfixes3 \
        libxkbcommon0 \
        libxshmfence1 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Set locale (UTF-8) before switching user
RUN locale-gen en_US.UTF-8 && update-locale LANG=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# Set up a non-root user and home directory
ARG USERNAME=itdocker
ARG USER_UID=1000
ARG USER_GID=1000
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m -d /home/$USERNAME -s /bin/bash $USERNAME \
    && usermod -aG sudo $USERNAME \
    && echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install Miniconda (x86_64 only)
ENV CONDA_DIR=/opt/conda
ENV PATH=$CONDA_DIR/bin:$PATH
RUN wget --quiet https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p $CONDA_DIR && \
    rm /tmp/miniconda.sh && \
    $CONDA_DIR/bin/conda clean -afy

# Make conda available for all users
RUN ln -s $CONDA_DIR/etc/profile.d/conda.sh /etc/profile.d/conda.sh

# Set workdir and copy project files (assumes build context is set to project root)
WORKDIR /home/$USERNAME
COPY --chown=$USERNAME:$USERNAME . .

# Install Python environment via environment.yml if present AFTER copying all files
RUN if [ -f /home/$USERNAME/environment.yml ]; then \
        conda env update -f /home/$USERNAME/environment.yml && \
        conda clean -afy ; \
    fi

# Install SDKMAN! for user, then install OpenJDK 8 and Maven (amd64 only)
USER $USERNAME
ENV SDKMAN_DIR="/home/$USERNAME/.sdkman"
ENV PATH="$SDKMAN_DIR/candidates/java/current/bin:$SDKMAN_DIR/candidates/maven/current/bin:$PATH"
RUN curl -s "https://get.sdkman.io" | bash \
    && bash -c "source $SDKMAN_DIR/bin/sdkman-init.sh && \
        sdk install java 8.0.302-open && \
        sdk install maven 3.8.3 && \
        sdk flush archives && sdk flush temp"

# Install Geckodriver (x86_64/amd64 only)
RUN wget --quiet https://github.com/mozilla/geckodriver/releases/download/v0.31.0/geckodriver-v0.31.0-linux64.tar.gz -O /tmp/geckodriver.tar.gz && \
    tar -xzf /tmp/geckodriver.tar.gz -C /tmp && \
    chmod +x /tmp/geckodriver && \
    mkdir -p /home/$USERNAME/.local/bin && \
    mv /tmp/geckodriver /home/$USERNAME/.local/bin/ && \
    rm /tmp/geckodriver.tar.gz

ENV PATH=/home/$USERNAME/.local/bin:$PATH

# Ensure all scripts in the repo are executable (common convention)
RUN find . -type f -name "*.sh" -exec chmod +x {} \;

# Switch to root to fix permissions for nested directories (if needed)
USER root
RUN chown -R $USERNAME:$USERNAME /home/$USERNAME

# Switch back to user
USER $USERNAME
WORKDIR /home/$USERNAME

# Activate conda env if named in environment.yml (replace 'exli' if env is named differently)
SHELL ["/bin/bash", "-c"]
RUN if [ -f environment.yml ] && grep -q "name: exli" environment.yml 2>/dev/null; then \
        echo "conda activate exli" >> ~/.bashrc ; \
    fi

# Default entrypoint
CMD ["/bin/bash"]