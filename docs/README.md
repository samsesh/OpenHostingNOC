# OpenHostingNOC

A comprehensive, self-hosted Network Operations Center (NOC) platform for hosting providers. Monitor servers, network devices, customer bandwidth, and security threats - all from a single pane of glass.

## Architecture

```
                    ┌──────────────────────────┐
                    │      Traefik (HTTPS)      │
                    │  Reverse Proxy + TLS + LDAP│
                    └──────────┬───────────────┘
                               │
           ┌───────────────────┼───────────────────┐
           │                   │                   │
     ┌─────▼─────┐      ┌─────▼─────┐      ┌──────▼─────┐
     │  Grafana   │      │  LibreNMS │      │   ntopng   │
     │ Dashboards │      │  Network  │      │   Traffic  │
     │ + Alerts   │      │ Monitoring│      │  Analysis  │
     └─────┬─────┘      └─────┬─────┘      └──────┬─────┘
           │                   │                   │
     ┌─────▼─────┐      ┌─────▼─────┐      ┌──────▼─────┐
     │ Prometheus │      │ MariaDB   │      │  OpenSearch│
     │  Metrics   │      │  + Redis  │      │  Security  │
     └─────┬─────┘      └───────────┘      └──────┬─────┘
           │                                       │
     ┌─────▼─────┐                          ┌──────▼─────┐
     │  Loki     │                          │  Suricata  │
     │  Logs     │                          │  (Optional)│
     └───────────┘                          └────────────┘
```

## Features

- **Infrastructure Monitoring**: CPU, RAM, Disk, Temperature, RAID, SMART, Network Interfaces
- **Network Monitoring**: BGP, OSPF, Interfaces, Ping, Latency, Packet Loss
- **Traffic Analysis**: NetFlow v5/v9, IPFIX, sFlow, Top Talkers, 95th Percentile
- **Security Detection**: DDoS, UDP/SYN/ICMP Floods, Port Scans, Brute Force
- **Customer Monitoring**: Per-IP Bandwidth, Historical Graphs, Monthly Usage
- **Alerting**: Telegram, Discord, Slack, Email, Webhook with deduplication
- **Config Backup**: Automated network device configuration backup via Oxidized
- **Log Management**: Centralized logging with Loki + Promtail
- **Container Monitoring**: Docker host and container metrics via cAdvisor

## Quick Start

```bash
# 1. Clone and configure
cp .env.example .env
nano .env

# 2. Run installation
sudo ./scripts/install.sh

# 3. Access dashboards
open https://grafana.$DOMAIN
open https://librenms.$DOMAIN
open https://ntopng.$DOMAIN
```

## Documentation

- [Installation Guide](installation/)
- [Configuration](configuration/)
- [Upgrade Guide](upgrade/)
- [Backup & Restore](backup/)
- [Troubleshooting](troubleshooting/)
- [High Availability](ha/)
- [Scaling](scaling/)
- [Security](security/)
- [Disaster Recovery](disaster-recovery/)

## Access URLs

| Service | URL | Default Credentials |
|---|---|---|
| Grafana | `https://grafana.$DOMAIN` | admin / from .env |
| LibreNMS | `https://librenms.$DOMAIN` | admin / from .env |
| ntopng | `https://ntopng.$DOMAIN` | admin / admin |
| Prometheus | `https://prometheus.$DOMAIN` | LDAP auth |
| Alertmanager | `https://alertmanager.$DOMAIN` | LDAP auth |
| Loki | `https://loki.$DOMAIN` | LDAP auth |
| OpenSearch Dashboards | `https://dashboards.$DOMAIN` | admin / from .env |
| LDAP Admin | `https://ldap.$DOMAIN` | admin / from .env |
| Traefik Dashboard | `https://traefik.$DOMAIN` | admin / htpasswd |

## Commands

```bash
# Start all services
docker compose up -d

# View logs
docker compose logs -f

# Stop services
docker compose down

# Update services
./scripts/update.sh

# Backup all data
./scripts/backup.sh

# Restore from backup
./scripts/restore.sh <timestamp>

# Health check
./scripts/healthcheck.sh

# Database optimization
./scripts/db-optimize.sh

# Cleanup old data
./scripts/cleanup.sh
```
