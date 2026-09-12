#!/bin/sh

service_is_running() {
	compose ps --status running --services |
		grep -qx "$1"
}

container_for_service() {
	compose ps -q "$1" 2>/dev/null || true
}

connect_to_proxy_network() {
	service="$1"
	container="$(container_for_service "$service")"

	[ -n "$container" ] || return 0

	if container_networks "$container" | grep -q "\"$proxy_network\""; then
		return 0
	fi

	Docker network connect "$proxy_network" "$container"
}

connect_running_service_to_proxy_network() {
	service="$1"

	service_is_running "$service" || return 0
	connect_to_proxy_network "$service"
}

connect_project_services() {
	for service in nginx mailpit eurooffice playwright signal-gateway; do
		connect_running_service_to_proxy_network "$service"
	done
}

report_environment_ready() {
	set -- \
		-e ENV_NEXTCLOUD_URL="https://${project}.localhost" \
		-e ENV_ADMIN_USER="$NEXTCLOUD_ADMIN_USER" \
		-e ENV_ADMIN_PASSWORD="$NEXTCLOUD_ADMIN_PASSWORD" \
		-e ENV_NEXTCLOUD_BRANCH="$VERSION_NEXTCLOUD"

	if service_is_running mailpit; then
		set -- "$@" -e ENV_MAILPIT_URL="https://${project}-mailpit.localhost"
	fi

	if service_is_running eurooffice; then
		set -- "$@" -e ENV_EUROOFFICE_URL="https://${project}-eurooffice.localhost"
	fi

	if service_is_running playwright; then
		set -- "$@" -e ENV_PLAYWRIGHT_URL="https://${project}-playwright.localhost"
	fi

	if service_is_running signal-gateway; then
		set -- "$@" -e ENV_SIGNAL_URL="https://${project}-signal.localhost"
	fi

	compose exec -T \
		"$@" \
		nextcloud sh /var/www/scripts/report-environment-ready
}
