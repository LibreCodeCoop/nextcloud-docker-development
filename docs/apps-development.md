# Develop a Nextcloud app

For a one-off local checkout, an app can still be placed under
`volumes/nextcloud/apps-extra` and used from the `nextcloud` container.

For app repositories that need a reusable development/devcontainer contract,
prefer the [downstream app consumer](downstream-consumers.md) workflow instead
of cloning or copying the full Docker Compose topology.

The consumer contract mounts the app checkout into `apps-extra` while this
repository remains responsible for Nextcloud, database, proxy, mail and runtime
services.

Example:

```bash
APP_SOURCE=/work/my-app APP_ID=my_app DB_TYPE=sqlite \
  sh ./dev-worker my-app up

APP_SOURCE=/work/my-app APP_ID=my_app DB_TYPE=sqlite \
  sh ./dev-worker my-app exec sh -lc 'cd /var/www/html/apps-extra/my_app && composer install'
```

See [Downstream app consumers](downstream-consumers.md) for setup hooks and the
minimal Compose adapter used by devcontainers.

⬅️ [Back to index](../README.md)
