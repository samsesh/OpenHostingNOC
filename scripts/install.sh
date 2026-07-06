#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Installation Script
# =============================================================================
# Initial setup and deployment of the entire NOC platform.
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

# Check prerequisites
check_prereqs() {
    log_step "Checking Prerequisites"
    
    # Check if running as root for Suricata/Fail2Ban
    if [[ $EUID -eq 0 ]]; then
        HAS_ROOT=true
        log_info "Running as root - can install Suricata and Fail2Ban"
    else
        HAS_ROOT=false
        log_warn "Not running as root - Suricata/Fail2Ban installation skipped"
    fi
    
    # Check Docker
    if command -v docker &>/dev/null; then
        DOCKER_VERSION=$(docker --version | cut -d' ' -f3 | tr -d ',')
        log_info "Docker: $DOCKER_VERSION"
    else
        log_error "Docker is not installed. Please install Docker first."
        log_info "  curl -fsSL https://get.docker.com | sh"
        exit 1
    fi
    
    # Check Docker Compose
    if docker compose version &>/dev/null; then
        COMPOSE_VERSION=$(docker compose version | cut -d' ' -f4)
        log_info "Docker Compose: $COMPOSE_VERSION"
    else
        log_error "Docker Compose v2 is not installed."
        log_info "  sudo apt-get install docker-compose-plugin"
        exit 1
    fi
    
    # Check .env file
    if [[ -f "${PROJECT_DIR}/.env" ]]; then
        log_info "Environment file found: .env"
    else
        log_warn "No .env file found. Creating from .env.example..."
        cp "${PROJECT_DIR}/.env.example" "${PROJECT_DIR}/.env"
        log_info "Please edit .env with your configuration before continuing."
        log_info "  nano ${PROJECT_DIR}/.env"
        exit 1
    fi
}

# Create required directories
create_dirs() {
    log_step "Creating Directory Structure"
    
    mkdir -p "${PROJECT_DIR}"/{docs,scripts,backups}
    mkdir -p "${PROJECT_DIR}"/prometheus/{rules,targets/{nodes,snmp,blackbox_icmp,blackbox_http,blackbox_tcp,blackbox_dns},alerts}
    mkdir -p "${PROJECT_DIR}"/grafana/{dashboards/json,datasources,provisioning/{dashboards,datasources,notifiers,alerting},reports}
    mkdir -p "${PROJECT_DIR}"/librenms/{config,data,rrd,logs,oxidized}
    mkdir -p "${PROJECT_DIR}"/ntopng/{data,logs,GeoIP}
    mkdir -p "${PROJECT_DIR}"/opensearch/{data,logs,backup,dashboards}
    mkdir -p "${PROJECT_DIR}"/loki/{data/{chunks,rules,index,cache,wal,compactor},config,backup}
    mkdir -p "${PROJECT_DIR}"/alertmanager/{data,templates}
    mkdir -p "${PROJECT_DIR}"/traefik/{config,dynamic}
    mkdir -p "${PROJECT_DIR}"/security/{suricata/{rules,templates,logs},fail2ban/filter.d,crowdsec}
    mkdir -p "${PROJECT_DIR}"/mariadb/{data,backup,config}
    mkdir -p "${PROJECT_DIR}"/redis/data
    
    log_info "Directories created successfully"
}

# Pull Docker images
pull_images() {
    log_step "Pulling Docker Images"
    
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" pull
    log_info "Images pulled successfully"
}

# Start the stack
start_stack() {
    log_step "Starting OpenHostingNOC Stack"
    
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" up -d
    log_info "Stack started successfully"
}

# Wait for services
wait_for_services() {
    log_step "Waiting for Services to Become Healthy"
    
    local services=(
        "traefik"
        "mariadb"
        "redis"
        "prometheus"
        "grafana"
        "alertmanager"
        "loki"
        "opensearch"
    )
    
    for service in "${services[@]}"; do
        log_info "Waiting for $service..."
        docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T "$service" true 2>/dev/null || \
        docker compose -f "${PROJECT_DIR}/docker-compose.yml" wait "$service" --timeout 120 2>/dev/null || \
        log_warn "$service health check timed out"
    done
    
    log_info "All services started"
}

# Initialize LibreNMS
init_librenms() {
    log_step "Initializing LibreNMS"
    
    log_info "Waiting for LibreNMS to initialize database..."
    sleep 30
    
    # Check if LibreNMS is ready
    docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T librenms \
        php /opt/librenms/init.php 2>/dev/null || true
    
    log_info "LibreNMS initialized. Access at: https://librenms.${DOMAIN}"
}

# Install optional native components
install_suricata() {
    if [[ "$HAS_ROOT" == true ]]; then
        log_step "Installing Suricata (Optional)"
        log_info "Run: sudo bash ${PROJECT_DIR}/security/suricata/install.sh"
    fi
}

install_fail2ban() {
    if [[ "$HAS_ROOT" == true ]]; then
        log_step "Installing Fail2Ban (Optional)"
        if command -v apt-get &>/dev/null; then
            apt-get install -y fail2ban
            cp "${PROJECT_DIR}/security/fail2ban/jail.local" /etc/fail2ban/jail.local
            cp "${PROJECT_DIR}/security/fail2ban/filter.d/traefik-auth.conf" /etc/fail2ban/filter.d/ 2>/dev/null || true
            cp "${PROJECT_DIR}/security/fail2ban/filter.d/librenms-auth.conf" /etc/fail2ban/filter.d/ 2>/dev/null || true
            systemctl enable fail2ban
            systemctl restart fail2ban
            log_info "Fail2Ban installed and configured"
        fi
    fi
}

# Create htpasswd file for Traefik
create_htpasswd() {
    log_step "Creating Traefik Auth Config"
    
    if [[ ! -f "${PROJECT_DIR}/traefik/config/users.htpasswd" ]]; then
        if command -v htpasswd &>/dev/null; then
            htpasswd -c "${PROJECT_DIR}/traefik/config/users.htpasswd" admin
        else
            log_warn "htpasswd not found. Install apache2-utils or httpd-tools."
            log_warn "  sudo apt-get install apache2-utils"
            log_warn "Then run: htpasswd -c traefik/config/users.htpasswd admin"
        fi
    else
        log_info "htpasswd file already exists"
    fi
}

# Post-installation steps
post_install() {
    log_step "Post-Installation"
    
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           OpenHostingNOC Installation Complete                  ║"
    echo "╠══════════════════════════════════════════════════════════════════╣"
    echo "║  Access URLs:                                                   ║"
    echo "║                                                                  ║"
    echo "║  Grafana:       https://grafana.\${DOMAIN}                       ║"
    echo "║  LibreNMS:      https://librenms.\${DOMAIN}                      ║"
    echo "║  ntopng:        https://ntopng.\${DOMAIN}                        ║"
    echo "║  Prometheus:    https://prometheus.\${DOMAIN}                    ║"
    echo "║  Alertmanager:  https://alertmanager.\${DOMAIN}                  ║"
    echo "║  Loki:          https://loki.\${DOMAIN}                          ║"
    echo "║  Dashboards:    https://dashboards.\${DOMAIN}                    ║"
    echo "║  LDAP Admin:    https://ldap.\${DOMAIN}                          ║"
    echo "║                                                                  ║"
    echo "║  Default Credentials:                                            ║"
    echo "║    - Check .env file for all passwords                           ║"
    echo "║    - Grafana: admin / \${GRAFANA_ADMIN_PASSWORD}                 ║"
    echo "║    - LibreNMS: admin / \${LIBRENMS_PASSWORD}                     ║"
    echo "║                                                                  ║"
    echo "║  Next Steps:                                                     ║"
    echo "║    1. Add devices to LibreNMS via SNMP                           ║"
    echo "║    2. Configure NetFlow/sFlow on routers to point to ntopng      ║"
    echo "║    3. Add Node Exporters to prometheus/targets/nodes/            ║"
    echo "║    4. Configure alerts in Alertmanager                           ║"
    echo "║    5. Set up Telegram/Discord bot tokens in .env                 ║"
    echo "║    6. Review and customize dashboards in Grafana                 ║"
    echo "║                                                                  ║"
    echo "║  Management Commands:                                            ║"
    echo "║    ./scripts/update.sh         Update all services               ║"
    echo "║    ./scripts/backup.sh         Backup all data                   ║"
    echo "║    ./scripts/restore.sh        Restore from backup               ║"
    echo "║    ./scripts/healthcheck.sh    Check system health               ║"
    echo "║    docker compose logs -f     View live logs                     ║"
    echo "║    docker compose down        Stop all services                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
}

# =============================================================================
# Main
# =============================================================================
main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              OpenHostingNOC Installation                         ║"
    echo "║           Self-Hosted Network Operations Center                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    
    check_prereqs
    create_dirs
    create_htpasswd
    pull_images
    start_stack
    wait_for_services
    init_librenms
    install_suricata
    install_fail2ban
    post_install
}

main "$@"
