#!/bin/bash
set -e
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Unsupported OS"
    exit 1
fi

# Check if Minikube is already installed
if command -v minikube >/dev/null 2>&1; then
    echo "Minikube is already installed"
    minikube version
    exit 0
fi

case "$OS" in
    ubuntu|debian)
        sudo apt-get update
        sudo apt-get install -y curl conntrack
        ;;
    centos|rhel|rocky)
        sudo yum install -y curl conntrack
        ;;
    *)
        echo "Unsupported OS: $OS"
        exit 1
        ;;
esac

# Install kubectl if not present
if ! command -v kubectl >/dev/null 2>&1; then
    echo "Installing kubectl..."
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    chmod +x kubectl
    sudo mv kubectl /usr/local/bin/
fi

# Install Minikube
echo "Installing Minikube..."
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64
sudo install minikube-linux-amd64 /usr/local/bin/minikube
rm minikube-linux-amd64

# Verify installation
echo "Verifying installation..."
minikube version
kubectl version --client

echo "Minikube installation completed successfully!"
