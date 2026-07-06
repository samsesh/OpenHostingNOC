# Backup & Restore

## Backup

```bash
# Full backup
./scripts/backup.sh

# Backup with custom output
./scripts/backup.sh --output /mnt/nfs/backups

# Pre-update backup (creates rollback point)
./scripts/backup.sh --pre-update
```

Backups include:
- All configuration files
- MariaDB database dump
- Grafana dashboards and settings
- Prometheus TSDB data
- Loki log data
- LibreNMS RRD files
- OpenSearch snapshot

## Restore

```bash
# List available backups
ls -la backups/*.tar.gz

# Restore from backup
./scripts/restore.sh 20260101_120000

# Rollback after failed update
./scripts/restore.sh rollback
```

## Automated Backups

Add to crontab:

```bash
0 2 * * * /opt/OpenHostingNOC/scripts/backup.sh
```

## S3 Backup

Enable in `.env`:

```
BACKUP_S3_ENABLED=true
BACKUP_S3_BUCKET=opennoc-backups
BACKUP_S3_ACCESS_KEY=xxx
BACKUP_S3_SECRET_KEY=xxx
```
