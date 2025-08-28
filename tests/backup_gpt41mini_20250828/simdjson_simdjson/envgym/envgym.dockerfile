ARG BASE_IMAGE=ubuntu:22.04
FROM --platform=linux/amd64 ${BASE_IMAGE}

ARG USER_NAME=cc
ARG USER_ID=1000
ARG GROUP_ID=1000

ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8
ENV LC_ALL=C.UTF-8
ENV HOME=/home/${USER_NAME}
ENV PATH=$HOME/.cargo/bin:/usr/local/bin:$PATH

# Create user and group matching host user to avoid permission issues
RUN groupadd --gid ${GROUP_ID} ${USER_NAME} \
 && useradd --uid ${USER_ID} --gid ${GROUP_ID} --create-home --shell /bin/bash ${USER_NAME}

# Enable universe and multiverse repositories explicitly
RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends software-properties-common \
 && add-apt-repository universe \
 && add-apt-repository multiverse

# Split install commands with apt-get update before each to isolate issues

RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends build-essential cmake ninja-build git python3 python3-pip wget curl sudo \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

RUN apt-get update -o Acquire::Retries=3 \
 && apt-get install -y --no-install-recommends libcurl4-openssl-dev linux-perf binutils clang clang++ lld llvm \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Set clang and clang++ as default clang compiler and c++ compiler alternatives
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang 100 \
 && update-alternatives --install /usr/bin/clang++ clang++ /usr/bin/clang++ 100 \
 && update-alternatives --install /usr/bin/cc cc /usr/bin/clang 100 \
 && update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 100

# Install Node.js 16.x (LTS) for compatibility (Ubuntu 22.04 default nodejs is v12)
RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - \
 && apt-get update -o Acquire::Retries=3 \
 && apt-get install -y nodejs \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Clean npm cache
RUN npm cache clean --force

# Configure sudo for the user without password prompt
RUN echo "${USER_NAME} ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/${USER_NAME} \
 && chmod 0440 /etc/sudoers.d/${USER_NAME}

# Create a cache directory for dependencies
RUN mkdir -p $HOME/.dep_cache

# Set working directory to root of the repository
WORKDIR /simdjson_simdjson

# Change to user
USER ${USER_NAME}

# Install Rustup and Rust stable toolchain as user
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --default-toolchain stable --no-modify-path

# Ensure npm version is >=6 (comes with Node.js 16+)
RUN npm install -g npm

# Default shell entrypoint: bash in working directory
CMD ["/bin/bash"]