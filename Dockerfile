FROM registry:2

# Need curl to get ContainerPilot
RUN apk add --update curl

# Add ContainerPilot and its configuration
ENV CONTAINERPILOT file:///etc/containerpilot.json

RUN export checksum=c1bcd137fadd26ca2998eec192d04c08f62beb1f \
    && export archive=containerpilot-2.6.0.tar.gz \
    && curl -Lso /tmp/${archive} \
    https://github.com/joyent/containerpilot/releases/download/2.6.0/${archive} \
    && echo "${checksum}  /tmp/${archive}" | sha1sum -c \
    && tar zxf /tmp/${archive} -C /usr/local/bin \
    && rm /tmp/${archive}

# We're only using ContainerPilot to do the initial configuration
# rendering from the environment. This config doesn't register us
# with Consul.
COPY etc/containerpilot.json /etc/containerpilot.json
COPY etc/config.yml.tmpl /etc/docker/registry/config.yml.tmpl
COPY bin/prestart.sh /usr/local/bin/prestart.sh

ENTRYPOINT [""]
CMD /usr/local/bin/containerpilot registry serve /etc/docker/registry/config.yml
