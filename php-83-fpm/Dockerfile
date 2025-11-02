# php-83-fpm/Dockerfile
FROM php:8.3-fpm-alpine

# -- BAGIAN 1: Instal Dependensi OS (APK) --
RUN apk update && apk add --no-cache \
    # Dependensi Database dan Tools
    libpq-dev \
    git \
    # Dependensi Ekstensi PHP
    icu-dev \
    libzip-dev \
    libpng-dev \
    libjpeg-turbo-dev \
    gmp-dev \
    freetype-dev \
    jpeg-dev \
    libsodium-dev \
    # SOLUSI: Tambahkan libxml2-dev di sini
    libxml2-dev \
    \
    && rm -rf /var/cache/apk/*

# -- BAGIAN 2: Konfigurasi dan Instal Ekstensi PHP --
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        intl pdo pdo_mysql pdo_pgsql zip gd sodium \
        bcmath exif pcntl soap gmp \
    \
    && rm -rf /var/cache/apk/*

# Unduh dan Instal Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer