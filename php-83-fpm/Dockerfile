# php-83-fpm/Dockerfile
FROM php:8.3-fpm-alpine

# Instal ekstensi yang dibutuhkan (MySQL dan PostgreSQL)
RUN apk add --no-cache libpq-dev \
    && docker-php-ext-install pdo pdo_mysql pdo_pgsql \
    && rm -rf /var/cache/apk/*