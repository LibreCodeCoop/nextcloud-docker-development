FROM php:7.4-fpm

RUN apt-get update

RUN apt-get install -y \
        git \
        libicu-dev \
        libzip-dev \
        unzip \
        && docker-php-ext-install opcache \
        && docker-php-ext-install zip

# Install PostgreSQL
RUN apt-get install -y \
        libpq-dev \
        && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
        && docker-php-ext-install pdo pdo_pgsql pgsql

# Install xdebug
RUN pecl install xdebug-3.0.3 \
    && docker-php-ext-enable xdebug

# Install Redis
RUN pecl install redis \
    && docker-php-ext-enable redis

# Install Memcached
RUN apt-get install -y libmemcached-dev \
    && pecl install memcached \
    && docker-php-ext-enable memcached

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

# Install intl
RUN docker-php-ext-install intl

# Install pcntl
RUN docker-php-ext-install pcntl

ENV NVM_DIR=/opt/nvm
RUN git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
RUN cd $NVM_DIR && \
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` && \
    . $NVM_DIR/nvm.sh && \
    nvm install 13 && \
    nvm use node && \
    npm install --global yarn
RUN echo "source ${NVM_DIR}/nvm.sh" > $HOME/.bashrc

COPY --from=composer /usr/bin/composer /usr/bin/composer

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/nextcloud
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]
