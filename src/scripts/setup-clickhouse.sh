#!/bin/bash

# Update package lists
sudo apt-get update

# Install ClickHouse
sudo apt-get install -y clickhouse-server clickhouse-client

# Create necessary directories
sudo mkdir -p /etc/clickhouse-server
sudo mkdir -p /var/lib/clickhouse
sudo mkdir -p /var/log/clickhouse-server

# Copy the ClickHouse configuration file
sudo cp ../config/clickhouse.yaml /etc/clickhouse-server/config.xml

# Start ClickHouse service
sudo service clickhouse-server start

# Enable ClickHouse to start on boot
sudo systemctl enable clickhouse-server

echo "ClickHouse installation and setup completed."