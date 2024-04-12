#!/bin/bash

# Ignore TERM, HUP and INT signals
trap '' TERM HUP INT

# Function to log changes
log_changes() {
    if [ "$verbose" = true ]; then
        echo "$1"
    fi
    logger "$1"
}

# Function to update hostname
update_hostname() {
    if [ "$desiredName" != "$(hostname)" ]; then
        echo "$desiredName" | sudo tee /etc/hostname >/dev/null
        sudo hostnamectl set-hostname "$desiredName"
        log_changes "Updated hostname from $(hostname) to $desiredName"
    else
        if [ "$verbose" = true ]; then
            echo "Hostname is already set to $desiredName"
        fi
    fi
}

# Function to update IP address
update_ip_address() {
    current_ip=$(ip addr show dev "$lan_interface" | grep -o -E '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' | head -n 1)
    if [ "$current_ip" != "$desiredIPAddress" ]; then
        sudo sed -i "s/$current_ip/$desiredIPAddress/g" /etc/hosts
        sudo netplan apply
        log_changes "Updated IP address from $current_ip to $desiredIPAddress"
    else
        if [ "$verbose" = true ]; then
            echo "IP address is already set to $desiredIPAddress"
        fi
    fi
}

# Function to update /etc/hosts
update_hosts_file() {
    if ! grep -q "$desiredIPAddress $desiredName" /etc/hosts; then
        echo "$desiredIPAddress $desiredName" | sudo tee -a /etc/hosts >/dev/null
        log_changes "Added $desiredName ($desiredIPAddress) to /etc/hosts"
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
lan_interface=$(ip route get 8.8.8.8 | awk '{print $5; exit}')

# Update hostname
update_hostname

# Update IP address
update_ip_address

# Update /etc/hosts
update_hosts_file
