#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
}

@test "default third-party runtime images are pinned by tag and digest" {
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:[0-9a-f]{64}$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: axllent/mailpit:v[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: redis:[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$' "$REPO_ROOT/docker-compose.yml"
	grep -Eq '^[[:space:]]+image: mysql:8\.4@sha256:[0-9a-f]{64}$' "$REPO_ROOT/.docker/database-services.yml"
	grep -Eq '^[[:space:]]+image: postgres:13-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/.docker/database-services.yml"
	grep -Eq '^[[:space:]]+image: nginxproxy/nginx-proxy:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/.docker/docker-compose.proxy.yml"
	grep -Eq '^[[:space:]]+image: sebastienheyd/self-signed-proxy-companion:[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}$' "$REPO_ROOT/.docker/docker-compose.proxy.yml"
}

@test "proxy helper reuses the coordinator image instead of duplicating its version" {
	grep -q 'container_image "${COORDINATOR_CONTAINER:-}"' "$REPO_ROOT/.docker/scripts/proxy/assets.sh"
	! grep -Eq 'docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:' "$REPO_ROOT/.docker/scripts/proxy/assets.sh"
}

@test "proxy integration fixture images are pinned by tag and digest" {
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
}

@test "compose files do not keep shutdown workarounds from runtime debugging" {
	for file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/tests/proxy/fixtures/compose.yml"; do
		! grep -Eq '^[[:space:]]+(stop_signal|stop_grace_period|init):' "$file"
	done
}

@test "shared proxy binds to loopback by default and supports explicit exposure" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	grep -Fq '"${IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"

	run env IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'
}

@test "docker socket mounts stay limited to proxy infrastructure" {
	main_socket_mounts="$(grep -Ec '^[[:space:]]+- .*DOCKER_SOCKET.*:/var/run/docker\.sock$' "$REPO_ROOT/docker-compose.yml")"
	[ "$main_socket_mounts" -eq 1 ]

	proxy_socket_mounts="$(grep -Ec '^[[:space:]]+- .*DOCKER_SOCKET.*:/.*docker\.sock:ro$' "$REPO_ROOT/.docker/docker-compose.proxy.yml")"
	[ "$proxy_socket_mounts" -eq 2 ]
}

@test "dashboard does not use innerHTML for Docker metadata" {
	! grep -q 'innerHTML' "$REPO_ROOT/.docker/nginx-proxy/dashboard.tmpl"
	grep -q 'textContent = currentProject' "$REPO_ROOT/.docker/nginx-proxy/dashboard.tmpl"
	grep -q 'textContent = link.href' "$REPO_ROOT/.docker/nginx-proxy/dashboard.tmpl"
}

@test "GitHub Actions are pinned to immutable commit SHAs" {
	while IFS= read -r workflow; do
		while IFS= read -r uses_line; do
			ref="${uses_line#*@}"
			ref="${ref%% *}"
			[[ "$ref" =~ ^[0-9a-f]{40}$ ]] || {
				printf 'mutable action reference in %s: %s\n' "$workflow" "$uses_line" >&2
				return 1
			}
		done < <(grep -E '^[[:space:]]*-?[[:space:]]*uses:[[:space:]]+[^./][^[:space:]]+@' "$workflow" || true)
	done < <(find "$REPO_ROOT/.github/workflows" -type f -name '*.yml' -o -name '*.yaml')
}
