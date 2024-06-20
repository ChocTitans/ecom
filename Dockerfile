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
RUN php artisan migrate
RUN php artisan db:seed
RUN php artisan vendor:publish
RUN php artisan storage:link
RUN composer dump-autoload

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Laravel artisan and composer commands

VOLUME ["/var/www/html"]

EXPOSE 8000

# Start the apache server in the foreground
CMD ["apache2-foreground"]