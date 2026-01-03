#!/bin/bash
set -e

DOMAIN="app.domain.tech"
EMAIL="you@example.com"
WEBROOT="/var/www/$DOMAIN"

sudo apt update
sudo apt install -y certbot python3-certbot-nginx

sudo certbot --nginx \
  -d $DOMAIN \
  --non-interactive \
  --agree-tos \
  -m $EMAIL \
  --redirect

sudo nginx -t
sudo systemctl reload nginx
