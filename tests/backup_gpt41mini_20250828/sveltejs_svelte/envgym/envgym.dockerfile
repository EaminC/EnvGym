FROM --platform=linux/amd64 node:18-bullseye

# Set working directory
WORKDIR /app

# Install Git
RUN apt-get update && apt-get install -y git curl ca-certificates \
  && rm -rf /var/lib/apt/lists/*

# Install pnpm 10.4.0 globally (matching packageManager field)
RUN npm install -g pnpm@10.4.0

# Copy workspace definition early for efficient caching
COPY pnpm-workspace.yaml ./

# Copy package.json and lockfile
COPY package.json pnpm-lock.yaml ./

# Copy .npmrc to disable Playwright browser downloads
COPY .npmrc ./

# Install dependencies
RUN pnpm install --frozen-lockfile

# Copy all source files (assuming context is repo root)
COPY . .

# Set environment variable for node architecture consistency
ENV NODE_ENV=development

# Default command: start a bash shell at /app (repo root)
CMD ["/bin/bash"]