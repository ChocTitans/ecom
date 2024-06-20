FROM php:8.1-apache


# Install required PHP extensions and other dependencies
RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libwebp-dev \
    git \
    zip \
    unzip \
    libfontconfig1-dev \
    xclip \
    libpng-dev \
    && docker-php-ext-configure gd --enable-gd --with-webp --with-jpeg --with-freetype \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-install \
    intl \
    calendar \
    pdo_mysql \
    gd \
    exif \
    pcntl \
    ldap \
    sysvmsg \
    zip \
    && docker-php-ext-enable \
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
# Install PHP dependencies with Composer
RUN composer create

# Set permissions for Laravel
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html/storage \
    && chmod -R 755 /var/www/html/bootstrap/cache

# Run Laravel artisan and composer commands

EXPOSE 8000

# Start the apache server in the foreground
CMD ["apache2-foreground"]