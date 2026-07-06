# Upgrade Guide

## Standard Upgrade

### 1. Backup Current State

```bash
./scripts/backup.sh
```

### 2. Update Images

```bash
# Pull latest images
docker compose pull

# Recreate containers
docker compose up -d --remove-orphans
```

### 3. Run Update Script

```bash
# Automated update with pre-update backup
./scripts/update.sh
```

### 4. Verify

```bash
./scripts/healthcheck.sh
docker compose ps
```

## Rolling Back

```bash
# Rollback to previous version
./scripts/update.sh --rollback
```

Or restore from backup:

```bash
# List available backups
ls -la backups/*.tar.gz

# Restore specific backup
./scripts/restore.sh 20260101_120000
```

## Upgrading Specific Services

```bash
# Update only specific services
./scripts/update.sh prometheus grafana

# Or manually:
docker compose pull prometheus grafana
docker compose up -d --no-deps prometheus grafana
```

## Major Version Upgrades

### LibreNMS

1. Backup database
2. Pull new image
3. Run database migrations automatically
4. Verify device polling

### OpenSearch

1. Check [breaking changes](https://opensearch.org/docs/latest/install-and-configure/upgrade-opensearch/)
2. Take snapshot backup
3. Update image version
4. Verify cluster health

### Grafana

1. Check [upgrade notes](https://grafana.com/docs/grafana/latest/upgrade/)
2. Backup grafana.db
3. Update image
4. Verify plugins and datasources

## Pre-Update Checklist

- [ ] Backup all databases (MariaDB, OpenSearch)
- [ ] Backup configuration files
- [ ] Check disk space (at least 20% free)
- [ ] Review release notes
- [ ] Notify team about maintenance window
- [ ] Run health check
