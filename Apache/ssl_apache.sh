#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

DOMAIN=$1
EMAIL=$2
WEBROOT="/var/www/$DOMAIN"

sudo apt update

# Install Certbot Apache plugin
sudo apt install -y certbot python3-certbot-apache

# Enable required Apache modules
sudo a2enmod ssl
sudo a2enmod rewrite

# Ensure Apache is running
sudo systemctl start apache2

# Obtain and install certificate (with redirect)
sudo certbot --apache \
  -d $DOMAIN \
  --non-interactive \
  --agree-tos \
  -m $EMAIL \
  --redirect

# Test Apache configuration
sudo apachectl configtest

# Reload Apache
sudo systemctl reload apache2
