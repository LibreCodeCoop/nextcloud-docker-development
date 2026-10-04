# Advanced setup

## Environment variables

The development environment can be customized through environment variables.

An `.env` file is optional. Variables can also be provided inline:

```bash
VERSION_NEXTCLOUD=stable33 docker compose up
```

By default, `VERSION_NEXTCLOUD` uses `master`. To use another Nextcloud version, set it to the corresponding branch from the [Nextcloud server repository](https://github.com/nextcloud/server).

Xdebug can be configured with its native `XDEBUG_MODE` variable:

```bash
XDEBUG_MODE=debug docker compose up
XDEBUG_MODE=develop,debug docker compose up
XDEBUG_MODE=coverage docker compose up
```

## Database

MySQL is used by default:

```bash
docker compose up
```

Use `DB_TYPE` to select the database backend and keep `DB_HOST` for the
connection hostname.

The currently implemented backends are:

- `sqlite`
- `mysql` (default)
- `mariadb`
- `pgsql`

To use PostgreSQL:

```bash
DB_TYPE=pgsql docker compose up
```

Existing callers that use `DB_HOST=pgsql docker compose up` remain supported
for compatibility. New automation should use `DB_TYPE`.

### Isolated workers

The `dev-worker` helper gives automation a deterministic Compose project and
mutable data directory per worker:

```bash
sh ./dev-worker test-a up
sh ./dev-worker test-a exec occ status
sh ./dev-worker test-a logs
sh ./dev-worker test-a destroy
```

Select the existing PHP and Nextcloud dimensions in the same invocation:

```bash
PHP_VERSION=83 VERSION_NEXTCLOUD=stable35 DB_TYPE=pgsql \
  sh ./dev-worker test-pg up
```

Each worker stores mutable state under `.workers/<worker-id>/volumes` and uses
its own Compose project name. Destroying one worker removes only that worker's
Compose resources and mutable directory.

SQLite workers do not start a network database container. Their database file
lives inside the worker's isolated Nextcloud filesystem:

```bash
DB_TYPE=sqlite sh ./dev-worker sqlite-a up
DB_TYPE=sqlite sh ./dev-worker sqlite-a status
DB_TYPE=sqlite sh ./dev-worker sqlite-a destroy
```

MariaDB workers support the 10.6 and 10.11 series without editing Compose YAML:

```bash
DB_TYPE=mariadb MARIADB_VERSION=10.6 sh ./dev-worker maria106 up
DB_TYPE=mariadb MARIADB_VERSION=10.11 sh ./dev-worker maria1011 up
```

The worker maps each supported series to a pinned image. Use `DB_SQL_MODE` to
request a deterministic global SQL mode when a test suite needs one:

```bash
DB_TYPE=mariadb MARIADB_VERSION=10.11 DB_SQL_MODE=ONLY_FULL_GROUP_BY \
  sh ./dev-worker maria-full-group-by up
```

## Optional services

Optional services are enabled with Docker Compose profiles:

```bash
docker compose --profile eurooffice up
docker compose --profile playwright up
docker compose --profile signal up
docker compose --profile whatsapp up
```

Multiple profiles can be enabled together:

```bash
docker compose \
	--profile eurooffice \
	--profile playwright \
	up
```

## Public Nextcloud URL

By default, each environment is available through the shared proxy at
`https://<compose-project>.localhost`.

Remote development platforms may expose the proxy through a different public
hostname. Set `NEXTCLOUD_HOST` and, when needed, `NEXTCLOUD_PROTOCOL` so the
proxy routing and Nextcloud canonical URL stay consistent:

```bash
NEXTCLOUD_HOST=example.dev NEXTCLOUD_PROTOCOL=https docker compose up
```

These values configure the routed host, Nextcloud `trusted_domains`,
`overwritehost`, `overwriteprotocol`, diagnostics and the default Playwright
base URL. Do not bypass the proxy by forwarding the nginx service directly
under a different hostname.

## Multiple environments

Multiple checkouts can run at the same time. Each checkout keeps its own Compose network, while the shared development proxy connects to the active project networks.

Start each environment from its own directory:

```bash
cd /path/to/first-checkout
docker compose up
```

```bash
cd /path/to/second-checkout
docker compose up
```

The Compose project name is used to build the local hostnames. With project names `first-checkout` and `second-checkout`, Nextcloud is available at:

```text
https://first-checkout.localhost
https://second-checkout.localhost
```

Open `https://localhost` to see the active environments and their available service URLs.

If the directory name creates a long local hostname, use a shorter Compose project name without renaming the directory:

```bash
COMPOSE_PROJECT_NAME=dev docker compose up
```

The shared proxy owns host ports `80` and `443` and binds to `127.0.0.1` by default. To expose only the proxy on other network interfaces, set:

```bash
PROXY_IP_BIND=0.0.0.0 docker compose up
```

MySQL and PostgreSQL use independent bind settings and also default to `127.0.0.1`:

```bash
MYSQL_IP_BIND=0.0.0.0 docker compose up
POSTGRES_IP_BIND=0.0.0.0 DB_HOST=pgsql docker compose up
```

Expose development services only on trusted networks and with an appropriate host firewall.

## Docker daemon access

The proxy coordinator, reverse proxy, and certificate companion access the Docker daemon as part of the development workflow. This is an intentional trust boundary: code running through these infrastructure components can interact with the local Docker daemon.

Application containers do not receive the Docker socket. Use this development environment only with repository code you trust.

## PHP custom settings

Custom PHP settings can be added as `.ini` files in `volumes/php/`. This directory is ignored by Git and is mounted into the PHP container without replacing the default configuration bundled in the image.

For example, create `volumes/php/99-local.ini`:

```ini
memory_limit=1024M
upload_max_filesize=512M
```

Restart the PHP service after changing these files:

```bash
docker compose restart nextcloud
```

⬅️ [Back to index](../README.md)
