# Docker MySQL/MariaDB-Server Container (servercontainers/mysql)
_maintained by ServerContainers_

[FAQ - All you need to know about the servercontainers Containers](https://marvin.im/docker-faq-all-you-need-to-know-about-the-marvambass-containers/)

## What is it

This Dockerfile (available as ___servercontainers/mysql___) gives you a MySQL/MariaDB SQL-Server on alpine. It is also possible to configure a auto mysqldump and restore mechanism.

For Configuration of the Server you use environment Variables.

It's based on the [alpine:latest](https://registry.hub.docker.com/_/alpine/) Image

View in Docker Registry [servercontainers/mysql](https://registry.hub.docker.com/u/servercontainers/mysql/)

View in GitHub [ServerContainers/docker-mysql](https://github.com/ServerContainers/docker-mysql)

## Environment variables and defaults

### MySQL Daemon

The daemon stores the database data beneath: __/var/lib/mysql__

* __ADMIN\_USER__
 * no default - needed only when _backup enabled_ or for _mysql initialisation_
* __ADMIN\_PASSWORD__
 * no default - needed only when _backup enabled_ or for _mysql initialisation_

### Backup

This is totaly optional - backup is disabled by default!  
In default it stores it's dumps beneath: __/var/mysql-backup__

* __BACKUP\_ENABLED__
 * default null, needs 'enable' to be enabled
* __BACKUP\_REPETITION\_SECONDS__
 * default: _3600_ seconds which is 1 hour the mysql dump will run
* __BACKUP\_PATH__
 * default: _/var/mysql-backup_ - the place to store the mysqldumps

### Optional DB & User auto-creation

* __DB\_NAME__
 * no default - required if you want the auto create a database with user
* __DB\_USER__
 * no default - required if you want the auto create a database with user
* __DB\_PASSWORD__
 * no default - required if you want the auto create a database with user


## Using the servercontainers/mysql Container

### Backups and restore

If you enabled the backup via environment variable, you get mysql dumps for each database, and one big sql dump containing all databases.

You can also use this to easily restore a single database. Just copy the sql dump to the backup folders subfolder __to\_restore__
with the __databasename__ as filename and __.sql__ as suffix.

for example: __to\_restore/nextcloud.sql__ will be imported as database __nextcloud__.

### Running MySQL

#### Quickstart (recommended)

The following example uses Docker Compose to start a example MySQL Server and a PhpMyAdmin Container

    docker-compose up

After that just open https://localhost/ - ingore the self signed certificate warning and login with your mysql admin credentials __admin__ / __password__.

#### Non persistent manual start

The following command starts a non persistent mysql database which will be lost after the container is deleted. (Great for testing!)

    docker run -d --name mysql \
    -e 'ADMIN_USER=dbadmin' -e 'ADMIN_PASSWORD=adminpw' \
    -e 'DB_NAME=testdb' -e 'DB_USER=testdbuser' -e 'DB_PASSWORD=usersecret' \
    servercontainers/mysql

#### Manual start

For the first start you'll need to provide the __ADMIN\_USER__ and __ADMIN\_PASSWORD__ variables

    docker run -d --name mysql \
    -e 'ADMIN_USER=dbadmin' -e 'ADMIN_PASSWORD=pa55worD!' \
    -e 'BACKUP_ENABLED=enable' \
    -p 3306:3306 \
    -v /tmp/mysqldata:/var/lib/mysql \
    -v /tmp/mysqlbackup:/var/mysql-backup \
    servercontainers/mysql

_you need to provide the admin credentials only if you start the container for the first time (so it can initialize a new Database) or if you use the internal mysqldump backup / restore mechanism_

### Connection example

Now you can connect to the MySQL Server via the normal mysql-client cli:

    mysql -u $ADMIN_USER -p -h $(docker inspect --format='{{.NetworkSettings.IPAddress}}' $CONTAINER_ID)
