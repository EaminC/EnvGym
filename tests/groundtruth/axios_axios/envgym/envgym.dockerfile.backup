FROM node:18-bullseye

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    TZ=Etc/UTC

# Set working directory
WORKDIR /home/cc/EnvGym/data/axios_axios

# Install system dependencies: git, chromium, firefox, and other dev tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      ca-certificates \
      curl \
      wget \
      gnupg \
      build-essential \
      python3 \
      python3-pip \
      chromium \
      chromium-driver \
      firefox-esr \
      xvfb \
      xauth \
      fonts-liberation \
      libappindicator3-1 \
      libasound2 \
      libatk-bridge2.0-0 \
      libatk1.0-0 \
      libcups2 \
      libdbus-1-3 \
      libdrm2 \
      libgbm1 \
      libgtk-3-0 \
      libnspr4 \
      libnss3 \
      libx11-xcb1 \
      libxcomposite1 \
      libxdamage1 \
      libxrandr2 \
      libxss1 \
      libxtst6 \
      lsb-release \
      xdg-utils \
      --no-install-suggests && \
    ln -sf /usr/bin/chromium /usr/bin/chromium-browser && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Optionally install Bower globally (for legacy browser support)
RUN npm install -g bower

# Copy all files (including husky and hooks) before npm ci so scripts can find them
COPY . .

# Install NPM dependencies
RUN npm ci

# Build the project before running tests (if required for tests)
RUN npm run build

# Set environment variable for headless browser testing (Karma, Chromium, Firefox)
ENV CHROME_BIN=/usr/bin/chromium \
    FIREFOX_BIN=/usr/bin/firefox

# Increase node and test process timeout, add more verbosity to help debug
ENV NODE_OPTIONS=--max_old_space_size=4096

# Expose commonly-used test ports for HTTP servers, update as needed for test/server code
EXPOSE 3000 4000 9876

# Add more logging and debugging for test server/network issues
ENV DEBUG=axios:*,test,server

# TEMP: Start an interactive shell for step-by-step debugging, as recommended
CMD ["/bin/bash"]