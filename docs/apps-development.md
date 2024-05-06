# Start development of apps

You will need create (or clone) the folder of the app that you will work inside the folder `volumes/nextcloud/apps-extra`.

It's not required install all dependencis like php or nodejs to develop apps, with this project is only use the bash in container to compile app.

## Sample

Using the [LibreSign](https://github.com/LibreSign/libresign):

To install LibreSign in the structure of develop is required [up servicer](#up-services). After nextcloud config and install.
  - open folder `volumes/nextcloud/app-extra`
  - clone project with `git clone https://github.com/LibreSign/libresign.git`
  - open bash in nextcloud container with `docker compose exec -u www-data nextcloud bash`
  - go to folder `apps-extra/libresign`
    ```bash
    cd apps-extra/libresign
    ```
  - Now you can run all the necessaries commands to build the project, i.e:
    ```bash
    # download composer dependencies
    composer install
    # download JS dependencies
    npm ci
    # build and watch JS changes
    npm run watch
    ```

⬅️ [Back to index](../README.md)
