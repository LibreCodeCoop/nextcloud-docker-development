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

You will need create (or clone) the folder of the app that you will work inside the folder `volumes/nextcloud/apps-extra`.

It's not required install all dependencis like php or nodejs to develop apps, with this project is only use the bash in container to compile app.

## Sample using the [LibreSign](https://github.com/LibreSign/libresign)

To install LibreSign in the structure of develop is required [up servicer](#up-services). After nextcloud config and install.
  - open folder `/volumes/nextcloud/app-extra`
  - clone project with `git clone https://github.com/LibreSign/libresign.git`
  - open bash in nextcloud container with `docker compose exec -u www-data nextcloud /bin/bash`
  - open folder `/app-extra`
  - run commands to compile LibreSign, commands like: `make serve`


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
- setup the extension [PHP Debug](https://marketplace.visualstudio.com/items?itemName=xdebug.php-debug) or [PHP Extension Pack](https://marketplace.visualstudio.com/items?itemName=xdebug.php-pack)
- Press `F5` to start debugging or go to "`Run > Start debugging`"
- Create a `launch.json` file to PHP
- Add the follow to your `launch.json` inside configuration named as `Listen for Xdebug`:
  ```json
            "pathMappings": {
                "/var/www/html": "${workspaceFolder}"
            }
  ```
- **PS**: [`log_level`](https://xdebug.org/docs/all_settings#log_level) is defined to 0 (Criticals). If you wish a different value, ghante this at `.env` file.

**I havent permission to write in files of my project using my user**
- The default user id (`UID`) and group id (`GID`) of root user inside container is the same of your user in host machine. This is defined in `.env` file. If is different of 1000 and 1000, change in your `.env` file.
- Run the follow command to move all files to your UID and GID:
  ```
  sudo chown -R $USER:$USER volumes/nextcloud
  ```