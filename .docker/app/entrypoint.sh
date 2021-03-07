#!/bin/bash
cd ../
. `pwd`/.env
php .docker/app/wait-for-db.php
if [ ! -d "nextcloud/.git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION}" --recurse-submodules -j 4 https://github.com/nextcloud/server nextcloud
    mkdir nextcloud/data
fi
cd nextcloud
php -S 0.0.0.0:"$HTTP_PORT"