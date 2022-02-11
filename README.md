# Nextcloud development environment

An development apps environment for Nextcloud.

## Development environment

### Before first run

Copy `.env.example` to `.env` and change the values of `.env`

`VERSION_NEXTCLOUD` To this environment get a or branch of [Nextcloud server repository](https://github.com/nextcloud/server).

If you want to use PostgreSQL, comment the environments of MySQL on `.env` and the MySQL service on `docker-compose.yml`. The same if you want to use MySQL, comment all about PostgreSQL on `.env` and on `docker-compose.yml`

### PHP custom settings

If you need custom settings in PHP, change the file [`.docker/app/config/php.ini`](/.docker/app/config/php.ini).

### Up services
```bash
docker-compose up
```
Access in the browser using the port defined on `HTTP_PORT`.

After finish the setup, access this url: http://localhost/.

## Start development of apps

You will need create (or clone) the folder of the app that you will work inside the folder `volumes/nextcloud/apps`. Because the owner of folder `apps` is the root user, you will need do the follow steps (using LibreSign app repository as example) to change the owner of folder `apps` to your user and group, clone the app and revert the owner of folder app to root again:

```sh
sudo chown $USER:$USER volumes/nextcloud/apps
git clone git@github.com:LibreSign/libresign.git volumes/nextcloud/apps/libresign
sudo chown www-data:www-data volumes/nextcloud/apps
```

Good work!

### LibreSign Setup

```sh
sudo chown $USER:$USER volumes/nextcloud/apps
git clone git@github.com:LibreSign/libresign.git volumes/nextcloud/apps/libresign
docker-compose exec nextcloud bash -c 'chown www-data:www-data /var/www/html/apps'

docker-compose exec -u www-data nextcloud php occ config:system:set --value=true debug
docker-compose exec -u www-data nextcloud php occ app:enable libresign
docker-compose exec -u www-data nextcloud php occ libresign:install --all
docker-compose exec -u www-data nextcloud php occ libresign:configure:cfssl --cn=LibreCode --ou=LibreCode --o=LibreCode --c=BR
```

#### Migrations

```sh
docker-compose exec -u www-data nextcloud php occ migrations:status libresign
docker-compose exec -u www-data nextcloud php occ migrations:migrate libresign
```