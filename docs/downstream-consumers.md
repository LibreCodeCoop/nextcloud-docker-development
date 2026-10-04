# Downstream app and devcontainer contract

This repository can be the canonical Nextcloud runtime for downstream app
repositories. A consumer keeps its application checkout outside this repository
and mounts it into an isolated worker instead of copying the Compose topology.

## Worker contract

Provide an app identifier and checkout path when a worker is created:

```bash
APP_ID=my_app \
APP_SOURCE_DIR=/path/to/my_app \
DB_TYPE=sqlite \
sh ./dev-worker my-app up
```

The worker persists the app binding under its own `.workers/<worker-id>`
metadata. Later commands only need the worker id and the runtime dimensions:

```bash
DB_TYPE=sqlite sh ./dev-worker my-app status
DB_TYPE=sqlite sh ./dev-worker my-app exec pwd
DB_TYPE=sqlite sh ./dev-worker my-app urls
DB_TYPE=sqlite sh ./dev-worker my-app destroy
```

The checkout is mounted at:

```text
/var/www/html/apps-extra/<APP_ID>
```

The same checkout is visible to the Nextcloud, nginx and optional Playwright
services through `.docker/downstream-app.yml`.

A worker cannot be rebound to a different app id or checkout path. Destroy the
worker first when you intentionally want a new binding.

## Runtime dimensions

The downstream contract reuses the same worker options as native NCDD workers:

- `PHP_VERSION`
- `VERSION_NEXTCLOUD`
- `DB_TYPE`
- `MARIADB_VERSION` where applicable
- `DB_SQL_MODE` where applicable

No fixed host application or mail port is required. Run:

```bash
sh ./dev-worker my-app urls
```

to get deterministic hostnames based on the worker's Compose project name.

## Post-readiness setup

A downstream project can run an idempotent command inside the Nextcloud
container after the worker becomes ready:

```bash
APP_ID=my_app \
APP_SOURCE_DIR=/path/to/my_app \
APP_SETUP_COMMAND='cd /var/www/html/apps-extra/my_app && composer install && occ app:enable my_app' \
sh ./dev-worker my-app up
```

`APP_SETUP_COMMAND` is intentionally executed as a shell command inside the
development container. Treat it as trusted developer input; do not populate it
from untrusted issue, PR or network content.

## Devcontainer adapters

The runtime service intended for a downstream devcontainer is `nextcloud`.
The reusable Compose pieces are:

```text
/path/to/nextcloud-docker-development/docker-compose.yml
/path/to/nextcloud-docker-development/.docker/downstream-app.yml
```

A downstream `.devcontainer` should stay thin: it may select the `nextcloud`
service and its workspace folder, while NCDD continues to own the Nextcloud,
database, proxy, mail and supporting service definitions.

The consumer must supply the same contract variables used by `dev-worker`:
a unique `COMPOSE_PROJECT_NAME`, isolated `WORKER_VOLUMES_DIR`,
`APP_ID`, absolute `APP_SOURCE_DIR`, and
`APP_TARGET_DIR=/var/www/html/apps-extra/<APP_ID>`.

The LibreSign migration is tracked separately; this contract intentionally
contains no LibreSign-specific setup.

## Isolation guarantees

Each worker owns:

- a Compose project name;
- a mutable volume directory;
- persisted downstream app binding metadata;
- database state when a network database is selected;
- deterministic `*.localhost` service hostnames.

Destroying one worker removes only that worker's Compose resources and mutable
state. The downstream source checkout is a bind mount and is never deleted by
`destroy`.
