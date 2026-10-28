#!/usr/bin/env bash
# Backs up the MySQL database and the uploaded doctor photos from the running compose stack.
# Usage: scripts/backup.sh [backup_dir]      (default: ./backups)
# Keeps the newest $KEEP backups (default 7).
set -euo pipefail
DIR="${1:-backups}"; KEEP="${KEEP:-7}"
STAMP=$(date -u +%Y%m%dT%H%M%SZ)
mkdir -p "$DIR"

docker compose exec -T db sh -c 'mysqldump -uroot -p"$MYSQL_ROOT_PASSWORD" --single-transaction --routines --no-tablespaces "$MYSQL_DATABASE"' \
  | gzip > "$DIR/db-$STAMP.sql.gz"
# A dump that is almost empty means mysqldump failed; do not keep a useless "backup".
[ "$(gzip -dc "$DIR/db-$STAMP.sql.gz" | grep -c 'CREATE TABLE')" -ge 5 ] || { rm -f "$DIR/db-$STAMP.sql.gz"; echo "backup FAILED: dump has no tables" >&2; exit 1; }

docker compose exec -T backend tar -C /app/uploads -cz . > "$DIR/uploads-$STAMP.tar.gz"

ls -1t "$DIR"/db-*.sql.gz      2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
ls -1t "$DIR"/uploads-*.tar.gz 2>/dev/null | tail -n +$((KEEP+1)) | xargs -r rm -f
echo "backup OK: $DIR/db-$STAMP.sql.gz  $DIR/uploads-$STAMP.tar.gz"
