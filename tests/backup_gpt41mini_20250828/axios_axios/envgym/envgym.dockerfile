FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive \
    NODE_VERSION=16 \
    YARN_VERSION=1.22.19 \
    PNPM_VERSION=7.29.0 \
    BUN_VERSION=0.5.9 \
    HUSKY=1

WORKDIR /axios_axios

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg2 \
    git \
    build-essential \
    python3 \
    python3-pip \
    python3-setuptools \
    unzip \
    wget \
    software-properties-common \
    apt-transport-https \
    lsb-release \
    libnss3 \
    libatk1.0-0 \
    libatk-bridge2.0-0 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    libgbm1 \
    libasound2 \
    libpangocairo-1.0-0 \
    libpango-1.0-0 \
    libgtk-3-0 \
    libatspi2.0-0 \
    libdrm2 \
    libxshmfence1 \
    libwayland-client0 \
    libwayland-cursor0 \
    libwayland-egl1 \
    libxkbcommon0 \
    xdg-utils \
    mesa-utils \
    firefox \
    chromium-browser

RUN curl https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > microsoft.gpg && \
    install -o root -g root -m 644 microsoft.gpg /etc/apt/trusted.gpg.d/ && \
    rm microsoft.gpg

RUN echo "deb [arch=amd64] https://packages.microsoft.com/repos/edge stable main" > /etc/apt/sources.list.d/microsoft-edge.list

RUN apt-get update && apt-get install -y microsoft-edge-stable && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://deb.nodesource.com/setup_16.x | bash - && \
    apt-get install -y nodejs && \
    node --version && npm --version

RUN npm install -g yarn@"$YARN_VERSION"

RUN npm install -g pnpm@"$PNPM_VERSION"

RUN curl -fsSL https://bun.sh/install | bash && \
    ln -sf /root/.bun/bin/bun /usr/local/bin/bun

ENV PATH=$PATH:/root/.bun/bin

RUN node -v && npm -v && yarn -v && pnpm -v && bun --version

COPY package.json package-lock.json ./
COPY . .

RUN git config --global user.email "you@example.com" && git config --global user.name "Your Name"

RUN npm ci --verbose && npx husky install && npm run prepare:hooks

RUN chown -R root:root /axios_axios

CMD ["/bin/bash"]