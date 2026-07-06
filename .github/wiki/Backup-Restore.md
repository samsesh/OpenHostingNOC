# Backup & Restore

## Backup Strategy

| Component | Method | Frequency |
|---|---|---|
| MariaDB | mysqldump (full) | Daily |
| Grafana | Volume snapshot | Daily |
| Prometheus | Volume snapshot | Weekly |
| Loki | Volume snapshot | Weekly |
| OpenSearch | Snapshot API | Weekly |
| LibreNMS RRD | Volume snapshot | Daily |
| Configuration | File copy | Every change |

**Retention**: Daily 7d, Weekly 30d, Monthly 12m

## Manual Backup

```bash
./scripts/backup.sh                           # Full backup
./scripts/backup.sh --output /mnt/nfs/backups # Custom location
./scripts/backup.sh --pre-update              # Pre-update rollback
```

Backups stored in `backups/YYYYMMDD_HHMMSS.tar.gz`.

## Manual Restore

```bash
./scripts/restore.sh 20260101_120000   # Restore specific backup
./scripts/restore.sh rollback           # Rollback after failed update
```

## Automated Backups (Cron)

```bash
crontab -e
0 2 * * * /opt/OpenHostingNOC/scripts/backup.sh >> /var/log/opennoc-backup.log 2>&1
```

## S3 Backups

```bash
# .env
BACKUP_S3_ENABLED=true
BACKUP_S3_BUCKET=opennoc-backups
BACKUP_S3_ACCESS_KEY=<key>
BACKUP_S3_SECRET_KEY=<secret>
```

---

*Full reference: [docs/backup/](../docs/backup/)*
