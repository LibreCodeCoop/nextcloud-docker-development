#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	TEST_LOG="$BATS_TEST_TMPDIR/proxy.log"
	: > "$TEST_LOG"

	# shellcheck source=.docker/scripts/proxy/common.sh
	source "$REPO_ROOT/.docker/scripts/proxy/common.sh"
	# shellcheck source=.docker/scripts/proxy/infrastructure.sh
	source "$REPO_ROOT/.docker/scripts/proxy/infrastructure.sh"
}

@test "ready proxy is reconciled and reused" {
	proxy_is_ready() { return 0; }
	proxy_compose() {
		printf 'proxy-compose %s\n' "$*" >> "$TEST_LOG"
	}

	run ensure_proxy_running

	[ "$status" -eq 0 ]
	[ "$output" = reused ]
	grep -q '^proxy-compose up --detach$' "$TEST_LOG"
}

@test "missing proxy is started" {
	proxy_is_ready() { return 1; }
	ensure_ports_available() { return 0; }
	start_proxy() {
		printf 'start-proxy\n' >> "$TEST_LOG"
	}

	run ensure_proxy_running

	[ "$status" -eq 0 ]
	[ "$output" = started ]
	grep -q '^start-proxy$' "$TEST_LOG"
}

@test "occupied required port prevents startup" {
	port_is_in_use() {
		[ "$1" = 80 ]
	}
	show_conflict() {
		printf 'conflict %s\n' "$1" >> "$TEST_LOG"
	}

	run ensure_ports_available

	[ "$status" -eq 1 ]
	grep -q '^conflict 80$' "$TEST_LOG"
}

@test "existing proxy network is reused" {
	Docker() {
		printf 'docker %s\n' "$*" >> "$TEST_LOG"
		case "$*" in
			"network inspect $(proxy_network_name)") return 0 ;;
		esac
		return 1
	}

	run ensure_proxy_network

	[ "$status" -eq 0 ]
	grep -q "^docker network inspect $(proxy_network_name)$" "$TEST_LOG"
	! grep -q '^docker network create' "$TEST_LOG"
}
