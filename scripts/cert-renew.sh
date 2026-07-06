#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC TLS Certificate Renewal Script
# =============================================================================
# Handles Let's Encrypt certificate renewal via Traefik.
# Typically runs automatically, but this script provides manual control.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log_info()  { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check if Traefik is running
if ! docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q traefik 2>/dev/null | grep -q .; then
    log_error "Traefik is not running. Start the stack first."
    exit 1
fi

# Force renew (Traefik handles auto-renewal by default)
log_info "Triggering certificate renewal check in Traefik..."

# Send SIGHUP to Traefik to reload config
TRAEFIK_CONTAINER=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q traefik)
docker kill -s HUP "$TRAEFIK_CONTAINER" 2>/dev/null || true

# Wait and check
sleep 3

# Check ACME storage
log_info "Checking ACME certificate store..."
docker exec "$TRAEFIK_CONTAINER" ls -la /certs/ 2>/dev/null || true

# Check certificate expiry for our domains
DOMAIN=${DOMAIN:-noc.example.com}
log_info "Checking certificate for *.$DOMAIN..."
echo | openssl s_client -connect "traefik:443" -servername "grafana.$DOMAIN" 2>/dev/null | \
    openssl x509 -noout -dates 2>/dev/null || \
log_warn "Could not check certificate expiry (service may not be exposed)"

log_info "Certificate renewal check complete."
log_info "Traefik handles automatic renewal 30 days before expiry."
