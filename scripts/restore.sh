#!/usr/bin/env bash
# Restores a database backup into the running compose stack. DESTROYS current database contents.
# Usage: scripts/restore.sh backups/db-<stamp>.sql.gz [backups/uploads-<stamp>.tar.gz]
set -euo pipefail
DB_FILE="${1:?usage: restore.sh <db-backup.sql.gz> [uploads-backup.tar.gz]}"; UP_FILE="${2:-}"
[ -f "$DB_FILE" ] || { echo "not found: $DB_FILE" >&2; exit 1; }
gzip -t "$DB_FILE"   # refuse a corrupt archive before touching the database

docker compose exec -T db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" -e "DROP DATABASE IF EXISTS \`$MYSQL_DATABASE\`; CREATE DATABASE \`$MYSQL_DATABASE\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"'
gzip -dc "$DB_FILE" | docker compose exec -T db sh -c 'mysql -uroot -p"$MYSQL_ROOT_PASSWORD" "$MYSQL_DATABASE"'
if [ -n "$UP_FILE" ]; then docker compose exec -T backend tar -C /app/uploads -xz < "$UP_FILE"; fi
# Dropping the database invalidates the API's pooled connections (no default schema) -> restart it.
docker compose restart backend >/dev/null
for i in $(seq 1 30); do docker compose exec -T backend wget -qO- http://127.0.0.1:4000/ready >/dev/null 2>&1 && break; sleep 2; done
echo "restore OK from $DB_FILE"
