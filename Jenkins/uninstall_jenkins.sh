#!/bin/bash

# Ensureubg the script is run with root privileges
if [ "$(id -u)" -ne 0 ]; then
  echo "This script must be run as root." >&2
  exit 1
fi

echo "--- Stopping the Jenkins service ---"
systemctl stop jenkins
systemctl disable jenkins

echo "--- Purging Jenkins and its dependencies ---"
apt-get purge -y jenkins

echo "--- Removing the Jenkins user and group ---"
deluser --remove-home jenkins
delgroup jenkins

echo "--- Removing the Jenkins repository and GPG key ---"
rm -f /etc/apt/sources.list.d/jenkins.list
rm -f /usr/share/keyrings/jenkins-keyring.asc

echo "--- Cleaning up unused dependencies ---"
apt-get autoremove -y

echo "--- Updating package lists ---"
apt-get update

echo "✅ Jenkins has been completely uninstalled."

echo "--- Now, uninstalling JDK ---"

# Find and list installed JDK packages
echo "🔍 Searching for installed OpenJDK packages..."
installed_jdk_packages=$(dpkg -l | grep -i openjdk | awk '{print $2}')

if [ -z "$installed_jdk_packages" ]; then
  echo "No OpenJDK packages found. Skipping JDK removal."
else
  echo "Found the following JDK packages to remove:"
  echo "$installed_jdk_packages"

  # Purge all identified OpenJDK packages
  echo "--- Purging all installed OpenJDK packages ---"
  apt-get purge -y $installed_jdk_packages

  # Clean up any remaining dependencies
  echo "--- Cleaning up remaining dependencies ---"
  apt-get autoremove -y

  echo "✅ JDK has been completely uninstalled."
fi

echo "--- Final system cleanup complete! ✅ ---"
