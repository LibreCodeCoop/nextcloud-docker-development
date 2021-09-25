#!/usr/bin/env php
<?php
function dbIsUp() {
    try {
        if ( getenv('POSTGRES_DB') && getenv('POSTGRES_USER') && getenv('POSTGRES_PASSWORD') && getenv('POSTGRES_HOST') ) {
            $dsn = 'pgsql:dbname='.getenv('POSTGRES_DB').';host='.getenv('POSTGRES_HOST');
            echo "Connecting to Postgres...\n";
            new PDO($dsn, getenv('POSTGRES_USER'), getenv('POSTGRES_PASSWORD'));
        } elseif ( getenv('MYSQL_DATABASE') && getenv('MYSQL_USER') && getenv('MYSQL_PASSWORD') && getenv('MYSQL_HOST') ) {
            $dsn = 'mysql:dbname='.getenv('MYSQL_DATABASE').';host='.getenv('MYSQL_HOST');
            echo "Connecting to MySQL...\n";
            new PDO($dsn, getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
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
