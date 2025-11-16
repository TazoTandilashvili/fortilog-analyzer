# VECTOR_CONFIG.md

# Vector Configuration for FortiLog Analyzer

This document provides an overview of the configuration options available in the `vector.toml` file for the FortiLog Analyzer. Each section of the configuration is detailed below, explaining its purpose and how to customize it for your needs.

## Overview

Vector is a high-performance observability data pipeline that can collect, transform, and route logs and metrics. For the FortiLog Analyzer, Vector is configured to process FortiGate syslog messages efficiently and send them to ClickHouse for storage and analysis.

## Configuration Sections

### 1. Sources

The `sources` section defines where Vector will collect logs from. For FortiGate syslog, you might use a UDP source:

```toml
[sources.fortigate_syslog]
  type = "socket"
  address = "0.0.0.0:514"
  mode = "udp"
```

### 2. Transforms

The `transforms` section is used to parse and enrich the logs. You can define various transformations to extract fields from the raw log messages:

```toml
[transforms.parse_fortigate]
  type = "remap"
  inputs = ["fortigate_syslog"]
  source = '''
    .message = parse_syslog!(.message)
  '''
```

### 3. Sinks

The `sinks` section specifies where the processed logs will be sent. For ClickHouse, you would configure it as follows:

```toml
[sinks.clickhouse]
  type = "clickhouse"
  inputs = ["parse_fortigate"]
  endpoint = "http://localhost:8123"
  database = "fortilog"
  table = "logs"
```

### 4. Optional File Sink

If you want to keep a backup of the raw logs, you can add a file sink:

```toml
[sinks.file_sink]
  type = "file"
  inputs = ["fortigate_syslog"]
  path = "/var/log/fortigate_backup.log"
```

## Additional Configuration Options

- **Buffering**: You can configure buffering options to handle bursts of log data.
- **Health Checks**: Set up health checks to monitor the status of your sinks.
- **Logging**: Configure logging levels and outputs for Vector's internal logs.

## Conclusion

This configuration allows you to effectively collect and process FortiGate syslog messages using Vector. Adjust the settings according to your environment and requirements to ensure optimal performance and reliability. For further customization, refer to the [Vector documentation](https://vector.dev/docs/).