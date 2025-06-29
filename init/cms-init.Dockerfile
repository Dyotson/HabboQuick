FROM php:8.2-cli

RUN apt-get update && apt-get install -y \
    libcurl4-openssl-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libonig-dev \
    libssl-dev \
    libzip-dev \
    && docker-php-ext-install -j$(nproc) curl gd mbstring pdo_mysql sockets fileinfo zip \
    && docker-php-ext-enable curl gd mbstring pdo_mysql sockets fileinfo zip

COPY cms-init.sh /usr/local/bin/cms-init.sh
RUN chmod +x /usr/local/bin/cms-init.sh

ENTRYPOINT ["/usr/local/bin/cms-init.sh"]
