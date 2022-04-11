#!/bin/bash
. `pwd`/../.env
if [ ! -d ".git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION_NEXTCLOUD}" --recurse-submodules -j 4 https://github.com/nextcloud/server /tmp/nextcloud
    rsync -r /tmp/nextcloud/ .
    mkdir data
    chown -R www-data:www-data .
fi
php /var/www/scripts/wait-for-db.php
if [[ ! -f "config/config.php" && ${AUTOINSTALL} -eq 1 ]]; then
    if [[ ! -z ${POSTGRES_HOST} && ! -z ${POSTGRES_DB} && ! -z ${POSTGRES_USER} && ! -z ${POSTGRES_PASSWORD} ]]; then
        runuser -u www-data -- php occ maintenance:install --verbose --database=pgsql --database-name=${POSTGRES_DB} --database-host=${POSTGRES_HOST} --database-port= --database-user=${POSTGRES_USER} --database-pass=${POSTGRES_PASSWORD} --admin-user=${NEXTCLOUD_ADMIN_USER} --admin-pass=${NEXTCLOUD_ADMIN_PASSWORD} --admin-email=${NEXTCLOUD_ADMIN_EMAIL}
    elif [[ ! -z ${MYSQL_HOST} && ! -z ${MYSQL_DATABASE} && ! -z ${MYSQL_USER} && ! -z ${MYSQL_PASSWORD} ]]; then
        runuser -u www-data -- php occ maintenance:install --verbose --database=mysql --database-name=${MYSQL_DATABASE} --database-host=${MYSQL_HOST} --database-port= --database-user=${MYSQL_USER} --database-pass=${MYSQL_PASSWORD} --admin-user=${NEXTCLOUD_ADMIN_USER} --admin-pass=${NEXTCLOUD_ADMIN_PASSWORD} --admin-email=${NEXTCLOUD_ADMIN_EMAIL}
    fi
    runuser -u www-data -- php occ config:system:set default_phone_region ${DEFAULT_PHONE_REGION}
    runuser -u www-data -- php occ config:system:set --value=1 allow_local_remote_servers
fi
php-fpm
