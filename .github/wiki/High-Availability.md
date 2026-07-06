# High Availability

## Architecture

```
                    ┌──────────────┐
                    │  Load Balancer│
                    │  (HAProxy)    │
                    └──┬─────────┬──┘
                      │         │
                ┌─────▼───┐ ┌───▼──────┐
                │ NOC-01  │ │ NOC-02   │
                │ (Active)│ │ (Standby)│
                └─────────┘ └──────────┘
                      │         │
                ┌─────▼─────────▼──────┐
                │  Shared Storage (NFS) │
                └──────────────────────┘
```

## Component Strategies

| Component | Strategy |
|---|---|
| **Traefik** | Active-passive + keepalived VIP |
| **MariaDB** | Master-slave replication |
| **OpenSearch** | Multi-node cluster (3+ nodes) |
| **Grafana** | Active-passive, shared SQLite on NFS |
| **Prometheus** | Active-passive with Thanos sidecar |
| **Redis** | Redis Sentinel |

## MariaDB Replication

```bash
# On master
CREATE USER 'replica'@'%' IDENTIFIED BY 'replica_password';
GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
SHOW MASTER STATUS;

# On slave
CHANGE MASTER TO MASTER_HOST='<master_ip>',
  MASTER_USER='replica', MASTER_PASSWORD='replica_password',
  MASTER_LOG_FILE='mariadb-bin.000001', MASTER_LOG_POS=<position>;
START SLAVE;
```

## OpenSearch Cluster

Add multiple nodes to `docker-compose.yml` with `discovery.seed_hosts` and `cluster.initial_master_nodes` configured.

## VIP with Keepalived

```bash
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    virtual_ipaddress { 10.0.0.100/24; }
}
```

## Shared Storage (NFS)

```bash
# On NFS server
apt-get install nfs-kernel-server
echo "/srv/nfs/opennoc <NOC_NETWORK>(rw,sync,no_subtree_check)" >> /etc/exports

# On NOC nodes
mount -t nfs <NFS_SERVER>:/srv/nfs/opennoc /var/lib/docker/volumes
```

---

*Full reference: [docs/ha/](../docs/ha/)*
