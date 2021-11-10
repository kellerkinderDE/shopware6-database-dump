# shopware6-database-dump
Dump a Shopware 6 database for backup or local environments (and filter GDPR data).

## Requirements
You need `gzip` and `mysqldump` installed and available via your `PATH`.

## Usage
Run `./shopware6-database-dump.sh` to see available options:

```
Dumps a Shopware 6 database with a bit of cleanup and a GDPR mode ignoring more data.

Usage:
  shopware6-database-dump.sh [filename.sql] --database db_name --user username [--host 127.0.0.1] [--port 3306] [--gdpr]
  shopware6-database-dump.sh [filename.sql] -d db_name -u username [-h 127.0.0.1] [-p 3306] [--gdpr]
  shopware6-database-dump.sh -h | --help

Arguments:
  filename.sql   Set output filename, will be gzipped, dump.sql by default

Options:
  -h --help      Display this help information.
  -d --database  Set database name
  -u --user      Set database user name
  -h --host      Set hostname for database server (default: 127.0.0.1)
  -p --port      Set database server port (default: 3306)
  --gdpr         Enable GDPR data filtering
```

## License
MIT
