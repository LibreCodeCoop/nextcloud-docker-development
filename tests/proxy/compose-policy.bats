#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "default third-party runtime images use concrete versions" {
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: axllent/mailpit:v[0-9]+\.[0-9]+\.[0-9]+$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: redis:[0-9]+\.[0-9]+\.[0-9]+$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: nginxproxy/nginx-proxy:[0-9]+\.[0-9]+\.[0-9]+-alpine$' "$REPO_ROOT/.docker/docker-compose.proxy.yml"
	grep -Eq '^[[:space:]]+image: sebastienheyd/self-signed-proxy-companion:[0-9]+\.[0-9]+\.[0-9]+$' "$REPO_ROOT/.docker/docker-compose.proxy.yml"
}

@test "proxy integration fixture uses concrete image versions" {
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
}

@test "compose files do not keep shutdown workarounds from runtime debugging" {
	for file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/tests/proxy/fixtures/compose.yml"; do
		! grep -Eq '^[[:space:]]+(stop_signal|stop_grace_period|init):' "$file"
	done
}
