FROM php:8.1-apache

# Install required PHP extensions and other dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    libwebp-dev \
    unzip \
    zip \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --enable-gd --with-freetype --with-jpeg \
    && docker-php-ext-configure gd --with-webp \
    && docker-php-ext-install \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif \
    zip \
    && docker-php-ext-enable \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif \
    zip

RUN docker-php-ext-install -j$(nproc) gd

# Enable apache mods and rewrite for Laravel
RUN a2enmod rewrite

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

COPY . .
# Install PHP dependencies with Composer

ENV COMPOSER_ALLOW_SUPERUSER=1
RUN composer dump-autoload

RUN { \
    echo '#!/bin/bash'; \
    echo 'set -e'; \
    echo ''; \
    echo ''; \
    echo 'if [ ! -f /var/www/html/storage/installed ]; then'; \
    echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan migrate"'; \
    echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan db:seed"'; \
    echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan vendor:publish --force"'; \
    echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan storage:link"'; \
    echo '    touch /var/www/html/storage/installed'; \
    echo 'fi'; \
    echo ''; \
    echo 'apache2-foreground'; \
} > /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Laravel artisan and composer commands

VOLUME ["/var/www/html"]

EXPOSE 8000

# Start the apache server in the foreground
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]