#!/bin/sh

copy_to_named_volume() {
	volume="$1"
	source="$2"
	destination="$3"

	Docker run --rm -i \
		-v "$volume:/target" \
		docker:29-cli \
		sh -c 'cat > "/target/$1"' sh "$destination" \
		< "$source"
}

install_proxy_assets() {
	Docker volume create "$proxy_assets_volume" >/dev/null
	Docker volume create "$proxy_vhost_volume" >/dev/null

	Docker run --rm \
		-v "$proxy_assets_volume:/target" \
		docker:29-cli \
		sh -c 'rm -f /target/Procfile /target/docker-gen.cfg /target/dashboard.tmpl'

	copy_to_named_volume "$proxy_assets_volume" "$PROJECT_DIR/.docker/nginx-proxy/Procfile" Procfile
	copy_to_named_volume "$proxy_assets_volume" "$PROJECT_DIR/.docker/nginx-proxy/docker-gen.cfg" docker-gen.cfg
	copy_to_named_volume "$proxy_assets_volume" "$PROJECT_DIR/.docker/nginx-proxy/dashboard.tmpl" dashboard.tmpl

	Docker run --rm \
		-v "$proxy_vhost_volume:/target" \
		docker:29-cli \
		sh -c 'rm -f /target/librecode-localhost.conf /target/localhost /target/localhost_location_override /target/\*.localhost /target/\*.localhost_location_override'

	copy_to_named_volume "$proxy_vhost_volume" "$PROJECT_DIR/.docker/nginx-proxy/localhost_location_override" localhost_location_override
	copy_to_named_volume "$proxy_vhost_volume" "$PROJECT_DIR/.docker/nginx-proxy/*.localhost" '*.localhost'
	copy_to_named_volume "$proxy_vhost_volume" "$PROJECT_DIR/.docker/nginx-proxy/*.localhost_location_override" '*.localhost_location_override'
}
