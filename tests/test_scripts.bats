# =============================================================================
# OpenHostingNOC - Script Tests
# =============================================================================
# Tests that shell scripts load without syntax errors and core functions work.
# =============================================================================

setup() {
    PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "all scripts have no syntax errors" {
    for script in "${PROJECT_DIR}"/scripts/*.sh; do
        bash -n "$script" || return 1
    done
    bash -n "${PROJECT_DIR}/security/suricata/install.sh"
}

@test "generate-env.sh --quick generates valid .env" {
    run bash "${PROJECT_DIR}/scripts/generate-env.sh" --quick
    [ -f "${PROJECT_DIR}/.env" ]
    grep -q "DOMAIN=" "${PROJECT_DIR}/.env"
    grep -q "GRAFANA_ADMIN_PASSWORD=admin" "${PROJECT_DIR}/.env"
    rm -f "${PROJECT_DIR}/.env"
}

@test "generate-env.sh detects ip correctly" {
    result=$(bash -c '
        PROJECT_DIR="'"${PROJECT_DIR}"'"
        SCRIPT_DIR="${PROJECT_DIR}/scripts"
        detect_ip() {
            local ip=""
            ip=$(ip route get 1 2>/dev/null | awk "{print \$NF; exit}") || true
            if [[ -z "$ip" ]]; then
                ip=$(hostname -I 2>/dev/null | awk "{print \$1}") || true
            fi
            if [[ -z "$ip" ]]; then
                ip="127.0.0.1"
            fi
            echo "$ip"
        }
        detect_ip
    ')
    [ -n "$result" ]
    [[ "$result" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || \
        [[ "$result" == "127.0.0.1" ]]
}

@test "install.sh has main function" {
    grep -q "^main()" "${PROJECT_DIR}/scripts/install.sh"
    grep -q "main \"\$@\"" "${PROJECT_DIR}/scripts/install.sh"
}

@test "backup.sh has required functions" {
    grep -q "^usage()" "${PROJECT_DIR}/scripts/backup.sh"
    grep -q "RETENTION_DAYS=" "${PROJECT_DIR}/scripts/backup.sh"
}

@test "healthcheck.sh exits cleanly with syntax check" {
    bash -n "${PROJECT_DIR}/scripts/healthcheck.sh"
}

@test "update.sh parses usage correctly" {
    bash -n "${PROJECT_DIR}/scripts/update.sh"
}

@test "cleanup.sh parses arguments correctly" {
    bash -n "${PROJECT_DIR}/scripts/cleanup.sh"
    grep -q "DEEP_CLEAN" "${PROJECT_DIR}/scripts/cleanup.sh"
}

@test "restore.sh validates backup argument" {
    bash -n "${PROJECT_DIR}/scripts/restore.sh"
    grep -q "BACKUP_TIMESTAMP" "${PROJECT_DIR}/scripts/restore.sh"
}

@test "db-optimize.sh has all optimization steps" {
    grep -q "Optimizing MariaDB" "${PROJECT_DIR}/scripts/db-optimize.sh"
    grep -q "Optimizing OpenSearch" "${PROJECT_DIR}/scripts/db-optimize.sh"
    grep -q "Optimizing Prometheus" "${PROJECT_DIR}/scripts/db-optimize.sh"
}

@test "logrotate.sh has rotate function" {
    grep -q "rotate_dir()" "${PROJECT_DIR}/scripts/logrotate.sh"
}

@test "cert-renew.sh checks for traefik" {
    grep -q "traefik" "${PROJECT_DIR}/scripts/cert-renew.sh"
}

@test "all scripts use consistent set flags" {
    for script in "${PROJECT_DIR}"/scripts/*.sh; do
        head -10 "$script" | grep -q "set -euo pipefail" || return 1
    done
}

@test "no script uses tabs for indentation" {
    for script in "${PROJECT_DIR}"/scripts/*.sh; do
        if grep -Pn '^\t' "$script" > /dev/null 2>&1; then
            echo "Tab indentation found in $script"
            return 1
        fi
    done
}
