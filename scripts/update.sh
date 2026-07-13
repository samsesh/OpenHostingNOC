#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Update Script
# =============================================================================
# Updates all Docker images and services to latest versions.
# Includes backup before update and rollback capability.
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

# Load environment (export all vars)
set -a; source "${PROJECT_DIR}/.env" 2>/dev/null || true; set +a

# Usage
usage() {
    echo "Usage: $0 [--no-backup] [service1 service2 ...]"
    echo ""
    echo "Options:"
    echo "  --no-backup    Skip backup before update"
    echo "  --rollback     Rollback to previous version (uses backup volumes)"
    echo "  -h, --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                          Update all services"
    echo "  $0 prometheus grafana       Update specific services"
    echo "  $0 --no-backup              Update without backup"
    echo "  $0 --rollback               Rollback to previous version"
    exit 0
}

# Parse arguments
NO_BACKUP=false
ROLLBACK=false
SERVICES=()

while [[ $# -gt 0 ]]; do
    case $1 in
        --no-backup) NO_BACKUP=true; shift ;;
        --rollback) ROLLBACK=true; shift ;;
        -h|--help) usage ;;
        *) SERVICES+=("$1"); shift ;;
    esac
done

# Rollback mode
if [[ "$ROLLBACK" == true ]]; then
    log_step "Rollback Mode"
    log_info "Restoring from previous backup..."
    
    # Check for rollback backup
    ROLLBACK_DIR="${PROJECT_DIR}/backups/rollback"
    if [[ -f "${ROLLBACK_DIR}/docker-compose.yml" ]]; then
        docker compose -f "${ROLLBACK_DIR}/docker-compose.yml" up -d
        log_info "Rollback complete. Previous configuration restored."
    else
        log_error "No rollback backup found at ${ROLLBACK_DIR}"
        exit 1
    fi
    exit 0
fi

# Main update
log_step "Starting Update"

# Backup current state
if [[ "$NO_BACKUP" == false ]]; then
    log_info "Creating backup before update..."
    "${SCRIPT_DIR}/backup.sh" --pre-update
fi

# Pull latest images
log_info "Pulling latest images..."
if [[ ${#SERVICES[@]} -gt 0 ]]; then
    # Update specific services
    for service in "${SERVICES[@]}"; do
        log_info "Updating $service..."
        if [ "$service" = "auth-service" ]; then
            docker compose -f "${PROJECT_DIR}/docker-compose.yml" build auth-service
        else
            docker compose -f "${PROJECT_DIR}/docker-compose.yml" pull "$service"
        fi
        docker compose -f "${PROJECT_DIR}/docker-compose.yml" up -d --no-deps "$service"
    done
else
    # Update all services
    CURRENT_HASH=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" images -q | md5sum 2>/dev/null || true)
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" pull
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" build auth-service
    NEW_HASH=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" images -q | md5sum 2>/dev/null || true)
    
    if [[ "$CURRENT_HASH" != "$NEW_HASH" ]]; then
        log_info "Changes detected, recreating containers..."
        docker compose -f "${PROJECT_DIR}/docker-compose.yml" up -d --remove-orphans
    else
        log_info "No changes detected, all images are current."
    fi
fi

# Clean up old images
log_info "Cleaning up old images..."
docker image prune -f --filter "until=24h"

log_info "Update complete!"

# Show status
echo ""
docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps
