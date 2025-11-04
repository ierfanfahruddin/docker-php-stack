# php-74-fpm/Dockerfile
FROM php:7.4-fpm-alpine

# -- Instalasi Dependensi dan Ekstensi PHP dalam satu layer --
RUN apk add --no-cache --virtual .build-deps $PHPIZE_DEPS \
    # Dependensi OS untuk ekstensi
    && apk add --no-cache \
        postgresql-dev \
        libzip-dev \
        libpng-dev \
        libjpeg-turbo-dev \
        freetype-dev \
        icu-dev \
        libxml2-dev \
        gmp-dev \
    # Konfigurasi dan instal ekstensi PHP
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        pdo_mysql pdo_pgsql pgsql \
        gd zip intl soap bcmath exif gmp \
    && docker-php-ext-enable opcache \
    # Hapus build dependencies
    && apk del .build-deps

WORKDIR /var/www/html

# Set correct permissions for the web root.
# Ini dijalankan sebagai CMD terpisah karena /var/www/html adalah volume.
# Perintah ini akan dijalankan setiap kali kontainer dimulai.
CMD chown -R www-data:www-data /var/www/html && php-fpm