# Quick Start

Get OpenHostingNOC running in 2 commands.

## Prerequisites

- Docker 24.0+, Docker Compose v2.20+
- Ubuntu 22.04+ / Debian 12+ / Rocky Linux 9+
- 4 CPU cores, 16 GB RAM, 200 GB SSD

## Quick Setup (no domain, no TLS)

```bash
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC
sudo ./scripts/install.sh
```

Choose **option 1 (Quick Setup)** when prompted. The script auto-detects your server IP and uses `nip.io` for hostname resolution.

**Access services at:**
| Service | URL | Credentials |
|---|---|---|
| Grafana | `http://<IP>:3000` | admin / admin |
| LibreNMS | `http://<IP>:8000` | admin / admin |
| Prometheus | `http://<IP>:9090` | via SSO |
| ntopng | `http://<IP>:3003` | via SSO |
| Alertmanager | `http://<IP>:9093` | via SSO |
| OpenSearch Dashboards | `http://<IP>:5601` | admin / admin |

## Full Setup (production)

```bash
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC
sudo ./scripts/install.sh
```

Choose **option 2 (Full Setup)**. Requires a domain with wildcard DNS pointing to your server.

## What's Next?

- Add Node Exporters to monitored servers (`prometheus/targets/nodes/`)
- Configure NetFlow/sFlow on network devices → ntopng
- Set up alert notifications in `.env` (Telegram, Discord, Slack)
- Explore pre-built Grafana dashboards
- Review [Configuration](Configuration) for all options
