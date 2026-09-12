#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	TEST_LOG="$BATS_TEST_TMPDIR/services.log"
	: > "$TEST_LOG"

	# shellcheck source=.docker/scripts/proxy/common.sh
	source "$REPO_ROOT/.docker/scripts/proxy/common.sh"
	# shellcheck source=.docker/scripts/proxy/services.sh
	source "$REPO_ROOT/.docker/scripts/proxy/services.sh"

	project=current
}

@test "running service is connected to proxy network" {
	service_is_running() { return 0; }
	container_for_service() { printf '%s\n' service-container; }
	container_networks() { printf '{}\n'; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	connect_running_service_to_proxy_network nginx

	grep -q "^docker network connect $proxy_network service-container$" "$TEST_LOG"
}

@test "service already on proxy network is not connected twice" {
	service_is_running() { return 0; }
	container_for_service() { printf '%s\n' service-container; }
	container_networks() { printf '{\"%s\":{}}\n' "$proxy_network"; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	connect_running_service_to_proxy_network nginx

	! grep -q '^docker network connect' "$TEST_LOG"
}

@test "stopped service is ignored" {
	service_is_running() { return 1; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	connect_running_service_to_proxy_network nginx

	[ ! -s "$TEST_LOG" ]
}
