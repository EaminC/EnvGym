FROM --platform=linux/amd64 node:20-bullseye

WORKDIR /home/cc/EnvGym/data/expressjs_express

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      git \
      redis-server \
    && rm -rf /var/lib/apt/lists/*

RUN npm install -g express-generator@4

COPY .npmrc package.json ./

# Ensure start script is present and matches existing index.js
RUN node -e "let p=require('./package.json');p.scripts=p.scripts||{};p.scripts.start='node index.js';require('fs').writeFileSync('package.json',JSON.stringify(p,null,2));"

RUN npm install

COPY . .

EXPOSE 3000

CMD service redis-server start && node index.js