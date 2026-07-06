# Configuration Guide

## Environment Variables

All configuration is managed through `.env`. See `.env.example` for all 200+ options.

### Core Settings

| Variable | Description | Default |
|---|---|---|
| `DOMAIN` | Base domain for all services | `noc.example.com` |
| `TIMEZONE` | Server timezone | `UTC` |
| `COMPOSE_PROFILE` | Service profile | `full` |

### Profiles

- **full** - All services (default)
- **core** - Prometheus, Grafana, Loki, Alertmanager
- **network** - LibreNMS, ntopng, SNMP, Blackbox
- **security** - OpenSearch, Dashboards, Suricata
- **minimal** - Prometheus, Grafana, Alertmanager

## Key Service Locations

| Service | Config Path | Key File |
|---|---|---|
| Traefik | `traefik/config/` | `middleware.yml`, `routers.yml` |
| Prometheus | `prometheus/` | `prometheus.yml`, `alerts/*.yml` |
| Grafana | `grafana/` | `grafana.ini`, `ldap.toml` |
| LibreNMS | `librenms/config/` | `librenms.php`, `snmp.conf` |
| ntopng | `ntopng/config/` | `ntopng.conf` |
| Loki | `loki/config/` | `loki.yml` |
| Alertmanager | `alertmanager/` | `alertmanager.yml` |
| Auth Service | `auth/` | `app/main.py` |

## Adding Monitoring Targets

```yaml
# prometheus/targets/nodes/servers.yml
- targets: ['10.0.0.1:9100', '10.0.0.2:9100']
  labels:
    group: production
```

## LDAP

Using built-in OpenLDAP — access `https://ldap.<DOMAIN>` to manage users.

Directory structure:
```
dc=noc,dc=example,dc=com
├── ou=users      # LDAP users
└── ou=groups     # cn=noc-admin, cn=noc-editor, cn=noc-viewer
```

For external LDAP/AD, set `LDAP_HOST`, `LDAP_BIND_DN`, `LDAP_BIND_PASSWORD` in `.env`.

---

*Full reference: [docs/configuration/](../docs/configuration/)*
