# syntax=docker/dockerfile:1
FROM --platform=linux/amd64 node:alpine AS builder

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/expressjs_express

COPY package*.json ./
RUN npm install

COPY . .

FROM --platform=linux/amd64 node:alpine

RUN apk add --no-cache bash

WORKDIR /home/cc/EnvGym/data-gpt-4.1mini/expressjs_express

COPY --from=builder /home/cc/EnvGym/data-gpt-4.1mini/expressjs_express .

ENV PORT=3000

EXPOSE 3000

CMD ["/bin/bash"]