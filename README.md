# FortiGate Log Analyzer (ClickHouse + Vector + Grafana)

This project provides a complete setup for analyzing FortiGate (FortiLog) traffic logs in real-time. It uses:
* **Vector:** To receive syslog messages from FortiGate, parse them, and batch-insert them.
* **ClickHouse:** A high-performance, column-oriented database for storing and querying the log data.
* **Grafana:** To visualize the log data and build dashboards.



## Architecture

`FortiGate (Syslog)` &rarr; `Vector (UDP:514)` &rarr; `ClickHouse (Buffer Table)` &rarr; `ClickHouse (Main Table)` &leftrightarrow; `Grafana`

## 1. Installation

### Prerequisites
* A Debian-based Linux server (e.g., Ubuntu 20.04+).
* Root or `sudo` privileges.
* Your FortiGate must be configured to send syslog to this server's IP on UDP port 514.

### Run the Installer
This script installs ClickHouse, Vector, and Grafana.

1.  Make the installation script executable:
    ```bash
    chmod +x install.sh
    ```
2.  Run the script:
    ```bash
    sudo ./install.sh
    ```

## 2. Configure ClickHouse

### A. Edit ClickHouse Config
You must allow ClickHouse to listen on all interfaces so Vector (and later Grafana) can connect.

1.  Open the config file:
    ```bash
    sudo nano /etc/clickhouse-server/config.xml
    ```

2.  Find the line `` and **uncomment** it (remove the ``):
    ```xml
    <listen_host>0.0.0.0</listen_host>
    ```

3.  Restart ClickHouse to apply the change:
    ```bash
    sudo systemctl restart clickhouse-server
    ```

### B. Create the Database and Tables
You can run the provided SQL script using the `clickhouse-client`.

**Note:** The `vector.toml` config uses the password `test123` for the `default` user. You must set this password in ClickHouse.

1.  Log in to the ClickHouse client:
    ```bash
    clickhouse-client
    ```

2.  Inside the client, set the password and run the setup script's contents.
    * First, set the password (replace `test123` if you used a different one):
        ```sql
        ALTER USER default IDENTIFIED WITH sha256_password BY 'test123';
        ```
    * Exit the client (`exit` or `Ctrl+D`).

3.  Now, pipe the SQL setup file to the client to create the database and tables (it will ask for the password `test123`):
    ```bash
    clickhouse-client --user default --password 'test123' --multiquery < ./sql/setup.sql
    ```
    This will create the `netlogs` database, the `fgt_traffic` table, and the `fgt_traffic_buffer` table.

## 3. Configure and Start Vector

1.  Create the Vector config directory:
    ```bash
    sudo mkdir -p /etc/vector
    ```

2.  Copy the configuration files to their destinations:
    ```bash
    sudo cp ./config/vector.toml /etc/vector/vector.toml
    sudo cp ./config/vector.service /lib/systemd/system/vector.service
    ```

3.  Create the `vector` user and group (the service file expects it):
    ```bash
    sudo groupadd --system vector
    sudo useradd --system -g vector vector
    ```

4.  Reload systemd, enable, and start the Vector service:
    ```bash
    sudo systemctl daemon-reload
    sudo systemctl enable vector.service
    sudo systemctl start vector.service
    ```

5.  Check its status to ensure it's running and listening on port 514:
    ```bash
    sudo systemctl status vector
    sudo ss -lunp | grep 514
    ```

At this point, if your FortiGate is sending logs, they should be flowing into your ClickHouse database.

## 4. Configure Grafana

1.  **Access Grafana:** Open your browser and go to `http://<your_server_ip>:3000`.
    * Default login: **admin**
    * Default password: **admin**
    * You will be prompted to change the password.

2.  **Add ClickHouse Data Source:**
    * Go to **Connections** &rarr; **Data sources**.
    * Click **Add data source**.
    * Search for and select **ClickHouse**.
    * Fill in the connection details:
        * **Host:** `http://127.0.0.1` (or your server's IP)
        * **Port:** `8123`
        * **Database:** `netlogs`
        * **Username:** `default`
        * **Password:** `test123` (or the password you set)
    * Click **Save & test**. You should see a "Data source is working" message.

3.  **Build Your Dashboard:**
    * Go to **Dashboards** &rarr; **New dashboard**.
    * Click **Add visualization**.
    * Select your **ClickHouse** data source.
    * You can now build queries to filter traffic.

    **Example Query (Top Talkers by Source IP):**
    ```sql
    SELECT
        srcip,
        count() AS c
    FROM fgt_traffic
    WHERE $__timeFilter(ts)
    GROUP BY srcip
    ORDER BY c DESC
    LIMIT 10
    ```
    * Set the visualization type to **Bar chart** or **Table**.
    * Save the panel and your dashboard.