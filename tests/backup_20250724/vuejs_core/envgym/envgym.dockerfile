FROM --platform=linux/amd64 node:22-bullseye

RUN apt-get update && apt-get install -y git bash wget curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /home/cc/EnvGym/data/vuejs_core

RUN npm install -g pnpm@10.12.4

COPY package.json pnpm-lock.yaml ./

RUN pnpm install --frozen-lockfile

COPY . .

ENV SHELL=/bin/bash
ENV NODE_ENV=development
ENV HOST=0.0.0.0
ENV VITE_HOST=0.0.0.0

EXPOSE 5173

HEALTHCHECK --interval=10s --timeout=5s --start-period=60s --retries=15 CMD wget --spider --quiet http://localhost:5173/ || exit 1

RUN pnpm build || true

RUN pnpm dev & sleep 10 && curl -f http://localhost:5173 || (ls -l /home/cc/EnvGym/data/vuejs_core/vite.config.*; exit 1)

CMD ["pnpm", "dev"]