#!/usr/bin/env bash
# =============================================================================
# OpenHostingNOC Health Check Script
# =============================================================================
# Comprehensive health check for all services, disk, memory, and connectivity.
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
BOLD='\033[1m'

log_info()  { echo -e "${GREEN}[✓]${NC} $1"; }
log_warn()  { echo -e "${YELLOW}[!]${NC} $1"; }
log_error() { echo -e "${RED}[✗]${NC} $1"; }
log_header() { echo -e "\n${BOLD}${CYAN}══ $1 ══${NC}"; }

EXIT_CODE=0

# ---- Docker Status ----
log_header "Docker Status"

if command -v docker &>/dev/null; then
    log_info "Docker is installed ($(docker --version))"
else
    log_error "Docker is not installed"
    EXIT_CODE=1
fi

# ---- Container Status ----
log_header "Container Status"

if [[ -f "${PROJECT_DIR}/docker-compose.yml" ]]; then
    while IFS= read -r service; do
        container_id=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q "$service" 2>/dev/null || true)
        if [[ -n "$container_id" ]]; then
            status=$(docker inspect --format='{{.State.Status}}' "$container_id" 2>/dev/null || true)
            health=$(docker inspect --format='{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' "$container_id" 2>/dev/null || true)
            
            if [[ "$status" == "running" ]]; then
                if [[ "$health" == "healthy" ]]; then
                    log_info "$service is running and healthy"
                elif [[ "$health" == "none" ]]; then
                    log_info "$service is running (no health check)"
                elif [[ "$health" == "starting" ]]; then
                    log_warn "$service is running but still starting"
                else
                    log_warn "$service is running but health is: $health"
                fi
            else
                log_error "$service is $status"
                EXIT_CODE=1
            fi
        else
            log_error "$service is not running (container not found)"
            EXIT_CODE=1
        fi
    done < <(docker compose -f "${PROJECT_DIR}/docker-compose.yml" config --services 2>/dev/null || echo "")
else
    log_error "docker-compose.yml not found"
    EXIT_CODE=1
fi

# ---- Disk Usage ----
log_header "Disk Usage"

for mount in / /var/lib/docker /prometheus /loki /var/lib/grafana; do
    if [[ -d "$mount" ]]; then
        usage=$(df -h "$mount" | awk 'NR==2 {print $5}' | tr -d '%')
        if [[ "$usage" -gt 90 ]]; then
            log_error "$mount is ${usage}% full"
            EXIT_CODE=1
        elif [[ "$usage" -gt 80 ]]; then
            log_warn "$mount is ${usage}% full"
        else
            log_info "$mount is ${usage}% full"
        fi
    fi
done

# ---- Memory Usage ----
log_header "Memory Usage"

total_mem=$(free -m | awk '/Mem:/ {print $2}')
used_mem=$(free -m | awk '/Mem:/ {print $3}')
mem_pct=$((used_mem * 100 / total_mem))

if [[ "$mem_pct" -gt 90 ]]; then
    log_error "Memory: ${used_mem}MB / ${total_mem}MB (${mem_pct}%)"
    EXIT_CODE=1
elif [[ "$mem_pct" -gt 80 ]]; then
    log_warn "Memory: ${used_mem}MB / ${total_mem}MB (${mem_pct}%)"
else
    log_info "Memory: ${used_mem}MB / ${total_mem}MB (${mem_pct}%)"
fi

# Swap usage
swap_total=$(free -m | awk '/Swap:/ {print $2}')
swap_used=$(free -m | awk '/Swap:/ {print $3}')
if [[ "$swap_total" -gt 0 ]]; then
    swap_pct=$((swap_used * 100 / swap_total))
    if [[ "$swap_pct" -gt 50 ]]; then
        log_warn "Swap: ${swap_used}MB / ${swap_total}MB (${swap_pct}%)"
    else
        log_info "Swap: ${swap_used}MB / ${swap_total}MB (${swap_pct}%)"
    fi
fi

# ---- CPU Load ----
log_header "CPU Load"

load=$(uptime | awk -F'load average:' '{print $2}' | tr -d ',')
cpu_cores=$(nproc 2>/dev/null || grep -c processor /proc/cpuinfo 2>/dev/null || echo 1)
load_15min=$(echo "$load" | awk '{print $3}')
load_pct=$(echo "$load_15min * 100 / $cpu_cores" | bc 2>/dev/null || echo 0)

if [[ "$load_pct" -gt 150 ]]; then
    log_error "Load average: $load (${load_pct}% of $cpu_cores cores)"
    EXIT_CODE=1
elif [[ "$load_pct" -gt 100 ]]; then
    log_warn "Load average: $load (${load_pct}% of $cpu_cores cores)"
else
    log_info "Load average: $load (${load_pct}% of $cpu_cores cores)"
fi

# ---- Network Connectivity ----
log_header "Network Connectivity"

test_endpoints=("8.8.8.8" "1.1.1.1" "9.9.9.9")
for endpoint in "${test_endpoints[@]}"; do
    if ping -c 1 -W 2 "$endpoint" &>/dev/null; then
        log_info "Ping to $endpoint successful"
    else
        log_warn "Ping to $endpoint failed"
    fi
done

# ---- Prometheus Targets ----
log_header "Prometheus Targets"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q prometheus 2>/dev/null | grep -q .; then
    # Check target health via API
    target_count=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T prometheus \
        wget -qO- http://localhost:9090/api/v1/targets 2>/dev/null | \
        python3 -c "import sys,json;d=json.load(sys.stdin);print(len(d['data']['activeTargets']))" 2>/dev/null || echo "0")
    
    unhealthy_count=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T prometheus \
        wget -qO- http://localhost:9090/api/v1/targets 2>/dev/null | \
        python3 -c "import sys,json;d=json.load(sys.stdin);print(len([t for t in d['data']['activeTargets'] if t['health'] != 'up']))" 2>/dev/null || echo "0")
    
    if [[ "$target_count" -gt 0 ]]; then
        if [[ "$unhealthy_count" -gt 0 ]]; then
            log_warn "Prometheus: $target_count targets, $unhealthy_count unhealthy"
        else
            log_info "Prometheus: $target_count targets, all healthy"
        fi
    else
        log_warn "Prometheus: No targets found (may still be starting)"
    fi
fi

# ---- OpenSearch Status ----
log_header "OpenSearch Status"

if docker compose -f "${PROJECT_DIR}/docker-compose.yml" ps -q opensearch 2>/dev/null | grep -q .; then
    os_status=$(docker compose -f "${PROJECT_DIR}/docker-compose.yml" exec -T opensearch \
        curl -sk -u "admin:${OPENSEARCH_INITIAL_ADMIN_PASSWORD:-changeme}" \
        https://localhost:9200/_cluster/health 2>/dev/null | \
        python3 -c "import sys,json;d=json.load(sys.stdin);print(d.get('status','unknown'))" 2>/dev/null || echo "unknown")
    
    case "$os_status" in
        green)  log_info "OpenSearch cluster status: green" ;;
        yellow) log_warn "OpenSearch cluster status: yellow" ;;
        red)    log_error "OpenSearch cluster status: RED"; EXIT_CODE=1 ;;
        *)      log_warn "OpenSearch cluster status: $os_status" ;;
    esac
fi

# ---- Uptime ----
log_header "System Uptime"

uptime_str=$(uptime -p 2>/dev/null || uptime | awk -F'up' '{print $2}' | awk -F',' '{print $1}')
log_info "System uptime: $uptime_str"

# ---- Result ----
log_header "Health Check Result"

if [[ "$EXIT_CODE" -eq 0 ]]; then
    echo -e "${GREEN}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║       ALL CHECKS PASSED - SYSTEM HEALTHY     ║${NC}"
    echo -e "${GREEN}╚═══════════════════════════════════════════════╝${NC}"
else
    echo -e "${RED}╔═══════════════════════════════════════════════╗${NC}"
    echo -e "${RED}║      SOME CHECKS FAILED - REVIEW ABOVE       ║${NC}"
    echo -e "${RED}╚═══════════════════════════════════════════════╝${NC}"
fi

exit "$EXIT_CODE"
