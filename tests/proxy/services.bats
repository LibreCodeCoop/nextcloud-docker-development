#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	TEST_LOG="$BATS_TEST_TMPDIR/services.log"
	: > "$TEST_LOG"

	# shellcheck source=.docker/scripts/proxy/common.sh
	source "$REPO_ROOT/.docker/scripts/proxy/common.sh"
	# shellcheck source=.docker/scripts/proxy/services.sh
	source "$REPO_ROOT/.docker/scripts/proxy/services.sh"

	PROJECT_NAME=current
}

@test "proxy is connected to the current Compose project network" {
	compatible_proxy_container() { printf '%s\n' librecode-dev-proxy; }
	container_networks() { printf '{}\n'; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	connect_proxy_to_project_network

	grep -q '^docker network connect current_default librecode-dev-proxy$' "$TEST_LOG"
}

@test "proxy is not connected twice to the project network" {
	compatible_proxy_container() { printf '%s\n' librecode-dev-proxy; }
	container_networks() { printf '{"current_default":{}}\n'; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	connect_proxy_to_project_network

	! grep -q '^docker network connect' "$TEST_LOG"
}

@test "project network is disconnected from proxy during release" {
	compatible_proxy_container() { printf '%s\n' librecode-dev-proxy; }
	container_networks() { printf '{"current_default":{}}\n'; }
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
	}

	disconnect_proxy_from_project_network

	grep -q '^docker network disconnect current_default librecode-dev-proxy$' "$TEST_LOG"
}
