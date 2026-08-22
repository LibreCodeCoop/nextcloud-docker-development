#!/bin/sh

set -eu

proxy_project=librecode-dev-proxy
proxy_network=librecode-dev-proxy
proxy_label=coop.librecode.dev-proxy=true

compose_project() {
	docker inspect \
		--format '{{ index .Config.Labels "com.docker.compose.project" }}' \
		"$(hostname)"
}

project="$(compose_project)"

if [ -z "$project" ]; then
	echo 'Could not determine the Compose project from the coordinator container.' >&2
	exit 1
fi

if [ -z "${PROJECT_DIR:-}" ]; then
	echo 'The host project directory was not provided to the coordinator.' >&2
	exit 1
fi

compose() {
	docker compose \
		--project-name "$project" \
		--project-directory "$PROJECT_DIR" \
		--file "$PROJECT_DIR/docker-compose.yml" \
		"$@"
}

proxy_compose() {
	docker compose \
		--project-name "$proxy_project" \
		--project-directory "$PROJECT_DIR" \
		--file "$PROJECT_DIR/.docker/docker-compose.proxy.yml" \
		"$@"
}

container_for_published_port() {
	port="$1"

	docker ps \
		--filter "publish=$port" \
		--format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Label "coop.librecode.dev-proxy"}}'
}

port_is_in_use() {
	container_for_published_port "$1" | grep -q .
}

compatible_proxy_container() {
	docker ps \
		--filter "label=$proxy_label" \
		--format '{{.ID}}' |
		head -n 1
}

is_compatible_proxy_port_owner() {
	port="$1"
	info="$(container_for_published_port "$port" | head -n 1)"

	[ -n "$info" ] || return 1

	compatible="$(printf '%s\n' "$info" | cut -f4)"

	[ "$compatible" = "true" ]
}

proxy_is_ready() {
	[ -n "$(compatible_proxy_container || true)" ] &&
		is_compatible_proxy_port_owner 80 &&
		is_compatible_proxy_port_owner 443
}

show_conflict() {
	port="$1"
	container_info="$(container_for_published_port "$port" | head -n 1)"

	printf '┌─ ⛔ Development proxy cannot start ─────────────────────\n' >&2
	printf '│\n' >&2
	printf '│ Port 80 or 443 is already in use by another service.\n' >&2
	printf '│\n' >&2
	printf '│ This development environment requires:\n' >&2
	printf '│\n' >&2
	printf '│   HTTP   localhost:80\n' >&2
	printf '│   HTTPS  localhost:443\n' >&2
	printf '│\n' >&2
	printf '│ Stop the conflicting service and run:\n' >&2
	printf '│\n' >&2
	printf '│   docker compose up\n' >&2
	printf '│\n' >&2

	if [ -n "$container_info" ]; then
		name="$(printf '%s\n' "$container_info" | cut -f2)"
		image="$(printf '%s\n' "$container_info" | cut -f3)"

		printf '│ Conflicting container\n' >&2
		printf '│   Name   %s\n' "$name" >&2
		printf '│   Image  %s\n' "$image" >&2
		printf '│   Port   %s\n' "$port" >&2
	else
		printf '│ Port %s is already in use by a process outside Docker.\n' "$port" >&2
	fi

	printf '│\n' >&2
	printf '└────────────────────────────────────────────────────────\n' >&2
}

ensure_ports_available() {
	for port in 80 443; do
		if port_is_in_use "$port"; then
			show_conflict "$port"
			exit 1
		fi
	done
}

start_proxy() {
	if proxy_compose up --detach; then
		return 0
	fi

	# Another checkout may have created the shared proxy concurrently.
	if proxy_is_ready; then
		return 0
	fi

	for port in 80 443; do
		if port_is_in_use "$port"; then
			show_conflict "$port"
			exit 1
		fi
	done

	echo 'Could not start the LibreCode development proxy.' >&2
	exit 1
}

running_services="$(compose ps --status running --services)"

service_is_running() {
	printf '%s\n' "$running_services" |
		grep -qx "$1"
}

container_for_service() {
	compose ps -q "$1" 2>/dev/null || true
}

connect_to_proxy_network() {
	service="$1"
	container="$(container_for_service "$service")"

	[ -n "$container" ] || return 0

	if docker inspect \
		--format '{{ json .NetworkSettings.Networks }}' \
		"$container" |
		grep -q "\"$proxy_network\""; then
		return 0
	fi

	docker network connect "$proxy_network" "$container"
}

connect_running_service_to_proxy_network() {
	service="$1"

	service_is_running "$service" || return 0
	connect_to_proxy_network "$service"
}

report_environment_ready() {
	set -- \
		-e ENV_NEXTCLOUD_URL="https://${project}.localhost" \
		-e ENV_ADMIN_USER="$NEXTCLOUD_ADMIN_USER" \
		-e ENV_ADMIN_PASSWORD="$NEXTCLOUD_ADMIN_PASSWORD" \
		-e ENV_NEXTCLOUD_BRANCH="$VERSION_NEXTCLOUD"

	if service_is_running mailpit; then
		set -- "$@" \
			-e ENV_MAILPIT_URL="https://${project}-mailpit.localhost"
	fi

	if service_is_running eurooffice; then
		set -- "$@" \
			-e ENV_EUROOFFICE_URL="https://${project}-eurooffice.localhost"
	fi

	if service_is_running playwright; then
		set -- "$@" \
			-e ENV_PLAYWRIGHT_URL="https://${project}-playwright.localhost"
	fi

	if service_is_running signal-gateway; then
		set -- "$@" \
			-e ENV_SIGNAL_URL="https://${project}-signal.localhost"
	fi

	compose exec -T \
		"$@" \
		nextcloud sh /var/www/scripts/report-environment-ready
}

install_proxy_assets() {
	docker run --rm \
		-v librecode-dev-proxy-conf:/conf \
		-v librecode-dev-proxy-html:/html \
		-v "$PROJECT_DIR/.docker/nginx-proxy:/source:ro" \
		alpine sh -c '
			cp /source/localhost.conf /conf/librecode-localhost.conf
			cp /source/index.html /html/index.html
		'
}

success() {
	case "$1" in
		reused)
			echo '✅ Existing LibreCode development proxy reused. Coordinator exiting normally.'
			;;
		started)
			echo '✅ Development proxy started successfully. Coordinator exiting normally.'
			;;
	esac
}

echo "Validating Compose project ${project} at ${PROJECT_DIR}."
compose config --quiet

install_proxy_assets

if proxy_is_ready; then
	proxy_state=reused
else
	ensure_ports_available
	start_proxy
	proxy_state=started
fi

connect_running_service_to_proxy_network nginx
connect_running_service_to_proxy_network mailpit
connect_running_service_to_proxy_network eurooffice
connect_running_service_to_proxy_network playwright
connect_running_service_to_proxy_network signal-gateway

if ! report_environment_ready; then
	echo 'Could not print environment banner.' >&2
fi

success "$proxy_state"