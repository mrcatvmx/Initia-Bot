#!/bin/bash

# Stop the Initia node service
echo "Stopping the Initia node service..."
sudo systemctl stop initiad.service

# Disable the service to prevent it from starting automatically on boot
echo "Disabling the Initia node service..."
sudo systemctl disable initiad.service

# Remove the systemd service file
echo "Removing the Initia node service file..."
sudo rm /etc/systemd/system/initiad.service

# Reload systemd daemon to apply changes
sudo systemctl daemon-reload

# Remove the initiad binary
echo "Removing the Initia node binary..."
sudo rm /usr/local/bin/initiad
sudo rm /usr/bin/initiad

# Remove the .initia configuration directory
echo "Removing the .initia configuration directory..."
sudo rm -rf ~/.initia

echo "Initia node service, binary, and configuration directory have been successfully removed."
