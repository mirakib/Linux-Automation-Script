# Step 3: Install kubectl

# Download kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"

# Make it executable and move it to a directory in your PATH
sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl


# Step 4: Install Minikube

# Download Minikube
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64

# Install Minikube
sudo install minikube-linux-amd64 /usr/local/bin/minikube


# Step 5: Start Minikube

minikube start --driver=docker
kubectl get nodes
