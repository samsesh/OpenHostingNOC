# Installation Guide

## Prerequisites

| Component | Minimum | Recommended |
|---|---|---|
| CPU | 4 cores | 8+ cores |
| RAM | 16 GB | 32-64 GB |
| Storage | 200 GB SSD | 1TB+ NVMe |
| Network | 1 Gbps | 10+ Gbps |

**Software**: Ubuntu 22.04+ / Debian 12+, Docker 24.0+, Docker Compose v2.20+

## Quick Install

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# 2. Clone repo
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC

# 3. Configure
cp .env.example .env
nano .env   # set DOMAIN, passwords, tokens

# 4. Deploy
sudo ./scripts/install.sh
```

## What the Install Script Does

1. Creates directory structure
2. Pulls all Docker images
3. Starts all 18+ services
4. Waits for health checks
5. Initializes LibreNMS database
6. Provides post-installation URLs

## Verify

```bash
./scripts/healthcheck.sh
docker compose ps
```

## DNS Setup

Create A records pointing to your NOC IP:

```
grafana.noc.example.com      A <NOC_IP>
librenms.noc.example.com     A <NOC_IP>
ntopng.noc.example.com       A <NOC_IP>
prometheus.noc.example.com   A <NOC_IP>
alertmanager.noc.example.com A <NOC_IP>
dashboards.noc.example.com   A <NOC_IP>
loki.noc.example.com         A <NOC_IP>
ldap.noc.example.com         A <NOC_IP>
auth.noc.example.com         A <NOC_IP>
```

## Post-Installation

- **Add users** via LDAP Admin at `https://ldap.<DOMAIN>`
- **Add Node Exporters** in `prometheus/targets/nodes/`
- **Add SNMP devices** in `prometheus/targets/snmp/`
- **Configure NetFlow** on network devices → ntopng (ports 2055/4739/6343)

## Next Steps

1. Add monitoring targets
2. Configure alert notifications (Telegram, Discord, Slack)
3. Customize Grafana dashboards
4. Set up Suricata IDS (optional)

---

*Full reference: [docs/installation/](../docs/installation/)*
