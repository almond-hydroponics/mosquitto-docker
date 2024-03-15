FROM python:3.13.0a4-alpine

# Build-time metadata as defined at http://label-schema.org
ARG BUILD_DATE
ARG VCS_REF
ARG VERSION
LABEL application="almond-mqtt"
LABEL maintainer="Francis Masha <francismasha96@gmail.com>" \
      org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.name="Mosquitto MQTT Broker with auth-plugin" \
      org.label-schema.description="This project builds almond mosquitto with auth-plugin. \
      It also has mosquitto_pub, mosquitto_sub and np." \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.version=$VERSION \
      org.label-schema.schema-version="1.0"

RUN addgroup -S mosquitto && \
    adduser -S -H -h /var/empty -s /sbin/nologin -D -G mosquitto mosquitto

ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH
ENV MOSQUITTO_VERSION=1.6.11
ENV LIBWEBSOCKETS_VERSION=v2.4.2

#RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.12/main' >> /etc/apk/repositories
#RUN echo 'http://dl-cdn.alpinelinux.org/alpine/v3.12/community' >> /etc/apk/repositories

# update the alpine image
RUN apk update
RUN apk add git python3

RUN apk add --no-cache --virtual buildDeps git cmake build-base c-ares-dev openssl-dev && \
    apk add --no-cache --virtual libc-ares-dev util-linux-dev hiredis-dev postgresql-dev curl-dev && \
    mkdir -p /var/lib/mosquitto && \
    touch /var/lib/mosquitto/.keep && \
    mkdir -p /etc/mosquitto.d && \
    apk add bash coreutils nano hiredis postgresql-libs libuuid c-ares openssl curl certbot ca-certificates && \
    rm -f /var/cache/apk/* && \
    pip3 install --upgrade pip && \
    pip3 install py-crypto pyRFC3339 configobj-dev ConfigArgParse && \
    git clone -b ${LIBWEBSOCKETS_VERSION} https://github.com/warmcat/libwebsockets && \
    cd libwebsockets && \
    cmake . \
      -DCMAKE_BUILD_TYPE=MinSizeRel \
      -DLWS_IPV6=ON \
      -DLWS_WITHOUT_CLIENT=ON \
      -DLWS_WITHOUT_TESTAPPS=ON \
      -DLWS_WITHOUT_EXTENSIONS=ON \
      -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
      -DLWS_WITH_ZIP_FOPS=OFF \
      -DLWS_WITH_ZLIB=OFF \
      -DLWS_WITH_SHARED=OFF && \
    make -j "$(nproc)" && \
    rm -rf /root/.cmake && \
    cd .. && \
    wget http://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    tar xzfv mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    mv mosquitto-${MOSQUITTO_VERSION} mosquitto && \
    rm mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
    cd mosquitto && \
    make -j "$(nproc)" \
      CFLAGS="-Wall -O2 -I/libwebsockets/include" \
      LDFLAGS="-L/libwebsockets/lib" \
      WITH_SRV=yes \
      WITH_STRIP=yes \
      WITH_ADNS=no \
      WITH_DOCS=no \
      WITH_MEMORY_TRACKING=no \
      WITH_TLS_PSK=no \
      WITH_WEBSOCKETS=yes \
    binary && \
    install -s -m755 client/mosquitto_pub /usr/bin/mosquitto_pub && \
    install -s -m755 client/mosquitto_rr /usr/bin/mosquitto_rr && \
    install -s -m755 client/mosquitto_sub /usr/bin/mosquitto_sub && \
    install -s -m644 lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && \
    ln -sf /usr/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so && \
    install -s -m755 src/mosquitto /usr/sbin/mosquitto && \
    install -s -m755 src/mosquitto_passwd /usr/bin/mosquitto_passwd && \
    git clone https://github.com/vankxr/mosquitto-auth-plug && \
    cd mosquitto-auth-plug && \
    cp config.mk.in config.mk && \
    sed -i "s/BACKEND_CDB ?= no/BACKEND_CDB ?= no/" config.mk && \
    sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk && \
    sed -i "s/BACKEND_SQLITE ?= no/BACKEND_SQLITE ?= no/" config.mk && \
    sed -i "s/BACKEND_REDIS ?= no/BACKEND_REDIS ?= yes/" config.mk && \
    sed -i "s/BACKEND_POSTGRES ?= no/BACKEND_POSTGRES ?= yes/" config.mk && \
    sed -i "s/BACKEND_LDAP ?= no/BACKEND_LDAP ?= no/" config.mk && \
    sed -i "s/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/" config.mk && \
    sed -i "s/BACKEND_JWT ?= no/BACKEND_JWT ?= no/" config.mk && \
    sed -i "s/BACKEND_MONGO ?= no/BACKEND_MONGO ?= no/" config.mk && \
    sed -i "s/BACKEND_FILES ?= no/BACKEND_FILES ?= no/" config.mk && \
    sed -i "s/BACKEND_MEMCACHED ?= no/BACKEND_MEMCACHED ?= no/" config.mk && \
    sed -i "s/MOSQUITTO_SRC =/MOSQUITTO_SRC = ..\//" config.mk && \
    make -j "$(nproc)" && \
    install -s -m755 auth-plug.so /usr/lib/ && \
    install -s -m755 np /usr/bin/ && \
    cd / && rm -rf mosquitto && \
    rm -rf libwebsockets && \
    apk del buildDeps && rm -rf /var/cache/apk/*

ADD mosquitto.conf /etc/mosquitto/mosquitto.conf
RUN mkdir -p /mosquitto
RUN mkdir -p /mosquitto/log

COPY certbot.sh /certbot.sh
COPY restart.sh /restart.sh
COPY run.sh /run.sh
COPY croncert.sh /etc/periodic/weekly/croncert.sh
RUN \
	chmod +x /run.sh && \
	chmod +x /certbot.sh && \
	chmod +x /restart.sh && \
	chmod +x /etc/periodic/weekly/croncert.sh

# MQTT default port and default port over TLS
EXPOSE 1883
EXPOSE 8883
# MQTT over websocket default port and default port over TLS
EXPOSE 8083
EXPOSE 80

ENTRYPOINT ["/run.sh"]
CMD ["mosquitto"]
