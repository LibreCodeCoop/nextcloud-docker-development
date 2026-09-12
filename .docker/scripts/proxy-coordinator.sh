#!/bin/sh

set -eu

script_dir="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
proxy_lib_dir="${PROXY_LIB_DIR:-$script_dir/proxy}"

# shellcheck source=.docker/scripts/proxy/common.sh
. "$proxy_lib_dir/common.sh"
# shellcheck source=.docker/scripts/proxy/infrastructure.sh
. "$proxy_lib_dir/infrastructure.sh"
# shellcheck source=.docker/scripts/proxy/assets.sh
. "$proxy_lib_dir/assets.sh"
# shellcheck source=.docker/scripts/proxy/services.sh
. "$proxy_lib_dir/services.sh"
# shellcheck source=.docker/scripts/proxy/lease.sh
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

shutdown() {
	trap - INT TERM HUP
	echo 'Releasing shared development proxy lease.'
	release_proxy_if_unused || true
	exit 0
}

wait_for_shutdown() {
	trap shutdown INT TERM HUP

	while :; do
		sleep 3600 &
		wait "$!" || true
	done
}

main() {
	validate_environment
	ensure_proxy_network
	install_proxy_assets

	proxy_state="$(ensure_proxy_running)"

	acquire_proxy_lease
	trap shutdown INT TERM HUP

	connect_project_services

	if ! report_environment_ready; then
		echo 'Could not print environment banner.' >&2
	fi

	success "$proxy_state"
	wait_for_shutdown
}

if [ "${PROXY_COORDINATOR_SOURCE_ONLY:-false}" != "true" ]; then
	main "$@"
fi
