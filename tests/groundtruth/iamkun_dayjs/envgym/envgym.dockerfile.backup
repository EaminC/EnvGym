# syntax=docker/dockerfile:1.4

FROM --platform=linux/amd64 node:18-bullseye-slim

# Set working directory to project root
WORKDIR /home/cc/EnvGym/data/iamkun_dayjs

# Install essential tools (git, vim, nano, curl, etc.)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      vim \
      nano \
      curl \
      ca-certificates \
      bash \
      build-essential \
      && rm -rf /var/lib/apt/lists/*

# Copy package files first for efficient Docker cache usage
COPY package.json package-lock.json ./

# Install npm dependencies with reproducible install
RUN npm ci

# Copy all project files (excluding files/directories in .dockerignore)
COPY . .

# Verify node and npm versions, ensure >=14.x and npm >=6.x
RUN node -v && npm -v

# Ensure all shell scripts are executable (if any pre-commit or build scripts exist)
RUN find . -type f -name "*.sh" -exec chmod +x {} \; || true

# Set default user (optional, can be root if permissions are OK)
# USER cc

# Set default command to bash, or override in docker-compose or CLI as needed
CMD ["bash"]