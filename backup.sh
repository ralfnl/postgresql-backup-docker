#! /bin/sh

set -e

if [ "${POSTGRES_HOST}" = "**None**" ]; then
  if [ -n "${POSTGRES_PORT_5432_TCP_ADDR}" ]; then
    POSTGRES_HOST=$POSTGRES_PORT_5432_TCP_ADDR
    POSTGRES_PORT=$POSTGRES_PORT_5432_TCP_PORT
  else
    echo "You need to set the POSTGRES_HOST environment variable."
    exit 1
  fi
fi

if [ "${POSTGRES_USER}" = "**None**" ]; then
  echo "You need to set the POSTGRES_USER environment variable."
  exit 1
fi

if [ "${POSTGRES_PASSWORD}" = "**None**" ]; then
  echo "You need to set the POSTGRES_PASSWORD environment variable or link to a container named POSTGRES."
  exit 1
fi

# Proces vars
export PGPASSWORD=$POSTGRES_PASSWORD
POSTGRES_HOST_OPTS="-h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER"
KEEP_DAYS=$BACKUP_KEEP_DAYS
KEEP_WEEKS=`expr $((($BACKUP_KEEP_WEEKS * 7) + 1))`
KEEP_MONTHS=`expr $((($BACKUP_KEEP_MONTHS * 31) + 1))`
DATE_DAY=`date +%Y%m%d-%H%M%S`
DATE_WEEK=`date +%G%V`
DATE_MONTH=`date +%Y%m`

# Initialize dirs
mkdir -p "$BACKUP_DIR/daily/" "$BACKUP_DIR/weekly/" "$BACKUP_DIR/monthly/"

################################################################################
# Dump Global Server Settings

echo "Creating global settings dump from ${POSTGRES_HOST}...";
GFILE="$BACKUP_DIR/daily/globals-$DATE_DAY.sql";
pg_dumpall -g -h $POSTGRES_HOST -p $POSTGRES_PORT -U $POSTGRES_USER --file=$GFILE;

# Copy (hardlink) for each entry
ln -vf "$GFILE" "$BACKUP_DIR/weekly/globals-$DATE_WEEK.sql"
ln -vf "$GFILE" "$BACKUP_DIR/monthly/globals-$DATE_MONTH.sql";

# Clean old files
find "$BACKUP_DIR/daily" -maxdepth 1 -mtime +$KEEP_DAYS -name "globals-*.sql*" -exec rm -rf '{}' ';'
find "$BACKUP_DIR/weekly" -maxdepth 1 -mtime +$KEEP_WEEKS -name "globals-*.sql*" -exec rm -rf '{}' ';'
find "$BACKUP_DIR/monthly" -maxdepth 1 -mtime +$KEEP_MONTHS -name "globals-*.sql*" -exec rm -rf '{}' ';'

################################################################################
# Dump all databases

psql $POSTGRES_HOST_OPTS -d postgres -t -A -c "SELECT datname FROM pg_database WHERE datname not in ('template0', 'template1', 'postgres')" |
while read f;
  do
    echo "Creating dump of $f database from ${POSTGRES_HOST}...";
    DFILE="$BACKUP_DIR/daily/$f-$DATE_DAY.sqlc";
    pg_dump $POSTGRES_HOST_OPTS $POSTGRES_EXTRA_OPTS -d $f --format=c --file="$DFILE";

    # Copy (hardlink) for each entry
    ln -vf "$DFILE" "$BACKUP_DIR/weekly/$f-$DATE_WEEK.sqlc"
    ln -vf "$DFILE" "$BACKUP_DIR/monthly/$f-$DATE_MONTH.sqlc"

    # Clean old files
    find "$BACKUP_DIR/daily" -maxdepth 1 -mtime +$KEEP_DAYS -name "$f-*.sql*" -exec rm -rf '{}' ';'
    find "$BACKUP_DIR/weekly" -maxdepth 1 -mtime +$KEEP_WEEKS -name "$f-*.sql*" -exec rm -rf '{}' ';'
    find "$BACKUP_DIR/monthly" -maxdepth 1 -mtime +$KEEP_MONTHS -name "$f-*.sql*" -exec rm -rf '{}' ';'
done;

echo "SQL backup successful"
