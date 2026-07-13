#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Log Rotation Script
# =============================================================================
# Manages log rotation for services that don't use Docker's logging driver.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Log directories to manage
LOG_DIRS=(
    "${PROJECT_DIR}/librenms/logs"
    "${PROJECT_DIR}/ntopng/logs"
    "${PROJECT_DIR}/opensearch/logs"
    "${PROJECT_DIR}/traefik/logs"
    "${PROJECT_DIR}/security/suricata/logs"
)

# Retention
RETENTION_DAYS=7
MAX_LOG_SIZE="100M"

log_info() { echo "[INFO] $1"; }

# Rotate logs in a directory
rotate_dir() {
    local dir="$1"

    if [[ ! -d "$dir" ]]; then
        return
    fi

    log_info "Processing: $dir"

    # Gzip files older than 1 day
    find "$dir" -name "*.log" -mtime +1 -not -name "*.gz" -exec gzip {} \; 2>/dev/null || true

    # Delete files older than retention
    find "$dir" -name "*.gz" -mtime +${RETENTION_DAYS} -delete 2>/dev/null || true

    # Truncate large log files (keep last 1000 lines)
    find "$dir" -name "*.log" -size +${MAX_LOG_SIZE} -exec sh -c 'tail -1000 "$1" > "$1.tmp" && mv "$1.tmp" "$1"' _ {} \; 2>/dev/null || true
}

# Main
log_info "Starting log rotation (retention: ${RETENTION_DAYS} days, max size: ${MAX_LOG_SIZE})"

for dir in "${LOG_DIRS[@]}"; do
    rotate_dir "$dir"
done

# Docker container log cleanup
log_info "Cleaning Docker container logs..."
find /var/lib/docker/containers -name "*-json.log" -size +100M -exec truncate -s 0 {} \; 2>/dev/null || true

log_info "Log rotation complete"
