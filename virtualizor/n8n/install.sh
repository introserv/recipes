#!/bin/bash

#
# Installing ThinLink access server
# v24-feb-26
#

targetDir='/opt/n8n'
hostname='app.introserv.cloud'
ip=$(hostname -I| cut -d " " -f 1)
email='admin@email.local'
pwd="$(openssl rand -base64 12)"
DEBIAN_FRONTEND=noninteractive
apt -qq update; apt -y -qq install curl jq
[[ ! $(command -v docker) ]] && curl -fsSL https://get.docker.com -o get-docker.sh && sh ./get-docker.sh
[[ -d $targetDir ]] || mkdir -p $targetDir/{ssl,n8n-data}
chmod 777 $targetDir/n8n-data
#[[ -f $targetDir/docker-compose.yaml ]] && rm -rvf "$targetDir/*"
cd $targetDir
curl -fsSL https://raw.githubusercontent.com/introserv/recipes/refs/heads/main/virtualizor/n8n/docker-compose.yml -o $targetDir/docker-compose.yaml.tmp
#export N8N_PWD="$pwd"
export N8N_FQDN="$ip"
envsubst < $targetDir/docker-compose.yaml.tmp > $targetDir/docker-compose.yaml
rm /opt/portainer-server/docker-compose.yaml.tmp
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout $targetDir/ssl/default.key -out $targetDir/ssl/default.crt -subj "/C=EU/O=INTROSERV/OU=CustomerService/CN=app.introserv.cloud"
extif=$(ip r | grep default | cut -d " " -f 5)
iptables -I INPUT -i $extif -p tcp -m tcp --dport 22 -j ACCEPT
iptables -I INPUT -i $extif -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I DOCKER-USER -i $extif -p tcp -m tcp -m multiport --dports 80,443,8000,9001 -j ACCEPT
iptables -I INPUT -i lo -j ACCEPT
iptables -P INPUT DROP
netfilter-persistent save
docker compose up -d
sleep 10
# wait for cont to become heathly for 60sec to apply user config
i='"unhealthy"';a=0
while [[ $a -le 60 ]]; do
  i=$(docker inspect --format='{{json .State.Health.Status}}' n8n-n8n-1)
  if [[ "$i" == '"healthy"' ]]; then
    pauload=$(jq -n --arg email "$email" --arg password "$pwd" '{"email": $email, "password": $password}')
    curl -s -X POST http://127.0.0.1:5678/rest/owner/setup -H "Content-Type: application/json" -d "$pauload"
    echo -e "N8N admin login credentials:\nURL:https://$ip/\nUser name: $email\nPassword: $pwd\n" >> /root/credentials.txt
    break
  else
    echo -n "."
    let "a++"
    sleep 1
  fi
done
exit 0
