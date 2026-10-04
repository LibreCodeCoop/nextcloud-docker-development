# Compose extensions and devcontainers

The base Docker Compose topology in this repository is the canonical Nextcloud
development runtime. Projects may extend that topology without teaching NCDD
which application is being developed.

This keeps one lifecycle for Nextcloud, PHP, databases, proxy, mail and optional
services while allowing a consumer to mount zero, one or many applications and
add project-specific services.

## Worker extension contract

Create a normal Compose override in the consuming project. For example:

```yaml
services:
  nextcloud:
    volumes:
      - /work/app-a:/var/www/html/apps-extra/app_a
      - /work/app-b:/var/www/html/apps-extra/app_b
  nginx:
    volumes:
      - /work/app-a:/var/www/html/apps-extra/app_a:ro
      - /work/app-b:/var/www/html/apps-extra/app_b:ro
```

Pass that file to the existing worker lifecycle:

```bash
NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
DB_TYPE=sqlite \
sh ./dev-worker project-a up
```

The same override must be supplied to worker commands that need the complete
Compose model:

```bash
NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
DB_TYPE=sqlite \
sh ./dev-worker project-a status

NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
DB_TYPE=sqlite \
sh ./dev-worker project-a destroy
```

The override is deliberately generic. NCDD does not assign a primary app,
persist an app id, decide where application source lives, or execute
application-specific setup hooks.

## Runtime dimensions

Compose extensions reuse the same worker dimensions as the base environment:

- `PHP_VERSION`
- `VERSION_NEXTCLOUD`
- `DB_TYPE`
- `MARIADB_VERSION` where applicable
- `DB_SQL_MODE` where applicable

Run:

```bash
sh ./dev-worker project-a urls
```

to print the deterministic Nextcloud and Mailpit hostnames for a worker.

## Application setup

Dependency installation, app enablement and other initialization belong to the
consumer repository. Keep those steps in its scripts, Makefile, task runner or
devcontainer lifecycle and invoke the NCDD worker when container access is
needed.

For example:

```bash
NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
sh ./dev-worker project-a exec sh -lc \
  'cd /var/www/html/apps-extra/app_a && composer install && occ app:enable app_a'
```

This avoids growing an NCDD API for application-specific setup.

## Devcontainers

A downstream devcontainer should remain a thin adapter over the same Compose
topology. It can use the `nextcloud` service as its runtime service and add a
project-owned override with its source mounts or extra services.

Do not copy the Nextcloud, database, proxy, mail or Redis definitions into the
application repository. Those remain owned by NCDD.

## Isolation

Each worker owns its Compose project name and mutable state under
`.workers/<worker-id>`. A Compose extension changes that worker's service
model but does not create a second lifecycle.

The worker id is an isolation namespace for development convenience, not a
security boundary between untrusted workloads sharing the same Docker daemon.
