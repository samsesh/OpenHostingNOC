#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Cleanup Script
# =============================================================================
# Cleans up old data, logs, Docker resources, and temporary files.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_step()  { echo -e "\n${CYAN}════════════════════════════════════════════${NC}"; echo -e "${CYAN}  $1${NC}"; echo -e "${CYAN}════════════════════════════════════════════${NC}"; }

# Load environment
source "${PROJECT_DIR}/.env" 2>/dev/null || true

# Determine cleanup depth
DEEP_CLEAN=false
if [[ "${1:-}" == "--deep" ]]; then
    DEEP_CLEAN=true
    log_warn "Deep cleanup mode enabled. This will remove unused Docker volumes."
fi

log_step "Starting Cleanup"

# ---- Docker Cleanup ----
log_info "Cleaning Docker resources..."

# Remove unused containers
docker container prune -f --filter "until=24h"
log_info "Removed unused containers"

# Remove unused images
docker image prune -f --filter "until=24h"
log_info "Removed unused images"

# Remove unused networks
docker network prune -f --filter "until=24h"
log_info "Removed unused networks"

# Deep: Remove unused volumes
if [[ "$DEEP_CLEAN" == true ]]; then
    log_warn "Removing unused Docker volumes..."
    docker volume prune -f
    log_info "Removed unused volumes"
fi

# Build cache
docker builder prune -f
log_info "Cleaned build cache"

# ---- Log Rotation ----
log_step "Cleaning Log Files"

# Container logs (via docker-compose logging driver)
log_info "Container logs are managed by Docker logging driver (max ${LOG_MAX_SIZE:-10m})"

# Suricata logs
if [[ -d "${PROJECT_DIR}/security/suricata/logs" ]]; then
    find "${PROJECT_DIR}/security/suricata/logs" -name "*.log" -mtime +7 -delete 2>/dev/null || true
    log_info "Cleaned Suricata logs"
fi

# Traefik logs
if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q traefik 2>/dev/null | grep -q .; then
    # Truncate large log files inside container
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T traefik \
        truncate -s 0 /var/log/traefik/access.log /var/log/traefik/traefik.log 2>/dev/null || true
    log_info "Cleaned Traefik logs"
fi

# ---- Old Backups ----
log_step "Cleaning Old Backups"

RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-30}
find "${PROJECT_DIR}/backups" -name "*.tar.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true
log_info "Removed backups older than ${RETENTION_DAYS} days"

# ---- Prometheus Data Retention ----
log_step "Checking Prometheus Data"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q prometheus 2>/dev/null | grep -q .; then
    PROM_SIZE=$(docker run --rm -v opennoc_prometheus_data:/data alpine du -sh /data 2>/dev/null | cut -f1 || echo "unknown")
    log_info "Prometheus data size: ${PROM_SIZE}"
    log_info "Prometheus retention: ${PROMETHEUS_RETENTION_TIME:-90d} / ${PROMETHEUS_RETENTION_SIZE:-200GB}"
fi

# ---- Loki Data Retention ----
log_step "Checking Loki Data"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q loki 2>/dev/null | grep -q .; then
    LOKI_SIZE=$(docker run --rm -v opennoc_loki_data:/data alpine du -sh /data 2>/dev/null | cut -f1 || echo "unknown")
    log_info "Loki data size: ${LOKI_SIZE}"
    log_info "Loki retention: ${LOKI_RETENTION_HOURS:-744}h"
fi

# ---- OpenSearch Data ----
log_step "Checking OpenSearch Data"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q opensearch 2>/dev/null | grep -q .; then
    OS_SIZE=$(docker run --rm -v opennoc_opensearch_data:/data alpine du -sh /data 2>/dev/null | cut -f1 || echo "unknown")
    log_info "OpenSearch data size: ${OS_SIZE}"
fi

# ---- System Cleanup ----
log_step "System Cleanup"

# Clear systemd journal logs (keep only 7 days)
if command -v journalctl &>/dev/null; then
    journalctl --vacuum-time=7d 2>/dev/null || true
    log_info "Cleaned systemd journal (7 days)"
fi

# Clear /tmp
find /tmp -type f -atime +7 -delete 2>/dev/null || true
log_info "Cleaned temporary files"

log_step "Cleanup Complete"
echo ""
echo "Disk usage after cleanup:"
df -h / /var/lib/docker | awk 'NR==1 || NR==2 || NR==3'
