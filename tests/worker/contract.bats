#!/usr/bin/env bats
# SPDX-FileCopyrightText: 2026 LibreCode coop and contributors
# SPDX-License-Identifier: AGPL-3.0-or-later

setup() {
	REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/../.." && pwd)"
	WORKER="$REPO_ROOT/dev-worker"
}

@test "worker id rejects path traversal and uppercase names" {
	run sh "$WORKER" '../bad' config
	[ "$status" -eq 2 ]

	run sh "$WORKER" 'WorkerA' config
	[ "$status" -eq 2 ]
}

@test "worker config isolates mutable paths and compose project names" {
	run sh "$WORKER" alpha config
	[ "$status" -eq 0 ]
	[[ "$output" == *"name: ncdev-alpha"* ]]
	[[ "$output" == *"$REPO_ROOT/.workers/alpha/volumes/nextcloud"* ]]

	run sh "$WORKER" beta config
	[ "$status" -eq 0 ]
	[[ "$output" == *"name: ncdev-beta"* ]]
	[[ "$output" == *"$REPO_ROOT/.workers/beta/volumes/nextcloud"* ]]
	[[ "$output" != *"$REPO_ROOT/.workers/alpha/volumes/nextcloud"* ]]
}

@test "DB_TYPE selects PostgreSQL while DB_HOST remains the connection host" {
	run env DB_TYPE=pgsql DB_HOST=database.internal sh "$WORKER" pg config
	[ "$status" -eq 0 ]
	[[ "$output" == *"image: postgres:13-alpine"* ]]
	[[ "$output" == *"DB_TYPE: pgsql"* ]]
	[[ "$output" == *"DB_HOST: database.internal"* ]]
}

@test "legacy DB_HOST PostgreSQL selection still resolves the PostgreSQL service" {
	run env DB_HOST=pgsql docker compose --project-directory "$REPO_ROOT" --file "$REPO_ROOT/docker-compose.yml" config
	[ "$status" -eq 0 ]
	[[ "$output" == *"image: postgres:13-alpine"* ]]
}

@test "SQLite is a supported worker backend" {
	run env DB_TYPE=sqlite sh "$WORKER" sqlite config
	[ "$status" -eq 0 ]
	[[ "$output" == *"DB_TYPE: sqlite"* ]]
	[[ "$output" == *"DB_DRIVER: sqlite"* ]]
}

@test "MariaDB version selects the matching configured service" {
	for version in 10.6 10.11; do
		service="mariadb${version//./}"
		run env DB_TYPE=mariadb MARIADB_VERSION="$version" sh "$WORKER" "maria-${version//./-}" config
		[ "$status" -eq 0 ]
		[[ "$output" == *"image: mariadb:$version"* ]]
		[[ "$output" == *"DB_TYPE: mariadb"* ]]
		[[ "$output" == *"DB_DRIVER: mysql"* ]]
		grep -q "^  $service:" "$REPO_ROOT/.docker/database-services.yml"
	done
}

@test "unsupported MariaDB versions fail before startup" {
	run env DB_TYPE=mariadb MARIADB_VERSION=99.99 sh "$WORKER" maria-unsupported config
	[ "$status" -eq 2 ]
	[[ "$output" == *"Unsupported MARIADB_VERSION"* ]]
}

@test "all PHP development images install PDO SQLite" {
	found=0
	for dockerfile in "$REPO_ROOT"/.docker/Dockerfile.php*; do
		[ -f "$dockerfile" ] || continue
		found=1
		grep -q 'pdo_sqlite' "$dockerfile"
	done
	[ "$found" -eq 1 ]
}

@test "worker mounts one workspace as the complete apps-extra directory" {
	workspace="$REPO_ROOT/tests/worker/fixtures/workspace"
	run env NCDD_WORKSPACE="$workspace" DB_TYPE=sqlite sh "$WORKER" workspace-config config
	[ "$status" -eq 0 ]
	[[ "$output" == *"source: $workspace"* ]]
	[[ "$output" == *"target: /var/www/html/apps-extra"* ]]
	[[ "$output" != *"target: /var/www/html/apps-extra/sample_app"* ]]
	[[ "$output" != *"target: /var/www/html/apps-extra/other_app"* ]]
}

@test "worker rejects a missing workspace before startup" {
	run env NCDD_WORKSPACE="$REPO_ROOT/does-not-exist" sh "$WORKER" missing-workspace config
	[ "$status" -eq 2 ]
	[[ "$output" == *"NCDD_WORKSPACE is not a directory"* ]]
}

@test "worker CI does not pin a concrete PHP series outside its matrix inputs" {
	workflow="$REPO_ROOT/.github/workflows/worker-tests.yml"
	! grep -Eq 'Dockerfile\.php[0-9]+|nextcloud-dev-php[0-9]+' "$workflow"
}

@test "MariaDB matrix version is not repeated in workflow conditionals or worker names" {
	workflow="$REPO_ROOT/.github/workflows/worker-tests.yml"
	! grep -Eq "matrix\.mariadb ==|MARIADB_VERSION\" = \"[0-9]|maria-[0-9]+-[0-9]+" "$workflow"
}


@test "worker accepts an explicit public Nextcloud URL" {
	run env DB_TYPE=sqlite NEXTCLOUD_HOST=example.test NEXTCLOUD_PROTOCOL=https sh "$WORKER" public-url config
	[ "$status" -eq 0 ]
	[[ "$output" == *"NEXTCLOUD_HOST: example.test"* ]]
	[[ "$output" == *"NEXTCLOUD_PROTOCOL: https"* ]]
	[[ "$output" == *"VIRTUAL_HOST: example.test"* ]]
}

