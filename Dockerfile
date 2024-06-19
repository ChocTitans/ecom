FROM php:8.1-apache

# Install required PHP extensions
RUN apt-get update && apt-get install -y \
    libicu-dev \
    libpq-dev \
    libzip-dev \
    unzip \
    zip \
    && docker-php-ext-install \
    intl \
    calendar \
    pdo_mysql

# Enable apache mods and rewrite for Laravel
RUN a2enmod rewrite

# Install Composer globally
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Set working directory
WORKDIR /var/www/html

# Copy existing application directory contents
COPY . /var/www/html

# Copy the PHP configuration file
COPY php.ini /usr/local/etc/php/

# Set bash as the default shell during build
SHELL ["/bin/bash", "-c"]

# Install composer dependencies
RUN composer install

# Add the additional CMDs to be run on container start
CMD service apache2 start && \
    su - www-data -s /bin/bash -c 'php /var/www/html/bagisto/artisan migrate' && \
    su - www-data -s /bin/bash -c 'php /var/www/html/bagisto/artisan db:seed' && \
    su - www-data -s /bin/bash -c 'php /var/www/html/bagisto/artisan vendor:publish' && \
    su - www-data -s /bin/bash -c 'php /var/www/html/bagisto/artisan storage:link' && \
    su - www-data -s /bin/bash -c 'composer dump-autoload -d /var/www/html/bagisto' && \
    tail -f /dev/null

EXPOSE 80