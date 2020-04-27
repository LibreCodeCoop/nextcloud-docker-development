#!/usr/bin/env php
<?php
function dbIsUp() {
    try {
        $dsn = getenv('DB_ADAPTER').':dbname='.getenv('DB_NAME').';host='.getenv('DB_HOST');
        new PDO($dsn, getenv('DB_USER'), getenv('DB_PASSWD'));
    } catch(Exception $e) {
        echo $e->getMessage()."\n";
        return false;
    }
    return true;
}
while(!dbIsUp()) {
    sleep(1);
}
echo "DB OK\n";
