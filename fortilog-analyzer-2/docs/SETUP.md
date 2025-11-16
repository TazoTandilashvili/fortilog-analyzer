# SETUP.md

# FortiLog Analyzer Setup Instructions

This document provides detailed instructions for setting up the FortiLog Analyzer, including the installation and configuration of Vector and ClickHouse without using Grafana or Docker.

## Prerequisites

Before you begin, ensure that you have the following:

- A Debian-based system (e.g., Ubuntu)
- Sudo privileges
- Basic knowledge of command-line operations

## Step 1: Install and Configure Vector

1. **Download and Install Vector**

   Open a terminal and run the following commands to download and install Vector:

   ```bash
   wget https://packages.timber.io/vector/0.14.0/vector-0.14.0-x86_64-unknown-linux-gnu.tar.gz
   tar -xzf vector-0.14.0-x86_64-unknown-linux-gnu.tar.gz
   sudo mv vector-0.14.0/vector /usr/local/bin/
   ```

2. **Configure Vector**

   Create a configuration file for Vector using the provided template:

   ```bash
   sudo cp src/config/vector.toml /etc/vector.toml
   ```

   Edit the configuration file as needed:

   ```bash
   sudo nano /etc/vector.toml
   ```

   Make sure to adjust the source and sink settings according to your environment.

3. **Start Vector**

   Start the Vector service:

   ```bash
   vector --config /etc/vector.toml &
   ```

## Step 2: Install and Configure ClickHouse

1. **Download and Install ClickHouse**

   Run the following commands to install ClickHouse:

   ```bash
   wget -qO - https://clickhouse.com/keys/ClickHouse.asc | sudo apt-key add -
   echo "deb https://repo.clickhouse.com/deb/stable/main/amd64/ clickhouse main" | sudo tee /etc/apt/sources.list.d/clickhouse.list
   sudo apt-get update
   sudo apt-get install clickhouse-server clickhouse-client
   ```

2. **Configure ClickHouse**

   Copy the ClickHouse configuration file:

   ```bash
   sudo cp src/config/clickhouse.yaml /etc/clickhouse-server/config.xml
   ```

   Edit the configuration file as needed:

   ```bash
   sudo nano /etc/clickhouse-server/config.xml
   ```

   Ensure that the user management and database settings are configured properly.

3. **Start ClickHouse**

   Start the ClickHouse service:

   ```bash
   sudo service clickhouse-server start
   ```

## Step 3: Verify Installation

To verify that both Vector and ClickHouse are running correctly, you can check their status:

```bash
sudo systemctl status vector
sudo systemctl status clickhouse-server
```

## Conclusion

You have successfully set up the FortiLog Analyzer with Vector and ClickHouse. For further configuration details, refer to the `VECTOR_CONFIG.md` and `CLICKHOUSE_CONFIG.md` documents in the `docs` directory.