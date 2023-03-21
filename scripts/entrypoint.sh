#!/bin/sh

cat <<EOF
################################################################################

Welcome to the ghcr.io/servercontainers/mysql

################################################################################

You'll find this container sourcecode here:

    https://github.com/ServerContainers/mysql

The container repository will be updated regularly.

################################################################################


EOF

## FUNCTIONS

exit_if_no_credentials_provided () {
  if [ "yes" != "$CREDENTIALS_PROVIDED" ]
  then
    >&2 echo ">> you need credentials for this action but no credentials were provided!";
    exit 1
  fi
}

init_db () {
  rm -rf /var/lib/mysql/*
  mysql_install_db --datadir=/var/lib/mysql --force --skip-name-resolve --skip-test-db

  chown -R mysql:mysql /var/lib/mysql

  mysqld_safe &
  sleep 3

  echo "GRANT ALL ON *.* TO $ADMIN_USER@'%' IDENTIFIED BY '$ADMIN_PASSWORD' WITH GRANT OPTION; FLUSH PRIVILEGES" | mysql

  killall mariadbd
  sleep 3
}

enable_backups () {
  if [ -z ${BACKUP_REPETITION_TIME+x} ]
  then
    echo ">> no \$BACKUP_REPETITION_TIME set, using default value"
    export BACKUP_REPETITION_TIME="1h"
  fi

  echo ">> using '$BACKUP_REPETITION_TIME' as \$BACKUP_REPETITION_TIME"

  echo ">> creating $MYSQL_DEFAULTS_FILE file"
  create_mysql_defaults_file
}

start_backup_loop () {
  echo ">> starting backup loop"
  sh -c "sleep 15; while true; do mysql-backup-helper.sh; sleep $BACKUP_REPETITION_TIME; done" &
}

create_mysql_defaults_file () {
cat > "$MYSQL_DEFAULTS_FILE" <<EOF
[client]
user="$ADMIN_USER"
password="$ADMIN_PASSWORD"
EOF
}


## MAIN

INITALIZED="/initialized"

if echo "$@" | grep mysqld_safe 2>/dev/null >/dev/null && [ ! -f "$INITALIZED" ]; then
  # variables stuff
  MY_IP=`ip a s eth0 | grep inet | awk '{print $2}' | sed 's/\/.*//g' | head -n1`

  CREDENTIALS_PROVIDED="yes"
  if [ -z ${ADMIN_USER+x} ]
  then
    >&2 echo ">> no \$ADMIN_USER specified"
    ADMIN_USER="\$ADMIN_USER"
    CREDENTIALS_PROVIDED="no"
  fi
  if [ -z ${ADMIN_PASSWORD+x} ]
  then
    >&2 echo ">> no \$ADMIN_PASSWORD specified"
    CREDENTIALS_PROVIDED="no"
  fi

  # backup stuff
  if [ -z ${BACKUP_ENABLED+x} ]
  then
    echo ">> disable auto-backups (mysqldump)"
  else
    echo ">> enable auto-backups (mysqldump)"
    echo ">> backups will be stored at default path"
    echo ">> !! link or overwrite it to gain access !!"
    exit_if_no_credentials_provided
    enable_backups
  fi

  # mysql daemon stuff
  echo ">> disable dns resolution for mysql (speeds it up)"
  sed -i 's/\[mysqld\]/&\nskip-host-cache\nskip-name-resolve/g' /etc/my.cnf
  
  echo ">> bind to all"
  sed -i 's/\[mysqld\]/&\nbind-address=0.0.0.0/g' /etc/my.cnf

  echo ">> disable other stuff"
  sed -i 's/symbolic-links/#symbolic-links/g' /etc/my.cnf
  sed -i 's/!includedir/#!includedir/g' /etc/my.cnf

  if [ ! -f /var/lib/mysql/ibdata1 ]; then
    echo ">> init db"
    exit_if_no_credentials_provided
    init_db
  fi
  echo ">> db installed"

  echo ">> set owner and group to current mysql user and group"
  chown -R mysql:mysql /var/lib/mysql

  # auto create db with user...
  if [ ! -z ${DB_NAME+x} ] && [ ! -z ${DB_USER+x} ] && [ ! -z ${DB_PASSWORD+x} ]
  then
    echo ">> auto configuring db '$DB_NAME' with user '$DB_USER' and password '<hidden>'"
    exit_if_no_credentials_provided

    echo "CREATE DATABASE $DB_NAME;" > /tmp/autocreatedb.mysql
    echo "CREATE USER '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD';" >> /tmp/autocreatedb.mysql
    echo "GRANT USAGE ON *.* TO '$DB_USER'@'%' IDENTIFIED BY '$DB_PASSWORD' REQUIRE NONE WITH MAX_QUERIES_PER_HOUR 0 MAX_CONNECTIONS_PER_HOUR 0 MAX_UPDATES_PER_HOUR 0 MAX_USER_CONNECTIONS 0;" >> /tmp/autocreatedb.mysql
    echo "GRANT ALL PRIVILEGES ON $DB_NAME.* TO '$DB_USER'@'%';" >> /tmp/autocreatedb.mysql
    echo "FLUSH PRIVILEGES;" >> /tmp/autocreatedb.mysql

    sh -c "sleep 3; mysql -u\"$ADMIN_USER\" -p\"$ADMIN_PASSWORD\" < /tmp/autocreatedb.mysql && echo '>> db '$DB_NAME' successfully installed'; rm /tmp/autocreatedb.mysql" &
  fi

  touch "$INITALIZED"
else
  echo ">> already initialized - direct start of mysqld"
fi

# start backup if not disabled
[ ! -z ${BACKUP_ENABLED+x} ] && start_backup_loop

##
# CMD
##
echo ">> CMD: exec docker CMD"
if echo "$@" | grep mysqld_safe >/dev/null 2>/dev/null; then
echo ">> you can connect via mysql cli with the following command:"
echo "   mysql -u $ADMIN_USER -p -h $MY_IP"
fi
echo "$@"
exec "$@"