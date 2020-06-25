#!/bin/bash
cd ../
. `pwd`/.env
php .docker/app/wait-for-db.php
if [ ! -d "nextcloud/.git" ]; then
    git clone https://github.com/nextcloud/server --branch "${VERSION}" nextcloud
    cd nextcloud
    git submodule update --init
    mkdir data
    cd -
fi
cd nextcloud
php -S 0.0.0.0:"$HTTP_PORT"