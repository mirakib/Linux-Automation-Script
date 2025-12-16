#!/bin/bash

# This script automates the installation of Docker Engine and adds the current user
# to the 'docker' group. It requires sudo permissions to run.


# Check if the script is being run as root.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo. Exiting."
   exit 1
fi

# Step 1: Install Docker Engine
print_status "Step 1: Installing Docker Engine and its dependencies..."

# Update the package list
apt-get update

# Install dependencies for the Docker repository
apt-get install -y ca-certificates curl gnupg

# Add Docker's official GPG key
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# Add the Docker repository to Apt sources. Using '--print-architecture' for better compatibility.
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

# Update the package list again to include Docker
apt-get update

# Install Docker Engine
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin


# Step 2: Add your user to the docker group
print_status "Step 2: Adding the current user '$USER' to the 'docker' group."
# This command adds the user to the group, but it won't be active until a new session.


print_status "Docker setup finished successfully."

sudo usermod -aG docker "$USER"
