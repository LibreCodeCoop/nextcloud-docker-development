#!/bin/sh

CERT_DIR=${CERT_DIR:-/certs}
CERT_PATH=${CERT_PATH:-$CERT_DIR/nextcloud.pem}

has_localhost_san() {
    [ -f "$CERT_PATH" ] && openssl x509 -in "$CERT_PATH" -noout -ext subjectAltName 2>/dev/null | grep -q 'DNS:localhost'
}

generate_self_signed_cert() {
    echo "Generating self-signed certificate for localhost..."
    mkdir -p "$CERT_DIR"
    tmp_key=$(mktemp)
    tmp_cert=$(mktemp)
    openssl req -x509 -newkey rsa:4096 -sha256 -days 365 -nodes \
        -subj "/C=BR/ST=State/L=City/O=Nextcloud/CN=localhost" \
        -addext "subjectAltName=DNS:localhost" \
        -keyout "$tmp_key" \
        -out "$tmp_cert"
    cat "$tmp_key" "$tmp_cert" > "$CERT_PATH"
    rm -f "$tmp_key" "$tmp_cert"
    echo "Certificate generated at $CERT_PATH"
}

if ! has_localhost_san; then
    generate_self_signed_cert
fi

# Execute nginx
exec nginx -g "daemon off;"
