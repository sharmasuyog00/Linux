#!/bin/bash

# Ignore TERM, HUP and INT signals
trap '' TERM HUP INT

# Function to log changes
logChanges() {
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
    logger "$1"
}

# Function to update hostname
updateHostname() {
    if [ "$desiredName" != "$(hostname)" ]; then
        echo "$desiredName" | sudo tee /etc/hostname >/dev/null
        sudo hostnamectl set-hostname "$desiredName"
        logChanges "Updated hostname from $(hostname) to $desiredName"
    else
        if [ "$verbose" = true ]; then
            echo "Hostname is already set to $desiredName"
        fi
    fi
}

# Function to update IP address
updateIpAddress() {
    currentIp=$(ip addr show dev "$lanInterface" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ "$currentIp" != "$desiredIPAddress" ]; then
        sudo sed -i "s/$currentIp/$desiredIPAddress/g" /etc/hosts
        sudo netplan apply
        logChanges "Updated IP address from $currentIp to $desiredIPAddress"
    else
        if [ "$verbose" = true ]; then
            echo "IP address is already set to $desiredIPAddress"
        fi
    fi
}

# Function to update /etc/hosts
updateHostsFile() {
    if ! grep -q "$desiredIPAddress $desiredName" /etc/hosts; then
        echo "$desiredIPAddress $desiredName" | sudo tee -a /etc/hosts >/dev/null
        logChanges "Added $desiredName ($desiredIPAddress) to /etc/hosts"
    else
        if [ "$verbose" = true ]; then
            echo "$desiredName ($desiredIPAddress) already exists in /etc/hosts"
        fi
    fi
}

# Parse command line arguments
verbose=false
while getopts "vn:i:h:" opt; do
    case $opt in
        v)
            verbose=true
            ;;
        n)
            desiredName=$OPTARG
            ;;
        i)
            desiredIPAddress=$OPTARG
            ;;
        h)
            IFS=' ' read -ra hostentry <<< "$OPTARG"
            desiredName="${hostentry[0]}"
            desiredIPAddress="${hostentry[1]}"
            ;;
        \?)
            echo "Invalid option: -$OPTARG" >&2
            exit 1
            ;;
    esac
done

# Determine the LAN interface
lanInterface=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

# Update hostname
updateHostname

# Update IP address
updateIpAddress

# Update /etc/hosts
updateHostsFile
