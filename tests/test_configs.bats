# =============================================================================
# OpenHostingNOC - Configuration Tests
# =============================================================================
# Tests that all configuration files are syntactically valid.
# =============================================================================

setup() {
    load 'test_helpers'
    PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "docker-compose.yml is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/docker-compose.yml'))"
}

@test "docker-compose.quickstart.yml is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/docker-compose.quickstart.yml'))"
}

@test "all prometheus configs are valid YAML" {
    for f in "${PROJECT_DIR}"/prometheus/*.yml; do
        python3 -c "import yaml; yaml.safe_load(open('$f'))" || return 1
    done
}

@test "all prometheus alert files are valid YAML" {
    for f in "${PROJECT_DIR}"/prometheus/alerts/*.yml; do
        python3 -c "import yaml; yaml.safe_load(open('$f'))" || return 1
    done
}

@test "all prometheus target files are valid YAML" {
    for f in "${PROJECT_DIR}"/prometheus/targets/**/*.yml; do
        [ -f "$f" ] && python3 -c "import yaml; yaml.safe_load(open('$f'))" || return 1
    done
}

@test "alertmanager config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/alertmanager/alertmanager.yml'))"
}

@test "grafana datasources are valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/grafana/datasources/datasources.yml'))"
}

@test "grafana dashboards provisioning is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/grafana/provisioning/dashboards/dashboards.yml'))"
}

@test "grafana notifiers are valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/grafana/provisioning/notifiers/notifiers.yml'))"
}

@test "loki config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/loki/config/loki.yml'))"
}

@test "promtail config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/loki/config/promtail.yml'))"
}

@test "traefik config is valid YAML" {
    for f in "${PROJECT_DIR}"/traefik/config/*.yml; do
        python3 -c "import yaml; yaml.safe_load(open('$f'))" || return 1
    done
}

@test "opensearch config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/opensearch/config/opensearch.yml'))"
}

@test "opensearch dashboards config is valid YAML" {
    python3 -c "import yaml; yaml.safe_load(open('${PROJECT_DIR}/opensearch/config/dashboards.yml'))"
}

@test "all grafana dashboards JSON are valid" {
    for f in "${PROJECT_DIR}"/grafana/dashboards/json/*.json; do
        python3 -m json.tool "$f" > /dev/null || return 1
    done
}

@test ".env.example has valid key format" {
    errors=0
    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^[[:space:]]*# ]] && continue
        echo "$line" | grep -q '^[A-Z_][A-Z0-9_]*=' || errors=$((errors + 1))
    done < "${PROJECT_DIR}/.env.example"
    [ "$errors" -eq 0 ]
}

@test ".env.example contains required variables" {
    for var in DOMAIN TIMEZONE; do
        grep -q "^${var}=" "${PROJECT_DIR}/.env.example" || return 1
    done
}

@test "librenms config.php has no syntax errors" {
    php -l "${PROJECT_DIR}/librenms/config/librenms.php"
}

@test "auth-service Dockerfile lints clean" {
    docker run --rm -v "${PROJECT_DIR}:/mnt" hadolint/hadolint:v2.12.0 \
        hadolint /mnt/auth/Dockerfile -c /mnt/.hadolint.yaml
}
