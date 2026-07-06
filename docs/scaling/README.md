# Scaling Guide

## Performance Sizing

### By Network Capacity

| Component | 1 Gbps | 10 Gbps | 25 Gbps | 40 Gbps | 100 Gbps |
|---|---|---|---|---|---|
| **OpenSearch** | 1 node, 8GB | 3 nodes, 16GB | 3 nodes, 32GB | 3+ nodes, 64GB | 5+ nodes, 64GB+ |
| **ntopng** | 4GB RAM | 16GB RAM | 32GB RAM | 64GB RAM | 128GB RAM |
| **Prometheus** | 2GB, 200GB | 4GB, 1TB | 8GB, 2TB | 16GB, 4TB | 32GB, 10TB |
| **Loki** | 2GB, 500GB | 8GB, 2TB | 16GB, 5TB | 32GB, 10TB | 64GB, 20TB |
| **Total Memory** | 16GB | 48GB | 96GB | 192GB | 384GB+ |
| **Total Storage** | 1TB | 4TB | 10TB | 20TB | 40TB+ |

### By Number of Devices

| Metric | Small (<50) | Medium (50-500) | Large (500-5000) | Enterprise (5000+) |
|---|---|---|---|---|
| LibreNMS Pollers | 1 | 2-4 | 4-8 | 8-16 |
| Prometheus Retention | 90 days | 60 days | 30 days | 14 days |
| Loki Retention | 30 days | 14 days | 7 days | 3 days |
| OpenSearch Nodes | 1 | 3 | 5 | 7+ |

## Scaling Strategies

### Vertical Scaling (Single Node)

1. Increase CPU cores and RAM
2. Use faster storage (NVMe RAID)
3. Tune JVM heap for OpenSearch (max 50% of RAM)
4. Increase Prometheus retention limits

### Horizontal Scaling (Multi-Node)

1. **OpenSearch Cluster**: Add nodes to distribute shards
2. **LibreNMS Poller Cluster**: Distribute polling across workers
3. **Prometheus Federation**: Hierarchical Prometheus setup
4. **Loki Simple Scalable**: Deploy read/write/backend components separately

## Specific Component Tuning

### Prometheus

```yaml
# Increase TSDB performance
--storage.tsdb.min-block-duration=2h
--storage.tsdb.max-block-duration=4h
--storage.tsdb.retention.size=2TB

# Increase query performance
--query.max-concurrency=40
--query.max-samples=100000000
```

### OpenSearch

```yaml
# Tune for write-heavy workload
thread_pool.write.queue_size: 10000
thread_pool.search.queue_size: 5000
index.translog.durability: async
index.translog.sync_interval: 30s
index.refresh_interval: 60s
```

### ntopng

```yaml
# For high flow volumes
--max-num-flows=5000000
--flow-serial=1
--pkt-max-size=9216
```

### Loki

```yaml
# For high log volume
limits_config:
  ingestion_rate_mb: 50
  ingestion_burst_size_mb: 100
  max_streams_per_user: 50000
  max_global_streams_per_user: 200000
```

## Storage Considerations

### Disk Type Recommendations

| Component | Minimum | Recommended |
|---|---|---|
| Prometheus (WAL) | SSD | NVMe RAID 10 |
| Loki (Chunks) | SSD | NVMe RAID 10 |
| OpenSearch | SSD | NVMe RAID 10 |
| MariaDB | SSD | NVMe RAID 1 |
| LibreNMS RRD | SSD | SSD |

### Capacity Planning

```bash
# Prometheus: ~1GB per 100k time series per day
# Loki: ~1GB per 10GB log input per day
# OpenSearch: ~3GB per TB of indexed data per day
# MariaDB: ~100MB per 1000 devices per day

# Example for 500 devices at 10Gbps:
# Prometheus: 200GB (200k series, 90d retention)
# Loki: 3TB (30GB/day log input, 30d retention)
# OpenSearch: 4.5TB (50GB/day, 30d retention)
# Total: ~8TB raw, ~15TB with replication
```

## Network Architecture for Scale

```
                   ┌──────────────┐
                   │  NOC Network  │
                   │  10/25/40G   │
                   └──────┬───────┘
                          │
          ┌───────────────┼───────────────┐
          │               │               │
    ┌─────▼─────┐  ┌─────▼─────┐  ┌─────▼─────┐
    │  ntopng   │  │Prometheus │  │ OpenSearch │
    │  + Redis  │  │  Cluster  │  │  Cluster  │
    └───────────┘  └───────────┘  └───────────┘
```

### Flow Distribution

For 100Gbps+ deployments:
1. Use hardware load balancers for NetFlow distribution
2. Deploy multiple ntopng instances, each handling a subset of flows
3. Use Kafka as a buffer between flow exporters and ntopng
