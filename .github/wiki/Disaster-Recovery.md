# Disaster Recovery

## Recovery Objectives

| Metric | Target |
|---|---|
| RTO | 4 hours |
| RPO | 24 hours |

## Complete Server Failure

```bash
# 1. Provision new server + install Docker
# 2. Clone repo
git clone https://github.com/samsesh/OpenHostingNOC.git
cd OpenHostingNOC

# 3. Copy backup from remote
scp user@backup-server:/backups/latest.tar.gz backups/

# 4. Restore
./scripts/restore.sh latest

# 5. Verify
./scripts/healthcheck.sh

# 6. Update DNS → new IP
```

## Database Corruption

```bash
# Stop service, restore from backup
docker compose stop mariadb
gunzip -c backups/<date>/mariadb.sql.gz | \
  docker compose exec -T mariadb mysql -u root

# OpenSearch: restore from snapshot
curl -sk -u admin:$OS_PASSWORD \
  -X POST "https://localhost:9200/_snapshot/backup/snapshot_<date>/_restore"
```

## Security Breach

1. Isolate server
2. Rotate all credentials (`.env`, LDAP, tokens, SSH keys)
3. Restore from pre-breach backup
4. Investigate via Loki logs
5. Patch vulnerabilities

## Backup Verification

Monthly DR test:

```bash
for backup in backups/*.tar.gz; do
    tar tzf "$backup" > /dev/null || echo "FAILED: $backup"
done
```

## Prevention

| What | When |
|---|---|
| Backup verification | Weekly |
| Security updates | Monthly |
| Full DR test | Quarterly |
| Security audit | Annually |

## Off-Site Backups

```bash
# .env
BACKUP_S3_ENABLED=true
BACKUP_S3_BUCKET=opennoc-backups
BACKUP_S3_ENDPOINT=https://s3.amazonaws.com
```

---

*Full reference: [docs/disaster-recovery/](../docs/disaster-recovery/)*
