FROM ubuntu:22.04

# Set environment variables for non-interactive installs
ENV DEBIAN_FRONTEND=noninteractive
ENV LANG=C.UTF-8

# Set working directory inside the container to the project root
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/CrossPrefetch

# Update and install essential build tools and dependencies compatible with x86_64
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    wget \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy the entire project into the container working directory
COPY . /home/cc/EnvGym/data-gpt-4.1mini/CrossPrefetch

# Install any Python dependencies if requirements.txt exists
RUN if [ -f requirements.txt ]; then python3 -m pip install --no-cache-dir -r requirements.txt; fi

# Build the project using all available CPU cores (make -j$(nproc))
# Assuming the project uses a Makefile or cmake; adjust commands accordingly

# If there is a CMakeLists.txt, configure and build
RUN if [ -f CMakeLists.txt ]; then \
      mkdir -p build && cd build && \
      cmake .. && \
      make -j$(nproc); \
    fi

# Alternatively, if a Makefile exists in the root
RUN if [ -f Makefile ] && [ ! -f CMakeLists.txt ]; then \
      make -j$(nproc); \
    fi

# Set environment variables if needed (none GPU related)

# Set entrypoint to bash shell at the project root directory
ENTRYPOINT ["/bin/bash"]
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/CrossPrefetch