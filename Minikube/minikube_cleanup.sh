#!/bin/bash

# --- Kubernetes and Docker Cleanup Script ---
# This script removes all Docker, Minikube, and Kubectl-related packages and files.
# It requires sudo permissions to run.

# Check if the script is being run as root.
if [[ $EUID -ne 0 ]]; then
   echo "This script must be run with sudo. Exiting."
   exit 1
fi

# Step 1: Remove Minikube and Kubectl
print_status "Step 1: Removing Minikube and Kubectl..."

# Remove the Minikube binary
if [ -f "/usr/local/bin/minikube" ]; then
    rm /usr/local/bin/minikube
    echo "Removed Minikube binary."
else
    echo "Minikube binary not found. No action taken."
fi

# Remove the kubectl binary
if [ -f "/usr/local/bin/kubectl" ]; then
    rm /usr/local/bin/kubectl
    echo "Removed kubectl binary."
else
    echo "Kubectl binary not found. No action taken."
fi

# Remove Minikube's configuration and data directories from the user's home
if [ -d "$HOME/.minikube" ]; then
    rm -rf "$HOME/.minikube"
    echo "Removed Minikube user data."
else
    echo "Minikube user data not found. No action taken."
fi


# Step 2: Remove Docker Packages and User Group
print_status "Step 2: Removing all Docker-related packages and files..."

# Remove the packages
apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

# Remove any remaining dependencies
apt-get autoremove -y

# Remove the Docker repository file
rm -f /etc/apt/sources.list.d/docker.list

# Remove the Docker GPG key
rm -f /etc/apt/keyrings/docker.gpg

# Remove the 'docker' user group
if getent group docker > /dev/null; then
    delgroup docker
    echo "Removed the 'docker' user group."
else
    echo "The 'docker' group does not exist. No action taken."
fi


print_status "Cleanup finished successfully."
echo "Your system is now clear of all Docker, Minikube, and Kubectl components."
