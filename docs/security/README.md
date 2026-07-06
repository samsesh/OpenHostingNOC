# Security Guide

## Security Architecture

### Defense in Depth

```
Layer 1: Host Security
├── OS hardening (minimal services, automatic updates)
├── Fail2Ban (SSH brute force protection)
├── Firewall (iptables/ufw)
└── AuditD (system audit logging)

Layer 2: Docker Security
├── Non-root containers
├── Read-only filesystems
├── Resource limits
├── No privileged containers
└── Network segmentation (6 isolated networks)

Layer 3: TLS/SSL
├── TLS 1.3 only
├── Strong ciphers (AEAD)
├── HSTS (1 year)
└── Let's Encrypt automatic renewal

Layer 4: Authentication
├── LDAP/AD integration
├── Role-based access (Admin/Editor/Viewer)
├── Session management
└── API authentication

Layer 5: Application Security
├── Rate limiting (100 req/s)
├── Security headers (CSP, X-Frame-Options, etc.)
└── Web application firewall (via Traefik)

Layer 6: Monitoring Security
├── Security event detection
├── DDoS monitoring
├── Port scan detection
├── Brute force detection
└── Real-time alerting
```

## Host Hardening

### Firewall Rules

```bash
# UFW (Ubuntu/Debian)
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh
ufw allow 80/tcp
ufw allow 443/tcp
ufw allow from 10.0.0.0/8
ufw enable

# For monitoring network (if exposed)
ufw allow from <MONITORING_NETWORK> to any port 9100  # Node Exporter
ufw allow from <MONITORING_NETWORK> to any port 9116  # SNMP Exporter
```

### Automatic Security Updates

```bash
# Ubuntu/Debian
apt-get install unattended-upgrades
dpkg-reconfigure -plow unattended-upgrades

# Verify
cat /etc/apt/apt.conf.d/20auto-upgrades
```

### SSH Hardening

```bash
# /etc/ssh/sshd_config
PermitRootLogin no
PasswordAuthentication no
MaxAuthTries 3
ClientAliveInterval 300
ClientAliveCountMax 0
AllowUsers <admin-users>
Protocol 2
```

## Container Security

### Security Scanning

```bash
# Scan images for vulnerabilities
docker scout quick <image>

# Using Trivy
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock \
  aquasec/trivy image --severity HIGH,CRITICAL <image>
```

### Docker Bench Security

```bash
# Run security audit
docker run --rm --net host --pid host --userns host \
  --cap-add audit_control \
  -e DOCKER_CONTENT_TRUST=$DOCKER_CONTENT_TRUST \
  -v /var/lib:/var/lib:ro \
  -v /var/run/docker.sock:/var/run/docker.sock:ro \
  -v /usr/lib/systemd:/usr/lib/systemd:ro \
  -v /etc:/etc:ro \
  docker/docker-bench-security
```

## Secret Management

### Docker Secrets

For production, use Docker secrets instead of environment variables:

```bash
# Create a secret
echo "my-secret-password" | docker secret create db_password -

# Use in docker-compose.yml
secrets:
  db_password:
    external: true

services:
  mariadb:
    secrets:
      - db_password
    environment:
      MARIADB_PASSWORD_FILE: /run/secrets/db_password
```

### .env File Security

```bash
# Restrict permissions
chmod 600 .env
chmod 600 traefik/config/users.htpasswd

# Never commit .env to git
echo ".env" >> .gitignore
echo "*.secret" >> .gitignore
```

## Network Security

### Docker Network Isolation

```
traefik_public (external)
    └── Only Traefik exposed here

internal_net
    ├── All web applications
    └── No external access

monitoring_net
    ├── Prometheus + Exporters
    └── Restricted access

database_net
    ├── MariaDB, Redis
    └── Isolated from apps

opensearch_net
    ├── OpenSearch cluster
    └── Internal only
```

### Firewall Rules (Host Level)

```bash
# /etc/iptables/rules.v4
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]

# Allow established connections
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow SSH
-A INPUT -p tcp --dport 22 -j ACCEPT

# Allow HTTP/HTTPS for Traefik
-A INPUT -p tcp --dport 80 -j ACCEPT
-A INPUT -p tcp --dport 443 -j ACCEPT

# Allow internal monitoring
-A INPUT -s 10.0.0.0/8 -j ACCEPT
-A INPUT -s 172.16.0.0/12 -j ACCEPT
-A INPUT -s 192.168.0.0/16 -j ACCEPT

# Rate limit SSH
-A INPUT -p tcp --dport 22 -m recent --set --name SSH
-A INPUT -p tcp --dport 22 -m recent --update --seconds 60 --hitcount 4 --name SSH -j DROP

# Drop invalid packets
-A INPUT -m state --state INVALID -j DROP

# Log dropped packets
-A INPUT -j LOG --log-prefix "FW-DROP: "
COMMIT
```

## Application Security

### Traefik Security Headers

Configured in `traefik/config/middleware.yml`:

- **HSTS**: 1 year, include subdomains, preload
- **CSP**: Strict content security policy
- **X-Frame-Options**: SAMEORIGIN
- **X-Content-Type-Options**: nosniff
- **Referrer-Policy**: strict-origin-when-cross-origin
- **Permissions-Policy**: Restrict camera, mic, geolocation

### Rate Limiting

```yaml
# Traefik rate limiting
ratelimit:
  rateLimit:
    average: 100    # requests per second
    burst: 200
    period: 1m
```

## Monitoring Security Events

### DDoS Detection

Alerts in `prometheus/alerts/security.yml`:

| Alert | Metric | Threshold |
|---|---|---|
| HighPPS | Packet rate | >500K pps |
| HighBPS | Bandwidth | >10 Gbps |
| UDP Flood | UDP datagrams | >50K/sec |
| SYN Flood | SYN overflows | >1K/sec |
| Port Scan | Failed connections | >500/sec |
| Connection Flood | Listen overflows | >100 |

### Security Dashboards

- Real-time PPS/BPS monitoring
- TCP anomaly detection
- UDP traffic analysis
- Connection tracking
- Alert status overview

## Audit Logging

### Enable Audit Logs

In `.env`:
```bash
AUDIT_LOG_ENABLED=true
```

### Log Shipping

All security events are:
1. Collected by Promtail from syslog and application logs
2. Stored in Loki for log analysis
3. Alerted via Alertmanager for real-time notification
4. (Optional) Sent to OpenSearch for long-term security analytics

## Incident Response

### Alert Severity Levels

| Level | Response Time | Escalation |
|---|---|---|
| Emergency | Immediate | All channels + phone |
| Critical | 5 minutes | Telegram + Discord + Slack + Email |
| Warning | 30 minutes | Telegram + Email |
| Info | Next business day | Email digest |

### Response Playbook

1. **Acknowledge alert** in Alertmanager
2. **Assess severity** and impact
3. **Contain** affected systems
4. **Investigate** root cause
5. **Remediate** and verify
6. **Document** incident
7. **Review** and update alert rules

## Compliance

### Data Retention

- Prometheus metrics: 90 days (configurable)
- Loki logs: 31 days (configurable)
- OpenSearch events: 90 days (configurable)
- Backups: 30 days (configurable)

### Sensitive Data

- Customer IPs stored in LibreNMS / ntopng
- Passwords stored in Docker secrets
- SNMP communities stored in config files
- API tokens in environment files

### Access Reviews

- Weekly: Review active users and roles
- Monthly: Audit LDAP group memberships
- Quarterly: Review API token usage
- Annually: Full security audit
