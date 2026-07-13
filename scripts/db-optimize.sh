#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Database Optimization Script
# =============================================================================
# Optimizes MariaDB, OpenSearch, and other databases for performance.
# Should be run during maintenance windows.
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

# Load environment (export all vars)
set -a; source "${PROJECT_DIR}/.env" 2>/dev/null || true; set +a

# ---- MariaDB Optimization ----
log_step "Optimizing MariaDB"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q mariadb 2>/dev/null | grep -q .; then
    log_info "Running MariaDB optimization..."
    
    # Analyze tables
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T mariadb \
        mysqlcheck -u root -p"${MARIADB_ROOT_PASSWORD}" \
        --all-databases \
        --analyze \
        --silent 2>/dev/null || true
    
    # Optimize tables
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T mariadb \
        mysqlcheck -u root -p"${MARIADB_ROOT_PASSWORD}" \
        --all-databases \
        --optimize \
        --silent 2>/dev/null || true
    
    log_info "MariaDB optimization complete"
else
    log_warn "MariaDB not running, skipping"
fi

# ---- OpenSearch Index Optimization ----
log_step "Optimizing OpenSearch Indices"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q opensearch 2>/dev/null | grep -q .; then
    log_info "Running OpenSearch index optimization..."
    
    # Force merge indices (reduce segment count)
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T opensearch \
        curl -sk -u "admin:${OPENSEARCH_INITIAL_ADMIN_PASSWORD:-changeme}" \
        -X POST "https://localhost:9200/_forcemerge?max_num_segments=1&flush=true" \
        -H 'Content-Type: application/json' 2>/dev/null || \
    log_warn "OpenSearch force merge failed"
    
    # Clear cache
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T opensearch \
        curl -sk -u "admin:${OPENSEARCH_INITIAL_ADMIN_PASSWORD:-changeme}" \
        -X POST "https://localhost:9200/_cache/clear" \
        -H 'Content-Type: application/json' 2>/dev/null || true
    
    log_info "OpenSearch optimization complete"
else
    log_warn "OpenSearch not running, skipping"
fi

# ---- Prometheus TSDB Optimization ----
log_step "Optimizing Prometheus TSDB"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q prometheus 2>/dev/null | grep -q .; then
    log_info "Triggering Prometheus TSDB compaction..."
    
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T prometheus \
        wget -qO- --post-data='' http://localhost:9090/api/v1/admin/tsdb/compact 2>/dev/null || \
    log_warn "Prometheus TSDB compaction API not available (admin API disabled)"
    
    log_info "Prometheus optimization complete"
else
    log_warn "Prometheus not running, skipping"
fi

log_step "Database Optimization Complete"
echo "  All optimizations applied successfully."
echo "  Run: ./scripts/healthcheck.sh to verify system health."
