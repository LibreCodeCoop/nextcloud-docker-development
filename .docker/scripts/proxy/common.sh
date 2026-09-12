#!/bin/sh

proxy_project=${PROXY_PROJECT:-librecode-dev-proxy}
proxy_network=${PROXY_NETWORK:-librecode-dev-proxy}
proxy_label=${PROXY_LABEL:-coop.librecode.dev-proxy=true}
proxy_client_label=${PROXY_CLIENT_LABEL:-coop.librecode.dev-proxy-client=true}
proxy_assets_volume=${PROXY_ASSETS_VOLUME:-librecode-dev-proxy-assets}
proxy_vhost_volume=${PROXY_VHOST_VOLUME:-librecode-dev-proxy-vhost}

Docker() {
	docker "$@"
}

container_project() {
	Docker inspect \
		--format '{{ index .Config.Labels "com.docker.compose.project" }}' \
		"$1" 2>/dev/null || true
}

container_virtual_host() {
	Docker inspect \
		--format '{{range .Config.Env}}{{println .}}{{end}}' \
		"$1" 2>/dev/null |
		sed -n 's/^VIRTUAL_HOST=//p' |
		head -n 1
}

container_networks() {
	Docker inspect \
		--format '{{ json .NetworkSettings.Networks }}' \
		"$1" 2>/dev/null || true
}

compose() {
	Docker compose \
		--project-name "$project" \
		--project-directory "$PROJECT_DIR" \
		--file "${PROJECT_COMPOSE_FILE:-$PROJECT_DIR/docker-compose.yml}" \
		"$@"
}

proxy_compose() {
	Docker compose \
		--project-name "$proxy_project" \
		--project-directory "$PROJECT_DIR" \
		--file "${PROXY_COMPOSE_FILE:-$PROJECT_DIR/.docker/docker-compose.proxy.yml}" \
		"$@"
}
