#!/bin/bash

CONSUL=${CONSUL:-consul}

# Render the configuration template using env vars
preStart() {
    consul-template \
        -once \
        -dedup \
        -consul ${CONSUL}:8500 \
        -template "/etc/docker/registry/config.yml.ctmpl:/etc/docker/registry/config.yml"
}

help() {
    echo "Usage: ./reload.sh preStart  => first-run configuration for Nginx"
    echo "       ./reload.sh onChange  => [default] update Nginx config on upstream changes"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        onChange
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    preStart
    exit
done