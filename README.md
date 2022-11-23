# Nextcloud development environment

An development apps environment for Nextcloud.

## Development environment

### Before first run

Copy `.env.example` to `.env` and change the values of `.env`

`VERSION_NEXTCLOUD` To this environment I recommend to use the branch `master`. If you need to work with old version of server, use other branch of [Nextcloud server repository](https://github.com/nextcloud/server).

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

You will need create (or clone) the folder of the app that you will work inside the folder `volumes/nextcloud/apps`. 
Good work!

## FAQ

**How to reset the entire setup?**
- Go down the containers, remove the folder volumes and go up. This will delete the database and Nextcloud volumes. Before do a backup of all that you don't want to lost, by example `volumes/nextcloud/config/config.php`

**How to upgrade to newest commits of server repository?**
- ```bash
  cd volumes/nextcloud
  git pull origin master
  ```

**What folder do I need to open my project on my IDE?**
- To work with PHP, I recommend to open in folder `volumes/nextcloud`
- To work only with frontend, you can directly open the folder of app that you are working

**How to use xdebug on VSCode or Codium?**
- Open the IDE on folder `volumes/nextcloud`
- setup the extension PHP Debug or PHP Extension Pack
- Press F5 to start debugging or go to "Run > Start debugging"
- Create a launch.json file to PHP
- Add the follow to your launch.json inside configuration named as `Listen for Xdebug`:
  ```json
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            }
  ```