#!/bin/bash
set -e

if [ $# -ne 2 ]; then
  echo "Usage: $0 <domain> <email>"
  exit 1
fi

DOMAIN=$1
EMAIL=$2

echo "Enabling SSL for $DOMAIN"

sudo apt update
sudo apt install -y certbot python3-certbot-nginx

sudo certbot --nginx \
  -d "$DOMAIN" \
  --non-interactive \
  --agree-tos \
  -m "$EMAIL" \
  --redirect

sudo nginx -t
sudo systemctl reload nginx
