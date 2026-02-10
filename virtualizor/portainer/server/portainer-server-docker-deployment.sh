#!/bin/bash

# portainer-server-docker-deployment.sh
# 10-feb-26

targetDir='/opt/portainer-server'
hostname='app.introserv.cloud'
DEBIAN_FRONTEND=noninteractive
apt -qq update; apt -y -qq install curl apache2-utils pwgen
[[ ! $(command -v docker) ]] && curl -fsSL https://get.docker.com -o get-docker.sh && sh ./get-docker.sh
[[ -d $targetDir ]] || mkdir -p $targetDir/ssl
[[ -f $targetDir/docker-compose.yaml ]] && rm -rvf "$targetDir/*"
cd $targetDir
curl -fsSL https://github.com/introserv/recipes/raw/main/virtualizor/portainer/server/docker-compose.yaml -o $targetDir/docker-compose.yaml.tmp
pwd=$(pwgen -svB 14 1)
password=$(htpasswd -nbB '' "$pwd" | cut -d ":" -f 2 | sed 's/\$/\$\$/g')
export PORTAINER_PWD="$password"
export PORTAINER_FQDN="$hostname"
envsubst < /opt/portainer-server/docker-compose.yaml.tmp > /opt/portainer-server/docker-compose.yaml
rm /opt/portainer-server/docker-compose.yaml.tmp
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $targetDir/ssl/default.key -out $targetDir/ssl/default.crt -subj "/C=EU/O=INTROSERV/OU=CustomerService/CN=app.introserv.cloud"
echo $pwd > /root/portainer.txt
extif=$(ip r | grep default | cut -d " " -f 5)
iptables -I INPUT -i $extif -p tcp -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -i $extif -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I DOCKER-USER -i $extif -p tcp -m tcp -m multiport --dports 80,443,8000,9001 -j ACCEPT
iptables -P INPUT DROP
netfilter-persistent save
docker compose up -d
exit 0
