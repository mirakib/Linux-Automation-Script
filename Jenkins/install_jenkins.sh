#!/bin/bash
# Ensureing the script is run with root privileges
if [ "$EUID" -ne 0 ]; then
  echo "Please run as root or use sudo."
  exit
fi

echo "--- Updating package list and installing OpenJDK 21 ---"
apt-get update
apt-get install -y openjdk-21-jdk wget

echo "--- Adding Jenkins repository ---"
wget -O /usr/share/keyrings/jenkins-keyring.asc \
  https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key

echo "deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc]" \
  https://pkg.jenkins.io/debian-stable binary/ | tee \
  /etc/apt/sources.list.d/jenkins.list > /dev/null

echo "--- Updating package list with Jenkins repo ---"
apt-get update

echo "--- Installing Jenkins ---"
apt-get install -y jenkins

echo "--- Jenkins installation complete! ---"
echo "You can check the service status with: systemctl status jenkins"
