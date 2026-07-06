# Backup & Restore

## Backup Strategy

### What Gets Backed Up

| Component | Method | Size | Frequency |
|---|---|---|---|
| MariaDB | mysqldump (full) | 1-10 GB | Daily |
| Grafana | Volume snapshot | 100 MB | Daily |
| Prometheus | Volume snapshot | 10-200 GB | Weekly |
| Loki | Volume snapshot | 10-500 GB | Weekly |
| OpenSearch | Snapshot API | 50-1000 GB | Weekly |
| LibreNMS RRD | Volume snapshot | 1-50 GB | Daily |
| Configuration | File copy | 10 MB | Every change |

### Retention

- Daily backups: 7 days
- Weekly backups: 30 days
- Monthly backups: 12 months

## Manual Backup

```bash
# Full backup
./scripts/backup.sh

# Backup to specific location
./scripts/backup.sh --output /mnt/nfs/backups/opennoc

# Pre-update backup (creates rollback point)
./scripts/backup.sh --pre-update
```

Backups are stored in `backups/YYYYMMDD_HHMMSS.tar.gz`.

## Manual Restore

```bash
# List available backups
ls -la backups/

# Restore specific backup
./scripts/restore.sh 20260101_120000

# Restore rollback backup
./scripts/restore.sh rollback
```

## Individual Component Restore

### MariaDB

```bash
# Restore specific database
gunzip -c backups/20260101_120000/mariadb.sql.gz | \
  docker compose exec -T mariadb \
  mysql -u root -p"$MARIADB_ROOT_PASSWORD" librenms

# Restore all databases
gunzip -c backups/20260101_120000/mariadb.sql.gz | \
  docker compose exec -T mariadb \
  mysql -u root -p"$MARIADB_ROOT_PASSWORD"
```

### OpenSearch

```bash
# Register snapshot repository
curl -sk -u "admin:$OPENSEARCH_PASSWORD" \
  -X PUT "https://localhost:9200/_snapshot/backup" \
  -H 'Content-Type: application/json' \
  -d '{"type": "fs", "settings": {"location": "/usr/share/opensearch/backup/snapshot"}}'

# Restore indices
curl -sk -u "admin:$OPENSEARCH_PASSWORD" \
  -X POST "https://localhost:9200/_snapshot/backup/snapshot_20260101/_restore" \
  -H 'Content-Type: application/json' \
  -d '{"indices": "*", "ignore_unavailable": true}'
```

## Automated Backups

### Using Cron

```bash
# Add to crontab
crontab -e

# Daily backup at 2 AM
0 2 * * * /opt/OpenHostingNOC/scripts/backup.sh >> /var/log/opennoc-backup.log 2>&1

# Weekly backup to NFS
0 3 * * 0 /opt/OpenHostingNOC/scripts/backup.sh --output /mnt/nfs/backups
```

### S3 Backup

Enable S3 backup in `.env`:

```bash
BACKUP_S3_ENABLED=true
BACKUP_S3_BUCKET=opennoc-backups
BACKUP_S3_ENDPOINT=https://s3.amazonaws.com
BACKUP_S3_ACCESS_KEY=<your-access-key>
BACKUP_S3_SECRET_KEY=<your-secret-key>
```

## Disaster Recovery

See [Disaster Recovery](../disaster-recovery/README.md) for complete DR procedures.
