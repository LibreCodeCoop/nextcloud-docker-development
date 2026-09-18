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
	grep -Eq '^[[:space:]]+image: traefik:v[0-9]+\.[0-9]+\.[0-9]+@sha256:[0-9a-f]{64}
@test "proxy integration fixture images are pinned by tag and digest" {
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
}

@test "compose files do not keep shutdown workarounds from runtime debugging" {
	for file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/tests/proxy/fixtures/compose.yml"; do
		! grep -Eq '^[[:space:]]+(stop_signal|stop_grace_period|init):' "$file"
	done
}

@test "network bind settings are scoped per infrastructure service" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	database_compose="$REPO_ROOT/.docker/database-services.yml"

	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"
	grep -Fq 'host_ip: ${MYSQL_IP_BIND:-127.0.0.1}' "$database_compose"
	grep -Fq 'host_ip: ${POSTGRES_IP_BIND:-127.0.0.1}' "$database_compose"
	! grep -Rq '${IP_BIND' "$proxy_compose" "$database_compose" "$REPO_ROOT/docker-compose.yml"

	run env PROXY_IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'

	run env MYSQL_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 0.0.0.0'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 127.0.0.1'

	run env POSTGRES_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 127.0.0.1'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 0.0.0.0'
}

@test "docker socket mounts stay limited to proxy infrastructure" {
	main_socket_mounts="$(grep -Ec '^[[:space:]]+- .*DOCKER_SOCKET.*:/var/run/docker\.sock$' "$REPO_ROOT/docker-compose.yml")"
	[ "$main_socket_mounts" -eq 1 ]

	proxy_socket_mounts="$(grep -Ec '^[[:space:]]+- .*DOCKER_SOCKET.*:/.*docker\.sock:ro
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
 "$REPO_ROOT/.docker/docker-compose.proxy.yml"
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}
@test "proxy integration fixture images are pinned by tag and digest" {
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
}

@test "compose files do not keep shutdown workarounds from runtime debugging" {
	for file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/tests/proxy/fixtures/compose.yml"; do
		! grep -Eq '^[[:space:]]+(stop_signal|stop_grace_period|init):' "$file"
	done
}

@test "network bind settings are scoped per infrastructure service" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	database_compose="$REPO_ROOT/.docker/database-services.yml"

	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"
	grep -Fq 'host_ip: ${MYSQL_IP_BIND:-127.0.0.1}' "$database_compose"
	grep -Fq 'host_ip: ${POSTGRES_IP_BIND:-127.0.0.1}' "$database_compose"
	! grep -Rq '${IP_BIND' "$proxy_compose" "$database_compose" "$REPO_ROOT/docker-compose.yml"

	run env PROXY_IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'

	run env MYSQL_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 0.0.0.0'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 127.0.0.1'

	run env POSTGRES_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 127.0.0.1'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 0.0.0.0'
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
 "$REPO_ROOT/.docker/docker-compose.proxy.yml"
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

@test "network bind settings are scoped per infrastructure service" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	database_compose="$REPO_ROOT/.docker/database-services.yml"

	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"
	grep -Fq 'host_ip: ${MYSQL_IP_BIND:-127.0.0.1}' "$database_compose"
	grep -Fq 'host_ip: ${POSTGRES_IP_BIND:-127.0.0.1}' "$database_compose"
	! grep -Rq '${IP_BIND' "$proxy_compose" "$database_compose" "$REPO_ROOT/docker-compose.yml"

	run env PROXY_IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'

	run env MYSQL_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 0.0.0.0'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 127.0.0.1'

	run env POSTGRES_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 127.0.0.1'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 0.0.0.0'
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
 "$REPO_ROOT/.docker/docker-compose.proxy.yml")"
	[ "$proxy_socket_mounts" -eq 1 ]
}

@test "dashboard does not use innerHTML for Traefik route metadata" {
	dashboard="$REPO_ROOT/.docker/traefik/dashboard.html"
	! grep -q 'innerHTML' "$dashboard"
	grep -q 'heading.textContent = currentProject' "$dashboard"
	grep -q 'link.textContent = link.href' "$dashboard"
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
 "$REPO_ROOT/.docker/docker-compose.proxy.yml"
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}
@test "proxy integration fixture images are pinned by tag and digest" {
	grep -Eq '^[[:space:]]+image: nginx:[0-9]+\.[0-9]+\.[0-9]+-alpine@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
	grep -Eq '^[[:space:]]+image: docker:[0-9]+\.[0-9]+\.[0-9]+-cli@sha256:[0-9a-f]{64}$' "$REPO_ROOT/tests/proxy/fixtures/compose.yml"
}

@test "compose files do not keep shutdown workarounds from runtime debugging" {
	for file in "$REPO_ROOT/docker-compose.yml" "$REPO_ROOT/tests/proxy/fixtures/compose.yml"; do
		! grep -Eq '^[[:space:]]+(stop_signal|stop_grace_period|init):' "$file"
	done
}

@test "network bind settings are scoped per infrastructure service" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	database_compose="$REPO_ROOT/.docker/database-services.yml"

	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"
	grep -Fq 'host_ip: ${MYSQL_IP_BIND:-127.0.0.1}' "$database_compose"
	grep -Fq 'host_ip: ${POSTGRES_IP_BIND:-127.0.0.1}' "$database_compose"
	! grep -Rq '${IP_BIND' "$proxy_compose" "$database_compose" "$REPO_ROOT/docker-compose.yml"

	run env PROXY_IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'

	run env MYSQL_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 0.0.0.0'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 127.0.0.1'

	run env POSTGRES_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 127.0.0.1'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 0.0.0.0'
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
 "$REPO_ROOT/.docker/docker-compose.proxy.yml"
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

@test "network bind settings are scoped per infrastructure service" {
	proxy_compose="$REPO_ROOT/.docker/docker-compose.proxy.yml"
	database_compose="$REPO_ROOT/.docker/database-services.yml"

	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:80:80"' "$proxy_compose"
	grep -Fq '"${PROXY_IP_BIND:-127.0.0.1}:443:443"' "$proxy_compose"
	grep -Fq 'host_ip: ${MYSQL_IP_BIND:-127.0.0.1}' "$database_compose"
	grep -Fq 'host_ip: ${POSTGRES_IP_BIND:-127.0.0.1}' "$database_compose"
	! grep -Rq '${IP_BIND' "$proxy_compose" "$database_compose" "$REPO_ROOT/docker-compose.yml"

	run env PROXY_IP_BIND=0.0.0.0 docker compose --file "$proxy_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -q 'host_ip: 0.0.0.0'

	run env MYSQL_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 0.0.0.0'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 127.0.0.1'

	run env POSTGRES_IP_BIND=0.0.0.0 docker compose --file "$database_compose" config
	[ "$status" -eq 0 ]
	printf '%s\n' "$output" | grep -B5 -A5 'target: 3306' | grep -q 'host_ip: 127.0.0.1'
	printf '%s\n' "$output" | grep -B5 -A5 'target: 5432' | grep -q 'host_ip: 0.0.0.0'
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
	done < <(find "$REPO_ROOT/.github/workflows" -type f \( -name '*.yml' -o -name '*.yaml' \))
}
