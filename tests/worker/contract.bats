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

@test "MariaDB remains reserved for its dedicated implementation" {
	run env DB_TYPE=mariadb sh "$WORKER" mariadb config
	[ "$status" -eq 3 ]
	[[ "$output" == *"not implemented yet"* ]]
}

@test "supported PHP images install PDO SQLite" {
	for dockerfile in "$REPO_ROOT"/.docker/Dockerfile.php81 "$REPO_ROOT"/.docker/Dockerfile.php82 "$REPO_ROOT"/.docker/Dockerfile.php83; do
		grep -q 'pdo_sqlite' "$dockerfile"
	done
}
