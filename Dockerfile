FROM alpine:3.5
LABEL github.user="ServerContainers"

ENV MYSQL_DEFAULTS_FILE /mysql-defaults.cnf

RUN apk update \
 && apk add mysql \
            mysql-client \
 && rm -f /var/cache/apk/*

VOLUME ["/var/lib/mysql/", "/var/mysql-backup"]
EXPOSE 3306

COPY scripts /usr/local/bin/

HEALTHCHECK CMD ["docker-healthcheck.sh"]
CMD ["/usr/local/bin/startup.sh"]
