# mysql/mariadb - (ghcr.io/servercontainers/mysql) [x86 + arm]

mysql/mariadb on alpine with backup scheduler and restore mechanism

## What is it

This Dockerfile (ghcr.io/servercontainers/mysql) gives you a MySQL/MariaDB SQL-Server on alpine. It is also possible to configure an auto mariadb-dump and restore mechanism.

For Configuration of the Server you use environment Variables.

It's based on the [alpine](https://registry.hub.docker.com/_/alpine/) Image

View in GitHub Registry [ghcr.io/servercontainers/mysql](https://ghcr.io/servercontainers/mysql)

View in GitHub [ServerContainers/mysql](https://github.com/ServerContainers/mysql)

_currently tested on: x86_64, arm64, arm_

## IMPORTANT!

In March 2023 - Docker informed me that they are going to remove my 
organizations `servercontainers` and `desktopcontainers` unless 
I'm upgrading to a pro plan.

I'm not going to do that. It's more of a professionally done hobby then a
professional job I'm earning money with.

In order to avoid bad actors taking over my org. names and publishing potenial
backdoored containers, I'd recommend to switch over to my new github registry: `ghcr.io/servercontainers`.

## Build & Versions

You can specify `DOCKER_REGISTRY` environment variable (for example `my.registry.tld`)
and use the build script to build the main container and it's variants for _x86_64, arm64 and arm_

You'll find all images tagged like `a3.15.0-m10.6.4-r2` which means `a<alpine version>-m<mysql/mariadb version>`.
This way you can pin your installation/configuration to a certian version. or easily roll back if you experience any problems
(don't forget to open a issue in that case ;D).

To build a `latest` tag run `./build.sh release`

## Changelogs

* 2025-08-09
    * some updates, moved to mariadb naming
* 2023-03-20
    * github action to build container
    * implemented ghcr.io as new registry
* 2023-03-19
    * switched from docker hub to a build-yourself container
* 2023-01-19
    * fixed restore code
* 2022-01-31
    * rewrite and update, multi-arch build, versioning

## Environment variables and defaults

### MySQL Daemon

The daemon stores the database data beneath: __/var/lib/mysql__

* __ADMIN\_USER__
    * no default - needed only when _backup enabled_ or for _mysql initialisation_
* __ADMIN\_PASSWORD__
    * no default - needed only when _backup enabled_ or for _mysql initialisation_

### Optional Backup & Restore

Backup/Restore is disabled by default!  
In default it stores it's dumps beneath: __/var/mysql-backup__
If you enable it the restore mechanism is automatically enabled too.
In default it loads the restorable dumps from __/var/mysql-backup/to\_restore/*.sql__

* __BACKUP\_ENABLED__
    * default not set - if set to any value it enables backup/restore functionality
* __BACKUP\_REPETITION\_TIME__
    * default: _1h_ time the backup/restore will be rerun. can have an optional suffix of (s)econds, (m)inutes, (h)ours, or (d)ays
* __BACKUP\_PATH__
    * default: _/var/mysql-backup_ - the place to store the mariadb-dumps
* __RESTORE\_DISABLE__
    * default not set - if set to any value it disables restore functionality

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

_you need to provide the admin credentials only if you start the container for the first time (so it can initialize a new Database) or if you use the internal mariadb-dump backup / restore mechanism_

### Connection example

Now you can connect to the MySQL Server via the normal mysql-client cli:

    mysql -u $ADMIN_USER -p -h $(docker inspect --format='{{.NetworkSettings.IPAddress}}' $CONTAINER_ID)
