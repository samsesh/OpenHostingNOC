# Security Guide

## Defense in Depth

```
Layer 1: Host Security     — OS hardening, Fail2Ban, firewall
Layer 2: Docker Security   — Non-root, read-only FS, network isolation
Layer 3: TLS/SSL           — TLS 1.3, HSTS, Let's Encrypt
Layer 4: Authentication    — LDAP/AD, RBAC, session management
Layer 5: App Security      — Rate limiting, security headers
Layer 6: Monitoring        — DDoS detection, brute force alerts
```

## Host Hardening

```bash
# Firewall
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw enable

# SSH
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
```

## Network Isolation

6 isolated Docker networks:
- `traefik_public` — Only Traefik exposed
- `internal_net` — All web apps
- `monitoring_net` — Prometheus + exporters
- `database_net` — MariaDB, Redis
- `opensearch_net` — OpenSearch cluster
- `ldap_net` — LDAP directory

## Security Headers (Traefik)

Configured in `traefik/config/middleware.yml`:
- HSTS: 1 year, subdomains, preload
- CSP: Strict policy
- X-Frame-Options: SAMEORIGIN
- Rate limiting: 100 req/s average, 200 burst

## Monitoring Security Events

Prometheus alerts detect:
| Threat | Threshold |
|---|---|
| High PPS | >500K pps |
| High Bandwidth | >10 Gbps |
| UDP Flood | >50K datagrams/sec |
| SYN Flood | >1K overflows/sec |
| Port Scan | >500 failed conn/sec |

## Secret Management

```bash
# Restrict .env permissions
chmod 600 .env
chmod 600 traefik/config/users.htpasswd
```

## Incident Severity Levels

| Level | Response | Channels |
|---|---|---|
| Emergency | Immediate | All + phone |
| Critical | 5 min | Telegram + Discord + Slack + Email |
| Warning | 30 min | Telegram + Email |

---

*Full reference: [docs/security/](../docs/security/)*
