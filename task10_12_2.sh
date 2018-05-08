#!/bin/sh
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
apt-get install docker-ce docker-compose
echo "Deploying dockers"
docker-compose up -d
