#!/bin/sh

service_is_running() {
	compose ps --status running --services |
		grep -qx "$1"
}

project_network_name() {
	printf '%s_default\n' "${PROJECT_NAME:-}"
}

connect_proxy_to_project_network() {
	proxy_container="$(compatible_proxy_container)"
	network="$(project_network_name)"

	[ -n "$proxy_container" ] || return 1
	[ -n "${PROJECT_NAME:-}" ] || return 1

	if container_networks "$proxy_container" | grep -q "\\\"$network\\\""; then
		return 0
	fi

	Docker network connect "$network" "$proxy_container"
}

disconnect_proxy_from_project_network() {
	proxy_container="$(compatible_proxy_container)"
	network="$(project_network_name)"

	[ -n "$proxy_container" ] || return 0
	[ -n "${PROJECT_NAME:-}" ] || return 0

	if ! container_networks "$proxy_container" | grep -q "\\\"$network\\\""; then
		return 0
	fi

	Docker network disconnect "$network" "$proxy_container" >/dev/null 2>&1 || true
}

report_environment_ready() {
	set -- \
		-e ENV_NEXTCLOUD_URL="https://${PROJECT_NAME:-}.localhost" \
		-e ENV_ADMIN_USER="${NEXTCLOUD_ADMIN_USER:-admin}" \
		-e ENV_ADMIN_PASSWORD="${NEXTCLOUD_ADMIN_PASSWORD:-admin}" \
		-e ENV_NEXTCLOUD_BRANCH="${VERSION_NEXTCLOUD:-master}"

	if service_is_running mailpit; then
		set -- "$@" -e ENV_MAILPIT_URL="https://${PROJECT_NAME:-}-mailpit.localhost"
	fi

	if service_is_running eurooffice; then
		set -- "$@" -e ENV_EUROOFFICE_URL="https://${PROJECT_NAME:-}-eurooffice.localhost"
	fi

	if service_is_running playwright; then
		set -- "$@" -e ENV_PLAYWRIGHT_URL="https://${PROJECT_NAME:-}-playwright.localhost"
	fi

	if service_is_running signal-gateway; then
		set -- "$@" -e ENV_SIGNAL_URL="https://${PROJECT_NAME:-}-signal.localhost"
	fi

	compose exec -T \
		"$@" \
		nextcloud sh /var/www/scripts/report-environment-ready
}
