#!/bin/sh

runtime_version() {
	component="$1"

	case "$component" in
		docker)
			Docker version --format '{{.Server.Version}}'
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

	IFS=. read -r version_major version_minor version_patch <<EOF
$version
EOF
	IFS=. read -r maximum_major maximum_minor maximum_patch <<EOF
$maximum
EOF

	version_major="${version_major:-0}"
	version_minor="${version_minor:-0}"
	version_patch="${version_patch:-0}"
	maximum_major="${maximum_major:-0}"
	maximum_minor="${maximum_minor:-0}"
	maximum_patch="${maximum_patch:-0}"

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

project_name_needs_shortening_hint() {
	project_name="$1"
	[ -n "$project_name" ] || return 1

	[ "$project_name" = "${PROXY_REPOSITORY_PROJECT_NAME:-nextcloud-docker-development}" ] && return 0
	[ "${#project_name}" -gt "${PROXY_PROJECT_NAME_HINT_LENGTH:-20}" ]
}

runtime_diagnostics_json() {
	docker_version="$(runtime_version docker)"
	runc_version="$(runtime_version runc)"
	project_name="${PROJECT_NAME:-}"

	if runtime_has_known_shutdown_risk "$docker_version" "$runc_version"; then
		warnings='[{"code":"outdated-docker-runtime","message":"This Docker and runc combination may fail to stop containers correctly on recent Linux/AppArmor hosts. Update Docker Engine before investigating shutdown problems."}]'
	else
		warnings='[]'
	fi

	if project_name_needs_shortening_hint "$project_name"; then
		hints="[{\"code\":\"long-project-name\",\"projectName\":\"$project_name\",\"exampleHost\":\"$project_name-playwright.localhost\"}]"
	else
		hints='[]'
	fi

	printf '{"docker":"%s","runc":"%s","project":{"name":"%s"},"warnings":%s,"hints":%s}\n' \
		"$docker_version" "$runc_version" "$project_name" "$warnings" "$hints"
}

install_runtime_diagnostics() {
	dashboard_container="${PROXY_DASHBOARD_CONTAINER:-librecode-dev-dashboard}"

	if ! Docker inspect "$dashboard_container" >/dev/null 2>&1; then
		return 1
	fi

	runtime_diagnostics_json |
		Docker exec -i "$dashboard_container" \
			sh -c 'cat > /usr/share/nginx/html/runtime.json'
}
