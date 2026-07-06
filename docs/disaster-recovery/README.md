# Disaster Recovery

## Recovery Objectives

| Metric | Target |
|---|---|
| Recovery Time Objective (RTO) | 4 hours |
| Recovery Point Objective (RPO) | 24 hours |
| Data Loss Tolerance | 1 day of metrics/logs |

## Disaster Scenarios

### 1. Complete Server Failure

**Scenario**: NOC server hardware failure, OS corruption, or extended outage.

**Recovery Procedure**:

1. **Provision new server** with same specs
2. **Install prerequisites**:
   ```bash
   curl -fsSL https://get.docker.com | sh
   git clone https://github.com/samsesh/OpenHostingNOC.git
   ```
3. **Restore from latest backup**:
   ```bash
   # Copy backup to new server
   scp user@backup-server:/backups/latest.tar.gz /opt/OpenHostingNOC/backups/
   
   # Restore
   cd /opt/OpenHostingNOC
   ./scripts/restore.sh latest
   ```
4. **Verify services**:
   ```bash
   ./scripts/healthcheck.sh
   ```
5. **Update DNS records** to point to new IP
6. **Notify team** that DR is complete

### 2. Database Corruption

**Scenario**: MariaDB or OpenSearch data corruption.

**Recovery**:

```bash
# Stop affected service
docker compose stop mariadb

# Restore from backup
gunzip -c backups/<date>/mariadb.sql.gz | \
  docker compose exec -T mariadb mysql -u root

# For OpenSearch:
# Delete corrupted indices first
curl -sk -u admin:$OS_PASSWORD \
  -X DELETE "https://localhost:9200/corrupted-index"

# Then restore from snapshot
curl -sk -u admin:$OS_PASSWORD \
  -X POST "https://localhost:9200/_snapshot/backup/snapshot_<date>/_restore"
```

### 3. Security Breach

**Scenario**: Unauthorized access to NOC server.

**Response**:

1. **Isolate server**: Remove from network
2. **Preserve evidence**: `docker commit` running containers
3. **Rotate all credentials**:
   - All .env passwords
   - LDAP admin password
   - Telegram bot tokens
   - API keys
   - SSH keys
4. **Restore from pre-breach backup**
5. **Investigate** via:
   - Loki logs (auth.log, traefik access.log)
   - Container logs
   - System audit logs
6. **Patch vulnerabilities**
7. **Re-deploy** with updated security

### 4. Data Center Failure

**Scenario**: Complete data center outage.

**Recovery**:

```bash
# 1. Provision in alternate data center
# 2. Restore from off-site backup (S3/NFS)
./scripts/restore.sh --from-s3 backup_20260101_120000

# 3. Update DNS
# 4. Reconfigure network devices to send flows to new IP
```

## Backup Verification

### Monthly DR Test

```bash
#!/bin/bash
# DR Test Script

echo "=== DR Test $(date) ==="

# 1. Test backup integrity
for backup in backups/*.tar.gz; do
    echo "Testing: $backup"
    tar tzf "$backup" > /dev/null || echo "FAILED: $backup"
done

# 2. Test MariaDB backup
gunzip -c backups/latest/mariadb.sql.gz | head -100 | grep -q "CREATE DATABASE" \
    && echo "MariaDB backup: OK" \
    || echo "MariaDB backup: FAILED"

# 3. Test restore to DR environment
# Simulate restore (requires DR environment)
# ./scripts/restore.sh --dry-run latest

echo "=== DR Test Complete ==="
```

### Recovery Testing

Quarterly: Full restore to isolated environment

```bash
# Test full recovery procedure
mkdir /tmp/dr-test
cp -r OpenHostingNOC /tmp/dr-test/
cd /tmp/dr-test
./scripts/install.sh
./scripts/restore.sh <latest-backup>
./scripts/healthcheck.sh
```

## Prevention

### Monitoring

- Disk space alerts at 85%, 90%, 95%
- Service health checks every 15 seconds
- Database replication lag monitoring
- Certificate expiry alerts (14 and 7 days)

### Maintenance

- Weekly: Backup verification
- Monthly: Security updates
- Quarterly: Full DR test
- Annually: Security audit

### High Availability

See [High Availability](../ha/README.md) for HA deployment options.

### Off-Site Backups

Enable S3 backup in `.env`:
```bash
BACKUP_S3_ENABLED=true
BACKUP_S3_BUCKET=opennoc-backups
BACKUP_S3_ENDPOINT=https://s3.amazonaws.com
```

## Quick Recovery Reference

```bash
# Full recovery in 5 commands:
1.  fresh VM setup with Docker
2.  git clone <repo> && cd OpenHostingNOC
3.  cp .env.example .env && nano .env   # restore from password manager
4.  scp backup-server:backups/latest.tar.gz backups/
5.  ./scripts/restore.sh latest
```
