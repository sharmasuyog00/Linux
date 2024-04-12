#!/bin/bash

# This script runs the configure-host.sh script from the current directory to modify 2 servers and update the local /etc/hosts file

# Set the remote server details
server1Host="server1-mgmt"
server1User="remoteadmin"
server2Host="server2-mgmt"
server2User="remoteadmin"

# Set the desired configurations
server1Name="loghost"
server1Ip="192.168.16.3"
server2Name="webhost"
server2Ip="192.168.16.4"

# Check if the configure-host.sh script exists
if [ ! -f "configure-host.sh" ]; then
    echo "Error: configure-host.sh script not found in the current directory."
    exit 1
fi

# Transfer the configure-host.sh script to the remote servers
echo "Transferring configure-host.sh to the remote servers..."
scp configure-host.sh "${server1User}@${server1Host}:/root"
scp configure-host.sh "${server2User}@${server2Host}:/root"

# Run the configure-host.sh script on the remote servers
echo "Running configure-host.sh on the remote servers..."
ssh "${server1User}@${server1Host}" -- /root/configure-host.sh -name "$server1Name" -ip "$server1Ip" -hostentry "$server2Name" "$server2Ip"
ssh "${server2User}@${server2Host}" -- /root/configure-host.sh -name "$server2Name" -ip "$server2Ip" -hostentry "$server1Name" "$server1Ip"

# Update the local /etc/hosts file
echo "Updating the local /etc/hosts file..."
./configure-host.sh -hostentry "$server1Name" "$server1Ip"
./configure-host.sh -hostentry "$server2Name" "$server2Ip"

echo "Script execution complete."
