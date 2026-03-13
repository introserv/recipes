#!/bin/bash

hostname='app.introserv.cloud'
ip=$(hostname -I| cut -d " " -f 1)
email='admin@email.local'
pwd="$(pwgen -sB 14 1)"
tmp=$(mktemp -d)
DEBIAN_FRONTEND=noninteractive
apt -qq update; apt -y -qq install curl jq pwgen npm caddy
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash
\. "$HOME/.nvm/nvm.sh"
nvm install 24
#node -v # Should print "v24.14.0"
#npm -v # Should print "11.9.0".
npm install -g n8n
npm install -g n8n@next
npm update -g n8n
n8n --version
npm install -g pm2
cat <<EOT >> ~/n8n.config.js
module.exports = {
  apps: [{
    name: 'n8n',
    script: 'n8n',
    env: {
      NODE_ENV: 'production',
      N8N_RELEASE_TYPE: '<stable/next>',
      N8N_HOST: '0.0.0.0',
      N8N_PORT: '5678',
      WEBHOOK_URL: '<https://your-domain.com/>',
    }
  }]
};
EOT
pm2 start ~/n8n.config.js
pm2 startup
pm2 save
#--
curl -fsSL https://raw.githubusercontent.com/introserv/recipes/refs/heads/main/virtualizor/n8n-npm/Caddyfile -o $tmp/caddy.tmp
export HOST_IP="$ip"
mv /etc/caddy/Caddyfile /etc/caddy/Caddyfile.bak
envsubst < $tmp/caddy.tmp > /etc/caddy/Caddyfile
rm $tmp/caddy.tmp
openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /var/lib/caddy/n8n.pem -out /var/lib/caddy/n8n.crt -subj "/C=EU/O=INTROSERV/OU=CustomerService/CN=app.introserv.cloud"
chown caddy:caddy /var/lib/caddy/n8n.*
systemctl restart caddy
sleep 10
a=0
while [[ $a -le 60 ]]; do
        wget --spider http://localhost:5678/healthz
        if [[ $? == 0 ]]; then
                payload=$(jq -n --arg email "$email" --arg password "$pwd" '{"email": $email, "password": $password,"firstName": "Admin","lastName": "User"}')
                curl -s -X POST http://127.0.0.1:5678/rest/owner/setup -H "Content-Type: application/json" -d "$payload"
                echo -e "N8N admin login credentials:\nURL:https://$ip/\nUser name: $email\nPassword: $pwd\n" >> /root/credentials.txt
                break
         else
#               echo -n "."
                let "a++"
                sleep 1
        fi
done
extif=$(ip r | grep default | cut -d " " -f 5)
iptables -I INPUT -i $extif -p tcp -m tcp -m multiport --dports 22,80,443 -j ACCEPT
iptables -I INPUT -i $extif -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -I INPUT -i lo -j ACCEPT
iptables -P INPUT DROP
exit 0
