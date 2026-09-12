#!/bin/sh

set -eu

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
proxy_lib_dir="${PROXY_LIB_DIR:-$script_dir/proxy}"
release_marker=/tmp/librecode-proxy-lease-released

# The modules are loaded from a runtime path in the coordinator container.
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/common.sh"
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/infrastructure.sh"
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/assets.sh"
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/diagnostics.sh"
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/services.sh"
# shellcheck disable=SC1090,SC1091
. "$proxy_lib_dir/lease.sh"

coordinator_container="$(hostname)"
project="$(container_project "$coordinator_container")"

validate_environment() {
	if [ -z "$project" ]; then
		echo 'Could not determine the Compose project from the coordinator container.' >&2
		return 1
	fi

	if [ -z "${PROJECT_DIR:-}" ]; then
		echo 'The host project directory was not provided to the coordinator.' >&2
		return 1
	fi

	echo "Validating Compose project ${project} at ${PROJECT_DIR}."
	compose config --quiet
}

success() {
	case "$1" in
		reused)
			echo '✅ Existing LibreCode development proxy reused. Coordinator lease is active.'
		;;
	started)
			echo '✅ Development proxy started successfully. Coordinator lease is active.'
		;;
	esac
}

release() {
	if [ -f "$release_marker" ]; then
		return 0
	fi

	echo 'Releasing shared development proxy lease.'
	if release_proxy_if_unused; then
		touch "$release_marker"
		return 0
	fi

	return 1
}

shutdown() {
	trap - INT TERM HUP
	release || true
	exit 0
}

wait_for_shutdown() {
	trap shutdown INT TERM HUP

	while :; do
		sleep 3600 &
		wait "$!" || true
	done
}

run() {
	validate_environment
	ensure_proxy_network
	install_proxy_assets

	proxy_state="$(ensure_proxy_running)"
	install_runtime_diagnostics

	acquire_proxy_lease
	rm -f "$release_marker"
	trap shutdown INT TERM HUP

	connect_project_services

	if ! report_environment_ready; then
		echo 'Could not print environment banner.' >&2
	fi

	success "$proxy_state"
	wait_for_shutdown
}

run
