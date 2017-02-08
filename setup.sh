#!/bin/bash
set -e -o pipefail

help() {
cat << EOF
Usage: ./setup.sh [command]

Creates a Compose file with the appropriate environment variables for a Docker
Registry to be deployed on Triton. Optional subcommands:

env:     Set up the 'docker-compose.yml' file only.
build:   Builds the registry container.
ship:    Pushes the registry container to the Docker Hub.
help:    Display this message.

EOF
}

IMAGE="${IMAGE:-autopilotpattern/registry}"
TAG="${TAG:-latest}"


build() {
    docker build -t "${IMAGE}:${TAG}" .
}

ship() {
    docker push "${IMAGE}:${TAG}"
}

env() {
    echo -n "Provide Let's Encrypt domain name for registry [registry.example.com]: "
    read -r domain
    echo -n "Provide email associated w/ Let's Encrypt [example@example.com]: "
    read -r email
    echo -n "Provide Let's Encrypt environment [staging|production]: "
    read -r environ
    echo -n "Provide username for registry basic auth [myname]: "
    read -r userName
    echo -n "Provide password for registry basic auth [password1]: "
    read -r password
    echo -n "Provide internal secret for registry [or hit Enter to autogenerate]: "
    read -r secret
    echo -n "Provide port number to listen on [443]: "
    read -r portNumber
    echo -n "Provide CNS service name [registry]: "
    read -r cnsName
    echo -n "Provide Triton package [g4-highcpu-2G]: "
    read -r packageName

    domain="${domain:-registry.example.com}"
    email="${email:-example@example.com}"
    environ="${environ:-staging}"
    userName="${userName:-myname}"
    password="${password:-password1}"
    secret=${secret:-$(dd if=/dev/urandom bs=20 count=1 2> /dev/null | base64 | tr -d "\n\\/")}
    portNumber="${portNumber:-443}"
    cnsName="${cnsName:-registry}"
    packageName="${packageName:-g4-highcpu-2G}"

    sed "s/=PORT/=${portNumber}/" docker-compose.yml.tmpl | \
        sed "s/PORT:/${portNumber}:/" | \
        sed "s/CNS_NAME/${cnsName}/" | \
        sed "s/=DOMAIN/=${domain}/" | \
        sed "s/=EMAIL/=${email}/" | \
        sed "s/=ENVIRON/=${environ}/" | \
        sed "s/=USERNAME/=${userName}/" | \
        sed "s/=PASSWORD/=${password}/" | \
        sed "s/=SECRET/=${secret}/" | \
        sed "s/PACKAGE_NAME/${packageName}/" \
            > docker-compose.yml
}

# ---------------------------------------------------
# parse arguments


while true; do
    case $1 in
        help | env | build | ship) cmd=$1; break;;
        *) break;;
    esac
done

if [ -z "${cmd}" ]; then
    env
    exit
fi

shift
$cmd "${@}"
