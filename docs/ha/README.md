# High Availability

## Overview

The default deployment is single-node. For production environments requiring HA, follow these recommendations.

## Architecture

```
                    ┌──────────────────────┐
                    │   Load Balancer      │
                    │   (HAProxy/Nginx)     │
                    └──────┬─────────────┬─┘
                           │             │
                    ┌──────▼────┐  ┌─────▼──────┐
                    │  NOC-01   │  │  NOC-02    │
                    │  (Active) │  │ (Standby)  │
                    └───────────┘  └────────────┘
                           │             │
                    ┌──────▼─────────────▼──────┐
                    │     Shared Storage (NFS)   │
                    └────────────────────────────┘
```

## Component HA Strategies

### Traefik (Active-Passive)

- Run Traefik instances on both nodes
- Use keepalived for VIP (Virtual IP) failover
- Shared ACME certificate storage

### MariaDB (Master-Master or Master-Slave)

**Master-Slave Replication**:

```bash
# On master node
docker compose exec mariadb mysql -u root -p -e "
  CREATE USER 'replica'@'%' IDENTIFIED BY 'replica_password';
  GRANT REPLICATION SLAVE ON *.* TO 'replica'@'%';
  SHOW MASTER STATUS;
"

# On slave node
docker compose exec mariadb mysql -u root -p -e "
  CHANGE MASTER TO
    MASTER_HOST='<master_ip>',
    MASTER_USER='replica',
    MASTER_PASSWORD='replica_password',
    MASTER_LOG_FILE='mariadb-bin.000001',
    MASTER_LOG_POS=<position>;
  START SLAVE;
  SHOW SLAVE STATUS\G;
"
```

### Redis Sentinel (High Availability)

Not applicable for single-node; for multi-node, configure Redis Sentinel:

```yaml
sentinel:
  image: redis:7-alpine
  command: redis-sentinel /etc/redis/sentinel.conf
  volumes:
    - ./redis/sentinel.conf:/etc/redis/sentinel.conf
```

### OpenSearch Cluster (Multi-Node)

```yaml
# In docker-compose.yml, add multiple OpenSearch nodes
opensearch-node1:
  image: opensearchproject/opensearch:2.19.5
  environment:
    - node.name=opennoc-os-1
    - discovery.type=zen
    - discovery.seed_hosts=opensearch-node2,opensearch-node3
    - cluster.initial_master_nodes=opennoc-os-1,opennoc-os-2,opennoc-os-3

opensearch-node2:
  image: opensearchproject/opensearch:2.19.5
  environment:
    - node.name=opennoc-os-2
    - discovery.seed_hosts=opensearch-node1,opensearch-node3
    - cluster.initial_master_nodes=opennoc-os-1,opennoc-os-2,opennoc-os-3

opensearch-node3:
  image: opensearchproject/opensearch:2.19.5
  environment:
    - node.name=opennoc-os-3
    - discovery.seed_hosts=opensearch-node1,opensearch-node2
    - cluster.initial_master_nodes=opennoc-os-1,opennoc-os-2,opennoc-os-3
```

### Grafana (Active-Passive)

- Shared SQLite database on NFS (or migrate to MySQL/PostgreSQL)
- Shared provisioning and dashboard files
- Session affinity through load balancer

### Prometheus (Active-Passive with Thanos)

For true HA, deploy Thanos:

```yaml
thanos-sidecar:
  image: thanosio/thanos:latest
  command:
    - sidecar
    - --tsdb.path=/prometheus
    - --prometheus.url=http://prometheus:9090
    - --objstore.config-file=/etc/thanos/object-store.yml

thanos-query:
  image: thanosio/thanos:latest
  command:
    - query
    - --store=thanos-sidecar:10901
    - --store=thanos-sidecar-remote:10901
```

## Load Balancer Configuration (HAProxy)

```haproxy
frontend noc_frontend
    bind *:80
    bind *:443
    mode tcp
    default_backend noc_backend

backend noc_backend
    mode tcp
    balance roundrobin
    option tcp-check
    server noc-01 <NOC1_IP>:443 check
    server noc-02 <NOC2_IP>:443 check backup
```

## Shared Storage (NFS)

```bash
# On NFS server
apt-get install nfs-kernel-server
mkdir -p /srv/nfs/opennoc
echo "/srv/nfs/opennoc <NOC_NETWORK>(rw,sync,no_subtree_check)" >> /etc/exports
exportfs -a

# On NOC nodes
apt-get install nfs-common
mount -t nfs <NFS_SERVER>:/srv/nfs/opennoc /var/lib/docker/volumes
```

## VIP with Keepalived

```bash
# /etc/keepalived/keepalived.conf on master
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    virtual_router_id 51
    priority 100
    advert_int 1
    authentication {
        auth_type PASS
        auth_pass 1234
    }
    virtual_ipaddress {
        10.0.0.100/24
    }
}
```
