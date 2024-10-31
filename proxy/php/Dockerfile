# Use AMD64-compatible NGINX base image
FROM php:8.2.7-fpm-buster

# Set environment variables
ENV PM_MAX_CHILDREN=6 \
    PM_START_SERVERS=3 \
    PM_MIN_SPARE_SERVERS=2 \
    PM_MAX_SPARE_SERVERS=4 \
    MAX_EXECUTION_TIME=1200 \
    PM_MAX_REQUEST=1200 \
    TERMINATE_TIME_OUT=1200 \
    MEMORY_LIMIT=512M \
    UPLOAD_MAX_SIZE=64M \
    TZ=Europe/London

# Set timezone
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone \
    && dpkg-reconfigure --frontend noninteractive tzdata

# Install dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    cron \
    sudo \
    curl \
    nano \
    git \
    g++ \
    libgmp-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libxml2-dev \
    libzip-dev \
    bash \
    bash-completion \
    zsh \
    default-mysql-client \
    linux-headers-amd64 \
    docker.io \
    autoconf \
    make \
    imagemagick \
    libmagickwand-dev \
    procps \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) \
        gd \
        mysqli \
        pdo_mysql \
        pdo_pgsql \
        soap \
        sockets \
        xml \
        gmp \
        zip \
    && docker-php-ext-install exif

# Install and configure Imagick extension
RUN pecl install imagick \
    && docker-php-ext-enable imagick

# Install Redis extension
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Opcache and configure it
RUN docker-php-ext-install opcache \
    && mkdir -p /usr/local/etc/php/conf-docker \
    && { \
        echo "opcache.memory_consumption=128"; \
        echo "opcache.interned_strings_buffer=8"; \
        echo "opcache.max_accelerated_files=4000"; \
        echo "opcache.revalidate_freq=2"; \
        echo "opcache.fast_shutdown=1"; \
    } > /usr/local/etc/php/conf-docker/opcache.ini

# Install Composer
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

# Modify the default PHP-FPM www.conf file
RUN sed -i "s/pm.max_children = 5/pm.max_children = ${PM_MAX_CHILDREN}/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/pm.start_servers = 2/pm.start_servers = ${PM_START_SERVERS}/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/pm.min_spare_servers = 1/pm.min_spare_servers = ${PM_MIN_SPARE_SERVERS}/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/pm.max_spare_servers = 3/pm.max_spare_servers = ${PM_MAX_SPARE_SERVERS}/g" /usr/local/etc/php-fpm.d/www.conf \
    && sed -i "s/;pm.max_requests = 500/pm.max_requests = ${PM_MAX_REQUEST}/g" /usr/local/etc/php-fpm.d/www.conf

# Memory and Upload Configurations (php-memlimit.ini)
RUN if [ ! -d "/usr/local/etc/php/conf-docker" ]; then \
        mkdir -p /usr/local/etc/php/conf-docker; \
    fi && \
    { \
        echo "memory_limit=${MEMORY_LIMIT}"; \
        echo "max_execution_time=${MAX_EXECUTION_TIME}"; \
        echo "upload_max_filesize=${UPLOAD_MAX_SIZE}"; \
        echo "post_max_size=${UPLOAD_MAX_SIZE}"; \
        echo "request_terminate_timeout=${TERMINATE_TIME_OUT}"; \
    } > /usr/local/etc/php/conf-docker/php-memlimit.ini

# FPM Configuration (www.conf)
RUN if [ ! -f "/usr/local/etc/php-fpm.d/www.conf" ]; then \
        touch /usr/local/etc/php-fpm.d/www.conf; \
    fi && \
    { \
        echo "php_admin_value[memory_limit] = ${MEMORY_LIMIT}"; \
        echo "php_value[memory_limit] = ${MEMORY_LIMIT}"; \
        echo "php_value[max_input_time] = ${MAX_EXECUTION_TIME}"; \
        echo "php_value[max_execution_time] = ${MAX_EXECUTION_TIME}"; \
        echo "php_value[upload_max_filesize] = ${UPLOAD_MAX_SIZE}"; \
        echo "php_value[post_max_size] = ${UPLOAD_MAX_SIZE}"; \
    } >> /usr/local/etc/php-fpm.d/www.conf

# Install Xdebug (optional for debugging)
RUN pecl install xdebug \
    && docker-php-ext-enable xdebug \
    && { \
        echo "xdebug.mode=debug"; \
        echo "xdebug.start_with_request=yes"; \
        echo "xdebug.client_host=host.docker.internal"; \
        echo "xdebug.client_port=9003"; \
        echo "xdebug.log=/tmp/xdebug.log"; \
    } > /usr/local/etc/php/conf-docker/xdebug.ini

# Set up working directory
WORKDIR /var/www/html

# Copy application files
COPY . .

# Add entrypoint script
ADD ./proxy/php/entrypoint.sh /

# Add cron
ADD ./proxy/php/cron /etc/cron.d/cron

# Set permissions for storage and cron files
RUN mkdir -p storage \
    && chmod -R 777 storage

# Set permissions for the cron directory and create necessary files
RUN mkdir -p /var/run && touch /var/run/crond.pid \
    && chown root:root /var/run/crond.pid \
    && chmod 0644 /etc/cron.d/cron \
    && crontab -u root /etc/cron.d/cron \
    && chmod u+s /usr/sbin/cron

# Set permissions for the entrypoint script
RUN if [ -f /entrypoint.sh ]; then \
    chmod +x /entrypoint.sh; \
    else \
    echo "Entrypoint script not found!"; \
    fi

# Ensure PHP-FPM config directory has correct permissions
RUN if [ -d /usr/local/etc/php-fpm.d ]; then \
    chown -R root:root /usr/local/etc/php-fpm.d; \
    else \
    echo "PHP-FPM config directory not found!"; \
    fi

# Remove composer.lock if it exists
RUN if [ -f composer.lock ]; then \
    rm -f composer.lock; \
    fi

# Install Composer dependencies
RUN COMPOSER_MIRROR_PATH_REPOS=1 composer install --prefer-dist --no-ansi --no-interaction --no-progress --optimize-autoloader --no-dev

RUN chmod +x ./proxy/php/worker.sh

# Expose port 9000 for PHP-FPM
EXPOSE 9000

# Set the entrypoint script
ENTRYPOINT ["sh", "/entrypoint.sh"]

CMD /bin/bash
