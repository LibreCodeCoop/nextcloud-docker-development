#!/bin/bash
. `pwd`/../.env
php /var/www/scripts/wait-for-db.php
if [ ! -d ".git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION}" --recurse-submodules -j 4 https://github.com/nextcloud/server /tmp/nextcloud
    rsync -r /tmp/nextcloud/ .
    mkdir data
    chown -R www-data:www-data .
fi
php-fpm
