# FAQ

## Reset setup

### Reset entire setup?

- Go down the containers
- Remove the folder volumes
- Go up the containers

This will delete the database and Nextcloud volumes. Before do a backup of all that you don't want to lost, by example `volumes/nextcloud/config/config.php`

## Upgrade to newest commits of server repository

- ```bash
  cd volumes/nextcloud
  git pull origin master
  ```

## Using IDE
### Workspace folder

- To work with PHP, I recommend to open in folder `volumes/nextcloud`
- To work only with frontend, you can directly open the folder of app that you are working

### Use xdebug on VSCode or Codium

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

## Fix permissions

- The default user id (`UID`) and group id (`GID`) of root user inside container is the same of your user in host machine. This is defined in `.env` file. If is different of 1000 and 1000, change in your `.env` file.
- Run the follow command to move all files to your UID and GID:
  ```bash
  sudo chown -R $USER:$USER volumes/nextcloud
  ```

⬅️ [Back to index](../README.md)
