# ClickHouse Configuration for FortiLog Analyzer

This document outlines the configuration settings for ClickHouse, which is used for storing and querying logs processed by the FortiLog Analyzer. Below are the key components of the ClickHouse configuration.

## User Management

ClickHouse allows you to manage users and their permissions. You can define users in the `clickhouse.yaml` configuration file. Ensure that you create a user with appropriate permissions for accessing the database.

Example user configuration:
```yaml
users:
  default:
    password: your_password
    profile: default
    quotas:
      - name: default
```

## Database Settings

You need to define the database where logs will be stored. The database can be created using the following SQL command:

```sql
CREATE DATABASE fortilog;
```

Make sure to replace `fortilog` with your desired database name if necessary.

## Table Definitions

Define the tables that will hold the log data. Below is an example of a table definition for storing syslog data:

```sql
CREATE TABLE fortilog.syslog (
    timestamp DateTime,
    host String,
    message String
) ENGINE = MergeTree()
ORDER BY timestamp;
```

Adjust the table schema according to the log structure you expect from FortiGate devices.

## Configuration File Structure

The `clickhouse.yaml` file should include the following sections:

- **users**: Define user credentials and permissions.
- **databases**: Specify the databases to be created.
- **tables**: Outline the structure of the tables for log storage.

## Starting ClickHouse

After configuring the `clickhouse.yaml` file, start the ClickHouse service using the following command:

```bash
sudo service clickhouse-server start
```

Ensure that the service is running correctly by checking the status:

```bash
sudo service clickhouse-server status
```

## Conclusion

This document provides a basic overview of the ClickHouse configuration for the FortiLog Analyzer. For more detailed instructions on setting up and managing ClickHouse, refer to the official ClickHouse documentation.