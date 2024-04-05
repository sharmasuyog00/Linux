#!/bin/bash

## 1. Network Configuration
# Check and update the persistent network configuration for the 192.168.16.21/24 interface
if ! grep -q "address: 192.168.16.21/24" /etc/netplan/00-installer-config.yaml; then
  echo "Updating network configuration..."
  sed -i 's/address: .*/address: 192.168.16.21\/24/' /etc/netplan/00-installer-config.yaml
  netplan apply
else
  echo "Network configuration is already correct."
fi

# Verify the /etc/hosts file has the correct entry for server1
if ! grep -q "192.168.16.21 server1" /etc/hosts; then
  echo "Updating /etc/hosts file..."
  echo "192.168.16.21 server1" >> /etc/hosts
else
  echo "/etc/hosts file is already correct."
fi

## 2. Software Installation
# Install Apache2 and Squid
if ! dpkg-query -W -f='${Status}' apache2 | grep -q "install ok installed"; then
  echo "Installing Apache2..."
  apt-get update
  apt-get install -y apache2
else
  echo "Apache2 is already installed."
fi

if ! dpkg-query -W -f='${Status}' squid | grep -q "install ok installed"; then
  echo "Installing Squid..."
  apt-get install -y squid
else
  echo "Squid is already installed."
fi

## 3. Firewall Configuration
# Enable and configure the firewall
if ! ufw status | grep -q "active"; then
  echo "Enabling UFW firewall..."
  ufw default deny
  ufw allow 22 from 192.168.16.0/24
  ufw allow 80
  ufw allow 3128
  ufw --force enable
else
  echo "UFW firewall is already enabled and configured."
fi

## 4. User Management
# Create users with specified configurations
echo "Creating user accounts..."

# Create the 'dennis' user with sudo access and the provided SSH key
if ! id -u dennis &> /dev/null; then
  useradd -m -s /bin/bash dennis
  echo "dennis ALL=(ALL:ALL) ALL" >> /etc/sudoers
  mkdir -p /home/dennis/.ssh
  echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIG4rT3vTt99Ox5kndS4HmgTrKBT8SKzhK4rhGkEVGlCI student@generic-vm" >> /home/dennis/.ssh/authorized_keys
else
  echo "User 'dennis' already exists."
fi

# Create the other users with SSH keys
for user in aubrey captain snibbles brownie scooter sandy perrier cindy tiger yoda; do
  if ! id -u $user &> /dev/null; then
    useradd -m -s /bin/bash $user
    mkdir -p /home/$user/.ssh
    ssh-keygen -t rsa -N "" -f /home/$user/.ssh/id_rsa
    ssh-keygen -t ed25519 -N "" -f /home/$user/.ssh/id_ed25519
    cat /home/$user/.ssh/id_rsa.pub >> /home/$user/.ssh/authorized_keys
    cat /home/$user/.ssh/id_ed25519.pub >> /home/$user/.ssh/authorized_keys
  else
    echo "User '$user' already exists."
  fi
done

echo "Script executed."
