#!/bin/bash


CONSUL=${CONSUL:-consul}

# Run the baseimage's preStart, then generate htpasswd file,
preStart() {

    # Check if both the username and password are set
    # Give a little suggestion if not
    if [ -z "${REGISTRYUSER}" ] || [ -z "${REGISTRYPASS}" ]; then
        echo "No password specified, registry is running in public mode with anonymous access."
        echo "It is strongly suggested you set a password using the REGISTRYUSER and REGISTRYPASS env vars."

        # Run the base image's preStart
        /usr/local/bin/reload.sh preStart

        exit 0
    fi

    # Generate htpasswd
    echo "generated htpasswd file in auth/nginx.htpasswd"
    htpasswd -b -c /etc/nginx/conf.d/nginx.htpasswd "${REGISTRYUSER}" "${REGISTRYPASS}"

    # Drop a key/value item in Consul for this user/pass
    # Future feature: allow management of users via Consul k/v store, but for now it's still a single user
    echo 'Registring users in Consul'
    CONSULRESPONSIVE=0
    while [ $CONSULRESPONSIVE != 1 ]; do
        echo -n '.'

        curl --fail -Lso /dev/null \
            -X PUT \
            -d "${REGISTRYPASS}" \
            "${CONSUL}:8500/v1/kv/docker-registry/users/${REGISTRYUSER}"

        if [ $? -eq 0 ]
        then
            let CONSULRESPONSIVE=1
        else
            sleep .7
        fi
    done
    echo # Trailing echo to insert a newline after all the -n echos above

    # Run the base image's preStart
    /usr/local/bin/reload.sh preStart

    exit 0
}

help() {
    echo "Usage: ./container-prestart preStart  => first-run configuration"
}

until
    cmd=$1
    if [ -z "$cmd" ]; then
        preStart
    fi
    shift 1
    $cmd "$@"
    [ "$?" -ne 127 ]
do
    preStart
    exit
done
