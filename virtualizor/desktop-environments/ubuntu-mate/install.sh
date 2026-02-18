#!/bin/bash

# Install Mate DE
# v18-feb-26
#

DEBIAN_FRONTEND=noninteractive
apt update && apt -qq -y full-upgrade
apt -qq -y install ubuntu-mate-desktop
[[ $? == "0" ]] && echo "[Seat:*]\nallow-guest=false\n" > /etc/lightdm/lightdm.conf.d/99-no-guest-session.conf || echo "Failed to install DE" >> /root/recipe.log
# reboot
