#!/bin/bash
. `pwd`/../.env
php /var/www/scripts/wait-for-db.php
if [ ! -d ".git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION_NEXTCLOUD}" --recurse-submodules -j 4 https://github.com/nextcloud/server /tmp/nextcloud
    rsync -r /tmp/nextcloud/ .
    mkdir data
    chown -R www-data:www-data .
    runuser -u www-data -- php occ maintenance:install --verbose --database=pgsql --database-name=nextcloud_main --database-host=postgres --database-port= --database-user=nextcloud --database-pass=nextcloud --admin-user=${NEXTCLOUD_ADMIN_USER} --admin-pass=${NEXTCLOUD_ADMIN_PASSWORD}
    runuser -u www-data -- php occ config:system:set default_phone_region ${DEFAULT_PHONE_REGION}
fi
php-fpm
