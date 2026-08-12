# Advanced setup

## Environments

You can customize the environment before first run changing some environments entries.

An `.env` file is optional. You can also set values inline, for example `VERSION_NEXTCLOUD=stable33 docker compose up`.

`VERSION_NEXTCLOUD` For this environment, the recommended branch is `master`. If you need to work with another Nextcloud server version, use the matching branch from the [Nextcloud server repository](https://github.com/nextcloud/server).

## PHP custom settings

Custom PHP settings have to be applied on [`.docker/app/config/php.ini`](/.docker/app/config/php.ini) file.

⬅️ [Back to index](../README.md)
