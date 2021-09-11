ARG version_php=8
ARG version_xdebug=3.0.4
ARG version_node=14
ARG version_jsignpdf=1.6.5

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

# Install xdebug
RUN pecl install xdebug-${XDEBUG_VERSION} \
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

# Install sockets
RUN docker-php-ext-install sockets

# Install bcmath
RUN docker-php-ext-install bcmath

# Install gmp
RUN apt-get install -y libgmp-dev
RUN docker-php-ext-install gmp

ENV NVM_DIR=/opt/nvm
RUN git clone https://github.com/nvm-sh/nvm.git $NVM_DIR
RUN cd $NVM_DIR && \
    git checkout `git describe --abbrev=0 --tags --match "v[0-9]*" $(git rev-list --tags --max-count=1)` && \
    . $NVM_DIR/nvm.sh && \
    nvm install ${NODE_VERSION} && \
    nvm use node && \
    npm install --global yarn
RUN echo "source ${NVM_DIR}/nvm.sh" > $HOME/.bashrc

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install Java and JsignPDF
RUN mkdir -p /usr/share/man/man1
RUN apt-get install -y default-jre
RUN curl -OL https://sourceforge.net/projects/jsignpdf/files/stable/JSignPdf%20${JSIGNPDF_VERSION}/JSignPdf-${JSIGNPDF_VERSION}.zip \
    && unzip JSignPdf-${JSIGNPDF_VERSION}.zip -d /opt \
    && rm JSignPdf-${JSIGNPDF_VERSION}.zip

RUN mkdir -p /cfssl ; chown -R www-data:www-data /cfssl
VOLUME /cfssl

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]
