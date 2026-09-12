#!/usr/bin/env bats

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"

	# shellcheck source=.docker/scripts/proxy/common.sh
	source "$REPO_ROOT/.docker/scripts/proxy/common.sh"
	# shellcheck source=.docker/scripts/proxy/diagnostics.sh
	source "$REPO_ROOT/.docker/scripts/proxy/diagnostics.sh"
}

@test "known old Docker and runc combination reports shutdown risk" {
	run runtime_has_known_shutdown_risk 25.0.2 1.1.12

	[ "$status" -eq 0 ]
}

@test "new Docker runtime does not report known shutdown risk" {
	run runtime_has_known_shutdown_risk 29.8.0 1.5.1

	[ "$status" -eq 1 ]
}

@test "new runc avoids warning even with old Docker" {
	run runtime_has_known_shutdown_risk 25.0.2 1.5.1

	[ "$status" -eq 1 ]
}

@test "runtime diagnostics include host versions without warning for current runtime" {
	runtime_version() {
		case "$1" in
			docker) printf '%s\n' 29.8.0 ;;
			runc) printf '%s\n' 1.5.1 ;;
		esac
	}

	run runtime_diagnostics_json

	[ "$status" -eq 0 ]
	[[ "$output" == *'"docker":"29.8.0"'* ]]
	[[ "$output" == *'"runc":"1.5.1"'* ]]
	[[ "$output" == *'"warnings":[]'* ]]
}

@test "runtime diagnostics warn for known old runtime combination" {
	runtime_version() {
		case "$1" in
			docker) printf '%s\n' 25.0.2 ;;
			runc) printf '%s\n' 1.1.12 ;;
		esac
	}

	run runtime_diagnostics_json

	[ "$status" -eq 0 ]
	[[ "$output" == *'"code":"outdated-docker-runtime"'* ]]
	[[ "$output" == *'Update Docker Engine'* ]]
}
