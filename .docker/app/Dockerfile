ARG version_php

FROM php:${version_php}-fpm
ARG version_php
ARG version_xdebug
ARG version_node
ARG version_jsignpdf

ENV VERSION_XDEBUG=${version_xdebug}
ENV VERSION_NODE=${version_node}
ENV VERSION_JSIGNPDF=${version_jsignpdf}

RUN apt-get update

RUN apt-get install -y \
        git \
        libicu-dev \
        libzip-dev \
        procps \
        rsync \
        unzip \
        && docker-php-ext-install opcache \
        && docker-php-ext-install zip

# Install PostgreSQL
RUN apt-get install -y \
        libpq-dev \
        && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
        && docker-php-ext-install pdo pdo_pgsql pgsql

# Install Redis
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Memcached
RUN apt-get install -y libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

# Install APCu
RUN pecl install apcu \
    && docker-php-ext-enable apcu

# Install MySQL
RUN docker-php-ext-configure mysqli -with-mysqli=mysqlnd \
    && docker-php-ext-configure pdo_mysql -with-pdo-mysql=mysqlnd \
    && docker-php-ext-install pdo pdo_mysql mysqli

# Install GD
RUN apt-get install -y \
        libfreetype6-dev \
        libjpeg62-turbo-dev \
        libpng-dev \
        libxpm-dev

RUN docker-php-ext-configure gd --with-freetype=/usr/include/ \
                                --with-jpeg=/usr/include/ \
                                --with-xpm=/usr/include/ \
                                --enable-gd-jis-conv \
    && docker-php-ext-install gd

# Install Imagick
RUN apt-get install -y libmagickwand-dev
RUN pecl install \
    imagick
RUN docker-php-ext-enable imagick
RUN sed -i'' 's|.*<policy domain="coder".*"PDF".*|<policy domain="coder" rights="read \| write" pattern="PDF" />|g' /etc/ImageMagick-6/policy.xml

# Install intl
RUN docker-php-ext-install intl

# Install pcntl
RUN docker-php-ext-install pcntl

# Install sockets
RUN docker-php-ext-install sockets

# Install bcmath
RUN docker-php-ext-install bcmath

# Install gmp
RUN apt-get install -y libgmp-dev
RUN docker-php-ext-install gmp

# Install xdebug
RUN pecl install xdebug-${VERSION_XDEBUG} \
    && docker-php-ext-enable xdebug

# Install node
RUN curl -fsSL https://deb.nodesource.com/setup_${VERSION_NODE}.x | bash - \
    && apt install --no-install-recommends -y nodejs \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list \
    && apt update \
    && apt install --no-install-recommends yarn \
    && node --version \
    && npm --version \
    && yarn --version

COPY --from=composer /usr/bin/composer /usr/bin/composer

RUN mkdir -p /cfssl ; chown -R www-data:www-data /cfssl
VOLUME /cfssl

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
