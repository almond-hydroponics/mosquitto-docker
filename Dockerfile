FROM python:3.6-alpine

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

# Set environment variables.
ENV TERM=xterm-color
ENV SHELL=/bin/bash

RUN \
	mkdir /mosquitto && \
	mkdir /mosquitto/log && \
	mkdir /mosquitto/conf && \
	apk update && \
	apk upgrade && \
	apk add bash coreutils nano ca-certificates certbot mosquitto mosquitto-clients && \
	rm -f /var/cache/apk/* && \
	pip install --upgrade pip && \
	pip install py-crypto pyRFC3339 configobj-dev ConfigArgParse

COPY run.sh /run.sh
COPY certbot.sh /certbot.sh
COPY restart.sh /restart.sh
COPY croncert.sh /etc/periodic/weekly/croncert.sh
RUN \
	chmod +x /run.sh && \
	chmod +x /certbot.sh && \
	chmod +x /restart.sh && \
	chmod +x /etc/periodic/weekly/croncert.sh

EXPOSE 1883
EXPOSE 8883
EXPOSE 80

# This will run any scripts found in /scripts/*.sh
# then start Apache
CMD ["/bin/bash","-c","/run.sh"]

#RUN addgroup -S mosquitto && \
#    adduser -S -H -h /var/empty -s /sbin/nologin -D -G mosquitto mosquitto
#
#ENV PATH=/usr/local/bin:/usr/local/sbin:$PATH
#ENV MOSQUITTO_VERSION=1.6.11
#ENV LIBWEBSOCKETS_VERSION=v2.4.2
#
#COPY run.sh /
#
#RUN apk --no-cache add --virtual buildDeps git cmake build-base openssl-dev c-ares-dev util-linux-dev hiredis-dev postgresql-dev curl-dev; \
#    chmod +x /run.sh && \
#    mkdir -p /var/lib/mosquitto && \
#    touch /var/lib/mosquitto/.keep && \
#    mkdir -p /etc/mosquitto.d && \
#    apk add hiredis postgresql-libs libuuid c-ares openssl curl ca-certificates && \
#    git clone -b ${LIBWEBSOCKETS_VERSION} https://github.com/warmcat/libwebsockets && \
#    cd libwebsockets && \
#    cmake . \
#      -DCMAKE_BUILD_TYPE=MinSizeRel \
#      -DLWS_IPV6=ON \
#      -DLWS_WITHOUT_CLIENT=ON \
#      -DLWS_WITHOUT_TESTAPPS=ON \
#      -DLWS_WITHOUT_EXTENSIONS=ON \
#      -DLWS_WITHOUT_BUILTIN_GETIFADDRS=ON \
#      -DLWS_WITH_ZIP_FOPS=OFF \
#      -DLWS_WITH_ZLIB=OFF \
#      -DLWS_WITH_SHARED=OFF && \
#    make -j "$(nproc)" && \
#    rm -rf /root/.cmake && \
#    cd .. && \
#    wget http://mosquitto.org/files/source/mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
#    tar xzfv mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
#    mv mosquitto-${MOSQUITTO_VERSION} mosquitto && \
#    rm mosquitto-${MOSQUITTO_VERSION}.tar.gz && \
#    cd mosquitto && \
#    make -j "$(nproc)" \
#      CFLAGS="-Wall -O2 -I/libwebsockets/include" \
#      LDFLAGS="-L/libwebsockets/lib" \
#      WITH_SRV=yes \
#      WITH_STRIP=yes \
#      WITH_ADNS=no \
#      WITH_DOCS=no \
#      WITH_MEMORY_TRACKING=no \
#      WITH_TLS_PSK=no \
#      WITH_WEBSOCKETS=yes \
#    binary && \
#    install -s -m755 client/mosquitto_pub /usr/bin/mosquitto_pub && \
#    install -s -m755 client/mosquitto_rr /usr/bin/mosquitto_rr && \
#    install -s -m755 client/mosquitto_sub /usr/bin/mosquitto_sub && \
#    install -s -m644 lib/libmosquitto.so.1 /usr/lib/libmosquitto.so.1 && \
#    ln -sf /usr/lib/libmosquitto.so.1 /usr/lib/libmosquitto.so && \
#    install -s -m755 src/mosquitto /usr/sbin/mosquitto && \
#    install -s -m755 src/mosquitto_passwd /usr/bin/mosquitto_passwd && \
#    git clone https://github.com/vankxr/mosquitto-auth-plug && \
#    cd mosquitto-auth-plug && \
#    cp config.mk.in config.mk && \
#    sed -i "s/BACKEND_CDB ?= no/BACKEND_CDB ?= no/" config.mk && \
#    sed -i "s/BACKEND_MYSQL ?= yes/BACKEND_MYSQL ?= no/" config.mk && \
#    sed -i "s/BACKEND_SQLITE ?= no/BACKEND_SQLITE ?= no/" config.mk && \
#    sed -i "s/BACKEND_REDIS ?= no/BACKEND_REDIS ?= yes/" config.mk && \
#    sed -i "s/BACKEND_POSTGRES ?= no/BACKEND_POSTGRES ?= yes/" config.mk && \
#    sed -i "s/BACKEND_LDAP ?= no/BACKEND_LDAP ?= no/" config.mk && \
#    sed -i "s/BACKEND_HTTP ?= no/BACKEND_HTTP ?= yes/" config.mk && \
#    sed -i "s/BACKEND_JWT ?= no/BACKEND_JWT ?= no/" config.mk && \
#    sed -i "s/BACKEND_MONGO ?= no/BACKEND_MONGO ?= no/" config.mk && \
#    sed -i "s/BACKEND_FILES ?= no/BACKEND_FILES ?= no/" config.mk && \
#    sed -i "s/BACKEND_MEMCACHED ?= no/BACKEND_MEMCACHED ?= no/" config.mk && \
#    sed -i "s/MOSQUITTO_SRC =/MOSQUITTO_SRC = ..\//" config.mk && \
#    make -j "$(nproc)" && \
#    install -s -m755 auth-plug.so /usr/lib/ && \
#    install -s -m755 np /usr/bin/ && \
#    cd / && rm -rf mosquitto && \
#    rm -rf libwebsockets && \
#    apk del buildDeps && rm -rf /var/cache/apk/*
#
#ADD mosquitto.conf /etc/mosquitto/mosquitto.conf
#
## MQTT default port and default port over TLS
#EXPOSE 1883 8883
## MQTT over websocket default port and default port over TLS
#EXPOSE 8083
#
##VOLUME ["/var/lib/mosquitto", "/etc/mosquitto", "/etc/mosquitto.d"]
#
#ENTRYPOINT ["/run.sh"]
#CMD ["mosquitto"]
