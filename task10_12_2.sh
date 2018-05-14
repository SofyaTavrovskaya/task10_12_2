#!/bin/bash

source config
export $(cut -d= -f1 config| grep -v '^$\|^\s*\#' config)

echo "Adding Docker repo key"
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | apt-key add -

echo "Adding Docker repo"
add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

echo "Updating apt"
apt-get update
echo "Installing Docker-CE and Compose" 
apt-get install docker-ce docker-compose -y

echo "Making dir for certs"
mkdir -p certs/

if [ ! -e certs/root.key ]
then
echo "Root key is absent, generating"
openssl genrsa -out certs/root.key 4096
else
echo "Root key present"
fi

echo "Generating root csr"
openssl req -new -nodes\
    -keyout certs/root.key\
    -out certs/root.csr\
    -subj "/C=UA/ST=Kharkov/L=Kharkov/O=Mirantis/OU=dev_ops/CN=$HOST_NAME/"

echo "Generating root certificate"
openssl x509 -req\
    -signkey certs/root.key\
    -in certs/root.csr\
    -out certs/root.crt

echo "Generating web.key"
openssl genrsa -out certs/web.key 2048

echo "Generating web.csr"
openssl req -new\
    -key certs/web.key\
    -out certs/web.csr\
    -subj "/C=UA/ST=Kharkov/L=Kharkov/O=Mirantis/OU=dev_ops/CN=$HOST_NAME/"

echo "Generating web.crt"
openssl x509 -req\
    -in certs/web.csr\
    -CA certs/root.crt\
    -CAkey certs/root.key\
    -CAcreateserial\
    -out certs/web.crt\
    -extfile <(printf "subjectAltName=IP:${EXTERNAL_IP},DNS:${HOST_NAME}")

cat certs/root.crt certs/web.crt  > certs/web-ca-chain.pem

envsubst < docker-compose_template.yml > docker-compose.yml

echo "Making dir for nginx-log"
mkdir -p ${NGINX_LOG_DIR}

echo "Deploying dockers"
docker-compose up -d
