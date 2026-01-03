#!/bin/bash
set -e

DOMAIN="app.mirakib.tech"
EMAIL="you@example.com"
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
