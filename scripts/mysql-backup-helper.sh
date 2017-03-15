#!/bin/sh

## MAIN

if [ -z ${BACKUP_PATH+x} ]
then
  BACKUP_PATH="/var/mysql-backup"
  echo ">> no \$BACKUP_PATH specified - using default value"
fi

RESTORE_PATH="$BACKUP_PATH/to_restore"

echo ">> using \$BACKUP_PATH: $BACKUP_PATH"
echo ">> using \$RESTORE_PATH: $RESTORE_PATH"

mkdir -p "$BACKUP_PATH" &> /dev/null
mkdir -p "$RESTORE_PATH" &> /dev/null

echo ">> searching for databases to import..."
for file in $(find "$RESTORE_PATH"/*.sql -type f); do
  if [ -e "$file" ]; then
    FILE_DB_NAME=$(basename "$file" | sed -e 's/\.sql$//g' -e 's/[^a-zA-Z0-9\-]//g')
    echo -n "  >> importing $FILE_DB_NAME... "
    mysql --defaults-extra-file="$MYSQL_DEFAULTS_FILE" "$I_DB_NAME" < "$file"
    echo "done"
  fi
done

DB_LIST=`echo "show databases;" | mysql --defaults-extra-file="$MYSQL_DEFAULTS_FILE" | tail -n +2 | grep -v "information_schema\|performance_schema"`

echo ">> backup of every single db"
for DB in $DB_LIST
do
	echo -n "  >> backing up '$DB'... "
	mysqldump --defaults-extra-file="$MYSQL_DEFAULTS_FILE" $DB > "$BACKUP_PATH/mysql-backup_$DB.sql"
	echo "  >> '$DB' finished"
	echo ""
done

echo ">> backup of complete sql server"
mysqldump --defaults-extra-file="$MYSQL_DEFAULTS_FILE" --all-databases > "$BACKUP_PATH/all-databases.sql"
