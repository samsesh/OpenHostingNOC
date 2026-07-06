# Installation Guide

## Prerequisites

| Component | Minimum | Recommended |
|---|---|---|
| CPU | 4 cores | 8+ cores |
| RAM | 16 GB | 32-64 GB |
| Storage | 200 GB SSD | 1TB+ NVMe |
| Network | 1 Gbps | 10+ Gbps |

**Software**: Ubuntu 22.04+ / Debian 12+ / Rocky Linux 9+, Docker 24.0+, Docker Compose v2.20+

## Quick Install

```bash
# 1. Install Docker
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER && newgrp docker

# 2. Clone repo
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC

# 3. Deploy (generates .env, pulls images, starts all services)
sudo ./scripts/install.sh
```

Choose **Quick Setup** (nip.io, no TLS, default `admin`/`admin`) or **Full Setup** (real domain, Let's Encrypt, random passwords).

## Custom .env Generation

To generate `.env` without installing:

```bash
./scripts/generate-env.sh            # Interactive
./scripts/generate-env.sh --quick    # Quick (no prompts)
./scripts/generate-env.sh --full     # Full (prompts for domain)
```

## What the Install Script Does

1. Runs `generate-env.sh` if `.env` is missing (quick or full)
2. Creates directory structure
3. Pulls all Docker images + builds auth service
4. Starts all 18+ services
5. Waits for health checks
6. Initializes LibreNMS database
7. Prints access URLs

## Verify

```bash
./scripts/healthcheck.sh
docker compose ps
```

## DNS Setup (full setup only)

```
grafana.noc.example.com      A <NOC_IP>
librenms.noc.example.com     A <NOC_IP>
ntopng.noc.example.com       A <NOC_IP>
prometheus.noc.example.com   A <NOC_IP>
alertmanager.noc.example.com A <NOC_IP>
dashboards.noc.example.com   A <NOC_IP>
auth.noc.example.com         A <NOC_IP>
```

## Access

- **Quick setup**: `http://<YOUR_IP>:<PORT>` — no TLS, default `admin`/`admin`
- **Full setup**: `https://<service>.${DOMAIN}` — TLS via Let's Encrypt

## Next Steps

1. Add monitoring targets (Node Exporters, SNMP devices)
2. Configure NetFlow/sFlow on network devices → ntopng (ports 2055/4739/6343)
3. Set up alert notifications (Telegram, Discord, Slack)
4. Customize Grafana dashboards
5. Review [Configuration](Configuration) for all options

---

*Full reference: [docs/installation/](../docs/installation/)*
