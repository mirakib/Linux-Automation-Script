#!/bin/bash
apt update -y
apt install apache2 -y

systemctl enable apache2
systemctl start apache2

# Allow Apache through firewall (if UFW exists)
if command -v ufw >/dev/null 2>&1; then
  ufw allow 'Apache Full'
fi

# FOR DEBIAN/UBUNTU LINUX 
