-- Create database for FortiGate logs
CREATE DATABASE IF NOT EXISTS netlogs;

USE netlogs;

-- Main table for FortiGate traffic logs
CREATE TABLE IF NOT EXISTS fgt_traffic
(
    `ts` DateTime,
    `date` Date DEFAULT toDate(ts),
    `devid` LowCardinality(String),
    `vd` LowCardinality(String),
    `logid` String,
    `level` LowCardinality(String),
    `subtype` LowCardinality(String),
    `action` LowCardinality(String),
    `policyid` UInt32,
    `service` LowCardinality(String),
    `proto` UInt16,
    `srcip` String,
    `dstip` String,
    `srcip_v4` IPv4 DEFAULT toIPv4OrNull(srcip),
    `dstip_v4` IPv4 DEFAULT toIPv4OrNull(dstip),
    `srcip_v6` IPv6 DEFAULT toIPv6OrNull(srcip),
    `dstip_v6` IPv6 DEFAULT toIPv6OrNull(dstip),
    `srcport` UInt16,
    `dstport` UInt16,
    `sessionid` UInt64,
    `duration` UInt32,
    `sentbyte` UInt64,
    `rcvdbyte` UInt64,
    `sentpkt` UInt64,
    `rcvdpkt` UInt64,
    `app` LowCardinality(String),
    `user` LowCardinality(String),
    `dstcountry` LowCardinality(String),
    `srccountry` LowCardinality(String),
    `msg` String
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(date)
ORDER BY (devid, vd, ts, srcip, dstip, srcport, dstport, sessionid)
TTL date + toIntervalDay(180)
SETTINGS index_granularity = 8192;

-- Buffer table for high-performance writes
CREATE TABLE IF NOT EXISTS fgt_traffic_buffer
(
    `ts` DateTime,
    `date` Date DEFAULT toDate(ts),
    `devid` LowCardinality(String),
    `vd` LowCardinality(String),
    `logid` String,
    `level` LowCardinality(String),
    `subtype` LowCardinality(String),
    `action` LowCardinality(String),
    `policyid` UInt32,
    `service` LowCardinality(String),
    `proto` UInt16,
    `srcip` String,
    `dstip` String,
    `srcip_v4` IPv4 DEFAULT toIPv4OrNull(srcip),
    `dstip_v4` IPv4 DEFAULT toIPv4OrNull(dstip),
    `srcip_v6` IPv6 DEFAULT toIPv6OrNull(srcip),
    `dstip_v6` IPv6 DEFAULT toIPv6OrNull(dstip),
    `srcport` UInt16,
    `dstport` UInt16,
    `sessionid` UInt64,
    `duration` UInt32,
    `sentbyte` UInt64,
    `rcvdbyte` UInt64,
    `sentpkt` UInt64,
    `rcvdpkt` UInt64,
    `app` LowCardinality(String),
    `user` LowCardinality(String),
    `dstcountry` LowCardinality(String),
    `srccountry` LowCardinality(String),
    `msg` String
)
ENGINE = Buffer('netlogs', 'fgt_traffic', 16, 10000, 100, 10000, 1000000, 10000000, 100000000);

-- Create table for system events
CREATE TABLE IF NOT EXISTS fgt_system
(
    `ts` DateTime,
    `date` Date DEFAULT toDate(ts),
    `devid` LowCardinality(String),
    `vd` LowCardinality(String),
    `logid` String,
    `level` LowCardinality(String),
    `subtype` LowCardinality(String),
    `action` LowCardinality(String),
    `msg` String,
    `user` LowCardinality(String),
    `srcip` String
)
ENGINE = MergeTree
PARTITION BY toYYYYMM(date)
ORDER BY (devid, vd, ts, subtype)
TTL date + toIntervalDay(180)
SETTINGS index_granularity = 8192;

CREATE TABLE IF NOT EXISTS fgt_system_buffer
(
    `ts` DateTime,
    `date` Date DEFAULT toDate(ts),
    `devid` LowCardinality(String),
    `vd` LowCardinality(String),
    `logid` String,
    `level` LowCardinality(String),
    `subtype` LowCardinality(String),
    `action` LowCardinality(String),
    `msg` String,
    `user` LowCardinality(String),
    `srcip` String
)
ENGINE = Buffer('netlogs', 'fgt_system', 16, 10000, 100, 10000, 1000000, 10000000, 100000000);

-- Create views for common queries
CREATE VIEW IF NOT EXISTS traffic_summary AS
SELECT
    date,
    count() as total_events,
    uniq(srcip) as unique_sources,
    uniq(dstip) as unique_destinations,
    sum(sentbyte + rcvdbyte) as total_bytes
FROM netlogs.fgt_traffic
GROUP BY date;

CREATE VIEW IF NOT EXISTS top_sources AS
SELECT
    srcip,
    count() as connection_count,
    sum(sentbyte + rcvdbyte) as total_bytes
FROM netlogs.fgt_traffic
WHERE date = today()
GROUP BY srcip
ORDER BY connection_count DESC
LIMIT 20;
