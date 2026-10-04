# Start development of apps

Nextcloud applications can continue to be developed directly under
`volumes/nextcloud/apps-extra`. That directory is an app space and may contain
as many applications as a development setup needs.

For repositories that keep application checkouts outside this repository, use a
[Compose extension](compose-extensions.md) rather than creating another
Nextcloud topology. The extension may mount one app, several apps, or add
supporting services while NCDD remains responsible for the runtime.

## Local apps-extra workflow

Clone or create applications under:

```text
volumes/nextcloud/apps-extra/
```

Then use the `nextcloud` container to install dependencies or run development
commands:

```bash
docker compose exec -u www-data nextcloud bash
cd apps-extra/my_app
composer install
npm ci
```

## External application checkouts

A project-specific Compose override can mount any number of source trees into
the same worker. For example:

```yaml
services:
  nextcloud:
    volumes:
      - /work/my_app:/var/www/html/apps-extra/my_app
      - /work/my_dependency:/var/www/html/apps-extra/my_dependency
```

Start the runtime with:

```bash
NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
DB_TYPE=sqlite \
sh ./dev-worker my-project up
```

Application-specific setup remains owned by the application repository. It can
run commands explicitly through the worker, for example:

```bash
NCDD_COMPOSE_OVERRIDE=/work/project/ncdd.override.yml \
DB_TYPE=sqlite \
sh ./dev-worker my-project exec sh -lc \
  'cd /var/www/html/apps-extra/my_app && composer install'
```

⬅️ [Back to index](../README.md)
