#!/bin/sh

set -eu

script_dir="$(cd -- "$(dirname -- "$0")" && pwd)"
proxy_lib_dir="${PROXY_LIB_DIR:-$script_dir/proxy}"
release_marker=/tmp/librecode-proxy-lease-released

# shellcheck source=.docker/scripts/proxy/common.sh
. "$proxy_lib_dir/common.sh"

COORDINATOR_CONTAINER="$(hostname)"
PROJECT_NAME="$(container_project "$COORDINATOR_CONTAINER")"
export COORDINATOR_CONTAINER PROJECT_NAME

# These modules share only exported environment and common.sh accessors.
# Keep the source directives in sync with the runtime paths so ShellCheck can
# analyze the complete dependency graph without file-wide suppressions.
# shellcheck source=.docker/scripts/proxy/infrastructure.sh
. "$proxy_lib_dir/infrastructure.sh"
# shellcheck source=.docker/scripts/proxy/diagnostics.sh
. "$proxy_lib_dir/diagnostics.sh"
# shellcheck source=.docker/scripts/proxy/services.sh
. "$proxy_lib_dir/services.sh"
# shellcheck source=.docker/scripts/proxy/lease.sh
. "$proxy_lib_dir/lease.sh"

validate_environment() {
	if [ -z "$PROJECT_NAME" ]; then
		echo 'Could not determine the Compose project from the coordinator container.' >&2
		return 1
	fi

	if [ -z "${PROJECT_DIR:-}" ]; then
		echo 'The host project directory was not provided to the coordinator.' >&2
		return 1
	fi

	echo "Validating Compose project ${PROJECT_NAME} at ${PROJECT_DIR}."
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
