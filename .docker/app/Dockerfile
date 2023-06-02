ARG version_php

FROM php:${version_php}-fpm
ARG version_php
ARG version_node
ARG host_uid
ARG host_gid
ENV VERSION_NODE=${version_node}

RUN apt-get update \
    && apt-get install -y \
        git \
        libicu-dev \
        libzip-dev \
        procps \
        rsync \
        unzip \
        ghostscript

# cron
RUN apt-get install -y \
        busybox-static \
    && mkdir -p /var/spool/cron/crontabs \
    && echo '*/5 * * * * php -f /var/www/html/cron.php' > /var/spool/cron/crontabs/www-data

RUN usermod --non-unique --uid ${host_uid} www-data \
  && groupmod --non-unique --gid ${host_gid} www-data

# Install PHP extensions
ADD https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions /usr/local/bin/
RUN chmod uga+x /usr/local/bin/install-php-extensions && sync \
    && install-php-extensions \
    apcu \
    bcmath \
    gd \
    gmp \
    exif \
    imagick \
    intl \
    memcached \
    mysqli \
    opcache \
    pcntl \
    pdo \
    pdo_mysql \
    pgsql \
    redis \
    sockets \
    sysvsem \
    xdebug \
    zip \
    && rm /usr/local/bin/install-php-extensions \
    && sed -i'' 's|.*<policy domain="coder".*"PDF".*|<policy domain="coder" rights="read \| write" pattern="PDF" />|g' /etc/ImageMagick-6/policy.xml

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

COPY config/php.ini /usr/local/etc/php/conf.d/


WORKDIR /var/www/html
COPY *.sh /usr/local/bin/
ENTRYPOINT [ "bash", "/usr/local/bin/entrypoint.sh" ]
