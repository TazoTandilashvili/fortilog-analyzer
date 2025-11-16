#!/bin/bash

# Script to install and set up Vector on a Debian-based system

# Update package list
sudo apt update

# Install necessary dependencies
sudo apt install -y curl

# Download the latest Vector package
curl -sSfL https://sh.vector.dev | sh

# Move the Vector binary to a directory in PATH
sudo mv ~/.cargo/bin/vector /usr/local/bin/

# Create a configuration directory for Vector
sudo mkdir -p /etc/vector

# Copy the provided vector.toml configuration file
sudo cp ../config/vector.toml /etc/vector/vector.toml

# Start the Vector service
sudo systemctl enable vector
sudo systemctl start vector

echo "Vector installation and setup completed."