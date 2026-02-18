#!/bin/bash

#
#
#

DEBIAN_FRONTEND=noninteractive
apt update && apt -qq -y full-upgrade && apt install -y -qq unzip curl
wget --quiet https://www.cendio.com/downloads/server/tl-4.20.0-server.zip -o /tmp/tl-server.zip
mkdir /tmp/tl-setup; unzip /tmp/tl-server.zip -d /tmp/tl-setup
dpkg -i /tmp/tl-setup/packages/thinlinc-server_4.20.0-4392_amd64.deb
curl -fsSL https://github.com/introserv/recipes/raw/main/virtualizor/desktop-environments/thinlinc/tl-setup-answer-file -o /tmp/tl-setup/tl-setup-answer-file.tmp
pwd="openssl rand -base64 12"
pwdhash="/opt/thinlinc/sbin/tl-gen-auth $pwd"
export $TLADMINPWD="$pwdhash"
envsubst < /tmp/tl-setup/tl-setup-answer-file.tmp > /tmp/tl-setup/tl-setup-answer-file
rm /tmp/tl-setup/tl-setup-answer-file.tmp
/opt/thinlinc/sbin/tl-setup -a /tmp/tl-setup/tl-setup-answer-file
