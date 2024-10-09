#!/bin/bash

if ! which podman &> /dev/null
then
    echo "podman not found" >&2
    exit 1
fi

container="docker.io/redis/redis-stack-server"

if podman ps | grep -qFe "$container"
then
    echo "redis container appears to be running" >&2
    exit 0
fi

exec podman run -d -p 6739:6379 docker.io/redis/redis-stack-server

