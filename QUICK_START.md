# FortiLog Analyzer - Quick Start Guide

## 🚀 Get Started in 5 Minutes

### 1. Configure Credentials
```bash
# Edit config file with your ClickHouse password
nano config.env
# Change: CLICKHOUSE_PASSWORD="changeme123!"
```

### 2. Run Installation
```bash
chmod +x install.sh
sudo ./install.sh
```

### 3. Configure FortiGate
Log into FortiGate → System → Log & Report
- **Syslog Server**: `<your-server-ip>`
- **Port**: `514`

### 4. Import Dashboard
1. Open Grafana: `http://<server-ip>:3000`
2. Go to: Dashboards → Import
3. Upload: `dashboards/fortilog-analytics.json`
4. Select ClickHouse data source
5. Click Import

## ✅ Verification Checklist

```bash
# Check Vector is listening
sudo ss -lunp | grep 514

# Check ClickHouse
clickhouse-client -u default --password 'your_password' -e "SELECT VERSION();"

# Check Grafana
curl -s http://localhost:3000/api/health | jq .

# Check logs in database
clickhouse-client -u default --password 'your_password' -d netlogs -e "
  SELECT COUNT() as total FROM fgt_traffic;
"
```

## 🔒 Security (CRITICAL)

- [ ] Change ClickHouse password in `config.env`
- [ ] Change Grafana admin password on first login
- [ ] Restrict syslog port 514 to your FortiGate IP only
- [ ] Remove `config.env` from git version control

```bash
# Add to .gitignore
echo "config.env" >> .gitignore

# Protect credentials file
chmod 600 config.env
```

## 📊 Dashboard Overview

Your dashboard includes these panels:

| Panel | What It Shows |
|-------|--------------|
| **Traffic** | All log entries with source, destination, action |
| **Source IP Filter** | Filter logs by source IP |
| **Destination IP Filter** | Filter logs by destination IP |

## 🐛 Troubleshooting

**No logs appearing?**
```bash
# Check Vector logs
sudo journalctl -u vector -f

# Check ClickHouse connectivity
curl -u default:your_password "http://localhost:8123/ping"

# Verify FortiGate is sending
# FortiGate → System → Log & Report → System Events
```

**Grafana can't connect to ClickHouse?**
- Settings → Data Sources → ClickHouse
- Verify database: `netlogs`
- Verify password matches `config.env`
- Click "Save & Test"

**ClickHouse password issues?**
```bash
# Reset password
clickhouse-client -u default
ALTER USER default IDENTIFIED BY 'new_password';
```

## 📚 Documentation

- **Full Setup Guide**: See `README.md`
- **Security & Recommendations**: See `RECOMMENDATIONS.md`
- **Dashboard Panels**: See `dashboards/fortilog-analytics.json`

## 🔗 Useful Links

- **Vector Docs**: https://vector.dev/docs/
- **ClickHouse Docs**: https://clickhouse.com/docs/
- **Grafana Docs**: https://grafana.com/docs/
- **FortiGate Syslog**: https://docs.fortinet.com/

## 💡 Next Steps

1. ✅ Complete quick start above
2. ✅ Import dashboard from `dashboards/`
3. 📖 Read full documentation in `README.md`
4. 🔒 Implement security hardening from `RECOMMENDATIONS.md`
5. 📊 Customize dashboard panels for your needs
6. 🚨 Set up monitoring and alerts

---

**Questions?** Check `README.md` Troubleshooting section
**Production deployment?** Follow `RECOMMENDATIONS.md` security checklist
