#!/usr/bin/env php
<?php
$dbName = (getenv('DB_TYPE') === 'mysql' ? '🐬' : '🐘' ) . getenv('DB_TYPE');

echo "⌛ Waiting for database $dbName\n";

function dbIsUp(string $dbName): bool {
    try {
        $dsn = getenv('DB_TYPE') . ':dbname='.getenv('DB_NAME').';host='.getenv('DB_HOST');
        new PDO($dsn, getenv('DB_USER'), getenv('DB_PASSWORD'));
    } catch(Exception $e) {
        echo "⛔ Unable to conect to $dbName server: " . $e->getMessage()."\n";
        return false;
    }
    return true;
}

while(!dbIsUp($dbName)) {
    sleep(1);
}

echo "✅ Database $dbName ready\n";