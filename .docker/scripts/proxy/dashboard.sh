#!/bin/sh

install_dashboard_assets() {
	dashboard_container="${PROXY_DASHBOARD_CONTAINER:-librecode-dev-dashboard}"

	Docker cp "${PROJECT_DIR:-}/.docker/traefik/dashboard.html" "$dashboard_container:/usr/share/nginx/html/index.html"
	Docker cp "${PROJECT_DIR:-}/.docker/traefik/dashboard.conf" "$dashboard_container:/etc/nginx/conf.d/default.conf"
	Docker exec "$dashboard_container" nginx -s reload
}
