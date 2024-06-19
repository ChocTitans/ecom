# Use the official PHP image as a base
FROM php:8.1-apache

# Set working directory
WORKDIR /var/www/html

# Enable Apache mod_rewrite
RUN a2enmod rewrite

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    unzip \
    libpng-dev \
    libonig-dev \
    libxml2-dev \
    libzip-dev \
    zip

# Install PHP extensions
RUN docker-php-ext-install pdo mbstring zip exif pcntl bcmath gd

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