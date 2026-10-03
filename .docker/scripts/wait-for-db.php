#!/usr/bin/env php
<?php
$dbType = getenv('DB_TYPE') ?: (getenv('DB_HOST') ?: 'mysql');
$dbHost = getenv('DB_HOST') ?: $dbType;
$dbName = ($dbType === 'mysql' ? '🐬' : ($dbType === 'pgsql' ? '🐘' : '💾')) . $dbType;

echo "⌛ Waiting for database $dbName\n";

function dbIsUp(string $dbName): bool {
    try {
        if ($GLOBALS['dbType'] === 'mysql' || $GLOBALS['dbType'] === 'mariadb') {
            $dsn = 'mysql:dbname='.getenv('MYSQL_DATABASE').';host='.$GLOBALS['dbHost'];
            new PDO($dsn, getenv('MYSQL_USER'), getenv('MYSQL_PASSWORD'));
        } elseif ($GLOBALS['dbType'] === 'pgsql') {
            $dsn = 'pgsql:dbname='.getenv('POSTGRES_DB').';host='.$GLOBALS['dbHost'];
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