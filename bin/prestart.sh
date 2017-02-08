#!/bin/sh

mkdir -p /auth
htpasswd -Bbn "${USERNAME}" "${PASSWORD}" > /auth/htpasswd

sed "s/PORT/${PORT}/" /etc/docker/registry/config.yml.tmpl | \
    sed "s/ENVIRON/${ENVIRON}/" | \
    sed "s/DOMAIN/${DOMAIN}/" | \
    sed "s/EMAIL/${EMAIL}/" | \
    sed "s/USERNAME/${USERNAME}/" \
        > /etc/docker/registry/config.yml
