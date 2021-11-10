# shopware6-database-dump
Dump a Shopware 6 database for backup or local environments (and filter GDPR data).

If you're using the official Klarna, PAYONE or Unzer plugins, all relevant GDPR data will be filtered for their tables
as well.

## Requirements
You need `gzip` and `mysqldump` installed and available via your `PATH`.
MySQL will be accessed via IP, sockets are not supported yet.

## Usage
Run `./shopware6-database-dump.sh` to see available options:

```
Dumps a Shopware 6 database with a bit of cleanup and a GDPR mode ignoring more data.

Usage:
  shopware6-database-dump.sh --database db_name --user username [--host 127.0.0.1] [--port 3306] [--gdpr]
  shopware6-database-dump.sh -d db_name -u username [-h 127.0.0.1] [-p 3306] [--gdpr]
  shopware6-database-dump.sh -h | --help

Options:
  -h --help      Display this help information.
  -d --database  Set database name
  -u --user      Set database user name
  -h --host      Set hostname for database server (default: 127.0.0.1)
  -p --port      Set database server port (default: 3306)
  --gdpr         Enable GDPR data filtering
```

Your dump will be written to `dump.sql.gz`.

## License
MIT
