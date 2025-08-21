FROM node:18-bullseye

WORKDIR /home/cc/EnvGym/data/anuraghazra_github-readme-stats

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git \
        vim \
        nano \
    && rm -rf /var/lib/apt/lists/*

RUN corepack enable && corepack prepare yarn@stable --activate

COPY package.json package-lock.json* yarn.lock* ./

RUN npm install express --save

RUN if [ -f package-lock.json ]; then npm ci; else npm install; fi

COPY . .

EXPOSE 3000

ENV NODE_ENV=production

HEALTHCHECK --interval=10s --timeout=3s --start-period=10s --retries=10 CMD curl --fail http://localhost:3000/api/status/up || exit 1

CMD ["node", "api/index.js"]