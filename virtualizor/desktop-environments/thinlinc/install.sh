#!/bin/bash

#
#
#

DEBIAN_FRONTEND=noninteractive
apt update && apt -qq -y full-upgrade && apt install -y -qq unzip
wget --quiet https://www.cendio.com/downloads/server/tl-4.20.0-server.zip -o /tmp/tl-server.zip
mkdir /tmp/tl-setup; unzip /tmp/tl-server.zip -d /tmp/tl-setup
dpkg -i /tmp/tl-setup/packages/thinlinc-server_4.20.0-4392_amd64.deb
