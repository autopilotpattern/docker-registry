FROM autopilotpattern/nginx:1-r6.1.0

RUN set -ex \
    && apt-get update && apt-get install -y --no-install-recommends \
        apache2-utils \
    # Clean up after apt \
    && rm -rf /var/lib/apt/lists/*

# Add our configuration files
COPY etc /etc/

# Add our executables
COPY bin /usr/local/bin/
