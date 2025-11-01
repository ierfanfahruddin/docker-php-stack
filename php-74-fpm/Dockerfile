# php-74-fpm/Dockerfile
FROM php:7.4-fpm-alpine

# Instal ekstensi yang dibutuhkan (MySQL dan PostgreSQL)
RUN apk add --no-cache libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql \
    && rm -rf /var/cache/apk/*