#!/bin/bash

IP="almondhydroponics.com"
SUBJECT_CA="/C=KE/ST=Nairobi/L=Nairobi/O=almond/OU=CA/CN=$IP"
SUBJECT_SERVER="/C=KE/ST=Nairobi/L=Nairobi/O=almond-server/OU=Server/CN=$IP"
SUBJECT_CLIENT="/C=KE/ST=Nairobi/L=Nairobi/O=almond-client/OU=Client/CN=$IP"

function generate_CA () {
   echo "$SUBJECT_CA"
   openssl req -new -x509 -days 1000 -subj "$SUBJECT_CA" -extensions v3_ca -keyout ca.key -out ca.crt
#   openssl req -x509 -nodes -newkey rsa:2048 -subj "$SUBJECT_CA" -days 730 -keyout ca.key -out ca.crt
}

function generate_server () {
   echo "$SUBJECT_SERVER"
   openssl genrsa -out server.key 2048
   openssl req -out server.csr -key server.key -new -subj "$SUBJECT_SERVER"
   openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 1000
#   openssl req -nodes -new -subj "$SUBJECT_SERVER" -keyout server.key -out server.csr
#   openssl x509 -req -in server.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out server.crt -days 730
}

function generate_client () {
   echo "$SUBJECT_CLIENT"
   openssl genrsa -out client.key 2048
   openssl req -out client.csr -key client.key -new -subj "$SUBJECT_CLIENT"
   openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 1000
#   openssl req -new -nodes -subj "$SUBJECT_CLIENT" -out client.csr -keyout client.key
#   openssl x509 -req -in client.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out client.crt -days 730
}

#function copy_keys_to_broker () {
#   sudo cp ca.crt /etc/mosquitto/certs/
#   sudo cp server.crt /etc/mosquitto/certs/
#   sudo cp server.key /etc/mosquitto/certs/
#}

generate_CA
generate_server
generate_client
#copy_keys_to_broker
