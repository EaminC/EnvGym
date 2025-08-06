FROM ubuntu:22.04

# Set noninteractive mode for apt to prevent tzdata prompts
ENV DEBIAN_FRONTEND=noninteractive

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        ca-certificates \
        git \
        bash \
        build-essential \
        wget \
        gnupg \
        lsb-release \
        unzip \
        xz-utils \
        fonts-liberation \
        libasound2 \
        libatk1.0-0 \
        libatk-bridge2.0-0 \
        libcups2 \
        libdbus-1-3 \
        libdrm2 \
        libgbm1 \
        libgtk-3-0 \
        libnss3 \
        libx11-xcb1 \
        libxcomposite1 \
        libxdamage1 \
        libxrandr2 \
        xauth \
        xvfb \
        libxtst6 \
        libxss1 \
        libxext6 \
        libxfixes3 \
        libpango-1.0-0 \
        libpangocairo-1.0-0 \
        libatspi2.0-0 \
        libwayland-client0 \
        libwayland-cursor0 \
        libwayland-egl1 \
        libxkbcommon0 \
        && rm -rf /var/lib/apt/lists/*

# Install Node.js 18.x LTS and npm via NodeSource (recommended method for up-to-date Node.js)
RUN curl -fsSL https://deb.nodesource.com/setup_18.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install latest Deno (optional, for experimental builds)
ENV DENO_INSTALL=/usr/local
RUN curl -fsSL https://deno.land/install.sh | sh && \
    ln -s /usr/local/bin/deno /usr/bin/deno || true

# Verify installations
RUN node -v && npm -v && git --version && deno --version

# Set up working directory
WORKDIR /home/cc/EnvGym/data/darkreader_darkreader

# Copy package.json and package-lock.json first for better caching
COPY package.json package-lock.json* ./

# Install npm dependencies (including dev and optional platform-specific ones)
RUN npm install

# Copy the rest of the source code and configs
COPY . .

# Set environment variables if .env exists (will be handled at runtime or by user as needed)

# Ensure plus symlink exists if building Plus variant
RUN if [ -d darkreader-plus ]; then npm run plus-link; fi

# Build the extension (can override CMD or use these as build/test steps)
# Here we default to a full build to verify the environment
RUN npm run build:all

# Expose build, test, and lint scripts as entrypoints for CI/CD flexibility
CMD ["/bin/bash"]

# Optional: Clean up npm cache to reduce image size
RUN npm cache clean --force

# Set permissions for non-root users if needed (uncomment and adjust as needed)
# RUN chown -R 1000:1000 /home/cc/EnvGym/data/darkreader_darkreader
# USER 1000

# Document environment in labels
LABEL org.opencontainers.image.title="Dark Reader Build Environment (Ubuntu 22.04, Node.js 18, Deno, x86_64, No GPU)" \
      org.opencontainers.image.description="Linux/x86_64 Docker image for building and testing Dark Reader extension. No Safari/macOS/Windows features. Includes Node.js, npm, git, Deno, browsers for headless testing." \
      org.opencontainers.image.source="https://github.com/darkreader/darkreader"