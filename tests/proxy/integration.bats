#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	FIXTURE="$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	BODY="$BATS_TEST_TMPDIR/body.html"
	cleanup_proxy_tests
}

teardown() {
	cleanup_proxy_tests
}

compose_test() {
	project="$1"
	shift
	COMPOSE_PROJECT_NAME="$project" REPO_ROOT="$REPO_ROOT" \
		docker compose --project-name "$project" --file "$FIXTURE" "$@"
}

cleanup_proxy_tests() {
	for project in proxytesta proxytestb; do
		COMPOSE_PROJECT_NAME="$project" REPO_ROOT="$REPO_ROOT" \
			docker compose --project-name "$project" --file "$FIXTURE" down --volumes --remove-orphans >/dev/null 2>&1 || true
	done

	docker compose \
		--project-name librecode-dev-proxy \
		--project-directory "$REPO_ROOT" \
		--file "$REPO_ROOT/.docker/docker-compose.proxy.yml" \
		down --remove-orphans >/dev/null 2>&1 || true

	docker network rm librecode-dev-proxy >/dev/null 2>&1 || true
}

container_is_running() {
	docker ps --format '{{.Names}}' | grep -qx "$1"
}

wait_for_running() {
	name="$1"
	for _ in $(seq 1 60); do
		container_is_running "$name" && return 0
		sleep 0.5
	done
	return 1
}

wait_for_absent() {
	name="$1"
	for _ in $(seq 1 60); do
		container_is_running "$name" || return 0
		sleep 0.5
	done
	return 1
}

wait_for_https_path_status() {
	host="$1"
	path="$2"
	expected="$3"

	for _ in $(seq 1 60); do
		status="$(curl --silent --show-error --insecure \
			--resolve "$host:443:127.0.0.1" \
			--output "$BODY" \
			--write-out '%{http_code}' \
			"https://$host$path" 2>/dev/null || true)"
		[ "$status" = "$expected" ] && return 0
		sleep 0.5
	done
	return 1
}

wait_for_https_status() {
	wait_for_https_path_status "$1" / "$2"
}

@test "single project starts routing and releases the shared proxy" {
	compose_test proxytesta up --detach

	wait_for_running librecode-dev-proxy
	wait_for_running librecode-dev-proxy-ssl-companion
	wait_for_https_status localhost 200
	grep -q 'LibreCode Development Proxy' "$BODY"
	grep -q 'Environment checks' "$BODY"

	wait_for_https_path_status localhost /runtime.json 200
	grep -q '"docker":"' "$BODY"
	grep -q '"runc":"' "$BODY"

	wait_for_https_status proxytesta.localhost 200
	grep -q 'Welcome to nginx' "$BODY"

	wait_for_https_status something-wrong.localhost 404
	grep -q 'Environment not found' "$BODY"

	compose_test proxytesta stop

	wait_for_absent librecode-dev-proxy
	wait_for_absent librecode-dev-proxy-ssl-companion
}

@test "Ctrl+C on attached compose stops the last shared proxy promptly" {
	log="$BATS_TEST_TMPDIR/compose-up.log"

	COMPOSE_PROJECT_NAME=proxytesta REPO_ROOT="$REPO_ROOT" \
		docker compose \
			--project-name proxytesta \
			--file "$FIXTURE" \
			up >"$log" 2>&1 &
	compose_pid=$!

	wait_for_running librecode-dev-proxy
	wait_for_running librecode-dev-proxy-ssl-companion
	wait_for_https_status proxytesta.localhost 200

	started_at="$(date +%s)"
	kill -INT "$compose_pid"
	wait "$compose_pid" || true
	finished_at="$(date +%s)"

	wait_for_absent librecode-dev-proxy
	wait_for_absent librecode-dev-proxy-ssl-companion

	elapsed=$((finished_at - started_at))
	[ "$elapsed" -lt 10 ]
}

@test "shared proxy stays alive until the last project stops" {
	compose_test proxytesta up --detach
	compose_test proxytestb up --detach

	wait_for_running librecode-dev-proxy
	wait_for_https_status proxytesta.localhost 200
	wait_for_https_status proxytestb.localhost 200

	compose_test proxytesta stop

	wait_for_running librecode-dev-proxy
	wait_for_https_status proxytestb.localhost 200

	compose_test proxytestb stop

	wait_for_absent librecode-dev-proxy
	wait_for_absent librecode-dev-proxy-ssl-companion
}
