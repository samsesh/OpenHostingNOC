#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Restore Script
# =============================================================================
# Restores the entire platform from a backup archive.
# Usage: ./scripts/restore.sh <backup_timestamp>
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

# Usage
usage() {
    echo "Usage: $0 <backup_timestamp>"
    echo ""
    echo "Arguments:"
    echo "  backup_timestamp  Timestamp of backup to restore (YYYYMMDD_HHMMSS)"
    echo ""
    echo "Examples:"
    echo "  $0 20260101_120000    Restore from specific backup"
    echo "  $0 rollback           Restore from pre-update rollback backup"
    echo ""
    echo "Available backups:"
    ls -1 "${PROJECT_DIR}/backups/"*.tar.gz 2>/dev/null || echo "  No backups found"
    exit 0
}

# Check arguments
if [[ $# -lt 1 ]]; then
    usage
fi

BACKUP_TIMESTAMP="$1"
BACKUP_ARCHIVE="${PROJECT_DIR}/backups/${BACKUP_TIMESTAMP}.tar.gz"
BACKUP_DIR="${PROJECT_DIR}/backups/restore_${BACKUP_TIMESTAMP}"

# Check backup exists
if [[ ! -f "$BACKUP_ARCHIVE" ]]; then
    log_error "Backup not found: ${BACKUP_ARCHIVE}"
    echo ""
    echo "Available backups:"
    ls -1 "${PROJECT_DIR}/backups/"*.tar.gz 2>/dev/null || echo "  No backups found"
    exit 1
fi

log_step "Starting Restore from ${BACKUP_TIMESTAMP}"

# Confirm
read -rp "This will OVERWRITE current data. Continue? [y/N] " confirm
if [[ "$confirm" != "y" ]] && [[ "$confirm" != "Y" ]]; then
    log_info "Restore cancelled."
    exit 0
fi

# Stop the stack
log_info "Stopping the stack..."
docker compose -f "${PROJECT_DIR}/docker-compose.yml" down

# Extract backup
log_info "Extracting backup archive..."
mkdir -p "$BACKUP_DIR"
tar xzf "$BACKUP_ARCHIVE" -C "$BACKUP_DIR"
EXTRACTED_DIR="${BACKUP_DIR}/${BACKUP_TIMESTAMP}"

if [[ ! -d "$EXTRACTED_DIR" ]]; then
    # Try flat extraction
    EXTRACTED_DIR="$BACKUP_DIR"
fi

log_info "Extracted to: $EXTRACTED_DIR"

# ---- 1. Restore configuration ----
log_step "Restoring Configuration"
cp "${EXTRACTED_DIR}/docker-compose.yml" "${PROJECT_DIR}/docker-compose.yml" 2>/dev/null || true
cp "${EXTRACTED_DIR}/.env" "${PROJECT_DIR}/.env" 2>/dev/null || true

# Restore config directories
for dir in traefik prometheus grafana alertmanager loki ntopng opensearch librenms security; do
    if [[ -d "${EXTRACTED_DIR}/${dir}" ]]; then
        rm -rf "${PROJECT_DIR:?}/${dir}"
        cp -r "${EXTRACTED_DIR}/${dir}" "${PROJECT_DIR}/${dir}"
        log_info "Restored ${dir} configuration"
    fi
done

# ---- 2. Restore MariaDB ----
if [[ -f "${EXTRACTED_DIR}/mariadb.sql" ]]; then
    log_step "Restoring MariaDB"
    gunzip -f "${EXTRACTED_DIR}/mariadb.sql.gz" 2>/dev/null || true
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" up -d mariadb
    log_info "Waiting for MariaDB to start..."
    sleep 15
    
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T mariadb \
        mysql -u root -p"${MARIADB_ROOT_PASSWORD}" < "${EXTRACTED_DIR}/mariadb.sql" 2>/dev/null || \
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T mariadb \
        mysql < "${EXTRACTED_DIR}/mariadb.sql" 2>/dev/null || \
    log_warn "MariaDB restore failed. Manual restore may be required."
    log_info "MariaDB restored"
fi

# ---- 3. Restore Grafana ----
if [[ -f "${EXTRACTED_DIR}/grafana_data.tar.gz" ]]; then
    log_step "Restoring Grafana"
    docker volume rm opennoc_grafana_data 2>/dev/null || true
    docker run --rm \
        -v opennoc_grafana_data:/data \
        -v "${EXTRACTED_DIR}:/backup" \
        alpine tar xzf /backup/grafana_data.tar.gz -C /data
    log_info "Grafana data restored"
fi

# ---- 4. Restore Prometheus ----
if [[ -f "${EXTRACTED_DIR}/prometheus_data.tar.gz" ]]; then
    log_step "Restoring Prometheus"
    docker volume rm opennoc_prometheus_data 2>/dev/null || true
    docker run --rm \
        -v opennoc_prometheus_data:/data \
        -v "${EXTRACTED_DIR}:/backup" \
        alpine tar xzf /backup/prometheus_data.tar.gz -C /data
    log_info "Prometheus data restored"
fi

# ---- 5. Restore Loki ----
if [[ -f "${EXTRACTED_DIR}/loki_data.tar.gz" ]]; then
    log_step "Restoring Loki"
    docker volume rm opennoc_loki_data 2>/dev/null || true
    docker run --rm \
        -v opennoc_loki_data:/data \
        -v "${EXTRACTED_DIR}:/backup" \
        alpine tar xzf /backup/loki_data.tar.gz -C /data
    log_info "Loki data restored"
fi

# ---- 6. Restore OpenSearch ----
if [[ -f "${EXTRACTED_DIR}/opensearch_backup.tar.gz" ]]; then
    log_step "Restoring OpenSearch"
    docker volume rm opennoc_opensearch_backup 2>/dev/null || true
    docker run --rm \
        -v opennoc_opensearch_backup:/data \
        -v "${EXTRACTED_DIR}:/backup" \
        alpine tar xzf /backup/opensearch_backup.tar.gz -C /data
    log_info "OpenSearch backup data restored (snapshot restore via API needed after startup)"
fi

# ---- 7. Restore LibreNMS Data ----
if [[ -f "${EXTRACTED_DIR}/librenms_data.tar.gz" ]]; then
    log_step "Restoring LibreNMS Data"
    docker volume rm opennoc_librenms_data 2>/dev/null || true
    docker run --rm \
        -v opennoc_librenms_data:/data \
        -v "${EXTRACTED_DIR}:/backup" \
        alpine tar xzf /backup/librenms_data.tar.gz -C /data
    log_info "LibreNMS data restored"
fi

# ---- 8. Start the stack ----
log_step "Starting Stack"
docker compose -f "${PROJECT_DIR}/docker-compose.yml" up -d

log_step "Restore Complete"
echo "  Backup: ${BACKUP_TIMESTAMP}"
echo "  Stack is starting up. Check status with:"
echo "    docker compose ps"
echo "    ./scripts/healthcheck.sh"

# Cleanup
rm -rf "$BACKUP_DIR"
