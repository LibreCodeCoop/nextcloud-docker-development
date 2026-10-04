# Start development of apps

For new app-development workflows, keep the app checkout outside NCDD and use
the [downstream app and devcontainer contract](downstream-consumers.md). This
avoids cloning application source into NCDD's mutable Nextcloud data directory
and allows multiple isolated worktrees to reuse the same canonical runtime.

The legacy `volumes/nextcloud/apps-extra` workflow remains possible for
existing local setups, but downstream repositories should prefer the worker
contract for automation, concurrent worktrees and devcontainer integration.

## Example

```bash
APP_ID=my_app \
APP_SOURCE_DIR=/path/to/my_app \
DB_TYPE=sqlite \
sh ./dev-worker my-app up

DB_TYPE=sqlite sh ./dev-worker my-app urls
DB_TYPE=sqlite sh ./dev-worker my-app exec sh -lc \
  'cd /var/www/html/apps-extra/my_app && composer install'
```

The app checkout stays owned by the downstream repository. NCDD owns only the
isolated runtime state under `.workers/<worker-id>`.

⬅️ [Back to index](../README.md)
