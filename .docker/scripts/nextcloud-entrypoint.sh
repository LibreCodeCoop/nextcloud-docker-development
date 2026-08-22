#!/bin/bash

# Set uid of host machine
usermod --non-unique --uid "${HOST_UID}" www-data
groupmod --non-unique --gid "${HOST_GID}" www-data

# Clone Nextcloud repository, if needed
if [ ! -d ".git" ]; then
    chown -R www-data:www-data .
    runuser -u www-data -- git config --global --add safe.directory /var/www/html
    runuser -u www-data -- git init
    runuser -u www-data -- git remote add origin https://github.com/nextcloud/server
    runuser -u www-data -- git fetch --depth=1 origin "${VERSION_NEXTCLOUD}"
    runuser -u www-data -- git checkout "${VERSION_NEXTCLOUD}"
    runuser -u www-data -- git submodule update --init --recursive
fi

install -d -o www-data -g www-data \
    data \
    apps-writable \
    config \
    apps-extra

# Wait for database
php /var/www/scripts/wait-for-db.php

install_cmd_status=0

# An empty or incomplete config.php (interrupted install) must not block a new installation
if [[ -f "config/config.php" ]] && ! grep -qE "'installed'[[:space:]]*=>[[:space:]]*true" config/config.php; then
    echo "⚠️  Found an empty or incomplete config/config.php. Removing it to install from scratch."
    rm -f config/config.php
fi

# Set configurations, if needed
if [[ ! -f "config/config.php" && ${AUTOINSTALL} -eq 1 ]]; then
    echo "⌛️ Starting installation ..."
    chown -R www-data:www-data .
    if [[ ${DB_HOST} == 'mysql' ]]; then
        occ maintenance:install --verbose --database="${DB_HOST}" --database-name="${MYSQL_DATABASE}" --database-host="${DB_HOST}" --database-port= --database-user="${MYSQL_USER}" --database-pass="${MYSQL_PASSWORD}" --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
        install_cmd_status=$?
    elif [[ "${DB_HOST}" == 'pgsql' ]]; then
        occ maintenance:install --verbose --database="${DB_HOST}" --database-name="${POSTGRES_DB}" --database-host="${DB_HOST}" --database-port= --database-user="${POSTGRES_USER}" --database-pass="${POSTGRES_PASSWORD}" --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
        install_cmd_status=$?
    else
        occ maintenance:install --verbose --admin-user="${NEXTCLOUD_ADMIN_USER}" --admin-pass="${NEXTCLOUD_ADMIN_PASSWORD}" --admin-email="${NEXTCLOUD_ADMIN_EMAIL}"
        install_cmd_status=$?
    fi

    if [[ ${install_cmd_status} -ne 0 ]]; then
        db_reset_hint="volumes/nextcloud/config and volumes/nextcloud/data"
        if [[ ${DB_HOST} == 'mysql' ]]; then
            db_reset_hint="volumes/mysql/data, ${db_reset_hint}"
        elif [[ ${DB_HOST} == 'pgsql' ]]; then
            db_reset_hint="volumes/postgres/data, ${db_reset_hint}"
        fi

        echo "❌ Installation failed. Check the logs above for the exact reason."
        echo "   If this is a local reset issue, remove: ${db_reset_hint}"
        exit ${install_cmd_status}
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

    occ config:system:set auth.bruteforce.protection.enabled --value false --type boolean

    if [ ! -d "apps-extra/hmr_enabler" ]; then
        echo "⌛️ Installing hmr_enabler app to be possible use Vue Developer Tools"
        runuser -u www-data -- git clone --progress --single-branch --depth 1 https://github.com/nextcloud/hmr_enabler apps-extra/hmr_enabler
        runuser -u www-data -- occ app:enable hmr_enabler
    fi

    if [ ! -d "apps-extra/viewer" ]; then
        echo "⌛️ Installing viewer app..."
        runuser -u www-data -- git clone --progress --single-branch --depth 1 https://github.com/nextcloud/viewer apps-extra/viewer
        runuser -u www-data -- occ app:enable viewer
    fi

    if [ ! -d "apps-extra/files_pdfviewer" ]; then
        echo "⌛️ Installing files_pdfviewer app..."
        runuser -u www-data -- git clone --progress --single-branch --depth 1 https://github.com/nextcloud/files_pdfviewer apps-extra/files_pdfviewer
        runuser -u www-data -- occ app:enable files_pdfviewer
    fi

    echo "🥳 Setup completed !!!"
fi

if ! occ status | grep -q 'installed: true'; then
    echo "❌ Nextcloud is not installed. Skipping startup tasks and stopping container."
    exit 1
fi

# Run cron
echo "📅 Running cron for the first time ..."
exec busybox crond -f -l 0 -L /dev/stdout > /dev/null 2>&1 &
runuser -u www-data -- php -f /var/www/html/cron.php

# Start PHP-FPM
echo "Starting PHP-FPM..."
exec "$@"
