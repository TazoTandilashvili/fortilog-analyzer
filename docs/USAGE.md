# Usage Examples for FortiLog Analyzer

## Querying Log Data

Once you have set up Vector and ClickHouse, you can start querying your log data. Below are some common usage examples to help you get started.

### 1. Basic Log Query

To retrieve all logs from the last 24 hours:

```sql
SELECT *
FROM logs
WHERE timestamp >= now() - INTERVAL 1 DAY
ORDER BY timestamp DESC
```

### 2. Count Logs by Severity

To count the number of logs grouped by severity level:

```sql
SELECT severity, COUNT(*) AS log_count
FROM logs
GROUP BY severity
ORDER BY log_count DESC
```

### 3. Filter Logs by Source

To filter logs from a specific source (e.g., a specific FortiGate device):

```sql
SELECT *
FROM logs
WHERE source = 'FortiGate-12345'
ORDER BY timestamp DESC
```

### 4. Aggregate Logs by Hour

To aggregate logs by hour and count the number of logs per hour:

```sql
SELECT toStartOfHour(timestamp) AS hour, COUNT(*) AS log_count
FROM logs
GROUP BY hour
ORDER BY hour DESC
```

### Best Practices

- **Indexing**: Ensure that your ClickHouse tables are properly indexed for faster query performance.
- **Partitioning**: Consider partitioning your log data by date to improve query efficiency and manageability.
- **Retention Policies**: Implement retention policies to manage the size of your log data and ensure that older logs are archived or deleted as necessary.

### Conclusion

These examples provide a starting point for querying your log data in ClickHouse. Modify the queries as needed to fit your specific use cases and data structure. For more advanced queries and optimizations, refer to the `docs/CLICKHOUSE_CONFIG.md` and `docs/VECTOR_CONFIG.md` for configuration details.