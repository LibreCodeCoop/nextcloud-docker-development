#!/bin/bash

# Set uid of host machine
usermod --non-unique --uid "${HOST_UID}" www-data
groupmod --non-unique --gid "${HOST_GID}" www-data

# Clone Nextcloud repository, if needed
if [ ! -d ".git" ]; then
    git clone --progress --single-branch --depth 1 --branch "${VERSION_NEXTCLOUD}" --recurse-submodules -j 4 https://github.com/nextcloud/server /tmp/nextcloud
    rsync -r /tmp/nextcloud/ .
    mkdir data
    mkdir apps-writable
    mkdir apps-extra
    chown -R www-data:www-data .
fi

# Wait for database
php /var/www/scripts/wait-for-db.php

# Set configurations, if needed
if [[ ! -f "config/config.php" && ${AUTOINSTALL} -eq 1 ]]; then
    echo "⌛️ Starting installation ..."
    if [[ ${DB_HOST} == 'mysql' ]]; then
        occ maintenance:install --verbose --database="${DB_HOST}" --database-name="${MYSQL_DATABASE}" --database-host="${DB_HOST}" --database-port= --database-user="${MYSQL_USER}" --database-pass="${MYSQL_PASSWORD}" --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
    elif [[ "${DB_HOST}" == 'pgsql' ]]; then
        occ maintenance:install --verbose --database="${DB_HOST}" --database-name="${POSTGRES_DB}" --database-host="${DB_HOST}" --database-port= --database-user="${POSTGRES_USER}" --database-pass="${POSTGRES_PASSWORD}" --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
    else
        occ maintenance:install --verbose --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
    fi

    echo "🔧 Making initial config ..."
    occ config:import <<EOF
{
    "system": {
        "apps_paths":[
            {
                "path":"/var/www/html/apps",
                "url":"/apps",
                "writable":false
            },
            {
                "path":"/var/www/html/apps-extra",
                "url":"/apps-extra",
                "writable":false
            },
            {
                "path":"/var/www/html/apps-writable",
                "url":"/apps-writable",
                "writable":true
            }
        ]
    }
}
EOF

    occ config:system:set memcache.local             --value "\OC\Memcache\APCu"
    occ config:system:set memcache.distributed       --value "\OC\Memcache\Redis"
    occ config:system:set redis host                 --value "redis"

    occ config:system:set debug                      --value true --type boolean
    occ config:system:set loglevel                   --value 0 --type integer
    occ config:system:set query_log_file             --value /var/www/html/data/database.log

    occ config:system:set default_phone_region       --value "${DEFAULT_PHONE_REGION}"
    occ config:system:set allow_local_remote_servers --value true --type boolean

    occ config:system:set mail_from_address          --value "${MAIL_FROM_ADDRESS}"
    occ config:system:set mail_domain                --value "${MAIL_DOMAIN}"
    occ config:system:set mail_smtpport              --value "${MAIL_SMTPPORT}" --type integer
    occ config:system:set mail_smtphost              --value "${MAIL_SMTPHOST}"

    occ config:app:set core backgroundjobs_mode      --value "cron"
    echo "🥳 Setup completed !!!"
fi

# Run cron
echo "📅 Running cron for the first time ..."
exec busybox crond -f -l 0 -L /dev/stdout > /dev/null 2>&1 &
runuser -u www-data -- php -f /var/www/html/cron.php

# Start PHP-FPM
if [[ "$HTTP_PORT" != 80 ]]; then
    echo "💙 Nextclud is up! Access http://localhost:$HTTP_PORT"
else
    echo "💙 Nextclud is up! Access http://localhost"
fi
php-fpm
