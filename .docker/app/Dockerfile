FROM php:8-fpm

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
RUN pecl install xdebug-3.0.4 \
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
    nvm install 14 && \
    nvm use node && \
    npm install --global yarn
RUN echo "source ${NVM_DIR}/nvm.sh" > $HOME/.bashrc

COPY --from=composer /usr/bin/composer /usr/bin/composer

# Install Java and JsignPDF
RUN mkdir -p /usr/share/man/man1
RUN apt-get install -y default-jre
RUN curl -OL https://sourceforge.net/projects/jsignpdf/files/stable/JSignPdf%201.6.5/JSignPdf-1.6.5.zip \
    && unzip JSignPdf-1.6.5.zip -d /opt \
    && rm JSignPdf-1.6.5.zip

RUN mkdir -p /cfssl ; chown -R www-data:www-data /cfssl
VOLUME /cfssl

COPY config/php.ini /usr/local/etc/php/conf.d/

WORKDIR /var/www/html
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
ENTRYPOINT [ "sh", "/usr/local/bin/entrypoint.sh" ]
