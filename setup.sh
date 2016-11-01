#!/bin/bash
set -e -o pipefail

help() {
    echo
    echo 'Usage ./setup.sh'
    echo
    echo 'Checks that your Triton and Docker environment is sane and configures'
    echo 'an environment file to use.'
    echo
    echo 'Additional details must be configured in the _env file.'
    echo
}

# populated by `check` function whenever we're using Triton
TRITON_USER=
TRITON_DC=
TRITON_ACCOUNT=

# ---------------------------------------------------
# Top-level commands

# Check for correct configuration and setup _env file
envcheck() {

    command -v docker >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Docker is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://docs.joyent.com/public-cloud/api-access/docker'
        exit 1
    }
    command -v json >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! JSON CLI tool is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://apidocs.joyent.com/cloudapi/#getting-started'
        exit 1
    }

    command -v triton >/dev/null 2>&1 || {
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Joyent Triton CLI is required, but does not appear to be installed.'
        tput sgr0 # clear
        echo 'See https://www.joyent.com/blog/introducing-the-triton-command-line-tool'
        exit 1
    }

    # make sure Docker client is pointed to the same place as the Triton client
    local docker_user=$(docker info 2>&1 | awk -F": " '/SDCAccount:/{print $2}')
    local docker_dc=$(echo $DOCKER_HOST | awk -F"/" '{print $3}' | awk -F'.' '{print $1}')
    TRITON_USER=$(triton profile get | awk -F": " '/account:/{print $2}')
    TRITON_DC=$(triton profile get | awk -F"/" '/url:/{print $3}' | awk -F'.' '{print $1}')
    TRITON_ACCOUNT=$(triton account get | awk -F": " '/id:/{print $2}')
    if [ ! "$docker_user" = "$TRITON_USER" ] || [ ! "$docker_dc" = "$TRITON_DC" ]; then
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! The Triton CLI configuration does not match the Docker CLI configuration.'
        tput sgr0 # clear
        echo
        echo "Docker user: ${docker_user}"
        echo "Triton user: ${TRITON_USER}"
        echo "Docker data center: ${docker_dc}"
        echo "Triton data center: ${TRITON_DC}"
        exit 1
    fi

    local triton_cns_enabled=$(triton account get | awk -F": " '/cns/{print $2}')
    if [ ! "true" == "$triton_cns_enabled" ]; then
        echo
        tput rev  # reverse
        tput bold # bold
        echo 'Error! Triton CNS is required and not enabled.'
        tput sgr0 # clear
        echo
        exit 1
    fi

    # setup environment file
    if [ ! -f "_env" ]; then
        echo '# Optional Let’s Encrypt details' > _env
        echo '# This will automatically generate a well-recognized SSL certificate' >> _env
        echo '# ACME_ENV=production' >> _env
        echo '# ACME_DOMAIN=<your registry domain name FQDN>' >> _env
        echo >> _env

        echo '# Optional Docker user info' >> _env
        echo '# This supports a single user/password pair.' >> _env
        echo '# More complex use-cases can be built using this as a base image.' >> _env
        echo '# These generated strings might be a good user/password combo for your registry' >> _env
        echo '# REGISTRYUSER='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 37) >> _env
        echo '# REGISTRYPASS='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 37) >> _env
        echo >> _env

        echo '# HTTP secret must be same among all instances of the same registry' >> _env
        echo '# Feel free to use the randomly generated secret or create your own' >> _env
        echo 'HTTPSECRET='$(cat /dev/urandom | LC_ALL=C tr -dc 'A-Za-z0-9' | head -c 37) >> _env
        echo >> _env

        echo '# Set the storage driver (required)' >> _env
        echo '# Either `filesystem` or `s3` are supported' >> _env
        echo 'STORAGEDRIVER=filesystem' >> _env
        echo >> _env

        echo '# Optional s3 bucket details if using s3 storage' >> _env
        echo '# S3ACCESSKEY=<your s3 access key>' >> _env
        echo '# S3SECRETKEY=<your s3 secret key>' >> _env
        echo '# S3REGION=<your s3 region>' >> _env
        echo '# S3BUCKET=<your s3 bucket>' >> _env
        echo >> _env

        echo '# Consul discovery via Triton CNS' >> _env
        echo "CONSUL=consul.svc.${TRITON_ACCOUNT}.${TRITON_DC}.cns.joyent.com" >> _env
        echo >> _env

        echo 'Edit the _env file to confirm and set your desired configuration details'
    else
        echo 'Existing _env file found, exiting'
        exit
    fi
}

# ---------------------------------------------------
# parse arguments

while getopts "f:p:h" optchar; do
    case "${optchar}" in
        f) export COMPOSE_FILE=${OPTARG} ;;
        p) export COMPOSE_PROJECT_NAME=${OPTARG} ;;
    esac
done
shift $(expr $OPTIND - 1 )

until
    cmd=$1
    if [ ! -z "$cmd" ]; then
        shift 1
        $cmd "$@"
        if [ $? == 127 ]; then
            help
        fi
        exit
    fi
do
    echo
done

# default behavior
envcheck