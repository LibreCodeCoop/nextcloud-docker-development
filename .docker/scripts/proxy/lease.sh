#!/bin/sh

acquire_proxy_lease() {
	network="$(proxy_network_name)"

	if ! container_networks "${COORDINATOR_CONTAINER:-}" | grep -q "\"$network\""; then
		Docker network connect "$network" "${COORDINATOR_CONTAINER:-}"
	fi
}

release_proxy_lease() {
	network="$(proxy_network_name)"

	if ! container_networks "${COORDINATOR_CONTAINER:-}" | grep -q "\"$network\""; then
		return 0
	fi

	if ! Docker network disconnect "$network" "${COORDINATOR_CONTAINER:-}" >/dev/null 2>&1; then
		echo 'Could not disconnect this coordinator lease from the shared proxy network; continuing with project-based lease detection.' >&2
	fi
}

other_proxy_client_is_running() {
	network="$(proxy_network_name)"

	for container in $(Docker ps \
		--filter "label=$(proxy_client_label)" \
		--filter "network=$network" \
		--format '{{.ID}}'); do
		[ "$(container_project "$container")" = "${PROJECT_NAME:-}" ] || return 0
	done

	return 1
}

proxy_is_used_by_another_environment() {
	other_proxy_client_is_running
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
	if ! proxy_compose down \
		--timeout "${PROXY_STOP_TIMEOUT_SECONDS:-3}" \
		--remove-orphans; then
		echo 'Could not stop the unused shared development proxy.' >&2
		return 1
	fi
}
