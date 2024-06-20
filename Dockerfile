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
    && docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp \
    && docker-php-ext-install -j$(nproc) \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif \
    zip

# Enable apache mods and rewrite for Laravel
RUN a2enmod rewrite

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

COPY . .

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Create and set up entrypoint script
RUN echo '#!/bin/bash' > /usr/local/bin/entrypoint.sh \
    && echo 'set -e' >> /usr/local/bin/entrypoint.sh \
    && echo '' >> /usr/local/bin/entrypoint.sh \
    && echo 'if [ ! -f /var/www/html/storage/installed ]; then' >> /usr/local/bin/entrypoint.sh \
    && echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan migrate"' >> /usr/local/bin/entrypoint.sh \
    && echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan db:seed"' >> /usr/local/bin/entrypoint.sh \
    && echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan vendor:publish --force"' >> /usr/local/bin/entrypoint.sh \
    && echo '    su - www-data -s /bin/bash -c "php /var/www/html/artisan storage:link"' >> /usr/local/bin/entrypoint.sh \
    && echo '    su - www-data -s /bin/bash -c "composer dump-autoload -d /var/www/html"' >> /usr/local/bin/entrypoint.sh \
    && echo '    touch /var/www/html/storage/installed' >> /usr/local/bin/entrypoint.sh \
    && echo 'fi' >> /usr/local/bin/entrypoint.sh \
    && echo '' >> /usr/local/bin/entrypoint.sh \
    && echo 'apache2-foreground' >> /usr/local/bin/entrypoint.sh \
    && chmod +x /usr/local/bin/entrypoint.sh

# Create a volume for /var/www/html
VOLUME ["/var/www/html"]

EXPOSE 8000

# Use the entrypoint script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]