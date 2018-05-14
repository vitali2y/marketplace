#!/bin/bash

FQDN=`hostname`
rm server.key server.crt
openssl genrsa -out server.key 2048
openssl req -nodes -newkey rsa:2048 -keyout server.key -out server.csr -subj "/C=UA/ST=UA/L=Zhytomyr/O=Vi+/OU=Vi+/CN=${FQDN}/emailAddress=vitaliyy@gmail.com"
openssl x509 -req -days 1024 -in server.csr -signkey server.key -out server.crt
rm server.csr
echo "server.key and server.crt are ready"
