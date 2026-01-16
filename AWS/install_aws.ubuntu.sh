# Switch to superuser
sudo su -

# If you’re on Amazon Linux, to install the latest version of the AWS CLI, you must first uninstall the pre-installed yum version
# yum remove awscli

# Download the AWS CLI zip file
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

# Install unzip
sudo apt install unzip

# Unzip the file
sudo unzip awscliv2.zip

# Run the installer
sudo ./aws/install

# Verify AWS CLI 
aws --version
