#!/bin/sh

container_for_published_port() {
	port="$1"

	Docker ps \
		--filter "publish=$port" \
		--format '{{.ID}}\t{{.Names}}\t{{.Image}}\t{{.Label "coop.librecode.dev-proxy"}}'
}

port_is_in_use() {
	container_for_published_port "$1" | grep -q .
}

compatible_proxy_container() {
	Docker ps \
		--filter "label=$(proxy_container_label)" \
		--format '{{.ID}}' |
		head -n 1
}

is_compatible_proxy_port_owner() {
	port="$1"
	info="$(container_for_published_port "$port" | head -n 1)"

	[ -n "$info" ] || return 1
	[ "$(printf '%s\n' "$info" | cut -f4)" = "true" ]
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
		printf '│ Conflicting container\n' >&2
		printf '│   Name   %s\n' "$(printf '%s\n' "$container_info" | cut -f2)" >&2
		printf '│   Image  %s\n' "$(printf '%s\n' "$container_info" | cut -f3)" >&2
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
			return 1
		fi
	done
}

ensure_proxy_network() {
	network="$(proxy_network_name)"

	if Docker network inspect "$network" >/dev/null 2>&1; then
		return 0
	fi

	if Docker network create "$network" >/dev/null 2>&1; then
		return 0
	fi

	# Another checkout may have created it concurrently.
	Docker network inspect "$network" >/dev/null
}

start_proxy() {
	if proxy_compose up --detach; then
		return 0
	fi

	# Another checkout may have started the shared proxy concurrently.
	if proxy_is_ready; then
		return 0
	fi

	ensure_ports_available || return 1

	echo 'Could not start the LibreCode development proxy.' >&2
	return 1
}

ensure_proxy_running() {
	if proxy_is_ready; then
		proxy_compose up --detach
		printf 'reused\n'
		return 0
	fi

	ensure_ports_available || return 1
	start_proxy || return 1
	printf 'started\n'
}
