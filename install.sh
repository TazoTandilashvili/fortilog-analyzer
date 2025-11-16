#!/bin/bash

set -e

echo "FortiGate + Vector + ClickHouse Log Collector Installation"
echo "=========================================================="

# Colors for output
RED='\\033[0;31m'
GREEN='\\033[0;32m'
YELLOW='\\033[1;33m'
NC='\\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if running as root
if [ "$EUID" -ne 0 ]; then
    print_error "Please run as root"
    exit 1
fi

# Generate random password for ClickHouse
CLICKHOUSE_PASSWORD=$(openssl rand -base64 16 | tr -dc 'a-zA-Z0-9' | head -c 16)

print_status "Generated ClickHouse password: $CLICKHOUSE_PASSWORD"

# Install ClickHouse
print_status "Installing ClickHouse..."

# Install prerequisite packages
apt-get update
apt-get install -y apt-transport-https ca-certificates curl gnupg

# Download the ClickHouse GPG key and store it in the keyring
curl -fsSL '<https://packages.clickhouse.com/rpm/lts/repodata/repomd.xml.key>' | gpg --dearmor -o /usr/share/keyrings/clickhouse-keyring.gpg

# Get the system architecture
ARCH=$(dpkg --print-architecture)

# Add the ClickHouse repository to apt sources
echo "deb [signed-by=/usr/share/keyrings/clickhouse-keyring.gpg arch=${ARCH}] <https://packages.clickhouse.com/deb> stable main" | tee /etc/apt/sources.list.d/clickhouse.list

# Update apt package lists
apt-get update
print_status "Installing clickhouse-server and clickhouse-client"

apt-get install -y clickhouse-server clickhouse-client

# Enable and start the ClickHouse server service
systemctl enable clickhouse-server
systemctl start clickhouse-server

print_status "ClickHouse installed and started"

# Install Vector
print_status "Installing Vector..."

# Update package list
apt update

# Install necessary dependencies
apt install -y curl

# Download and install Vector
curl -1sLf '<https://repos.vector.dev/setup.sh>' | bash
apt install -y vector

print_status "Vector installed"

# Create directories
mkdir -p /etc/vector

# Copy Vector configuration
print_status "Configuring Vector..."
cp vector/vector.toml /etc/vector/
chown vector:vector /etc/vector/vector.toml
chmod 644 /etc/vector/vector.toml

# Copy Vector service file
cp vector/vector.service /lib/systemd/system/vector.service
systemctl daemon-reload

# Setup ClickHouse
print_status "Setting up ClickHouse..."

# Create password file for ClickHouse
cat > /etc/clickhouse-server/users.d/password.xml << EOF
<clickhouse>
    <users>
        <default>
            <password>$CLICKHOUSE_PASSWORD</password>
        </default>
    </users>
</clickHouse>
EOF

# Restart ClickHouse to apply password
systemctl restart clickhouse-server

# Wait for ClickHouse to start
sleep 5

# Create database and tables
print_status "Creating ClickHouse database and tables..."
clickhouse-client --password "$CLICKHOUSE_PASSWORD" --queries-file clickhouse/create_tables.sql

# Update Vector config with ClickHouse password
sed -i "s/CLICKHOUSE_PASSWORD_PLACEHOLDER/$CLICKHOUSE_PASSWORD/g" /etc/vector/vector.toml

# Create Vector user and set permissions
if ! id "vector" &>/dev/null; then
    useradd --system --no-create-home --shell /bin/false vector
fi

# Set proper ownership
chown -R vector:vector /etc/vector

# Enable and start Vector
systemctl enable vector
systemctl start vector

print_status "Waiting for services to stabilize..."
sleep 10

# Verify services are running
if systemctl is-active --quiet clickhouse-server; then
    print_status "ClickHouse is running"
else
    print_error "ClickHouse failed to start"
    exit 1
fi

if systemctl is-active --quiet vector; then
    print_status "Vector is running"
else
    print_error "Vector failed to start"
    exit 1
fi

# Test data flow
print_status "Testing data flow..."
# Send test FortiGate log
echo "<14>\\$(date +'%b %d %H:%M:%S') test-fw date=2025-11-16 time=16:30:00 devid=FGT001 type=traffic srcip=192.168.1.100 dstip=8.8.8.8 srcport=54321 dstport=80 action=accept" | nc -u localhost 514

sleep 5

# Check if data reached ClickHouse
ROW_COUNT=$(clickhouse-client --password "$CLICKHOUSE_PASSWORD" --query "SELECT count() FROM netlogs.fgt_traffic" 2>/dev/null || echo "0")

if [ "$ROW_COUNT" -gt "0" ]; then
    print_status "Data flow test successful! Found $ROW_COUNT rows in ClickHouse"
else
    print_warning "No data found in ClickHouse. Please check FortiGate configuration."
fi

print_status "Installation completed successfully!"
echo ""
echo "=== IMPORTANT INFORMATION ==="
echo "ClickHouse password: $CLICKHOUSE_PASSWORD"
echo "ClickHouse HTTP interface: <http://localhost:8123>"
echo "ClickHouse client: clickhouse-client --password [PASSWORD]"
echo "Vector logs: journalctl -u vector.service -f"
echo "FortiGate syslog destination: $(hostname -I | awk '{print $1}') port 514 UDP"
echo ""
echo "FortiGate configuration guide saved to: fortigate/syslog_config.txt"
echo "=========================================================="
