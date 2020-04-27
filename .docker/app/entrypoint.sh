#!/bin/bash
cd ../
. `pwd`/.env
php .docker/php7/wait-for-db.php
if [ ! -d "nextcloud/.git" ]; then
    git clone https://github.com/nextcloud/server --branch "${VERSION}" nextcloud
    cd nextcloud
    git submodule update --init
    mkdir data
    cp config/config.sample.php config/config.php
    sed -i -e "s/'debug' => false,/'debug' => true,/g" config/config.php
    sed -i -e "s/'instanceid' => '',/'instanceid' => 'd3c944a9a',/g" config/config.php
    cd -
fi
cd nextcloud
php -S 0.0.0.0:"$HTTP_PORT"