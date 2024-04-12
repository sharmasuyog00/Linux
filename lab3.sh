#!/bin/bash

# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

# Set the remote server details
server1_host="server1-mgmt"
server1_user="remoteadmin"
server2_host="server2-mgmt"
server2_user="remoteadmin"

# Set the desired configurations
server1_name="loghost"
server1_ip="192.168.16.3"
server2_name="webhost"
server2_ip="192.168.16.4"

# Check if the configure-host.sh script exists
if [ ! -f "configure-host.sh" ]; then
    echo "Error: configure-host.sh script not found in the current directory."
    exit 1
fi

# Transfer the configure-host.sh script to the remote servers
echo "Transferring configure-host.sh to the remote servers..."
scp configure-host.sh "${server1_user}@${server1_host}:/root"
scp configure-host.sh "${server2_user}@${server2_host}:/root"

# Run the configure-host.sh script on the remote servers
echo "Running configure-host.sh on the remote servers..."
ssh "${server1_user}@${server1_host}" -- /root/configure-host.sh -name "$server1_name" -ip "$server1_ip" -hostentry "$server2_name" "$server2_ip"
ssh "${server2_user}@${server2_host}" -- /root/configure-host.sh -name "$server2_name" -ip "$server2_ip" -hostentry "$server1_name" "$server1_ip"

# Update the local /etc/hosts file
echo "Updating the local /etc/hosts file..."
./configure-host.sh -hostentry "$server1_name" "$server1_ip"
./configure-host.sh -hostentry "$server2_name" "$server2_ip"

echo "Script execution complete."
