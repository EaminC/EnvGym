FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV NODE_VERSION=22.17.1
ENV ELECTRON_VERSION=37.2.6
ENV PLAYWRIGHT_VERSION=1.51.1
ENV NVM_DIR=/root/.nvm
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

RUN dpkg --add-architecture amd64 \
 && apt-get update \
 && apt-get install -y --no-install-recommends \
      curl \
      ca-certificates \
      git \
      build-essential \
      libfontconfig-dev \
      xz-utils \
      libstdc++6 \
      python3 \
      python3-pip \
      unzip \
      xvfb \
      wget \
      gnupg \
      apt-transport-https \
      software-properties-common \
 && rm -rf /var/lib/apt/lists/*

# Install nvm and Node.js
RUN curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash \
 && . $NVM_DIR/nvm.sh \
 && nvm install $NODE_VERSION \
 && nvm alias default $NODE_VERSION \
 && nvm use default \
 && npm install -g npm@10

# Set node and npm in PATH
ENV NODE_PATH=$NVM_DIR/versions/node/v$NODE_VERSION/lib/node_modules
ENV PATH=$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Create working directory
WORKDIR /workspace

# Copy repo files to container
COPY . /workspace

# Clear Electron cache if any (safe no-op on fresh image)
RUN rm -rf /root/.cache/electron || true

# Install global dependencies needed for Electron and Playwright
RUN npm install -g electron@$ELECTRON_VERSION \
 && npm install -g playwright@$PLAYWRIGHT_VERSION

# Install project dependencies including native modules and run postinstall
RUN npm install

# Fix node-libcurl native binaries for Electron
RUN ./node_modules/.bin/node-pre-gyp install --update-binary --directory node_modules/@getinsomnia/node-libcurl || true

# Install Electron specific libcurl binaries using npm script with target env var
RUN target=$ELECTRON_VERSION npm run install-libcurl-electron || true

# Build insomnia-inso CLI binaries
RUN cd packages/insomnia-inso \
 && npm run prepackage \
 && npm run package \
 && npm run postpackage \
 && npm run artifacts

# Expose environment variables for Playwright headless tests with xvfb-maybe
ENV DISPLAY=:99

# Entrypoint to bash shell at /workspace root
CMD ["/bin/bash"]