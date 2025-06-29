FROM node:lts-alpine

RUN apk add --no-cache \
    git \
    wget \
    unzip \
    bash \
    curl \
    python3 \
    py3-pip

# Instalar habbo-downloader globalmente
RUN npm install -g habbo-downloader

WORKDIR /assets

# Script para descargar todos los assets automáticamente
COPY download-assets.sh /download-assets.sh
RUN chmod +x /download-assets.sh

ENTRYPOINT ["/download-assets.sh"]
