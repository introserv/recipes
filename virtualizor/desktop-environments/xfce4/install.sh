#!/bin/bash

#
# Installing XFCE4 DE
# v19-feb-26
#

DEBIAN_FRONTEND=noninteractive
username="admin"
pwd="$(openssl rand -base64 12)"
apt -qq update && apt -o "Dpkg::Options::=--force-confdef" -o "Dpkg::Options::=--force-confold" -y -qq upgrade
useradd -m -s /bin/bash -G sudo $username
echo "$username:$pwd"|chpasswd
echo -e "Desktop login credentials:\nUser name: $username\nPassword: $pwd\n" >> /root/credentials.txt
apt -qq -y install xubuntu-desktop
#reboot
