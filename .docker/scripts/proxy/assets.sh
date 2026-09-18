#!/bin/sh

proxy_helper_image() {
	if [ -n "${PROXY_HELPER_IMAGE:-}" ]; then
		printf '%s\n' "$PROXY_HELPER_IMAGE"
		return 0
	fi

	container_image "${COORDINATOR_CONTAINER:-}"
}

copy_to_named_volume() {
	volume="$1"
	source="$2"
	destination="$3"
	helper_image="$(proxy_helper_image)"

	[ -n "$helper_image" ] || return 1

	Docker run --rm -i \
		-v "$volume:/target" \
		"$helper_image" \
		tee "/target/$destination" \
		< "$source" >/dev/null
}

install_proxy_assets() {
	assets_volume="$(proxy_assets_volume_name)"
	vhost_volume="$(proxy_vhost_volume_name)"
	helper_image="$(proxy_helper_image)"

	[ -n "$helper_image" ] || return 1

	Docker volume create "$assets_volume" >/dev/null
	Docker volume create "$vhost_volume" >/dev/null

	Docker run --rm \
		-v "$assets_volume:/target" \
		"$helper_image" \
		sh -c 'rm -f /target/Procfile /target/docker-gen.cfg /target/dashboard.tmpl'

	copy_to_named_volume "$assets_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/Procfile" Procfile
	copy_to_named_volume "$assets_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/docker-gen.cfg" docker-gen.cfg
	copy_to_named_volume "$assets_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/dashboard.tmpl" dashboard.tmpl

	Docker run --rm \
		-v "$vhost_volume:/target" \
		"$helper_image" \
		sh -c 'rm -f /target/librecode-localhost.conf /target/localhost /target/localhost_location_override /target/\*.localhost /target/\*.localhost_location_override'

	copy_to_named_volume "$vhost_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/localhost_location_override" localhost_location_override
	copy_to_named_volume "$vhost_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/*.localhost" '*.localhost'
	copy_to_named_volume "$vhost_volume" "${PROJECT_DIR:-}/.docker/nginx-proxy/*.localhost_location_override" '*.localhost_location_override'
}
