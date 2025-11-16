-- Create the database
CREATE DATABASE IF NOT EXISTS netlogs;

-- Switch to the new database
USE netlogs;

-- Create the main table for FortiGate traffic logs
CREATE TABLE fgt_traffic
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


-- Create the buffer table for high-performance writes
CREATE TABLE fgt_traffic_buffer
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