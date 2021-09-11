#!/usr/bin/env php
<?php
function dbIsUp() {
    try {
        if ( !empty('POSTGRES_DB') && !empty('POSTGRES_USER') && !empty('POSTGRES_PASSWORD') && !empty('POSTGRES_HOST') ) {
            $dsn = 'pgsql:dbname='.getenv('POSTGRES_DB').';host='.getenv('POSTGRES_HOST');
            new PDO($dsn, getenv('POSTGRES_USER'), getenv('POSTGRES_PASSWORD'));
        }
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
