#!/bin.bash

# This script performs a fully non-interactive installation of the
# FortiLog analysis stack (ClickHouse & Vector).
#
# It ASSUMES it is being run from the root of the project directory
# and that a 'config.env' file exists in the same directory.

set -e

# --- 1. LOAD CONFIGURATION ---
if [ ! -f config.env ]; then
    echo "❌ ERROR: Configuration file 'config.env' not found."
    echo "Please create 'config.env' with your credentials before running this script."
    exit 1
fi
source ./config.env
echo "Configuration loaded from config.env."

# Check if variables are set
if [ -z "$CLICKHOUSE_USER" ] || [ -z "$CLICKHOUSE_PASSWORD" ]; then
    echo "❌ ERROR: CLICKHOUSE_USER or CLICKHOUSE_PASSWORD are not set in config.env."
    exit 1
fi

echo "🚀 Starting non-interactive installation of FortiLog Analyzer..."

# ==================================
# 2. INSTALL CLICKHOUSE
# ==================================
echo "Installing ClickHouse..."
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg
curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
ARCH=$(dpkg --print-architecture)
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client
sudo systemctl enable clickhouse-server
sudo systemctl start clickhouse-server
echo "ClickHouse installed."

# ==================================
# 3. CONFIGURE CLICKHOUSE
# ==================================
echo "Configuring ClickHouse..."
sudo sed -i "s||<listen_host>0.0.0.0</listen_host>|g" /etc/clickhouse-server/config.xml
sudo systemctl restart clickhouse-server
echo "ClickHouse configured to listen on 0.0.0.0 and restarted."

echo "Waiting for ClickHouse to be ready (10 seconds)..."
sleep 10

echo "Setting ClickHouse '$CLICKHOUSE_USER' user password..."
# Note: This will create the user if it doesn't exist (like 'vector_user')
# or alter it if it does (like 'default').
clickhouse-client --query "CREATE USER IF NOT EXISTS ${CLICKHOUSE_USER} IDENTIFIED WITH sha256_password BY '${CLICKHOUSE_PASSWORD}'"
clickhouse-client --query "GRANT ALL ON netlogs.* TO ${CLICKHOUSE_USER}"
# If the user is 'default', the above command might fail, so we alter it.
if [ "$CLICKHOUSE_USER" == "default" ]; then
    clickhouse-client --query "ALTER USER default IDENTIFIED WITH sha256_password BY '${CLICKHOUSE_PASSWORD}'"
fi

echo "Creating database and tables from sql/setup.sql..."
clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery < ./sql/setup.sql
echo "ClickHouse database and tables created."

# ==================================
# 4. INSTALL VECTOR
# ==================================
echo "Installing Vector..."
bash -c "$(curl -L https://setup.vector.dev)"
sudo apt-get install -y vector
echo "Vector installed."

# ==================================
# 5. CONFIGURE VECTOR
# ==================================
echo "Configuring Vector..."
if ! getent group vector > /dev/null; then
    sudo groupadd --system vector
    echo "Created 'vector' group."
fi
if ! id -u vector > /dev/null 2>&1; then
    sudo useradd --system -g vector vector
    echo "Created 'vector' user."
fi

sudo mkdir -p /etc/vector

# Copy environment file to a location the service can read
sudo cp ./config.env /etc/vector/fortilog.env
sudo chmod 640 /etc/vector/fortilog.env
sudo chown root:vector /etc/vector/fortilog.env

# Copy configs from the project directory
sudo cp ./config/vector.toml /etc/vector/vector.toml
sudo cp ./config/vector.service /lib/systemd/system/vector.service

sudo systemctl daemon-reload
sudo systemctl enable vector.service
sudo systemctl start vector.service
echo "Vector configured and started."

# ==================================
# COMPLETION
# ==================================
echo ""
echo "✅ All components installed and configured!"
echo ""
echo "Installation complete. Here's your setup:"
echo "------------------------------------------------"
echo "  ClickHouse:"
echo "    - User: $CLICKHOUSE_USER"
echo "    - Pass: (set in /etc/vector/fortilog.env)"
echo ""
echo "  Vector:"
echo "    - Status: sudo systemctl status vector"
echo "    - Listening on: UDP 0.0.0.0:514"
echo "------------------------------------------------"
echo "Next step: Point your FortiGate to this server's IP (UDP 514) and check Grafana."