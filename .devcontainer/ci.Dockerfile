FROM golang:1.16.3-alpine3.13

RUN apk add --no-cache --update nodejs npm make
RUN npm i -g pnpm

WORKDIR /workspace
