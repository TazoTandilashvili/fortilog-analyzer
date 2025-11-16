#!/bin/bash

set -e
echo "Starting installation of FortiLog Analyzer components..."

# ==================================
# 1. INSTALL CLICKHOUSE
# ==================================
echo "Installing ClickHouse..."
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
ARCH=$(dpkg --print-architecture)
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo apt-get install -y clickhouse-server clickhouse-client
sudo systemctl enable clickhouse-server
sudo systemctl start clickhouse-server

echo "ClickHouse installed and started."

# ==================================
# 2. INSTALL VECTOR
# ==================================
echo "Installing Vector..."
bash -c "$(curl -L https://setup.vector.dev)"
sudo apt-get install -y vector
echo "Vector installed."

# ==================================
# 3. INSTALL GRAFANA
# ==================================
echo "Installing Grafana..."
sudo apt-get install -y apt-transport-https software-properties-common
sudo wget -q -O /usr/share/keyrings/grafana.key https://apt.grafana.com/gpg.key
echo "deb [signed-by=/usr/share/keyrings/grafana.key] https://apt.grafana.com stable main" | sudo tee /etc/apt/sources.list.d/grafana.list
sudo apt-get update
sudo apt-get install -y grafana
sudo systemctl daemon-reload
sudo systemctl enable grafana-server.service
sudo systemctl start grafana-server

echo "Grafana installed and started."

# ==================================
# COMPLETION
# ==================================
echo "All components installed."
echo ""
echo "!!! IMPORTANT NEXT STEPS !!!"
echo "1. Edit /etc/clickhouse-server/config.xml to uncomment <listen_host>0.0.0.0</listen_host>"
echo "2. Restart ClickHouse: sudo systemctl restart clickhouse-server"
echo "3. Run the SQL commands in sql/setup.sql (see README.md)"
echo "4. Copy the configs from config/ to /etc/vector/ and /lib/systemd/system/ (see README.md)"
echo "5. Start Vector: sudo systemctl start vector"