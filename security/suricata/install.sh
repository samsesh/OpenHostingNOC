#!/usr/bin/env bash
# =============================================================================
# Suricata Installation Script - OpenHostingNOC
# =============================================================================
# Installs Suricata IDS/IPS natively on the host for packet capture.
# Run as root or with sudo.
# =============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Check root
if [[ $EUID -ne 0 ]]; then
    log_error "This script must be run as root"
    exit 1
fi

# Detect OS
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    OS=$ID
    VERSION=$VERSION_ID
else
    log_error "Cannot detect OS"
    exit 1
fi

log_info "Detected OS: $OS $VERSION"

# Install Suricata
case $OS in
    ubuntu|debian)
        log_info "Adding Suricata repository..."
        apt-get update
        apt-get install -y software-properties-common
        add-apt-repository -y ppa:oisf/suricata-stable
        apt-get update
        log_info "Installing Suricata..."
        apt-get install -y suricata
        ;;
    centos|rhel|rocky|almalinux)
        log_info "Installing Suricata from EPEL..."
        dnf install -y epel-release
        dnf install -y suricata
        ;;
    *)
        log_error "Unsupported OS: $OS"
        log_info "Please install Suricata manually: https://suricata.io/download/"
        exit 1
        ;;
esac

# Create directories
mkdir -p /etc/suricata/rules
mkdir -p /var/log/suricata
mkdir -p /etc/suricata/templates

# Copy configuration templates
log_info "Copying Suricata configuration..."
cp "${SCRIPT_DIR}/templates/suricata.yaml" /etc/suricata/suricata.yaml 2>/dev/null || true

# Get interface
read -rp "Enter monitoring interface [eth0]: " MONITOR_INTERFACE
MONITOR_INTERFACE=${MONITOR_INTERFACE:-eth0}

# Update configuration with interface
sed -i "s/INTERFACE_PLACEHOLDER/$MONITOR_INTERFACE/g" /etc/suricata/suricata.yaml

# Get home network
read -rp "Enter HOME_NET CIDR [10.0.0.0/8,172.16.0.0/12,192.168.0.0/16]: " HOME_NET
HOME_NET=${HOME_NET:-10.0.0.0/8,172.16.0.0/12,192.168.0.0/16}
sed -i "s|HOME_NET_PLACEHOLDER|$HOME_NET|g" /etc/suricata/suricata.yaml

# Update suricata config file
sed -i "s/eth0/$MONITOR_INTERFACE/g" /etc/default/suricata 2>/dev/null || true

# Update rules
log_info "Updating Suricata rules..."
suricata-update || suricata-update enable-source et/open || true
suricata-update || true

# Enable and start service
log_info "Enabling and starting Suricata..."
systemctl enable suricata
systemctl start suricata

# Wait for startup
sleep 3
if systemctl is-active --quiet suricata; then
    log_info "Suricata installed and running successfully!"
    log_info "Monitoring interface: $MONITOR_INTERFACE"
    log_info "Logs: /var/log/suricata/"
    log_info "Eve log: /var/log/suricata/eve.json"
    log_info ""
    log_info "Next steps:"
    log_info "  1. Configure Filebeat/Logstash to ship eve.json to OpenSearch"
    log_info "  2. Run: docker compose -f ${PROJECT_DIR}/docker-compose.yml up -d filebeat"
    log_info "  3. View alerts in OpenSearch Dashboards: https://dashboards.${DOMAIN}"
else
    log_error "Suricata failed to start. Check: journalctl -xeu suricata"
    exit 1
fi
