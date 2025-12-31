#!/bin/bash
set -e
sudo apt update -y
sudo apt install -y openjdk-21-jdk
sudo update-alternatives --set java $(update-alternatives --list java | grep java-21)
sudo update-alternatives --set javac $(update-alternatives --list javac | grep java-21)

echo "Verifying installation..."
java -version
javac -version

echo "OpenJDK 21 installation completed successfully."
