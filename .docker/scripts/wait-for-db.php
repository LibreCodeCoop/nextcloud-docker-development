#!/usr/bin/env php
<?php
$dbName = (getenv('DB_HOST') === 'mysql' ? '🐬' : '🐘' ) . getenv('DB_HOST');

echo "⌛ Waiting for database $dbName\n";

function dbIsUp(string $dbName): bool {
    try {
        if (getenv('DB_HOST') === 'mysql') {
            $dsn = getenv('DB_HOST') . ':dbname='.getenv('MYSQL_DATABASE').';host='.getenv('DB_HOST');
            new PDO($dsn, getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
        } elseif (getenv('DB_HOST') === 'pgsql') {
            $dsn = getenv('DB_HOST') . ':dbname='.getenv('POSTGRES_DB').';host='.getenv('DB_HOST');
            new PDO($dsn, getenv('POSTGRES_USER'), getenv('POSTGRES_PASSWORD'));
        } else {
            // Will use SQLite
            return true;
        }
    } catch(Exception $e) {
        echo "⌛ Database $dbName not ready yet\n";
        return false;
    }
    return true;
}

while(!dbIsUp($dbName)) {
    sleep(1);
}

echo "✅ Database $dbName ready\n";