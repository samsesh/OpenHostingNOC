<p align="center">
  <img src="https://img.shields.io/badge/version-1.0.0-blue.svg" alt="Version">
  <img src="https://img.shields.io/badge/release-stable-00BFA5.svg" alt="Release">
  <img src="https://img.shields.io/badge/license-MIT-green.svg" alt="License">
  <img src="https://img.shields.io/badge/Docker-24.0%2B-2496ED" alt="Docker">
  <img src="https://img.shields.io/badge/Compose-v2.20%2B-2496ED" alt="Compose">
  <img src="https://img.shields.io/badge/OpenSearch-2.19-005EB8" alt="OpenSearch">
  <img src="https://img.shields.io/badge/Grafana-11-FF8F00" alt="Grafana">
  <img src="https://img.shields.io/badge/LibreNMS-26.6-00BFA5" alt="LibreNMS">
</p>

<h1 align="center">🔭 OpenHostingNOC</h1>
<p align="center">
  <strong>Self-hosted Network Operations Center for hosting providers</strong>
  <br>
  Monitor servers, network devices, customer bandwidth, and security threats — all from a single pane of glass.
</p>

<p align="center">
  <a href="#features">Features</a> •
  <a href="#architecture">Architecture</a> •
  <a href="#quick-start">Quick Start</a> •
  <a href="#screenshots">Screenshots</a> •
  <a href="#documentation">Documentation</a> •
  <a href="#contributing">Contributing</a>
</p>

---

## Features

<table>
  <tr>
    <td width="50%">
      <h3>📊 Infrastructure Monitoring</h3>
      <ul>
        <li>CPU, RAM, Disk, Temperature</li>
        <li>RAID, SMART, Network Interfaces</li>
        <li>Ping, Packet Loss, Latency</li>
        <li>BGP Sessions, OSPF, WireGuard</li>
        <li>Linux, Windows, Proxmox, VMware</li>
      </ul>
    </td>
    <td width="50%">
      <h3>🔒 Security Detection</h3>
      <ul>
        <li>UDP/SYN/ICMP Floods</li>
        <li>DNS/NTP/SSDP Amplification</li>
        <li>Port Scanning, SSH Brute Force</li>
        <li>DDoS Indicators</li>
        <li>Suricata IDS/IPS (optional)</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td>
      <h3>🌐 Traffic Analysis</h3>
      <ul>
        <li>NetFlow v5/v9, IPFIX, sFlow</li>
        <li>Top Talkers, Top Ports, Top Protocols</li>
        <li>95th Percentile Billing</li>
        <li>Per-IP Bandwidth Historical Graphs</li>
        <li>Daily/Monthly Usage</li>
      </ul>
    </td>
    <td>
      <h3>📡 Network Monitoring</h3>
      <ul>
        <li>LibreNMS SNMP Discovery</li>
        <li>MikroTik, Cisco, Juniper, Arista</li>
        <li>Fortinet, OPNsense, pfSense</li>
        <li>Automated Config Backup (Oxidized)</li>
        <li>Syslog Collection</li>
      </ul>
    </td>
  </tr>
  <tr>
    <td>
      <h3>🚨 Alerting</h3>
      <ul>
        <li>Telegram, Discord, Slack</li>
        <li>Email, Webhook, PagerDuty</li>
        <li>Warning / Critical / Emergency</li>
        <li>Deduplication, Silencing</li>
        <li>Maintenance Windows, Escalation</li>
      </ul>
    </td>
    <td>
      <h3>🔧 Operations</h3>
      <ul>
        <li>Centralized Logging (Loki)</li>
        <li>Container Monitoring (cAdvisor)</li>
        <li>Automated Backups to S3</li>
        <li>Health Checks & Self-Monitoring</li>
        <li>LDAP/AD Authentication</li>
      </ul>
    </td>
  </tr>
</table>

---

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

### Components

| Service | Role | Port |
|---|---|---|
| **Traefik** | Reverse proxy, TLS, rate limiting, LDAP auth | 80, 443 |
| **Grafana** | Metrics dashboards, alerting UI | 3000 |
| **Prometheus** | Metrics collection, alert evaluation | 9090 |
| **Loki** | Log aggregation | 3100 |
| **Alertmanager** | Alert routing, deduplication, notifications | 9093 |
| **OpenSearch** | Security events, flow history, log analytics | 9200 |
| **LibreNMS** | SNMP network discovery, syslog, billing | 80 |
| **ntopng** | NetFlow/sFlow/IPFIX, DDoS detection | 3000 |
| **MariaDB** | LibreNMS database | 3306 |
| **Redis** | Cache and queue | 6379 |

### Supported Flow Protocols

| Protocol | Port | Devices |
|---|---|---|
| NetFlow v5/v9 | 2055 UDP/TCP | Cisco, Juniper, MikroTik, Linux (softflowd) |
| IPFIX | 4739 UDP/TCP | Cisco, Arista, Fortinet |
| sFlow | 6343 UDP | Arista, Fortinet, OPNsense |

---

## Quick Start

### Prerequisites

- Docker 24.0+ & Compose v2.20+
- Ubuntu 22.04+ / Debian 12+ / Rocky Linux 9+
- Domain with wildcard DNS pointing to your NOC server
- 4+ CPU cores, 16GB+ RAM, 200GB+ SSD

### Installation

```bash
# Clone the repository
git clone https://github.com/your-org/OpenHostingNOC.git
cd OpenHostingNOC

# Configure environment
cp .env.example .env
nano .env                          # Set DOMAIN, passwords, tokens

# Run automated install
sudo ./scripts/install.sh
```

The installer will:
1. Create directory structure
2. Pull all Docker images
3. Start all services
4. Initialize LibreNMS
5. Provide access URLs

### Post-Install

```bash
# Check everything is healthy
./scripts/healthcheck.sh

# View service status
docker compose ps

# Follow logs
docker compose logs -f
```

### Access URLs

Once deployed, access your dashboards at:

| Service | URL | Auth |
|---|---|---|
| Grafana | `https://grafana.$DOMAIN` | LDAP |
| LibreNMS | `https://librenms.$DOMAIN` | LDAP |
| ntopng | `https://ntopng.$DOMAIN` | LDAP |
| Prometheus | `https://prometheus.$DOMAIN` | LDAP |
| Alertmanager | `https://alertmanager.$DOMAIN` | LDAP |
| OpenSearch Dashboards | `https://dashboards.$DOMAIN` | admin + password |

---

## Screenshots

<table>
  <tr>
    <th>NOC Overview Dashboard</th>
    <th>Security Dashboard</th>
  </tr>
  <tr>
    <td><img src="docs/images/noc-overview.png" alt="NOC Overview" width="400"></td>
    <td><img src="docs/images/security-dashboard.png" alt="Security Dashboard" width="400"></td>
  </tr>
  <tr>
    <th>Traffic & Bandwidth</th>
    <th>Docker Monitoring</th>
  </tr>
  <tr>
    <td><img src="docs/images/traffic-bandwidth.png" alt="Traffic Bandwidth" width="400"></td>
    <td><img src="docs/images/docker-monitoring.png" alt="Docker" width="400"></td>
  </tr>
</table>

*Note: Add screenshots to `docs/images/` after deployment.*

---

## Use Cases

### 🏢 Hosting Provider NOC
- Monitor hundreds of servers and thousands of customer IPs
- Track per-customer bandwidth usage for billing (95th percentile)
- Detect and alert on DDoS attacks targeting your infrastructure
- SLA monitoring with ping/latency probes

### 🌐 ISP Network Operations
- Monitor BGP sessions, OSPF neighbors, interface utilization
- Collect NetFlow from core routers for traffic analysis
- Config backup for all network devices via Oxidized
- Security event correlation from Suricata and ntopng

### 🏭 Enterprise IT Operations
- Unified monitoring across Linux/Windows/VMware/Proxmox
- Centralized logging with Loki
- Container monitoring with cAdvisor
- RBAC via LDAP for team access control

---

## Documentation

Full documentation is in the `docs/` directory and GitHub Wiki:

| Topic | Docs | Wiki |
|---|---|---|
| Installation Guide | [docs/installation](docs/installation/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Installation) |
| Configuration | [docs/configuration](docs/configuration/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Configuration) |
| NetFlow Examples | [docs/configuration/netflow-examples.md](docs/configuration/netflow-examples.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/NetFlow-Examples) |
| Upgrade Guide | [docs/upgrade](docs/upgrade/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Upgrade) |
| Backup & Restore | [docs/backup](docs/backup/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Backup-Restore) |
| Troubleshooting | [docs/troubleshooting](docs/troubleshooting/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Troubleshooting) |
| High Availability | [docs/ha](docs/ha/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/High-Availability) |
| Scaling | [docs/scaling](docs/scaling/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Scaling) |
| Security | [docs/security](docs/security/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Security) |
| Disaster Recovery | [docs/disaster-recovery](docs/disaster-recovery/README.md) | [Wiki](https://github.com/your-org/OpenHostingNOC/wiki/Disaster-Recovery) |

---

## Scripts

| Script | Purpose |
|---|---|
| `scripts/install.sh` | Full installation of all services |
| `scripts/update.sh` | Update services with rollback support |
| `scripts/backup.sh` | Backup all configs, databases, volumes |
| `scripts/restore.sh` | Restore from any backup |
| `scripts/healthcheck.sh` | Comprehensive system health check |
| `scripts/cert-renew.sh` | Manual TLS certificate renewal trigger |
| `scripts/db-optimize.sh` | MariaDB/OpenSearch index optimization |
| `scripts/cleanup.sh` | Remove old data, logs, Docker artifacts |
| `scripts/logrotate.sh` | Log rotation for non-Docker services |

---

## Alerting

```
Emergency ──── Telegram ──── Discord (@everyone) ──── Slack (@channel) ──── Email ──── Webhook
Critical ───── Telegram ──── Discord ──── Slack ──── Email ──── Webhook
Warning ────── Telegram ──── Email (digest)
Security ───── Telegram ──── Email (dedicated security channel)
Maintenance ── Silenced via Alertmanager
```

---

## Security

- **TLS 1.3** with strong ciphers, HSTS preload
- **LDAP/AD** authentication for all services
- **Rate limiting** (100 req/s per IP)
- **Security headers** (CSP, X-Frame-Options, etc.)
- **Network segmentation** — 6 isolated Docker networks
- **Non-root containers** with resource limits
- **Fail2Ban** for SSH brute force protection
- **Suricata** optional IDS/IPS with OpenSearch export
- **Automated backups** with S3 off-site sync

---

## Performance Sizing

| Capacity | RAM | Storage | OpenSearch Nodes |
|---|---|---|---|
| 1 Gbps | 16 GB | 1 TB | 1 |
| 10 Gbps | 48 GB | 4 TB | 3 |
| 25 Gbps | 96 GB | 10 TB | 3 |
| 40 Gbps | 192 GB | 20 TB | 3+ |
| 100 Gbps | 384 GB+ | 40 TB+ | 5+ |

---

## Tech Stack

```
Traefik 3.7     → Reverse Proxy
Grafana 11      → Dashboards
Prometheus 3.13 → Metrics
Loki 3.8        → Logs
OpenSearch 2.19 → Search & Analytics
LibreNMS 26.6   → Network Monitoring
ntopng (latest) → Traffic Analysis
MariaDB 11      → SQL Database
Redis 7         → Cache
Alertmanager    → Alert Routing
cAdvisor 0.60   → Container Metrics
Suricata 7      → IDS/IPS (optional)
```

---

## Contributing

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/my-feature`
3. Commit changes: `git commit -am 'Add my feature'`
4. Push: `git push origin feature/my-feature`
5. Open a Pull Request

### Development

```bash
# Start in development mode
docker compose up -d

# View logs
docker compose logs -f

# Make config changes and reload
docker compose restart <service>
```

---

## License

MIT License — see [LICENSE](LICENSE) for details.

## Support

- [GitHub Issues](https://github.com/your-org/OpenHostingNOC/issues)
- [Discussions](https://github.com/your-org/OpenHostingNOC/discussions)

## Donate

If you find this project useful, consider supporting development:

- **Donation Page**: [donate.samsesh.net](https://donate.samsesh.net)
