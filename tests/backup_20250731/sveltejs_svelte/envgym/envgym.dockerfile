FROM --platform=linux/amd64 node:20-bullseye

WORKDIR /home/cc/EnvGym/data/sveltejs_svelte

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git wget ca-certificates \
      fonts-liberation libappindicator3-1 libasound2 \
      libatk-bridge2.0-0 libatk1.0-0 libcups2 \
      libdbus-1-3 libdrm2 libgbm1 libnspr4 libnss3 \
      libxcomposite1 libxdamage1 libxrandr2 xdg-utils \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g pnpm@10.4.0

COPY . .

RUN if [ -d "packages/svelte/scripts" ]; then chmod +x packages/svelte/scripts/* || true; fi

RUN pnpm install

RUN npx playwright install

EXPOSE 5173

# Start with a shell for debugging; switch to pnpm run dev after investigation
CMD ["/bin/sh"]