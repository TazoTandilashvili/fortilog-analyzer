#!/bin/bash

# Script to install and set up Vector on a Debian-based system

# Update package list
sudo apt update

# Install necessary dependencies
sudo apt install -y curl

# Download the latest Vector package
bash -c "$(curl -L https://setup.vector.dev)"

# Move the Vector binary to a directory in PATH
sudo apt-get install vector

# Copy the provided vector.toml configuration file
sudo cp ../config/vector.toml /etc/vector/vector.toml

cat <<EOF | sudo tee /etc/systemd/system/vector.service
[Unit]
Description=Vector
Documentation=https://vector.dev
After=network-online.target
Requires=network-online.target

[Service]
User=vector
Group=vector
ExecStartPre=/usr/bin/vector validate /etc/vector/vector.toml
ExecStart=/usr/bin/vector --config /etc/vector/vector.toml
ExecReload=/bin/kill -HUP $MAINPID
Restart=always
AmbientCapabilities=CAP_NET_BIND_SERVICE
EnvironmentFile=-/etc/default/vector
StartLimitInterval=10
StartLimitBurst=5

[Install]
WantedBy=multi-user.target
EOF

# Start the Vector service
sudo systemctl daemon-reload
sudo systemctl enable vector
sudo systemctl start vector

echo "Vector installation and setup completed."