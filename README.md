# FortiLog Analyzer

A high-performance, production-ready log analysis and security monitoring solution for Fortinet FortiGate firewall appliances. Real-time ingestion, storage, and visualization of FortiGate security events with ClickHouse and Grafana.

## 📋 Overview

**FortiLog Analyzer** provides a complete end-to-end solution for collecting, processing, storing, and analyzing Fortinet FortiGate firewall logs. It's designed for:

- **Security Operations Centers (SOCs)** - Real-time threat investigation and response
- **Network Administrators** - Traffic analysis, policy effectiveness, and capacity planning
- **Compliance Teams** - Log retention (180 days by default) and audit trail generation
- **Enterprise Deployments** - High-throughput environments with multi-gigabyte daily log volumes

### Key Capabilities

✅ **Real-time Ingestion** - UDP syslog receiver with 128 MB buffer for high-volume environments
✅ **Smart Parsing** - Automatic type conversion (IPs, timestamps, integers) and field enrichment
✅ **High-Performance Storage** - ClickHouse columnar database optimized for analytics queries
✅ **Interactive Dashboards** - Grafana visualization with pre-built query templates
✅ **Automatic Data Management** - TTL-based retention with monthly partitioning
✅ **Scalable Architecture** - Handles millions of logs daily with efficient batch processing

## 🏗️ System Architecture

```
┌─────────────────┐
│   FortiGate     │
│   Firewall      │────────────────────┐
└─────────────────┘                    │
                              (Syslog UDP 514)
                                      │
                                      ▼
                        ┌──────────────────────┐
                        │   Vector             │
                        │  ┌────────────────┐  │
                        │  │ Syslog Receiver│  │  Port 514 (UDP)
                        │  └────────────────┘  │
                        │  ┌────────────────┐  │
                        │  │ KV Parser      │  │  Parse & Transform
                        │  └────────────────┘  │
                        │  ┌────────────────┐  │
                        │  │ Batch Writer   │  │  300K events/batch
                        │  └────────────────┘  │
                        └──────────┬───────────┘
                                   │
                                   │ (HTTP API Port 8123)
                                   ▼
                        ┌──────────────────────┐
                        │   ClickHouse         │
                        │  ┌────────────────┐  │
                        │  │ Buffer Table   │  │  Temporary Buffer
                        │  └────────┬───────┘  │
                        │           │          │
                        │           ▼          │
                        │  ┌────────────────┐  │
                        │  │ Main Table     │  │  Analytics DB
                        │  │ (MergeTree)    │  │  30+ columns
                        │  └────────────────┘  │  180-day TTL
                        └──────────┬───────────┘
                                   │
                                   │ (SQL Queries)
                                   ▼
                        ┌──────────────────────┐
                        │   Grafana            │
                        │  ┌────────────────┐  │
                        │  │ Dashboards     │  │  Port 3000
                        │  │ Visualizations │  │  Security Analytics
                        │  │ Alerts         │  │  Traffic Analysis
                        │  └────────────────┘  │
                        └──────────────────────┘
```

## 🛠️ Technology Stack

| Component | Technology | Purpose | Port |
|-----------|-----------|---------|------|
| **Log Source** | Fortinet FortiGate | Security appliance | 514/UDP |
| **Log Collector** | Vector (by Datadog) | Syslog parser & batch processor | 514/UDP |
| **Database** | ClickHouse 23.x+ | OLAP analytics database | 8123 (HTTP), 9000 (Native) |
| **Visualization** | Grafana 9.x+ | Interactive dashboards | 3000 |
| **OS** | Debian/Ubuntu 20.04+ | Base operating system | — |

## 📦 Prerequisites

- **Operating System**: Debian 10+ / Ubuntu 20.04+ (other Linux distributions may work)
- **Memory**: Minimum 4 GB RAM (8+ GB recommended for production)
- **Storage**: Minimum 100 GB (depends on daily log volume)
- **Network**: Inbound access to UDP port 514 from FortiGate appliances
- **User Privileges**: Root or `sudo` access for installation
- **FortiGate**: Any recent FortiGate model with syslog capability

## 🚀 Quick Start (5 minutes)

### Step 1: Prepare Configuration

```bash
# Edit credentials (IMPORTANT: change default password!)
nano config.env
# Change: CLICKHOUSE_PASSWORD="changeme123!"
```

### Step 2: Run Installation

```bash
chmod +x install.sh
sudo ./install.sh
```

The installer will:
- ✅ Install and configure ClickHouse
- ✅ Create database schema with optimized tables
- ✅ Install Vector with syslog support
- ✅ Install Grafana for visualization

### Step 3: Configure FortiGate

Log into your FortiGate admin panel and configure syslog:

1. Navigate: `System` → `Log & Report` → `Log Settings`
   - Enable logging for desired traffic types

2. Navigate: `System` → `Log & Report` → `Syslog Settings`
   - **Syslog Server**: `<analyzer-server-ip>`
   - **Port**: `514`
   - **Facility**: `Local 7` (or your preference)

### Step 4: Access Dashboards

- **Grafana**: `http://<server-ip>:3000`

- Add ClickHouse data source (see [Configure Grafana](#configure-grafana) below)

## 📥 Detailed Installation Guide

### A. Configure ClickHouse

The installation script handles most setup, but you may need to verify:

```bash
# Verify ClickHouse is listening on all interfaces
sudo nano /etc/clickhouse-server/config.xml
# Ensure this line is uncommented:
# <listen_host>0.0.0.0</listen_host>

# Verify database exists
clickhouse-client --user default --password 'changeme123!' --query "SHOW DATABASES;"
# Output should include: netlogs
```

### B. Configure and Start Vector

The installation script handles this automatically. Verify:

```bash
# Check Vector service status
sudo systemctl status vector

# Verify listening on port 514
sudo ss -lunp | grep 514
# Output: udp  0  0  0.0.0.0:514  0.0.0.0:*  vector

# View Vector logs
sudo journalctl -u vector -f
```

### C. Configure Grafana

1. **Access Grafana**
   ```
   Browser: http://<your-server-ip>:3000
   ```

2. **Add ClickHouse Data Source**
   - Settings → Data Sources → Add data source → ClickHouse
   - **Connection Details:**
     - URL: `http://clickhouseIP:8123`
     - Database: `netlogs`
     - Username: `default`
     - Password: `changeme123!` (or your password)
   - Click "Save & test"

3. **Import Pre-built Dashboard (Recommended)**

   **Quick Import (Easiest)**
   - Go to: **Dashboards** → **Import**
   - Upload the file: `dashboards/fortilog-analytics.json`
   - The data source will auto-configure for your environment
   - Click **Import**
   - Dashboard will load with traffic visualization

   **Alternative: Manual Build**
   - Dashboards → New → Create dashboard
   - Add panel → ClickHouse data source
   - Use example queries below

### Pre-built Dashboard Features

The included **`dashboards/fortilog-analytics.json`** provides:

**Main Panel: Traffic Table**
- Full FortiGate traffic log visualization
- Columns: Source IP, Source Port, Destination IP, Destination Port, Service, Action, Protocol, Policy ID, Virtual Domain, Log Level, Log Subtype, Timestamp
- Sortable columns (click column headers)
- Pagination support (1000 rows per page)
- Real-time updates

**Filter Variables:**
- **Source IP** - Multi-select dropdown (populated from last 24 hours)
  - Shows top 500 unique source IPs
  - Select "All" or specific IPs to filter traffic

- **Destination IP** - Multi-select dropdown (populated from last 24 hours)
  - Shows top 500 unique destination IPs
  - Select "All" or specific IPs to filter traffic

**Time Range:**
- Default: Last 5 minutes (real-time monitoring)
- Customizable: Use dashboard time picker (top right)
- Supports: 5m, 1h, 24h, 7d, 30d, custom ranges

**Features:**
- ✅ Dynamic IP filtering (auto-populated from data)
- ✅ Real-time log streaming
- ✅ Sortable columns for analysis
- ✅ Time range filtering
- ✅ Multi-select IP filtering
- ✅ Dark theme for 24/7 SOC operations
- ✅ IPv4 conversion from binary format

### Using the Dashboard

1. **Monitor Live Traffic**
   - Set time range to "Last 5 minutes"
   - Watch traffic in real-time as FortiGate sends logs

2. **Filter by Source IP**
   - Click "Source IP" dropdown at top
   - Select specific IPs or leave as "All"
   - Table updates automatically

3. **Filter by Destination IP**
   - Click "Destination IP" dropdown at top
   - Select specific IPs or leave as "All"
   - Combine with source IP for detailed filtering

4. **Investigate Security Events**
   - Look for Action = "Deny" entries
   - Analyze denied connections by IP pair
   - Check policy IDs and protocols involved

5. **Export Data**
   - Click download icon in table footer
   - Export to CSV for further analysis

### Example Queries for Custom Panels

If you want to add more panels to the dashboard:

**Top Source IPs by Traffic:**
```sql
SELECT
    IPv4NumToString(srcip_v4) as source_ip,
    COUNT() as events,
    SUM(sentbyte + rcvdbyte) as total_bytes
FROM netlogs.fgt_traffic
WHERE $__timeFilter(ts)
GROUP BY srcip_v4
ORDER BY total_bytes DESC
LIMIT 20
```

**Top Denied Connections:**
```sql
SELECT
    IPv4NumToString(srcip_v4) as src_ip,
    IPv4NumToString(dstip_v4) as dst_ip,
    COUNT() as blocks,
    proto,
    policyid
FROM netlogs.fgt_traffic
WHERE action = 'Deny' AND $__timeFilter(ts)
GROUP BY srcip_v4, dstip_v4, proto, policyid
ORDER BY blocks DESC
LIMIT 20
```

**Bandwidth Usage by Hour:**
```sql
SELECT
    toStartOfHour(ts) as hour,
    COUNT() as events,
    SUM(sentbyte) / 1024 / 1024 / 1024 as sent_gb,
    SUM(rcvdbyte) / 1024 / 1024 / 1024 as received_gb
FROM netlogs.fgt_traffic
WHERE $__timeFilter(ts)
GROUP BY hour
ORDER BY hour DESC
LIMIT 24
```

## 🗄️ Database Schema

### Table: `fgt_traffic` (Main Analytics Table)

**Storage Engine**: MergeTree (optimized for OLAP queries)
**Partitioning**: Monthly by date (`PARTITION BY toYYYYMM(date)`)
**Data Retention**: 180 days (TTL-based automatic deletion)
**Approx. Size**: ~50 KB per log entry

**Key Columns**:

| Column | Type | Description |
|--------|------|-------------|
| `ts` | DateTime | Log timestamp |
| `date` | Date | Date (for partitioning) |
| `devid` | String | Device ID from FortiGate |
| `vd` | String | Virtual domain |
| `logid` | String | Log ID/subtype |
| `srcip`, `dstip` | IPv4 | Source/destination IPv4 addresses |
| `srcip_v6`, `dstip_v6` | IPv6 | Source/destination IPv6 addresses |
| `srcport`, `dstport` | UInt16 | Source/destination ports |
| `sentbyte`, `rcvdbyte` | UInt64 | Bytes sent/received |
| `sentpkt`, `rcvdpkt` | UInt64 | Packets sent/received |
| `action` | String | Action: Allow/Deny/Block |
| `policyid` | UInt32 | Firewall policy ID |
| `proto` | String | Protocol: TCP/UDP/ICMP/etc |
| `service` | String | Service/application protocol |
| `user` | String | Username (if available) |
| `app` | String | Application detected (if DPI enabled) |
| `dstcountry`, `srccountry` | String | GeoIP country codes |
| `sessionid` | UInt64 | Session ID |
| `duration` | UInt32 | Session duration (seconds) |

### Table: `fgt_traffic_buffer` (Temporary Ingestion Buffer)

**Storage Engine**: Buffer (auto-flushes to main table)
**Purpose**: High-speed temporary writes from Vector

## 🔒 Critical Security Recommendations

### ⚠️ MUST DO IMMEDIATELY

1. **Change ClickHouse Password**
   ```bash
   clickhouse-client -u default --password 'changeme123!'
   ALTER USER default IDENTIFIED BY 'your_strong_password_here';
   ```

2. **Restrict Network Access**
   ```bash
   # Only allow syslog from specific FortiGate IP
   sudo ufw allow from 10.0.1.5 to any port 514/udp
   sudo ufw deny to any port 514/udp

   # Restrict ClickHouse to internal network only
   sudo ufw allow from 127.0.0.1 to any port 8123
   sudo ufw allow from 10.0.0.0/8 to any port 8123
   ```

3. **Protect Credentials File**
   ```bash
   chmod 600 config.env
   # Add to .gitignore:
   echo "config.env" >> .gitignore
   ```

### 🛡️ Recommended Hardening

1. **Create Read-Only Grafana User for ClickHouse**
   ```sql
   CREATE USER grafana IDENTIFIED BY 'grafana_secure_password';
   GRANT SELECT ON netlogs.* TO grafana;
   ```
   Update Grafana datasource to use `grafana` user instead of `default`

3. **System Firewall Configuration**
   ```bash
   sudo ufw default deny incoming
   sudo ufw default allow outgoing
   sudo ufw allow 22/tcp      # SSH
   sudo ufw allow 514/udp from <fortigate-ip>  # Syslog
   sudo ufw allow 3000/tcp from 10.0.0.0/8     # Grafana (internal only)
   sudo ufw enable
   ```

4. **Keep System Updated**
   ```bash
   sudo apt update && sudo apt upgrade -y
   sudo apt autoremove -y
   ```

5. **Enable Audit Logging**
   - Grafana: Administration → Settings → Audit → Enable
   - ClickHouse: Review `/var/log/clickhouse-server/`

6. **Backup Configuration**
   ```bash
   tar -czf fortilog-backup-$(date +%s).tar.gz \
     config.env \
     config/vector.toml \
     config/vector.service \
     sql/setup.sql

   # Store backup securely (encrypted storage, separate location)
   ```

## 🔍 Verification & Testing

### Verify Installation Success

```bash
# 1. Check all services running
sudo systemctl status vector
sudo systemctl status clickhouse-server
sudo systemctl status grafana-server

# 2. Verify Vector is listening
sudo ss -lunp | grep vector
# Should show: udp  0  0  0.0.0.0:514

# 3. Verify ClickHouse connectivity
clickhouse-client -u default --password 'changeme123!' -e "SELECT VERSION();"

# 4. Check database exists
clickhouse-client -u default --password 'changeme123!' -e "SHOW DATABASES;"

# 5. Verify Grafana is accessible
curl -s http://localhost:3000/api/health | jq .
```

### Test Log Ingestion

Once FortiGate is configured to send logs:

```bash
# Check ClickHouse for received logs
clickhouse-client --user=default --password='changeme123!' -d netlogs <<EOF
SELECT COUNT() as total_logs FROM fgt_traffic;
SELECT MAX(ts) as latest_log FROM fgt_traffic;
SELECT DISTINCT action FROM fgt_traffic LIMIT 10;
EOF

# View sample logs
clickhouse-client -u default --password='changeme123!' -d netlogs \
  --query "SELECT ts, srcip, dstip, action, proto FROM fgt_traffic ORDER BY ts DESC LIMIT 20"

```

## 📊 Example Queries

### Top Denied Connections
```sql
SELECT srcip, dstip, COUNT() as blocks
FROM fgt_traffic
WHERE action = 'Deny' AND $__timeFilter(ts)
GROUP BY srcip, dstip
ORDER BY blocks DESC
LIMIT 10;
```

### Bandwidth Usage by Hour
```sql
SELECT
    toStartOfHour(ts) as hour,
    COUNT() as events,
    SUM(sentbyte) / 1024 / 1024 as sent_mb,
    SUM(rcvdbyte) / 1024 / 1024 as received_mb
FROM fgt_traffic
WHERE $__timeFilter(ts)
GROUP BY hour
ORDER BY hour DESC;
```

### Top Applications
```sql
SELECT app, COUNT() as events, SUM(sentbyte + rcvdbyte) as total_bytes
FROM fgt_traffic
WHERE app != '' AND $__timeFilter(ts)
GROUP BY app
ORDER BY total_bytes DESC
LIMIT 15;
```

### Users Activity
```sql
SELECT user, COUNT() as activity_count, COUNT(DISTINCT srcip) as unique_ips
FROM fgt_traffic
WHERE user != '' AND $__timeFilter(ts)
GROUP BY user
ORDER BY activity_count DESC
LIMIT 20;
```

## 🐛 Troubleshooting

### Vector Not Receiving Logs

**Check if port 514 is listening:**
```bash
sudo ss -lunp | grep 514
# Should show vector process
```

**Check Vector logs:**
```bash
sudo journalctl -u vector -n 100 -f
# Look for parsing errors or connection issues
```

**Verify FortiGate is sending:**
- FortiGate: Monitor → Logs → System Events (verify "Syslog" in Facility)
- Check FortiGate→system→log settings is enabled
- Verify network connectivity: `ping <analyzer-ip>` from FortiGate CLI

### No Data Appearing in ClickHouse

**Check buffer and main tables:**
```bash
clickhouse-client -u default --password 'changeme123!' -d netlogs -e "
SELECT COUNT() FROM fgt_traffic;
SELECT COUNT() FROM fgt_traffic_buffer;
"
```

**Verify Vector→ClickHouse connectivity:**
```bash
curl -u default:changeme123! "http://localhost:8123/ping"
# Should return: Ok
```

**Check Vector configuration:**
```bash
sudo cat /etc/vector/vector.toml
# Verify endpoint: http://127.0.0.1:8123
# Verify database: netlogs
# Verify table: fgt_traffic_buffer
```

### Grafana Can't Connect to ClickHouse

**Test ClickHouse HTTP endpoint directly:**
```bash
curl -u default:changeme123! "http://localhost:8123/" -d "SELECT 1"
# Should return: 1
```

**Verify Grafana datasource configuration:**
- Grafana → Configuration → Data Sources
- ClickHouse datasource → Test
- Check logs: `sudo journalctl -u grafana-server -f`

**Common issues:**
- Wrong password in datasource
- Wrong database name (should be: `netlogs`)
- ClickHouse not listening on all interfaces
- Firewall blocking port 8123

## 🚀 Performance Tuning & Optimization

### For High-Volume Environments (100K+ logs/day)

1. **Increase Buffer Settings in Vector**
   ```toml
   # /etc/vector/vector.toml
   [sinks.clickhouse.buffer]
   max_events = 500000      # Increase from 300000
   type = "memory"
   max_bytes = 268435456    # 256 MB instead of 100 MB
   ```

2. **ClickHouse Query Optimization**
   ```sql
   -- Add indexes for common queries
   ALTER TABLE fgt_traffic ADD INDEX idx_action action TYPE set(0) GRANULARITY 3;
   ALTER TABLE fgt_traffic ADD INDEX idx_proto proto TYPE set(0) GRANULARITY 3;
   ```

3. **Monitor Database Performance**
   ```bash
   clickhouse-client -u default --password 'changeme123!' -e "
   SELECT * FROM system.processes LIMIT 10;
   SELECT * FROM system.query_log ORDER BY event_time DESC LIMIT 50;
   "
   ```

## 📈 Future Enhancements

### Recommended

- [ ] High Availability: ClickHouse cluster with replication
- [ ] Automated Alerts: Slack/Teams webhooks for policy violations
- [ ] GeoIP Enrichment: Automatically resolve IP locations
- [ ] Machine Learning: Anomaly detection for unusual traffic patterns
- [ ] Backup/Disaster Recovery: Automated backup strategy
- [ ] REST API: Programmatic access to logs and statistics
- [ ] SIEM Integration: Export to Splunk, ELK, or other SIEMs
- [ ] Multi-FortiGate Support: Aggregate logs from multiple firewalls
- [ ] Kubernetes: Helm charts for K8s deployment
- [ ] Performance Analytics: Built-in system health dashboard

## 📝 Configuration Files Reference

| File | Purpose | Key Variables |
|------|---------|----------------|
| `config.env` | Database credentials | `CLICKHOUSE_USER`, `CLICKHOUSE_PASSWORD` |
| `config/vector.toml` | Vector data pipeline | Syslog address, parser rules, ClickHouse endpoint |
| `config/vector.service` | Systemd service | User, restart policy, capabilities |
| `sql/setup.sql` | Database schema | Table creation, columns, indexes |
| `install.sh` | Automated setup | Installation steps, service enablement |
| `dashboards/fortilog-analytics.json` | Grafana dashboard | Pre-built analytics panels with queries |

### Grafana Dashboards

The `dashboards/` directory contains pre-built Grafana dashboard JSON files that can be imported directly:

**FortiLog Analytics Dashboard** (`fortilog-analytics.json`)
- **Real-time Traffic Monitoring Table** with 1000 rows per page
- **Columns**: Source IP, Source Port, Destination IP, Destination Port, Service, Action, Protocol, Policy ID, VD, Level, Subtype, Timestamp
- **Dynamic IP Filters**: Multi-select dropdowns for Source and Destination IPs (auto-populated from last 24 hours)
- **Time Range Control**: Default 5-minute view, customizable from top-right picker
- **Sortable Columns**: Click any column header to sort data
- **Dark Theme**: Optimized for 24/7 SOC monitoring and eye strain reduction

**How to Import:**
1. Navigate to Grafana → Dashboards → Import
2. Upload `dashboards/fortilog-analytics.json`
3. The data source will auto-detect your ClickHouse environment
4. Click Import
5. Start monitoring FortiGate traffic immediately

**What You Get:**
- ✅ Live traffic streaming from FortiGate
- ✅ Filter by Source IP (top 500 from last 24h)
- ✅ Filter by Destination IP (top 500 from last 24h)
- ✅ Real-time action monitoring (Allow/Deny/Block)
- ✅ Protocol and service identification
- ✅ Policy ID tracking for security analysis
- ✅ Timestamp for forensics and incident response

**Customization:**
- Edit dashboard panels in Grafana UI for quick changes
- Add new panels using the example queries in [Example Queries](#example-queries-for-custom-panels) section
- Export modified dashboard as JSON
- Version control dashboard JSON in `dashboards/` directory

## 📞 Support & Resources

- **Vector Documentation**: https://vector.dev/docs/
- **ClickHouse Documentation**: https://clickhouse.com/docs/
- **Grafana Documentation**: https://grafana.com/docs/
- **FortiGate Syslog Format**: https://docs.fortinet.com/

## 📄 License

[Add your license here]

## ✨ Version History

- **v1.0** - Initial release with basic log ingestion
- **v2.0** - Enhanced with IPv6 support and optimized partitioning
- **v2.1** - Improved documentation and security hardening

---

**Last Updated**: 2025-11-17
**Status**: Production-Ready (with recommended security hardening)
**Tested On**: Ubuntu 20.04 LTS, Debian 11+