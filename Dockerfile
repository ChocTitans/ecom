FROM php:8.1-apache

# Install required PHP extensions and other dependencies
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libzip-dev \
    unzip \
    zip \
    git \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif \
    && docker-php-ext-enable \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif


# Enable apache mods and rewrite for Laravel
RUN a2enmod rewrite

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

COPY . .
# Install PHP dependencies with Composer
RUN composer install

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Laravel artisan and composer commands
RUN su - www-data -s /bin/bash -c 'php /var/www/html/artisan bagisto:install' 

EXPOSE 80

# Start the apache server in the foreground
CMD ["apache2-foreground"]