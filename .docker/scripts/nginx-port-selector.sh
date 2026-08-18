#!/bin/sh

set -eu

compose_project() {
	docker inspect --format '{{ index .Config.Labels "com.docker.compose.project" }}' "$HOSTNAME"
}

project="$(compose_project)"
if [ -z "$project" ]; then
	echo 'Could not determine the Compose project from the selector container.' >&2
	exit 1
fi

if [ -z "${PROJECT_DIR:-}" ]; then
	echo 'The host project directory was not provided to the selector.' >&2
	exit 1
fi

compose() {
	docker compose \
		--project-name "$project" \
		--project-directory "$PROJECT_DIR" \
		--file "$PROJECT_DIR/docker-compose.yml" \
		"$@"
}

echo "Validating Compose project ${project} at ${PROJECT_DIR}."
compose config --quiet

cleanup_nginx() {
	compose rm --force --stop nginx || true
}

trap cleanup_nginx INT TERM

start_nginx() {
	HTTP_PORT="$1" HTTPS_PORT="$2" IP_BIND="${IP_BIND:-127.0.0.1}" \
		compose up --detach --no-deps --scale nginx=1 nginx
}

published_port() {
	mapping="$(compose port "$1" "$2" 2>/dev/null || true)"
	[ -n "$mapping" ] || return 0
	printf '%s\n' "${mapping##*:}"
}

prepare_environment_banner() {
	selector_http_port="$1"
	selector_https_port="$2"
	mailpit_port="$(published_port mailpit 8025)"
	eurooffice_port="$(published_port eurooffice 80)"
	playwright_port="$(published_port playwright 9323)"
	signal_port="$(published_port signal-gateway 8080)"

	compose exec -T \
		-e ENV_HTTP_PORT="$selector_http_port" \
		-e ENV_HTTPS_PORT="$selector_https_port" \
		-e ENV_MAILPIT_PORT="$mailpit_port" \
		-e ENV_EUROOFFICE_PORT="$eurooffice_port" \
		-e ENV_PLAYWRIGHT_PORT="$playwright_port" \
		-e ENV_SIGNAL_PORT="$signal_port" \
		nextcloud /usr/local/bin/report-environment-ready --prepare
}

if [ "${HTTP_PORT+x}" = x ] || [ "${HTTPS_PORT+x}" = x ]; then
	echo "Explicit ports requested: HTTP ${HTTP_PORT:-80}, HTTPS ${HTTPS_PORT:-443}."
	set +e
	output="$(start_nginx "${HTTP_PORT:-80}" "${HTTPS_PORT:-443}" 2>&1)"
	status=$?
	set -e
	printf '%s\n' "$output"
	if [ "$status" -ne 0 ]; then
		cleanup_nginx
		exit "$status"
	fi
	echo 'nginx started with explicit ports.'
	if ! prepare_environment_banner "${HTTP_PORT:-80}" "${HTTPS_PORT:-443}"; then
		echo 'Could not prepare environment banner.' >&2
	fi
	exit 0
fi

offset=0
while [ "$offset" -le 19 ]; do
	http_port=$((80 + offset))
	https_port=$((443 + offset))
	echo "Trying nginx ports HTTP ${http_port} / HTTPS ${https_port}."

	set +e
	output="$(start_nginx "$http_port" "$https_port" 2>&1)"
	status=$?
	set -e
	printf '%s\n' "$output"

	if [ "$status" -eq 0 ]; then
		echo "nginx started with HTTP ${http_port} / HTTPS ${https_port}."
		if ! prepare_environment_banner "$http_port" "$https_port"; then
			echo 'Could not prepare environment banner.' >&2
		fi
		exit 0
	fi

	if ! printf '%s\n' "$output" | grep -Eiq \
		'address already in use|port is already allocated|port is already in use|failed to bind host port|cannot bind .* port'; then
		echo 'nginx failed for a reason unrelated to a port conflict; stopping.' >&2
		cleanup_nginx
		exit "$status"
	fi

	echo "Ports ${http_port}/${https_port} are unavailable; trying the next pair." >&2
	cleanup_nginx
	offset=$((offset + 1))
done

echo 'No available nginx port pair found in HTTP 80-99 / HTTPS 443-462.' >&2
exit 1
