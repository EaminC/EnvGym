# syntax=docker/dockerfile:1.4
FROM --platform=linux/amd64 node:18-bullseye-slim AS builder

# Set working directory
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui

# Install build dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      python3 \
      python3-pip \
      build-essential \
      ca-certificates \
      git && \
    rm -rf /var/lib/apt/lists/*

# Copy package manifests first for caching
COPY package.json package-lock.json* ./

# Install node modules
RUN npm ci

# Copy rest of the source code
COPY . .

# Build the project (assuming a build script is defined)
RUN npm run build

# Final stage: minimal runtime image
FROM --platform=linux/amd64 node:18-bullseye-slim

# Set working directory
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui

# Install runtime dependencies only
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates \
      python3 \
      python3-pip && \
    rm -rf /var/lib/apt/lists/*

# Copy node_modules and build artifacts from builder
COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui/node_modules ./node_modules
COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui/dist ./dist
COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui/package.json .
COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui/package-lock.json* .

# Copy any other necessary files if needed (e.g. config, scripts)
COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/mui_material-ui/ .

# Default command: launch bash in working directory
CMD ["/bin/bash"]