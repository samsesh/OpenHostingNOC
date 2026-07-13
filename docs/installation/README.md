# Installation Guide

## Prerequisites

### Hardware Requirements

| Component | Minimum | Recommended |
|---|---|---|
| CPU | 4 cores | 8+ cores |
| RAM | 16 GB | 32-64 GB |
| Storage | 200 GB SSD | 1TB+ NVMe |
| Network | 1 Gbps | 10+ Gbps |

### Software Requirements

- **OS**: Ubuntu 22.04+ / Debian 12+ / Rocky Linux 9+
- **Docker**: 24.0+
- **Docker Compose**: v2.20+
- **Git**: latest

### Network Requirements

**Quick setup (no domain):** No network requirements — uses `nip.io` for auto-resolution, HTTP only.

**Full setup (production):**
- **Public Domain**: `noc.example.com` (or your domain)
- **Ports**: 80 (HTTP redirect), 443 (HTTPS)
- **DNS Records**: `*.noc.example.com` pointing to your NOC server IP

## Step-by-Step Installation

### 1. Install Docker

```bash
# Ubuntu/Debian
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER
newgrp docker

# Verify
docker --version
docker compose version
```

### 2. Clone the Repository

```bash
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC
```

### 3. Run Installation

```bash
sudo ./scripts/install.sh
```

The script will:
1. Prompt for **Quick Setup** (nip.io, no TLS, default passwords) or **Full Setup** (real domain, Let's Encrypt, secure passwords)
2. Automatically generate `.env` with your choices
3. Create directory structure
4. Pull all Docker images
5. Start all services
6. Wait for health checks
7. Initialize LibreNMS database
8. Provide access URLs

### Custom .env (manual)

To customize before deploying, run the generator separately:

```bash
./scripts/generate-env.sh            # Interactive (quick or full)
./scripts/generate-env.sh --quick    # Non-interactive quick setup
./scripts/generate-env.sh --full     # Non-interactive full setup
sudo ./scripts/install.sh
```

### 4. Verify Installation

```bash
# Check all services
./scripts/healthcheck.sh

# View running containers
docker compose ps

# Check logs
docker compose logs -f
```

### 5. Configure DNS (full setup only)

Create DNS A records pointing to your NOC server IP:

```
grafana.noc.example.com    A <NOC_SERVER_IP>
librenms.noc.example.com   A <NOC_SERVER_IP>
ntopng.noc.example.com     A <NOC_SERVER_IP>
prometheus.noc.example.com A <NOC_SERVER_IP>
alertmanager.noc.example.com A <NOC_SERVER_IP>
dashboards.noc.example.com A <NOC_SERVER_IP>
loki.noc.example.com       A <NOC_SERVER_IP>
ldap.noc.example.com       A <NOC_SERVER_IP>
auth.noc.example.com       A <NOC_SERVER_IP>
```

### 6. Access Services

**Quick setup**: `http://<YOUR_IP>:<PORT>` — no TLS, default creds `admin`/`admin`.
**Full setup**: `https://<service>.${DOMAIN}` — TLS via Let's Encrypt.

## Post-Installation

### Add Users via LDAP

Access LDAP Admin at `https://ldap.$DOMAIN` and add users/groups:

```
Base DN: dc=noc,dc=example,dc=com

Groups:
  cn=noc-admin,ou=groups    -> Grafana Admin
  cn=noc-editor,ou=groups   -> Grafana Editor
  cn=noc-viewer,ou=groups   -> Grafana Viewer
```

### Add Monitoring Targets

1. **Node Exporters**: Edit `prometheus/targets/nodes/example.yml`
2. **SNMP Devices**: Edit `prometheus/targets/snmp/example.yml`
3. **Ping Targets**: Edit `prometheus/targets/blackbox_icmp/example.yml`
4. **HTTP Targets**: Edit `prometheus/targets/blackbox_http/example.yml`

### Configure LibreNMS

1. Access `https://librenms.$DOMAIN`
2. Log in with admin credentials
3. Add devices via SNMP
4. Configure alert rules
5. Set up syslog

### Configure ntopng for NetFlow

Configure your network devices to send NetFlow/sFlow to the NOC server:

```
NetFlow Collector: <NOC_SERVER_IP>:2055 (UDP)
sFlow Collector:   <NOC_SERVER_IP>:6343 (UDP)
IPFIX Collector:   <NOC_SERVER_IP>:4739 (UDP)
```

## Next Steps

1. Add Node Exporters to all monitored servers
2. Configure SNMP on all network devices
3. Set up NetFlow/sFlow exports to ntopng
4. Configure alert notifications (Telegram, Discord, etc.)
5. Customize Grafana dashboards
6. Set up Suricata for IDS (optional)
