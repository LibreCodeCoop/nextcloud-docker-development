#!/bin/sh

# Generate self-signed certificate if it doesn't exist
if [ ! -f /tmp/nextcloud.pem ]; then
    echo "Generating self-signed certificate..."
    openssl req -new -x509 -days 365 -nodes \
        -subj "/C=BR/ST=State/L=City/O=Nextcloud/CN=localhost" \
        -out /tmp/nextcloud.pem -keyout /tmp/nextcloud.pem 2>/dev/null || true
fi

# Execute nginx
exec nginx -g "daemon off;"
