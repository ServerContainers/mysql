#!/bin/sh -x

IMG="servercontainers/mysql"

PLATFORM="linux/amd64,linux/arm64,linux/arm/v7,linux/arm/v6"


if [ -z ${MYSQL_VERSION+x} ] || [ -z ${ALPINE_VERSION+x} ]; then
  docker-compose build -q --pull --no-cache
  export MYSQL_VERSION=$(docker run --rm -ti "$IMG" apk list 2>/dev/null | grep '\[installed\]' | grep "mysql-[0-9]" | cut -d " " -f1 | sed 's/mysql-//g' | tr -d '\r')
  export ALPINE_VERSION=$(docker run --rm -ti "$IMG" cat /etc/alpine-release | tail -n1 | tr -d '\r')
fi

if echo "$@" | grep -v "force" 2>/dev/null >/dev/null; then
  echo "check if image was already build and pushed - skip check on release version"
  echo "$@" | grep -v "release" && docker pull "$IMG:a$ALPINE_VERSION-m$MYSQL_VERSION" 2>/dev/null >/dev/null && echo "image already build" && exit 1
fi

docker buildx build -q --pull --no-cache --platform "$PLATFORM" -t "$IMG:a$ALPINE_VERSION-m$MYSQL_VERSION" --push .

echo "$@" | grep "release" 2>/dev/null >/dev/null && echo ">> releasing new latest" && docker buildx build -q --pull --platform "$PLATFORM" -t "$IMG:latest" --push .