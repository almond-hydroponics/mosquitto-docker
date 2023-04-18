FROM redis:6.2.11-alpine
WORKDIR /redis
COPY redis.conf /usr/local/etc/redis/redis.conf
COPY init.sh ./
RUN chmod +x init.sh
