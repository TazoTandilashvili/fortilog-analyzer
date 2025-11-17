#!/bin/bash

set -e

# Load config
if [ ! -f config.env ]; then
    echo "❌ ERROR: config.env not found"
    exit 1
fi
source ./config.env

if [ -z "$CLICKHOUSE_USER" ] || [ -z "$CLICKHOUSE_PASSWORD" ]; then
    echo "❌ ERROR: CLICKHOUSE_USER or CLICKHOUSE_PASSWORD not set"
    exit 1
fi

echo "🚀 Installing ClickHouse..."

# Add repository
sudo apt-get update
sudo apt-get install -y apt-transport-https ca-certificates curl gnupg

if [ ! -f /usr/share/keyrings/clickhouse-keyring.gpg ]; then
    curl -fsSL 'https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key' | \
        sudo gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg
fi

ARCH=$(dpkg --print-architecture)
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] https://packages.clickhouse.com/deb stable main" | \
    sudo tee /etc/apt/sources.list.d/clickhouse.list

# Install ClickHouse (non-interactive)
sudo apt-get update
sudo DEBIAN_FRONTEND=noninteractive apt-get install -y clickhouse-server clickhouse-client

# Stop ClickHouse if running
sudo systemctl stop clickhouse-server || true
sudo pkill -9 clickhouse-server || true
sleep 2

# Clean any conflicting configs
sudo rm -f /etc/clickhouse-server/users.d/*
sudo rm -f /etc/clickhouse-server/config.d/*

# Configure listen on all interfaces
sudo mkdir -p /etc/clickhouse-server/config.d
echo '<?xml version="1.0"?>
<clickhouse>
    <listen_host>0.0.0.0</listen_host>
</clickhouse>' | sudo tee /etc/clickhouse-server/config.d/listen.xml

# CRITICAL: Remove the <password></password> line from main users.xml
# This prevents conflict with password_sha256_hex in users.d
sudo sed -i '/<password><\/password>/d' /etc/clickhouse-server/users.xml

# Generate SHA256 hash of password
PASSWORD_HASH=$(echo -n "$CLICKHOUSE_PASSWORD" | sha256sum | tr -d ' -')

# Create user configuration with password
sudo mkdir -p /etc/clickhouse-server/users.d

if [ "$CLICKHOUSE_USER" == "default" ]; then
    # Override default user password
    echo "<?xml version=\"1.0\"?>
<clickhouse>
    <users>
        <default>
            <password_sha256_hex>${PASSWORD_HASH}</password_sha256_hex>
        </default>
    </users>
</clickhouse>" | sudo tee /etc/clickhouse-server/users.d/default_password.xml
else
    # Create new user
    echo "<?xml version=\"1.0\"?>
<clickhouse>
    <users>
        <${CLICKHOUSE_USER}>
            <password_sha256_hex>${PASSWORD_HASH}</password_sha256_hex>
            <networks>
                <ip>::/0</ip>
            </networks>
            <profile>default</profile>
            <quota>default</quota>
            <access_management>1</access_management>
        </${CLICKHOUSE_USER}>
    </users>
</clickhouse>" | sudo tee /etc/clickhouse-server/users.d/${CLICKHOUSE_USER}.xml
fi

# Set permissions
sudo chown -R clickhouse:clickhouse /etc/clickhouse-server
sudo chmod 644 /etc/clickhouse-server/users.d/*.xml
sudo chmod 644 /etc/clickhouse-server/config.d/*.xml

# Start ClickHouse
sudo systemctl enable clickhouse-server
sudo systemctl start clickhouse-server

# Wait for ClickHouse to be ready
echo "Waiting for ClickHouse..."
for i in {1..30}; do
    if clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --query "SELECT 1" &>/dev/null; then
        echo "✅ ClickHouse is ready and authenticated"
        break
    fi
    echo "Attempt $i/30..."
    sleep 2
done

# Verify connection
if clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --query "SELECT version()"; then
    echo "✅ ClickHouse installed and configured successfully"
    echo "   User: $CLICKHOUSE_USER"
    echo "   Listening on: 0.0.0.0:9000"
else
    echo "❌ Failed to authenticate with ClickHouse"
    echo "Check logs: sudo tail -100 /var/log/clickhouse-server/clickhouse-server.err.log"
    exit 1
fi

# Create database and tables if sql/setup.sql exists
if [ -f ./sql/setup.sql ]; then
    echo "Creating database and tables from sql/setup.sql..."
    clickhouse-client --user "$CLICKHOUSE_USER" --password "$CLICKHOUSE_PASSWORD" --multiquery < ./sql/setup.sql
    echo "✅ Database and tables created."
fi