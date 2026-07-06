# Configuration Guide

## Environment Variables

All configuration is managed through `.env` file and mounted configuration files.

### Core Configuration

| Variable | Description | Default |
|---|---|---|
| `DOMAIN` | Base domain for all services | `noc.example.com` |
| `TIMEZONE` | Server timezone | `UTC` |
| `LOG_LEVEL` | Logging verbosity | `info` |
| `COMPOSE_PROFILE` | Service profile (full/core/network/security/minimal) | `full` |

### Docker Compose Profiles

- **full** - All services (default)
- **core** - Prometheus, Grafana, Loki, Alertmanager
- **network** - LibreNMS, ntopng, SNMP, Blackbox
- **security** - OpenSearch, Dashboards, Suricata
- **minimal** - Prometheus, Grafana, Alertmanager

### Resource Limits

Configure per-service resource limits in `.env`:

```bash
# Format: <SERVICE>_<CPU|MEM>
PROMETHEUS_CPU=2
PROMETHEUS_MEM=4g
OPENSEARCH_CPU=4
OPENSEARCH_MEM=8g
NTOPNG_MEM=8g
```

See `.env.example` for all available options.

## Service-Specific Configuration

### Traefik

Location: `traefik/config/`

Files:
- `middleware.yml` - Security headers, rate limiting, CORS
- `routers.yml` - Route definitions, TLS options

Key features:
- Automatic Let's Encrypt certificate management
- Rate limiting: 100 req/s average, 200 burst
- Security headers: HSTS, CSP, X-Frame-Options
- LDAP forward authentication via built-in auth service

### Prometheus

Location: `prometheus/`

Files:
- `prometheus.yml` - Main config with scrape targets
- `rules/*.yml` - Recording rules
- `alerts/*.yml` - Alert rules (infrastructure, security, network, container, monitoring)
- `targets/` - File-based service discovery targets
- `blackbox.yml` - Blackbox exporter probe modules
- `snmp.yml` - SNMP exporter OID modules

Targets:
- Add Node Exporters: `targets/nodes/*.yml`
- Add SNMP devices: `targets/snmp/*.yml`
- Add ping targets: `targets/blackbox_icmp/*.yml`
- Add HTTP targets: `targets/blackbox_http/*.yml`

### Grafana

Location: `grafana/`

Files:
- `grafana.ini` - Server, auth, security, alerting settings
- `ldap.toml` - LDAP authentication config
- `datasources/datasources.yml` - Data source provisioning
- `dashboards/json/` - Pre-built dashboards
- `provisioning/` - Auto-provisioning config

Datasources configured:
- Prometheus (default)
- Loki
- OpenSearch
- ntopng
- LibreNMS
- Alertmanager

### LibreNMS

Location: `librenms/config/`

Files:
- `librenms.php` - Main LibreNMS config (DB, Redis, LDAP, alerting, modules)
- `snmp.conf` - SNMP defaults
- `oxidized.yaml` - Config backup settings

### ntopng

Location: `ntopng/config/ntopng.conf`

Configuration includes:
- NetFlow v5/v9/IPFIX/sFlow collectors on ports 2055, 4739, 6343
- Redis connection
- OpenSearch export (optional)
- Local network definitions
- Performance tuning

### Loki

Location: `loki/config/loki.yml`

Configuration:
- TSDB index
- File system storage
- Retention: 744 hours (31 days)
- Query parallelization: 32
- Compactor with auto-deletion

### Alertmanager

Location: `alertmanager/`

Files:
- `alertmanager.yml` - Route tree, receivers, inhibition rules
- `templates/*.tmpl` - Notification templates (Telegram, Discord, Slack, Email)

Alert routing:
- Emergency: Immediate, all channels, 15min repeat
- Critical: All channels, 1h repeat
- Warning: Telegram + Email, 4h repeat
- Security: Dedicated receiver, 15min repeat
- Maintenance: Null receiver (silenced)

### OpenSearch

Location: `opensearch/config/`

Files:
- `opensearch.yml` - Cluster, memory, security settings
- `dashboards.yml` - Dashboards UI configuration
- `security/` - TLS certificates

### MariaDB

Location: `mariadb/config/my.cnf`

Optimized for:
- InnoDB buffer pool: 2GB
- Query cache disabled (InnoDB native)
- Binary logging enabled (7 day retention)
- Performance schema enabled

## LDAP Configuration

### Built-in OpenLDAP

If using the built-in OpenLDAP container:
1. Access `https://ldap.$DOMAIN` (phpLDAPadmin)
2. Log in with admin credentials
3. Create user structure:
   ```
   dc=noc,dc=example,dc=com
   ├── ou=users
   │   ├── uid=admin
   │   └── uid=operator
   └── ou=groups
       ├── cn=noc-admin
       ├── cn=noc-editor
       └── cn=noc-viewer
   ```

### External LDAP/AD

Point to your existing LDAP/AD server:

```bash
USE_LDAP=true
LDAP_HOST=ldap.example.com
LDAP_PORT=389
LDAP_BASE_DN=dc=example,dc=com
LDAP_BIND_DN=cn=admin,dc=example,dc=com
LDAP_BIND_PASSWORD=<password>
```

## Network Flow Configuration

### MikroTik RouterOS

```
/ip traffic-flow set enabled=yes cache-entries=64k active-flow-timeout=30m inactive-flow-timeout=15s
/ip traffic-flow target add address=<NOC_IP> port=2055 version=9
```

### Cisco IOS/IOS-XE

```
flow exporter NOC
 destination <NOC_IP>
 transport udp 2055
 template data timeout 30
!
flow monitor NOC-MONITOR
 exporter NOC
 record netflow ipv4 original-input
!
interface GigabitEthernet0/0/0
 ip flow monitor NOC-MONITOR input
 ip flow monitor NOC-MONITOR output
```

### Juniper JunOS

```
forwarding-options {
    sampling {
        instance {
            NOC-SAMPLING {
                input {
                    rate 1000;
                }
                family inet {
                    output {
                        flow-server <NOC_IP> {
                            port 2055;
                            version 9;
                        }
                    }
                }
            }
        }
    }
}
```

### Linux softflowd

```bash
# Install
apt-get install softflowd

# Start (replace <NOC_IP> and <INTERFACE>)
softflowd -i <INTERFACE> -n <NOC_IP>:2055 -T full -t 60
```

## SNMP Configuration

### Device SNMP Setup

```bash
# MikroTik
/snmp community set public addresses=0.0.0.0/0
/snmp set enabled=yes trap-community=public

# Cisco
snmp-server community public RO
snmp-server enable traps

# Juniper
set snmp community public authorization read-only
```

### Prometheus SNMP Targets

Add devices to `prometheus/targets/snmp/`:

```yaml
- targets:
    - '192.168.1.1'
  labels:
    host: core-router
    vendor: mikrotik
    role: router
```

## Customization

### Adding New Dashboards

1. Create JSON in `grafana/dashboards/json/`
2. Add provisioning entry in `grafana/provisioning/dashboards/dashboards.yml`
3. Restart Grafana: `docker compose restart grafana`

### Custom Alert Rules

Add new rules in `prometheus/alerts/` with the pattern:
```yaml
groups:
  - name: custom
    rules:
      - alert: MyAlert
        expr: my_metric > threshold
        for: 5m
        labels:
          severity: warning
        annotations:
          summary: "Alert summary"
```

### Adding New Services

1. Add service to `docker-compose.yml`
2. Add Traefik labels for routing
3. Add Prometheus scrape config
4. Add Loki log collection (optional)
5. Create relevant alerts and dashboards
