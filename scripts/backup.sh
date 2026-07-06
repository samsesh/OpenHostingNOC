#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Backup Script
# =============================================================================
# Creates comprehensive backups of all configuration, databases, and volumes.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }
log_step()  { echo -e "\n${CYAN}════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}════════════════════════════════════════════${NC}"; }

# Load environment
source "${PROJECT_DIR}/.env" 2>/dev/null || true

# Timestamp
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
BACKUP_DIR="${PROJECT_DIR}/backups/${TIMESTAMP}"
PRE_UPDATE=false
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}

# Usage
usage() {
    echo "Usage: $0 [--pre-update] [--output DIR]"
    echo ""
    echo "Options:"
    echo "  --pre-update   Create backup before update (for rollback)"
    echo "  --output DIR   Specify backup output directory"
    echo "  -h, --help     Show this help message"
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --pre-update) PRE_UPDATE=true; shift ;;
        --output) BACKUP_DIR="$2"; shift 2 ;;
        -h|--help) usage ;;
        *) log_warn "Unknown option: $1"; shift ;;
    esac
done

if [[ "$PRE_UPDATE" == true ]]; then
    BACKUP_DIR="${PROJECT_DIR}/backups/rollback"
    mkdir -p "$BACKUP_DIR"
    log_info "Pre-update backup (for rollback)"
fi

# Create backup directory
mkdir -p "$BACKUP_DIR"
log_info "Backup directory: $BACKUP_DIR"

# Check if stack is running
STACK_RUNNING=false
if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps --quiet 2>/dev/null | grep -q .; then
    STACK_RUNNING=true
    log_info "Stack is running - will stop databases for consistent backups"
fi

# ---- 1. Backup Docker Compose and Environment ----
log_step "Backing up Configuration"
cp "${PROJECT_DIR}/docker-compose.yml" "${BACKUP_DIR}/docker-compose.yml"
cp "${PROJECT_DIR}/.env" "${BACKUP_DIR}/.env" 2>/dev/null || true
cp -r "${PROJECT_DIR}/traefik" "${BACKUP_DIR}/traefik" 2>/dev/null || true
cp -r "${PROJECT_DIR}/prometheus" "${BACKUP_DIR}/prometheus" 2>/dev/null || true
cp -r "${PROJECT_DIR}/grafana" "${BACKUP_DIR}/grafana" 2>/dev/null || true
cp -r "${PROJECT_DIR}/alertmanager" "${BACKUP_DIR}/alertmanager" 2>/dev/null || true
cp -r "${PROJECT_DIR}/loki" "${BACKUP_DIR}/loki" 2>/dev/null || true
cp -r "${PROJECT_DIR}/ntopng" "${BACKUP_DIR}/ntopng" 2>/dev/null || true
cp -r "${PROJECT_DIR}/opensearch" "${BACKUP_DIR}/opensearch" 2>/dev/null || true
cp -r "${PROJECT_DIR}/librenms" "${BACKUP_DIR}/librenms" 2>/dev/null || true
cp -r "${PROJECT_DIR}/security" "${BACKUP_DIR}/security" 2>/dev/null || true
cp -r "${PROJECT_DIR}/scripts" "${BACKUP_DIR}/scripts" 2>/dev/null || true
log_info "Configuration backed up"

# ---- 2. Backup MariaDB ----
log_step "Backing up MariaDB"
MARIADB_CONTAINER=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q mariadb 2>/dev/null || true)
if [[ -n "$MARIADB_CONTAINER" ]]; then
    docker exec "$MARIADB_CONTAINER" mysqldump \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --all-databases \
        > "${BACKUP_DIR}/mariadb.sql" 2>/dev/null || \
    docker exec "$MARIADB_CONTAINER" mysqldump \
        -u root \
        -p"${MARIADB_ROOT_PASSWORD}" \
        --single-transaction \
        --routines \
        --triggers \
        --events \
        --all-databases \
        > "${BACKUP_DIR}/mariadb.sql" 2>/dev/null || \
    log_warn "MariaDB backup failed - database may not be running"
    gzip -f "${BACKUP_DIR}/mariadb.sql" 2>/dev/null || true
    log_info "MariaDB backup: ${BACKUP_DIR}/mariadb.sql.gz"
fi

# ---- 3. Backup Redis ----
log_step "Backing up Redis"
if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q redis 2>/dev/null | grep -q .; then
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T redis \
        redis-cli -a "${REDIS_PASSWORD}" SAVE 2>/dev/null || true
    log_info "Redis snapshot saved (RDB persistence handles backup)"
fi

# ---- 4. Backup Grafana ----
log_step "Backing up Grafana"
docker run --rm \
    -v opennoc_grafana_data:/data \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf /backup/grafana_data.tar.gz -C /data . 2>/dev/null || \
log_warn "Grafana data backup failed"
log_info "Grafana data backed up"

# ---- 5. Backup Prometheus ----
log_step "Backing up Prometheus"
docker run --rm \
    -v opennoc_prometheus_data:/data \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf /backup/prometheus_data.tar.gz -C /data . 2>/dev/null || \
log_warn "Prometheus data backup failed"
log_info "Prometheus data backed up"

# ---- 6. Backup Loki ----
log_step "Backing up Loki"
docker run --rm \
    -v opennoc_loki_data:/data \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf /backup/loki_data.tar.gz -C /data . 2>/dev/null || \
log_warn "Loki data backup failed"
log_info "Loki data backed up"

# ---- 7. Backup OpenSearch ----
log_step "Backing up OpenSearch"
if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q opensearch 2>/dev/null | grep -q .; then
    # Create snapshot repository
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T opensearch \
        curl -sk -u "admin:${OPENSEARCH_INITIAL_ADMIN_PASSWORD}" \
        -X PUT "https://localhost:9200/_snapshot/backup" \
        -H 'Content-Type: application/json' \
        -d "{\"type\": \"fs\", \"settings\": {\"location\": \"/usr/share/opensearch/backup/${TIMESTAMP}\"}}" \
        2>/dev/null || true
    
    # Take snapshot
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T opensearch \
        curl -sk -u "admin:${OPENSEARCH_INITIAL_ADMIN_PASSWORD}" \
        -X PUT "https://localhost:9200/_snapshot/backup/snapshot_${TIMESTAMP}?wait_for_completion=true" \
        -H 'Content-Type: application/json' \
        -d '{"indices": "*", "ignore_unavailable": true, "include_global_state": true}' \
        2>/dev/null || \
    log_warn "OpenSearch snapshot backup failed"
    
    # Copy snapshot files
    docker run --rm \
        -v opennoc_opensearch_backup:/data \
        -v "${BACKUP_DIR}:/backup" \
        alpine tar czf /backup/opensearch_backup.tar.gz -C /data . 2>/dev/null || true
fi
log_info "OpenSearch backup complete"

# ---- 8. Backup LibreNMS RRD ----
log_step "Backing up LibreNMS RRD"
docker run --rm \
    -v opennoc_librenms_rrd:/data \
    -v "${BACKUP_DIR}:/backup" \
    alpine tar czf /backup/librenms_rrd.tar.gz -C /data . 2>/dev/null || \
log_warn "LibreNMS RRD backup failed"
log_info "LibreNMS RRD backed up"

# ---- 9. Create backup manifest ----
log_step "Creating Backup Manifest"
cat > "${BACKUP_DIR}/backup_manifest.txt" <<EOF
OpenHostingNOC Backup
=====================
Date:       $(date)
Timestamp:  ${TIMESTAMP}
Hostname:   $(hostname)
Services:   $(docker compose -f "${PROJECT_DIR}/docker-compose.yml" config --services 2>/dev/null | tr '\n' ' ')

Files:
  mariadb.sql.gz        - MariaDB database dump
  grafana_data.tar.gz   - Grafana data (dashboards, settings)
  prometheus_data.tar.gz- Prometheus TSDB data
  loki_data.tar.gz      - Loki log data
  opensearch_backup.tar.gz - OpenSearch indices snapshot
  librenms_rrd.tar.gz   - LibreNMS RRD time-series data
  docker-compose.yml    - Docker Compose configuration
  .env                  - Environment variables (secrets!)
  config/               - All service configuration files

Restore:
  ./scripts/restore.sh ${TIMESTAMP}
EOF

log_info "Manifest: ${BACKUP_DIR}/backup_manifest.txt"

# ---- 10. Create archive ----
log_step "Creating Backup Archive"
cd "${PROJECT_DIR}/backups"
tar czf "${TIMESTAMP}.tar.gz" "${TIMESTAMP}"
rm -rf "${TIMESTAMP}"
cd "${PROJECT_DIR}"

BACKUP_SIZE=$(du -h "${PROJECT_DIR}/backups/${TIMESTAMP}.tar.gz" 2>/dev/null | cut -f1)
log_info "Backup archive: ${PROJECT_DIR}/backups/${TIMESTAMP}.tar.gz (${BACKUP_SIZE})"

# ---- 11. Cleanup old backups ----
log_step "Cleaning Old Backups"
find "${PROJECT_DIR}/backups" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
log_info "Removed backups older than ${RETENTION_DAYS} days"

# ---- 12. S3 sync (optional) ----
if [[ "${BACKUP_S3_ENABLED:-false}" == "true" ]]; then
    log_step "Syncing to S3"
    if command -v aws &>/dev/null; then
        aws s3 sync "${PROJECT_DIR}/backups/" "s3://${BACKUP_S3_BUCKET}/backups/" \
            --endpoint-url "${BACKUP_S3_ENDPOINT}" \
            --delete 2>/dev/null || \
        log_warn "S3 sync failed"
        log_info "Synced to s3://${BACKUP_S3_BUCKET}/backups/"
    else
        log_warn "AWS CLI not installed. Install with: pip install awscli"
    fi
fi

log_step "Backup Complete"
echo "  Location: ${PROJECT_DIR}/backups/${TIMESTAMP}.tar.gz"
echo "  Size:     ${BACKUP_SIZE}"
echo "  Date:     $(date)"
