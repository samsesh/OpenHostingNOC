# Quick Start

Get OpenHostingNOC running in under 10 minutes.

## Prerequisites

- Docker 24.0+ and Docker Compose v2.20+
- A domain with wildcard DNS (e.g., `*.noc.example.com`)
- 4 CPU cores, 16GB RAM, 200GB SSD
- Ports 80 and 443 reachable from the internet (for Let's Encrypt)

## Step 1: Clone & Configure

```bash
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC

cp .env.example .env
```

Edit `.env` — set at minimum:

```bash
DOMAIN=noc.example.com
TRAEFIK_ACME_EMAIL=admin@example.com
OPENLDAP_ADMIN_PASSWORD=your-strong-password
MARIADB_ROOT_PASSWORD=your-strong-password
GRAFANA_ADMIN_PASSWORD=your-strong-password
OPENSEARCH_INITIAL_ADMIN_PASSWORD=your-strong-password
```

## Step 2: Run Installer

```bash
sudo ./scripts/install.sh
```

## Step 3: Verify

```bash
./scripts/healthcheck.sh
docker compose ps
```

## Step 4: Access Services

Once Traefik provisions certificates (may take 60s), access:

- **Grafana**: `https://grafana.$DOMAIN`
- **LibreNMS**: `https://librenms.$DOMAIN`
- **ntopng**: `https://ntopng.$DOMAIN`
- **OpenSearch Dashboards**: `https://dashboards.$DOMAIN`

## Step 5: Add Monitoring Targets

```bash
# Node Exporters
nano prometheus/targets/nodes/example.yml

# SNMP Devices
nano prometheus/targets/snmp/example.yml

# Reload Prometheus
docker compose exec prometheus kill -HUP 1
```

## Next Steps

- [Add users via LDAP](Configuration#ldap)
- [Configure NetFlow on routers](NetFlow-Examples)
- [Set up Telegram alerts](Configuration#alerting)
- [Review security settings](Security)
