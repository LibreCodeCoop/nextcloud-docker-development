#!/bin/sh
set -eu

EXPECTED_HOST="$1"
shift

CURRENT_HOST="${DB_HOST:-mysql}"

if [ "$CURRENT_HOST" != "$EXPECTED_HOST" ]; then
    case "$EXPECTED_HOST" in
        mysql) DATABASE_NAME="MySQL" ;;
        pgsql) DATABASE_NAME="PostgreSQL" ;;
    esac

    echo
    echo "$DATABASE_NAME disabled."
    echo "Selected DB_HOST: $CURRENT_HOST."
    echo "This is expected."
    echo "Set DB_HOST=$EXPECTED_HOST to enable $DATABASE_NAME."
    echo
    exit 0
fi

exec "$@"