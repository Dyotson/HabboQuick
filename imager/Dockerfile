FROM node:18-bullseye AS builder

ARG BRANCH=dev
ARG COMMIT=7ff2405

WORKDIR /app

RUN apt-get update && apt-get install -y \
    git \
    build-essential \
    python3 \
    libcairo2-dev \
    libpango1.0-dev \
    libjpeg-dev \
    libgif-dev \
    librsvg2-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

RUN git clone --branch ${BRANCH} --recurse-submodules https://github.com/billsonnn/nitro-imager.git .
RUN git checkout $COMMIT
RUN yarn install --network-timeout 1000000
RUN yarn build

ENTRYPOINT ["node", "/app/dist/src/main.js"]