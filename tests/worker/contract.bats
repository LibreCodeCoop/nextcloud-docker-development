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

@test "MariaDB 10.6 selects the pinned 10.6 service" {
	run env DB_TYPE=mariadb MARIADB_VERSION=10.6 sh "$WORKER" maria106 config
	[ "$status" -eq 0 ]
	[[ "$output" == *"mariadb:10.6.28@sha256:23616f0bd3aff922f4dea4130f1d0a09f3571d20b7b36c8f49840672dc309e8c"* ]]
	[[ "$output" == *"DB_TYPE: mariadb"* ]]
	[[ "$output" == *"DB_DRIVER: mysql"* ]]
}

@test "MariaDB 10.11 selects the pinned 10.11 service" {
	run env DB_TYPE=mariadb MARIADB_VERSION=10.11 sh "$WORKER" maria1011 config
	[ "$status" -eq 0 ]
	[[ "$output" == *"mariadb:10.11.19@sha256:07c0aaff7396b74cb7975cba78257178d188e30f531a5db2b617c48beef13c41"* ]]
}

@test "unsupported MariaDB versions fail before startup" {
	run env DB_TYPE=mariadb MARIADB_VERSION=11.4 sh "$WORKER" maria114 config
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

@test "worker accepts a generic Compose override with multiple app mounts" {
	override="$REPO_ROOT/tests/worker/fixtures/compose-extension.yml"
	app_a="$REPO_ROOT/tests/worker/fixtures/sample-app"
	app_b="$REPO_ROOT/tests/worker/fixtures/other-app"

	run env \
		NCDD_COMPOSE_OVERRIDE="$override" \
		TEST_APP_A="$app_a" \
		TEST_APP_B="$app_b" \
		DB_TYPE=sqlite \
		sh "$WORKER" compose-extension config

	[ "$status" -eq 0 ]
	[[ "$output" == *"source: $app_a"* ]]
	[[ "$output" == *"target: /var/www/html/apps-extra/sample_app"* ]]
	[[ "$output" == *"source: $app_b"* ]]
	[[ "$output" == *"target: /var/www/html/apps-extra/other_app"* ]]
}

@test "worker rejects a missing Compose override before startup" {
	run env NCDD_COMPOSE_OVERRIDE="$REPO_ROOT/does-not-exist.yml" sh "$WORKER" missing-override config
	[ "$status" -eq 2 ]
	[[ "$output" == *"NCDD_COMPOSE_OVERRIDE is not a file"* ]]
}

@test "worker CI does not pin a concrete PHP series" {
	workflow="$REPO_ROOT/.github/workflows/worker-tests.yml"
	! grep -Eq 'Dockerfile\.php[0-9]+|nextcloud-dev-php[0-9]+' "$workflow"
}
