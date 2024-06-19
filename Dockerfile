FROM php:8.1-apache

# Install required PHP extensions and other dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    unzip \
    zip \
    git \
    && docker-php-ext-install \
    intl \
    calendar \
    pdo_mysql \
    && docker-php-ext-enable \
    intl \
    calendar \
    pdo_mysql

# Enable apache mods and rewrite for Laravel
RUN a2enmod rewrite

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Install PHP dependencies with Composer
RUN composer install

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Laravel artisan and composer commands
RUN su - www-data -s /bin/bash -c 'php /var/www/html/artisan migrate' \
    && su - www-data -s /bin/bash -c 'php /var/www/html/artisan db:seed' \
    && su - www-data -s /bin/bash -c 'php /var/www/html/artisan vendor:publish --all' \
    && su - www-data -s /bin/bash -c 'php /var/www/html/artisan storage:link' \
    && su - www-data -s /bin/bash -c 'composer dump-autoload'

EXPOSE 80

# Start the apache server in the foreground
CMD ["apache2-foreground"]