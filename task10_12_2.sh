#!/bin/bash

source config
export $(cut -d= -f1 config| grep -v '^$\|^\s*\#' config)

echo "Adding Docker repo key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "Adding Dicker repo"
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "Updating apt"
apt-get update
echo "Installing Docker-CE and Compose" # probably docker.io package is needed
apt-get install docker-ce docker-compose -y
echo "Deploying dockers"
docker-compose up -d

envsubst < subjalt_template.cnf > subjalt.cnf
echo "Making dir for certs"
mkdir -p certs/

if [ ! -e certs/root.key ]
then
echo "Root key is absent, generating"
openssl genrsa -out certs/root.key 4096
else
echo "Root key present"
fi

echo "Generating root certificate"
openssl req -x509 -new -nodes -key certs/root.key -sha256 -days 365\
       -out certs/root.crt\
       -subj "/C=UA/ST=Kharkov/L=Kharkov/O=Mirantis/OU=dev_ops/CN=docker-host/"\
       -extensions v3_req\
       -config <(cat /etc/ssl/openssl.cnf; cat subjalt.cnf)

echo "Generating web.key"
openssl genrsa -out certs/web.key 2048
echo "Generating web.ctr"
openssl req -new -out certs/web.crt -key certs/web.key -subj "/C=UA/ST=Kharkov/L=Kharkov/O=Mirantis/OU=dev_ops/CN=nginx/"
openssl x509 -req\
       -in certs/web.crt\
       -CA certs/root.crt\
       -CAkey certs/root.key\
       -CAcreateserial\
       -out certs/web.crt
cat certs/root.crt certs/web.crt> \
    certs/web-ca-chain.pem




