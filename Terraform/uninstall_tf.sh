#!/bin/bash
set -e

echo "Removing Terraform package..."

sudo apt-get remove -y terraform

echo "Removing HashiCorp repository..."

sudo rm -f /etc/apt/sources.list.d/hashicorp.list
sudo rm -f /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "Cleaning unused packages..."

sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo "Terraform removed successfully!"

# Verify cleanup
if command -v terraform >/dev/null 2>&1; then
  echo "WARNING: Terraform binary still exists"
else
  echo "Terraform uninstalled"
fi
