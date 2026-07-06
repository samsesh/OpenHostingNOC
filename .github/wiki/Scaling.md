# Scaling Guide

## Performance Sizing

### By Network Capacity

| Component | 1 Gbps | 10 Gbps | 25 Gbps | 100 Gbps |
|---|---|---|---|---|
| OpenSearch | 1 node, 8GB | 3 nodes, 16GB | 3 nodes, 32GB | 5+ nodes, 64GB+ |
| ntopng | 4GB RAM | 16GB RAM | 32GB RAM | 128GB RAM |
| Prometheus | 2GB, 200GB | 4GB, 1TB | 8GB, 2TB | 32GB, 10TB |
| Loki | 2GB, 500GB | 8GB, 2TB | 16GB, 5TB | 64GB, 20TB |
| **Total Memory** | 16GB | 48GB | 96GB | 384GB+ |

### By Number of Devices

| Metric | <50 | 50-500 | 500-5000 | 5000+ |
|---|---|---|---|---|
| LibreNMS Pollers | 1 | 2-4 | 4-8 | 8-16 |
| Prometheus Retention | 90d | 60d | 30d | 14d |
| OpenSearch Nodes | 1 | 3 | 5 | 7+ |

## Tuning

### Prometheus

```yaml
--storage.tsdb.min-block-duration=2h
--storage.tsdb.max-block-duration=4h
--query.max-concurrency=40
```

### OpenSearch

```yaml
thread_pool.write.queue_size: 10000
index.translog.durability: async
index.refresh_interval: 60s
```

### ntopng

```yaml
--max-num-flows=5000000
--pkt-max-size=9216
```

### Loki

```yaml
limits_config:
  ingestion_rate_mb: 50
  max_streams_per_user: 50000
```

## Storage

| Component | Minimum | Recommended |
|---|---|---|
| Prometheus (WAL) | SSD | NVMe RAID 10 |
| Loki (Chunks) | SSD | NVMe RAID 10 |
| OpenSearch | SSD | NVMe RAID 10 |
| MariaDB | SSD | NVMe RAID 1 |

### Capacity Planning

- Prometheus: ~1GB per 100k time series / day
- Loki: ~1GB per 10GB log input / day
- OpenSearch: ~3GB per TB indexed / day

---

*Full reference: [docs/scaling/](../docs/scaling/)*
