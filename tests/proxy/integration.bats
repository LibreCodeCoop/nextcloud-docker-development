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

wait_for_network() {
	container="$1"
	network="$2"

	for _ in $(seq 1 60); do
		networks="$(docker inspect --format '{{json .NetworkSettings.Networks}}' "$container" 2>/dev/null || true)"
		[[ "$networks" == *"\"$network\""* ]] && return 0
		sleep 0.5
	done

	return 1
}

wait_for_https_path_status() {
	host="$1"
	path="$2"
	expected="$3"

	for _ in $(seq 1 30); do
		status="$(curl --silent --show-error --insecure \
			--connect-timeout 1 \
			--max-time 2 \
			--resolve "$host:443:127.0.0.1" \
			--output "$BODY" \
			--write-out '%{http_code}' \
			"https://$host$path" 2>/dev/null || true)"
		[ "$status" = "$expected" ] && return 0
		sleep 0.5
	done
	printf 'Timed out waiting for https://%s%s to return %s; last status was %s\n' "$host" "$path" "$expected" "${status:-none}" >&2
	docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}' >&2 || true
	docker inspect proxytesta-nginx-1 --format '{{json .NetworkSettings.Networks}}' >&2 2>/dev/null || true
	curl --silent --show-error --insecure --connect-timeout 1 --max-time 2 \
		--resolve 'localhost:443:127.0.0.1' https://localhost/api/http/routers >&2 || true
	docker logs librecode-dev-proxy >&2 || true
	docker logs librecode-dev-dashboard >&2 || true
	return 1
}

wait_for_https_status() {
	wait_for_https_path_status "$1" / "$2"
}

@test "single project starts routing and releases the shared proxy" {
	compose_test proxytesta up --detach

	wait_for_running librecode-dev-proxy
	wait_for_running librecode-dev-dashboard

	wait_for_network librecode-dev-proxy proxytesta_default
	backend_networks="$(docker inspect --format '{{json .NetworkSettings.Networks}}' proxytesta-nginx-1)"
	[[ "$backend_networks" != *'"librecode-dev-proxy"'* ]]

	http_host_ip="$(docker inspect --format '{{(index (index .NetworkSettings.Ports "80/tcp") 0).HostIp}}' librecode-dev-proxy)"
	https_host_ip="$(docker inspect --format '{{(index (index .NetworkSettings.Ports "443/tcp") 0).HostIp}}' librecode-dev-proxy)"
	[ "$http_host_ip" = "127.0.0.1" ]
	[ "$https_host_ip" = "127.0.0.1" ]

	wait_for_https_status localhost 200
	grep -q 'LibreCode Nextcloud Development Environment' "$BODY"
	grep -q 'Environment checks' "$BODY"
	grep -q 'Help improve this development environment' "$BODY"
	grep -q 'Contribute on GitHub' "$BODY"
	grep -q 'Report an issue' "$BODY"
	grep -q 'Star on GitHub' "$BODY"

	wait_for_https_path_status localhost /api/http/routers 200
	grep -q 'librecode-proxytesta--nextcloud' "$BODY"

	wait_for_https_path_status localhost /runtime.json 200
	grep -q '"docker":"' "$BODY"
	grep -q '"runc":"' "$BODY"

	wait_for_https_status proxytesta.localhost 200
	grep -q 'Welcome to nginx' "$BODY"

	wait_for_https_status something-wrong.localhost 404
	grep -q 'Environment not found' "$BODY"

	wait_for_https_path_status something-wrong.localhost /runtime.json 404
	! grep -q '"docker":"' "$BODY"
	! grep -q '"runc":"' "$BODY"

	compose_test proxytesta stop

	wait_for_absent librecode-dev-proxy
	wait_for_absent librecode-dev-dashboard
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
	wait_for_running librecode-dev-dashboard
	wait_for_https_status proxytesta.localhost 200

	started_at="$(date +%s)"
	kill -INT "$compose_pid"
	wait "$compose_pid" || true
	finished_at="$(date +%s)"

	wait_for_absent librecode-dev-proxy
	wait_for_absent librecode-dev-dashboard

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
	wait_for_absent librecode-dev-dashboard
}
