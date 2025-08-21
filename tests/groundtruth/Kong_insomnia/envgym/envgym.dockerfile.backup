FROM --platform=linux/amd64 ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22.14.0

# Install system dependencies and Node.js via NodeSource
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl \
      wget \
      git \
      ca-certificates \
      build-essential \
      libfontconfig-dev \
      libstdc++6 \
      xz-utils \
      openssl \
      libssl-dev \
      gnupg2 \
      lsb-release \
      tzdata \
      sudo && \
    curl -fsSL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    rm -rf /var/lib/apt/lists/*

# Install mkcert (from GitHub releases)
RUN curl -L -o /usr/local/bin/mkcert https://github.com/FiloSottile/mkcert/releases/download/v1.4.4/mkcert-v1.4.4-linux-amd64 && \
    chmod +x /usr/local/bin/mkcert && \
    mkcert --version

# Set working directory to project root
WORKDIR /home/cc/EnvGym/data/Kong_insomnia

# Copy root package files and all packages for workspace install
COPY package.json package-lock.json ./
COPY .nvmrc ./
COPY packages ./packages

# Install Node.js dependencies (root and workspaces)
RUN npm ci

# Install Playwright browsers
RUN npx playwright install --with-deps

# Install node-pre-gyp binary for native module rebuilds
RUN npx node-pre-gyp install --update-binary --directory node_modules/@getinsomnia/node-libcurl || true

# Optionally, run patch-package if used in postinstall
RUN if [ -f node_modules/.bin/patch-package ]; then npx patch-package; fi

# Ensure mkcert root CA is installed
RUN mkcert -install

# Set environment variables for consistent builds (optional, adjust as needed)
ENV NODE_ENV=development
ENV PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0

# Copy the rest of the source code
COPY . .

# Install dependencies in the insomnia workspace explicitly
WORKDIR /home/cc/EnvGym/data/Kong_insomnia/packages/insomnia
RUN npm ci

# Set working directory back to project root
WORKDIR /home/cc/EnvGym/data/Kong_insomnia

# Temporarily start a shell for debugging; after fixing the root cause, change this back to `npm run dev`
CMD [ "bash" ]