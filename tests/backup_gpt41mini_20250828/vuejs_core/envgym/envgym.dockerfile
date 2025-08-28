FROM node:22-bullseye

# Set working directory
WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/vuejs_core

# Install Git and curl (for pnpm install script)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        curl \
        ca-certificates \
        bash \
        unzip \
        xz-utils \
        gnupg && \
    rm -rf /var/lib/apt/lists/*

# Install pnpm 10.15.0 globally
RUN npm install -g pnpm@10.15.0

# Verify node, pnpm, git versions
RUN node -v && pnpm -v && git --version

# Configure Git user (placeholder, to be overridden by user if desired)
RUN git config --global user.name "Your Name" && \
    git config --global user.email "you@example.com"

# Clone the repository (optional: if not mounted as volume, otherwise skip)
# RUN git clone https://your.repo.url /home/cc/EnvGym/data-gpt-4.1mini/vuejs_core

# Copy project files into container (assuming build context contains project root)
COPY . .

# Install project dependencies using pnpm
RUN pnpm install

# Expose ports if necessary (e.g., for Vite dev server)
EXPOSE 3000 5173

# Set default shell to bash and start container at project root
CMD ["/bin/bash"]