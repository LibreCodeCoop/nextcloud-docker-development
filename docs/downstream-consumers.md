# Downstream app consumers

`nextcloud-docker-development` can provide the canonical Nextcloud runtime for
another app repository without copying the infrastructure topology into that
repository.

## Worker contract

Point the worker at an app checkout with:

- `APP_SOURCE`: host path to the app checkout;
- `APP_ID`: directory name under `/var/www/html/apps-extra`;
- `APP_SETUP_HOOK`: optional POSIX shell script relative to the app checkout,
  executed as the mapped `www-data` user after Nextcloud is ready.

Example:

```bash
APP_SOURCE=/work/my-app APP_ID=my_app APP_SETUP_HOOK=.devcontainer/setup.sh \
  DB_TYPE=sqlite sh ./dev-worker my-app-worker up

APP_SOURCE=/work/my-app APP_ID=my_app DB_TYPE=sqlite \
  sh ./dev-worker my-app-worker exec occ app:enable my_app

APP_SOURCE=/work/my-app APP_ID=my_app DB_TYPE=sqlite \
  sh ./dev-worker my-app-worker destroy
```

The app is mounted into the Nextcloud and nginx services. The normal worker
contract still owns Compose naming, mutable state, database selection, runtime
logs and teardown.

## Devcontainer adapter

Docker Compose `include` can keep the infrastructure model owned by this
repository while a downstream repository keeps only a small adapter.

A consumer can keep a local Compose file similar to:

```yaml
include:
  - path:
      - ${NCDD_ROOT:?set NCDD_ROOT}/docker-compose.yml
      - ${NCDD_ROOT:?set NCDD_ROOT}/.docker/consumer-app.yml
    project_directory: ${NCDD_ROOT:?set NCDD_ROOT}
```

Set `APP_SOURCE` to an absolute path, `APP_ID` to the app directory name
and `APP_CONTAINER_PATH=/var/www/html/apps-extra/$APP_ID` before running Compose.
The downstream devcontainer can then use the included `nextcloud` service as its
runtime service.

This adapter does not redefine Nextcloud, database, proxy, mail or Redis
services. Changes to that infrastructure remain owned by
`nextcloud-docker-development`.

Docker Compose 2.20+ is required for the top-level `include` feature.

## Isolation

Each worker still receives its own Compose project and mutable directory. Two
consumers may therefore use the same `APP_ID` and container path while mounting
different source checkouts without sharing Nextcloud state.

The worker ID is an isolation namespace for development convenience, not a
security boundary between untrusted workloads sharing the same Docker daemon.
