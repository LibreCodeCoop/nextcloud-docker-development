# Worker workspaces and devcontainers

The base Docker Compose topology in this repository is the canonical Nextcloud
development runtime. A worker may optionally attach one external workspace
containing all applications needed by that environment.

This keeps the contract intentionally small: NCDD owns the runtime and the
caller owns the source directory.

## Workspace contract

A workspace is a normal host directory whose direct children are Nextcloud
application checkouts:

```text
/work/issue-123/
├── app_a/
├── app_b/
└── app_c/
```

Start a worker with:

```bash
NCDD_WORKSPACE=/work/issue-123 \
DB_TYPE=sqlite \
sh ./dev-worker issue-123 up
```

NCDD mounts that directory as:

```text
/var/www/html/apps-extra
```

The workspace can contain zero, one or many applications. NCDD does not know
which application is primary, how repositories were created, or which
application an agent intends to modify.

Without `NCDD_WORKSPACE`, the existing local
`volumes/nextcloud/apps-extra` behavior is unchanged.

## Runtime dimensions

The workspace reuses the same worker dimensions as the base environment:

- `PHP_VERSION`
- `VERSION_NEXTCLOUD`
- `DB_TYPE`
- `MARIADB_VERSION` where applicable
- `DB_SQL_MODE` where applicable

For example:

```bash
NCDD_WORKSPACE=/work/pr-123 \
PHP_VERSION=83 \
VERSION_NEXTCLOUD=stable35 \
DB_TYPE=mariadb \
sh ./dev-worker pr-123 up
```

## Application setup

Dependency installation, builds and app enablement belong to the caller rather
than the NCDD lifecycle:

```bash
NCDD_WORKSPACE=/work/pr-123 \
sh ./dev-worker pr-123 exec sh -lc \
  'cd /var/www/html/apps-extra/app_a && composer install'
```

This lets agents create whatever set of app worktrees a task requires without
expanding the NCDD API for individual applications.

## Isolation and cleanup

Each worker owns its Compose project name and mutable state under
`.workers/<worker-id>`. The workspace is external source state and is never
removed by `dev-worker destroy`.

Workers can therefore run in parallel with different PHP, Nextcloud and
database dimensions and with completely different application directories.

## Devcontainers

A downstream devcontainer should use the same worker contract instead of
carrying a second Compose topology. The application repository or agent can
prepare a workspace, start the worker and then execute development commands in
the `nextcloud` service.

The worker id is an isolation namespace for development convenience, not a
security boundary between untrusted workloads sharing the same Docker daemon.
