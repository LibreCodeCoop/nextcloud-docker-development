#!/bin/sh

proxy_lease_acquired=false

acquire_proxy_lease() {
	if ! container_networks "$coordinator_container" | grep -q "\"$proxy_network\""; then
		Docker network connect "$proxy_network" "$coordinator_container"
	fi

	proxy_lease_acquired=true
}

release_proxy_lease() {
	[ "$proxy_lease_acquired" = true ] || return 0

	if ! Docker network disconnect "$proxy_network" "$coordinator_container" >/dev/null 2>&1; then
		echo 'Could not disconnect this coordinator lease from the shared proxy network; continuing with project-based lease detection.' >&2
	fi

	proxy_lease_acquired=false
}

other_proxy_client_is_running() {
	for container in $(Docker ps \
		--filter "label=$proxy_client_label" \
		--filter "network=$proxy_network" \
		--format '{{.ID}}'); do
		[ "$(container_project "$container")" = "$project" ] || return 0
	done

	return 1
}

other_proxy_route_is_running() {
	for container in $(Docker ps --filter "network=$proxy_network" --format '{{.ID}}'); do
		container_project_name="$(container_project "$container")"

		case "$container_project_name" in
			"$project"|"$proxy_project")
				continue
				;;
		esac

		[ -z "$(container_virtual_host "$container")" ] || return 0
	done

	return 1
}

proxy_is_used_by_another_environment() {
	other_proxy_client_is_running || other_proxy_route_is_running
}

wait_for_concurrent_lease() {
	sleep "${PROXY_LEASE_GRACE_SECONDS:-1}"
}

release_proxy_if_unused() {
	release_proxy_lease

	if proxy_is_used_by_another_environment; then
		echo '✅ Shared development proxy is still used by another environment.'
		return 0
	fi

	wait_for_concurrent_lease

	if proxy_is_used_by_another_environment; then
		echo '✅ Shared development proxy is still used by another environment.'
		return 0
	fi

	echo 'Stopping unused shared development proxy.'
	if ! proxy_compose down --remove-orphans; then
		echo 'Could not stop the unused shared development proxy.' >&2
		return 1
	fi
}
