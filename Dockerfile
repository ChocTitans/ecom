# Use the official PHP image as a base
FROM php:8.1-apache

# Set working directory
WORKDIR /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Install system dependencies and PHP extensions
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    libicu-dev \
    zlib1g-dev \
    libcurl4-gnutls-dev \
    libjpeg-dev \
    libfreetype6-dev \
    libonig-dev \
    libtidy-dev \
    libxslt1-dev \
    libgmp-dev \
    libpspell-dev \
    locales \
    libbz2-dev \
    libgmp-dev \
    libtidy-dev \
    libcurl4-openssl-dev \
    libxpm-dev \
    libvpx-dev \
    libaspell-dev \
    zip \
    autoconf \
    libc-dev \
    pkg-config \
    libmcrypt-dev \
    && docker-php-ext-install pdo \
    && docker-php-ext-install mysqli \
    && docker-php-ext-install pdo_mysql \
    && docker-php-ext-install calendar \
    && docker-php-ext-install intl \
    && docker-php-ext-install gettext \
    && docker-php-ext-install gd \
    && docker-php-ext-install zip \
    && docker-php-ext-install iconv \
    && docker-php-ext-install exif \
    && docker-php-ext-install opcache \
    && docker-php-ext-install pcntl \
    && docker-php-ext-configure intl \
    && docker-php-ext-enable intl

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Copy existing application directory contents
COPY . .

# Install Bagisto dependencies
RUN composer install

# Run necessary artisan commands
RUN su - www-data -s /bin/bash -c 'php artisan migrate' && \
    su - www-data -s /bin/bash -c 'php artisan db:seed' && \
    su - www-data -s /bin/bash -c 'php artisan vendor:publish --all' && \
    su - www-data -s /bin/bash -c 'php artisan storage:link' && \
    su - www-data -s /bin/bash -c 'composer dump-autoload'

# Give permission to storage and bootstrap cache (if not already set)
RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Expose port 80
EXPOSE 80

# Start Apache server
CMD ["apache2-foreground"]