# Advanced setup

## Environment variables

The development environment can be customized through environment variables.

An `.env` file is optional. Variables can also be provided inline:

```bash
VERSION_NEXTCLOUD=stable33 docker compose up
```

By default, `VERSION_NEXTCLOUD` uses `master`. To use another Nextcloud version, set it to the corresponding branch from the [Nextcloud server repository](https://github.com/nextcloud/server).

## Database

MySQL is used by default:

```bash
docker compose up
```

The supported `DB_HOST` values are:

- `mysql`
- `pgsql`

To use PostgreSQL:

```bash
DB_HOST=pgsql docker compose up
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

## Multiple environments

Multiple checkouts can run at the same time.

Docker uses the standard host ports when they are available. If a port is already in use, another available port is selected automatically.

Start each environment from its own directory:

```bash
cd /path/to/first-checkout
docker compose up
```

```bash
cd /path/to/second-checkout
docker compose up
```

To see the ports assigned to an environment:

```bash
docker compose ps
```

To check a specific port, use:

```bash
docker compose port nginx 80
```

For example, if it returns:

```text
0.0.0.0:81
```

access Nextcloud at:

```text
http://localhost:81
```

When port `80` is available, Nextcloud remains accessible normally at:

```text
http://localhost
```

A specific host port can still be requested explicitly:

```bash
HTTP_PORT=9000 HTTPS_PORT=9443 docker compose up
```

By default, published services bind to `127.0.0.1`. To expose them on other host interfaces, set:

```bash
IP_BIND=0.0.0.0 docker compose up
```

HTTP and HTTPS use automatic ranges beginning at ports `80` and `443` when no override is provided. The example above forces `host:9000 -> container:80` and `host:9443 -> container:443`.

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
