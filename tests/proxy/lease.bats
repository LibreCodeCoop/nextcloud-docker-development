#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	TEST_LOG="$BATS_TEST_TMPDIR/docker.log"
	: > "$TEST_LOG"

	# shellcheck source=.docker/scripts/proxy/common.sh
	source "$REPO_ROOT/.docker/scripts/proxy/common.sh"
	# shellcheck source=.docker/scripts/proxy/lease.sh
	source "$REPO_ROOT/.docker/scripts/proxy/lease.sh"

	project=current
	coordinator_container=current-coordinator
	PROXY_LEASE_GRACE_SECONDS=0
}

@test "current project coordinator is not another proxy client" {
	Docker() {
		printf '%s\n' current-coordinator
	}
	container_project() {
		printf '%s\n' current
	}

	run other_proxy_client_is_running

	[ "$status" -eq 1 ]
}

@test "coordinator from another project keeps the proxy leased" {
	Docker() {
		printf '%s\n' current-coordinator other-coordinator
	}
	container_project() {
		case "$1" in
			current-coordinator) printf '%s\n' current ;;
			other-coordinator) printf '%s\n' other ;;
		esac
	}

	run other_proxy_client_is_running

	[ "$status" -eq 0 ]
}

@test "route from another project keeps the proxy leased" {
	Docker() {
		printf '%s\n' proxy current-route other-route
	}
	container_project() {
		case "$1" in
			proxy) printf '%s\n' "$proxy_project" ;;
			current-route) printf '%s\n' current ;;
			other-route) printf '%s\n' other ;;
		esac
	}
	container_virtual_host() {
		[ "$1" = other-route ] && printf '%s\n' other.localhost
	}

	run other_proxy_route_is_running

	[ "$status" -eq 0 ]
}

@test "last lease stops the shared proxy with bounded timeout" {
	proxy_lease_acquired=true
	PROXY_STOP_TIMEOUT_SECONDS=7
	proxy_is_used_by_another_environment() {
		return 1
	}
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}
	proxy_compose() {
		printf 'proxy-compose %s\n' "$*" >> "$TEST_LOG"
	}

	run release_proxy_if_unused

	[ "$status" -eq 0 ]
	grep -q '^proxy-compose down --timeout 7 --remove-orphans$' "$TEST_LOG"
}

@test "another lease prevents proxy shutdown" {
	proxy_lease_acquired=true
	proxy_is_used_by_another_environment() {
		return 0
	}
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}
	proxy_compose() {
		printf 'proxy-compose %s\n' "$*" >> "$TEST_LOG"
	}

	run release_proxy_if_unused

	[ "$status" -eq 0 ]
	! grep -q '^proxy-compose down' "$TEST_LOG"
}

@test "acquiring a lease connects the coordinator only when needed" {
	container_networks() {
		printf '{}\n'
	}
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	acquire_proxy_lease

	grep -q "^docker network connect $proxy_network $coordinator_container$" "$TEST_LOG"
	[ "$proxy_lease_acquired" = true ]
}
