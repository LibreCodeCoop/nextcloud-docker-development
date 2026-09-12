#!/bin/sh

# Globals are provided by common.sh before this module is sourced.
# shellcheck disable=SC2154

runtime_version() {
	component="$1"

	case "$component" in
		docker)
			Docker version --format '{{.Server.Version}}'
			;;
		compose)
			Docker compose version --short
			;;
		runc)
			Docker version --format '{{range .Server.Components}}{{if eq .Name "runc"}}{{.Version}}{{end}}{{end}}'
			;;
	esac
}

version_at_most() {
	version="${1#v}"
	maximum="${2#v}"

	version="${version%%-*}"
	maximum="${maximum%%-*}"

	old_ifs="$IFS"
	IFS=.
	set -- $version
	version_major="${1:-0}"
	version_minor="${2:-0}"
	version_patch="${3:-0}"
	set -- $maximum
	maximum_major="${1:-0}"
	maximum_minor="${2:-0}"
	maximum_patch="${3:-0}"
	IFS="$old_ifs"

	[ "$version_major" -lt "$maximum_major" ] && return 0
	[ "$version_major" -gt "$maximum_major" ] && return 1
	[ "$version_minor" -lt "$maximum_minor" ] && return 0
	[ "$version_minor" -gt "$maximum_minor" ] && return 1
	[ "$version_patch" -le "$maximum_patch" ]
}

runtime_has_known_shutdown_risk() {
	docker_version="$1"
	runc_version="$2"

	version_at_most "$docker_version" "${PROXY_KNOWN_BAD_DOCKER_MAX:-25.0.2}" &&
		version_at_most "$runc_version" "${PROXY_KNOWN_BAD_RUNC_MAX:-1.1.12}"
}

runtime_diagnostics_json() {
	docker_version="$(runtime_version docker)"
	compose_version="$(runtime_version compose)"
	runc_version="$(runtime_version runc)"

	if runtime_has_known_shutdown_risk "$docker_version" "$runc_version"; then
		warnings='[{"code":"outdated-docker-runtime","message":"This Docker and runc combination may fail to stop containers correctly on recent Linux/AppArmor hosts. Update Docker Engine before investigating shutdown problems."}]'
	else
		warnings='[]'
	fi

	printf '{"docker":"%s","compose":"%s","runc":"%s","warnings":%s}\n' \
		"$docker_version" "$compose_version" "$runc_version" "$warnings"
}

install_runtime_diagnostics() {
	runtime_diagnostics_json |
		Docker run --rm -i \
			-v "$proxy_assets_volume:/target" \
			docker:29-cli \
			sh -c 'cat > /target/runtime.json'
}
