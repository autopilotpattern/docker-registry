# Autopilot Pattern Registry

*Implementation of the Autopilot Pattern for the Docker Registry, including SSL with Let's Encrypt.*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/registry.svg)](https://registry.hub.docker.com/u/autopilotpattern/registry/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/registry.svg)](https://registry.hub.docker.com/u/autopilotpattern/registry/)

### Automatic SSL with Let's Encrypt

This project includes support for automatic SSL certificates via Let's Encrypt. You must ensure the domain resolves to the container so that it can respond to the ACME http challenges. Triton users should [refer to this document](https://docs.joyent.com/public-cloud/network/cns/faq#can-i-use-my-own-domain-name-with-triton-cns) for more information on how to insure your domain resolves to your Triton containers.

### Authentication

This implementation supports a single user/password combo to limit access (see [autopilotpattern/docker-registry#3](https://github.com/autopilotpattern/docker-registry/issues/3) for plans to support more users, or feel free to extend this Docker image for your needs).

### Storage Driver

This configuration will store your Docker images in the local filesystem of the container. Back up your container to back up your images, or use an object storage system to store the images. A future version of this repo will support [using Manta as a storage backend](https://github.com/docker/distribution/issues/2041).

### Setup

The supplied `setup.sh` script will configure a `docker-compose.yml` file from the template in this repo with the details needed for your private registry with Let's Encrypt. When given the option, make sure the Triton package you select has enough disk space for what you expect to store. In a future version of this repo, we'll support [using Manta as a storage backend](https://github.com/docker/distribution/issues/2041). Once your `docker-compose.yml` file is written, make sure your Docker client is configured to run on Triton.


```bash
# create 'docker-compose.yml' file from template
$ ./setup.sh
Provide Let's Encrypt domain name for registry [registry.example.com]:
Provide email associated w/ Let's Encrypt [example@example.com]:
Provide Let's Encrypt environment [staging|production]:
Provide username for registry basic auth [myname]:
Provide password for registry basic auth [password1]:
Provide internal secret for registry [or hit Enter to autogenerate]:
Provide port number to listen on [443]:
Provide CNS service name [registry]:
Provide Triton package [g4-highcpu-2G]:

# point Docker at Triton
$ eval $(triton env)
$ env | grep DOCKER_HOST
DOCKER_HOST=tcp://us-sw-1.docker.joyent.com:2376

```

### Deploy

Deploying to Triton is then just a matter of running a Compose command. Now you can login to your Docker Registry and use it as a source for containers you deploy to Triton.


```bash
$ docker-compose up -d
Pulling registry (autopilotpattern/registry:latest)...
...
Status: Downloaded newer image for autopilotpattern/registry:latest
Creating registry_registry_1

$ docker-compose ps
       Name                      Command               State               Ports
---------------------------------------------------------------------------------------------
registry_registry_1   /bin/sh -c /usr/local/bin/ ...   Up      0.0.0.0:443->443/tcp, 5000/tcp


$ docker login registry.example.com
Username (myname): myname
Password:
Login Succeeded

```

### Contributing

It's all open source. Please [open an issue](https://github.com/autopilotpattern/docker-registry/issues), or better yet, a [pull request](https://github.com/autopilotpattern/docker-registry/pulls).
