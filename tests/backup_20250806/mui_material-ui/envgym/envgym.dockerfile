# syntax=docker/dockerfile:1.7
FROM --platform=linux/amd64 node:20.11.1-bullseye-slim

# Set build arguments for non-root user creation (optional, for better security)
ARG USER=muiuser
ARG UID=1000
ARG GID=1000

# Set working directory
WORKDIR /app

# Install system dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        build-essential \
        git \
        python3 \
        python3-pip \
        python3-venv \
        ca-certificates \
        openssh-client \
        curl \
        nano \
        vim \
        && rm -rf /var/lib/apt/lists/*

# Optional: create a non-root user (recommended for dev environments)
RUN groupadd -g $GID $USER && \
    useradd -m -u $UID -g $GID -s /bin/bash $USER

# Copy package manager files and install JS dependencies first for better cache
COPY package.json package-lock.json* yarn.lock* ./

# Install npm dependencies (prefer npm ci if lockfile exists)
RUN if [ -f "package-lock.json" ]; then npm ci --prefer-offline --no-audit; \
    elif [ -f "yarn.lock" ]; then yarn install --frozen-lockfile; \
    else npm install --prefer-offline --no-audit; fi

# Copy the rest of the repository
COPY . .

# Ensure scripts are executable (if you have scripts/)
RUN if [ -d scripts ]; then chmod -R +x scripts; fi

# Build the project (if you have a build step, e.g., for React or TypeScript projects)
# Use all available CPU cores for build tools that support it
RUN if [ -f "package.json" ] && grep -q '"build"' package.json; then \
        if grep -q '"mui-material-ui"' package.json; then \
            npm run build -- --max-old-space-size=2048; \
        else \
            npm run build; \
        fi \
    ; fi

# Expose port (change if your app uses a different port)
EXPOSE 3000

# Switch to non-root user (optional, for dev environments)
USER $USER

# Default command to start the development server (adjust as needed)
CMD ["npm", "start"]