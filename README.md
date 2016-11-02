Autopilot Pattern Docker Registry
=================================

*A private Docker registry with automatic SSL support implemented according to the [Autopilot Pattern](http://autopilotpattern.io/) for automatic discovery and configuration.*

[![DockerPulls](https://img.shields.io/docker/pulls/autopilotpattern/docker-registry.svg)](https://registry.hub.docker.com/u/autopilotpattern/docker-registry/)
[![DockerStars](https://img.shields.io/docker/stars/autopilotpattern/docker-registry.svg)](https://registry.hub.docker.com/u/autopilotpattern/docker-registry/)

### Hello world example

1. [Get a Joyent account](https://my.joyent.com/landing/signup/) and [add your SSH key](https://docs.joyent.com/public-cloud/getting-started).
1. Install the [Docker Toolbox](https://docs.docker.com/installation/mac/) (including `docker` and `docker-compose`) on your laptop or other environment, as well as the [Joyent Triton CLI](https://docs.joyent.com/public-cloud/api-access/cloudapi).
1. [Configure Docker and Docker Compose for use with Joyent.](https://docs.joyent.com/public-cloud/api-access/docker)

Check that everything is configured correctly by running `./setup.sh`. This will check that your environment is setup correctly and will create an `_env` file with some reasonable defaults. Be sure to review that `_env` file and make any changes you desire (see configuration below)

Start everything:

```bash
docker-compose up -d
```
You can open the demo app that Nginx is proxying by opening a browser to the Nginx instance IP:

```bash
open "http://$(triton ip nginx_nginx_1)/example"
```

### Configuration

The following sample `_env` file is similar to those that are automatically generated using the `setup.sh` script. See additional details about [SSL encryption](#automatic-ssl-via-letsencrypt-acme), [password configuration](#passwordprotection), and [storage drivers](#storage-drivers) further below.

```bash
# Optional Let’s Encrypt details
# This will automatically generate a well-recognized SSL certificate
# ACME_ENV=production
# ACME_DOMAIN=<your registry domain name FQDN>

# Optional Docker user info
# This supports a single user/password pair.
# More complex use-cases can be built using this as a base image.
# These generated strings might be a good user/password combo for your registry
# REGISTRYUSER=<long random string>
# REGISTRYPASS=<long random string>

# HTTP secret must be same among all instances of the same registry
# Feel free to use the randomly generated secret or create your own
HTTPSECRET=<long random string>

# Set the storage driver (required)
# Either `filesystem` or `s3` are supported
STORAGEDRIVER=filesystem

# Optional s3 bucket details if using s3 storage
# S3ACCESSKEY=<your s3 access key>
# S3SECRETKEY=<your s3 secret key>
# S3REGION=<your s3 region>
# S3BUCKET=<your s3 bucket>

# Consul discovery via Triton CNS
CONSUL=consul.svc.<user uuid>.<data center>.cns.joyent.com
```

### Automatic SSL via LetsEncrypt (ACME)

This project includes support for automatic SSL certificates via Let's Encrypt as implemented in [autopilotpattern/nginx](https://github.com/autopilotpattern/nginx).

After configuring your domain name to resolve to the Nginx instance(s) that front the registry, they will automatically acquire certificates for the given domain, and renew them over time. If you scale to multiple instances of Nginx, they will elect a leader who will be responsible for renewing the certificates.  Any challenge response tokens as well as acquired certificates will be replicated to all Nginx instances. 

You must ensure the domain resolves to the Nginx container(s) that front the registry so that they can respond to the ACME http challenges. Triton users may [refer to this document](https://docs.joyent.com/public-cloud/network/cns/faq#can-i-use-my-own-domain-name-with-triton-cns) for more information on how to insure your domain resolves to your Triton containers.

In the `_env` file, set the `ACME_ENV` and `ACME_DOMAIN` to your desired values:

```bash
# Optional Let’s Encrypt details
# This will automatically generate a well-recognized SSL certificate
ACME_ENV=production # or `staging`
ACME_DOMAIN=<your registry domain name FQDN>
```

### Password protection

This implementation supports a single user/password combo to limit access (see [autopilotpattern/docker-registry#3](https://github.com/autopilotpattern/docker-registry/issues/3) for plans to support more users, or feel free to extend this Docker image for your needs).

The `setup.sh` script will generate long random strings to use as the username and password pair, simply uncomment those lines to use them, or change them to the username and password of your choice.

```bash
# Optional Docker user info
# This supports a single user/password pair.
# More complex use-cases can be built using this as a base image.
# These generated strings might be a good user/password combo for your registry
REGISTRYUSER=<long random string>
REGISTRYPASS=<long random string>
```

To change the username/password, you must re-deploy the Nginx image. After updating the `_env` file, you can redeploy using Docker Compose:

```bash
docker-compose up -d nginx
```

### Storage drivers

The default configuration will store your Docker images in the local filesystem of the container. You can backup your container to save your images, or you can use an object storage system to store the images.

For that, this image also supports s3. Simply enter your s3 configuration details in the `_env` file:

```bash
# Set the storage driver (required)
# Either `filesystem` or `s3` are supported
STORAGEDRIVER=s3

# Optional s3 bucket details if using s3 storage
S3ACCESSKEY=<your s3 access key>
S3SECRETKEY=<your s3 secret key>
S3REGION=<your s3 region>
S3BUCKET=<your s3 bucket>
```

### "It doesn't do X"

It's all open source. Please [open an issue](https://github.com/autopilotpattern/docker-registry/issues), or better yet, a [pull request](https://github.com/autopilotpattern/docker-registry/pulls).