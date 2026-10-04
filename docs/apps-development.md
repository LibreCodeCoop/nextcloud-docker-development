# Start development of apps

Nextcloud applications can be developed directly under
`volumes/nextcloud/apps-extra`. That directory may contain one application or
dozens of applications required by the development environment.

For isolated workers, an external directory can be used as the worker workspace.
The workspace is mounted as the complete `/var/www/html/apps-extra` directory,
so NCDD does not need to know which applications it contains.

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

## Worker workspace

A workspace is simply a directory containing the applications needed by that
worker:

```text
/tmp/workspaces/issue-123/
├── app_a/
├── app_b/
└── any_other_app/
```

Start an isolated worker with that directory:

```bash
NCDD_WORKSPACE=/tmp/workspaces/issue-123 \
DB_TYPE=sqlite \
sh ./dev-worker issue-123 up
```

The complete workspace is mounted at:

```text
/var/www/html/apps-extra
```

NCDD does not assign a primary application, manage application repositories or
limit how many applications the workspace contains. Clones, Git worktrees and
other source layouts are the responsibility of the caller.

Application-specific setup remains owned by the application repository or the
agent operating the worker:

```bash
NCDD_WORKSPACE=/tmp/workspaces/issue-123 \
DB_TYPE=sqlite \
sh ./dev-worker issue-123 exec sh -lc \
  'cd /var/www/html/apps-extra/app_a && composer install'
```

Worker runtime state remains under `.workers/<worker-id>`; destroying a worker
never deletes its external workspace.

⬅️ [Back to index](../README.md)
