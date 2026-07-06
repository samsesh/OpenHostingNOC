# Upgrade Guide

## Standard Upgrade

```bash
# 1. Backup first
./scripts/backup.sh

# 2. Pull latest images & rebuild auth service
docker compose pull
docker compose build auth-service

# 3. Recreate containers
docker compose up -d --remove-orphans

# 4. Verify
./scripts/healthcheck.sh
```

Or use the automated script:

```bash
./scripts/update.sh
```

## Update Specific Services

```bash
./scripts/update.sh prometheus grafana
```

## Rolling Back

```bash
# Rollback to previous version
./scripts/update.sh --rollback

# Or restore from backup
./scripts/restore.sh rollback
```

## Pre-Update Checklist

- [ ] Backup all databases
- [ ] Backup configuration files
- [ ] Check disk space (20%+ free)
- [ ] Review release notes
- [ ] Notify team about maintenance window
- [ ] Run health check

## Major Version Notes

- **LibreNMS**: Database migrations run automatically on startup
- **OpenSearch**: Check breaking changes before upgrading major versions
- **Grafana**: Verify plugins and datasources after upgrade

---

*Full reference: [docs/upgrade/](../docs/upgrade/)*
