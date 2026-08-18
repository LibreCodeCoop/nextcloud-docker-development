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

report_urls() {
	http_url="http://localhost"
	https_url="https://localhost"
	[ "$1" -eq 80 ] || http_url="${http_url}:$1"
	[ "$2" -eq 443 ] || https_url="${https_url}:$2"
	echo "Nextcloud: ${http_url}"
	echo "HTTPS: ${https_url}"
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
	report_urls "${HTTP_PORT:-80}" "${HTTPS_PORT:-443}"
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
		report_urls "$http_port" "$https_port"
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
