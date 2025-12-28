#!/bin/bash
set -e

echo "Installing prerequisites..."

sudo apt-get update -y
sudo apt-get install -y curl gnupg software-properties-common

echo "Adding HashiCorp GPG key..."

curl -fsSL https://apt.releases.hashicorp.com/gpg | \
sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "Adding HashiCorp repository..."
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
sudo tee /etc/apt/sources.list.d/hashicorp.list > /dev/null

echo "Installing Terraform..."

sudo apt-get update -y
sudo apt-get install -y terraform

echo "Terraform installed successfully"

terraform -version
