mosquitto-docker
================
Almond docker mosquitto server

## Version

**mosquitto** v1.6.11

This version implement MQTT over WebSocket. You can use an MQTT JavaScript library to connect, like Paho: https://github.com/eclipse/paho.mqtt.javascript

It has the auth plugin `https://github.com/jpmens/mosquitto-auth-plug` included. It uses (and is compiled with) support for `Redis`, `PostgreSQL`, `http` and `JWT` backends. The additional config for this plugin (sample `auth-plugin.conf` included) can be bind mounted in the extended configuration directory: `/etc/mosquitto.d`. Any file with a `.conf` extension will be loaded by `mosquitto` on startup.

For details on the auth plugin configuration, refer to the author repository. A little quick&dirty example its included at the end.

The docker images builds with _Official Alpine Linux edge_.

# Build

Use the provide _Makefile_ to build the image.

Alternatively you can start it by means of [docker-compose](https://docs.docker.com/compose): `docker-compose up`. This is useful when testing. It start up _redis_ and link it to _mosquitto_ so you can test the _auth-plugin_ easily.

## Build the Mosquitto docker image

    $ sudo make build

You can specify your repository and tag by

    $ sudo make REPOSITORY=my_own_repo/mqtt TAG=v1.6.11

# Example of authenticated access

By default, there is an `admin` superuser added to `auth-plugin.conf`. We will use it as an example.

## 1. Add a password for the admin user

(or whatever user u have configured...)

    $ docker run -ti --rm almond/mqtt:v1.6.11 np -p secretpass
    PBKDF2$sha256$901$5nH8dWZV5NXTI63/$0n3XrdhMxe7PedKZUcPKMd0WHka4408V

    $ docker exec -it redis-mqtt redis-cli
    172.17.0.64:6379> SET admin PBKDF2$sha256$901$5nH8dWZV5NXTI63/$0n3XrdhMxe7PedKZUcPKMd0WHka4408V
    OK
    172.17.0.64:6379> QUIT

## 2. Subscribe to a test channel

    $ mosquitto_sub -h localhost -t test

## 3. Publish to test channel

    $ mosquitto_pub -h localhost -t test -m "sample pub"

And... nothing happens because our `anonymous` user have no permission on that channel. Check the _mosquitto_ logs:

    mosquitto_1 | 1437183848: New connection from 192.168.59.3 on port 1883.
    mosquitto_1 | 1437183848: New client connected from 192.168.59.3 as mosqpub/14736-MacBook-P (c1, k60).
    mosquitto_1 | 1437183848: Sending CONNACK to mosqpub/14736-MacBook-P (0, 0)
    mosquitto_1 | 1437183848: |-- mosquitto_auth_acl_check(..., mosqpub/14736-MacBook-P, anonymous, test, MOSQ_ACL_WRITE)
    mosquitto_1 | 1437183848: |-- user anonymous was authenticated in back-end 0 (redis)
    mosquitto_1 | 1437183848: |-- aclcheck(anonymous, test, 2) AUTHORIZED=0 by redis
    mosquitto_1 | 1437183848: |--  Cached  [9B6BD92B391C9366FC67942CE0020635A2E289AD] for (mosqpub/14736-MacBook-P,anonymous,2)
    mosquitto_1 | 1437183848: |--  Cleanup [D45B453EA5A7900B66AD58FC314C28CD515C1572]
    mosquitto_1 | 1437183848: Denied PUBLISH from mosqpub/14736-MacBook-P (d0, q0, r0, m0, 'test', ... (10 bytes))
    mosquitto_1 | 1437183848: Received DISCONNECT from mosqpub/14736-MacBook-P

Cool!! Let's try again:

    $ mosquitto_pub -h localhost -t test -m "sample pub" -u admin -P secretpass

See the logs:

    mosquitto_1 | 1437183987: New connection from 192.168.59.3 on port 1883.
    mosquitto_1 | 1437183987: |-- mosquitto_auth_unpwd_check(admin)
    mosquitto_1 | 1437183987: |-- ** checking backend redis
    mosquitto_1 | 1437183987: |-- getuser(admin) AUTHENTICATED=1 by redis
    mosquitto_1 | 1437183987: New client connected from 192.168.59.3 as mosqpub/14767-MacBook-P (c1, k60, u'admin').
    mosquitto_1 | 1437183987: Sending CONNACK to mosqpub/14767-MacBook-P (0, 0)
    mosquitto_1 | 1437183987: |-- mosquitto_auth_acl_check(..., mosqpub/14767-MacBook-P, admin, test, MOSQ_ACL_WRITE)
    mosquitto_1 | 1437183987: |-- aclcheck(admin, test, 2) GLOBAL SUPERUSER=Y
    mosquitto_1 | 1437183987: |--  Cached  [CB67C9EA1CEA7676A1B3667076C142A05E1A6C94] for (mosqpub/14767-MacBook-P,admin,2)
    mosquitto_1 | 1437183987: Received PUBLISH from mosqpub/14767-MacBook-P (d0, q0, r0, m0, 'test', ... (10 bytes))
    mosquitto_1 | 1437183987: |-- mosquitto_auth_acl_check(..., mosqsub/14237-MacBook-P, anonymous, test, MOSQ_ACL_READ)
    mosquitto_1 | 1437183987: |-- user anonymous was authenticated in back-end 0 (redis)
    mosquitto_1 | 1437183987: |-- aclcheck(anonymous, test, 1) AUTHORIZED=0 by redis
    mosquitto_1 | 1437183987: |--  Cached  [6E2BE05D56B509A1912C1A6921B4AEFE80A498CA] for (mosqsub/14237-MacBook-P,anonymous,1)
    mosquitto_1 | 1437183987: Received DISCONNECT from mosqpub/14767-MacBook-P

Much better... But, did you get any output in the `mosquitto_sub`? None. Try this and replay:

    $ mosquitto_sub -h localhost -t test -u admin -P secretpass

And now everything *should* work! ;)
