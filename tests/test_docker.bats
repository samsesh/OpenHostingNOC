# =============================================================================
# OpenHostingNOC - Docker Tests
# =============================================================================
# Tests Dockerfile and Docker Compose configuration.
# =============================================================================

setup() {
    load 'test_helpers'
    PROJECT_DIR="$(cd "$(dirname "$BATS_TEST_FILENAME")/.." && pwd)"
}

@test "Dockerfile compiles without errors" {
    require_docker
    docker build -t opennoc-test -f "${PROJECT_DIR}/Dockerfile" "${PROJECT_DIR}" > /dev/null 2>&1
    docker image rm opennoc-test > /dev/null 2>&1
}

@test "Dockerfile has required labels" {
    grep -q "org.opencontainers.image.title" "${PROJECT_DIR}/Dockerfile"
    grep -q "org.opencontainers.image.source" "${PROJECT_DIR}/Dockerfile"
    grep -q "org.opencontainers.image.licenses" "${PROJECT_DIR}/Dockerfile"
}

@test "docker-compose.yml has required services" {
    for svc in traefik mariadb redis librenms prometheus grafana; do
        grep -q "  ${svc}:" "${PROJECT_DIR}/docker-compose.yml" || return 1
    done
}

@test "docker-compose.yml has healthchecks on critical services" {
    for svc in traefik mariadb redis prometheus grafana opensearch; do
        grep -q "healthcheck:" "${PROJECT_DIR}/docker-compose.yml" || return 1
    done
}

@test "docker-compose.yml uses named volumes" {
    grep -q "volumes:" "${PROJECT_DIR}/docker-compose.yml"
    for vol in grafana_data prometheus_data mariadb_data redis_data; do
        grep -q "  ${vol}:" "${PROJECT_DIR}/docker-compose.yml" || return 1
    done
}

@test "no service uses latest tag without pin" {
    local latest_tags
    latest_tags=$(grep -E 'image:.*:latest' "${PROJECT_DIR}/docker-compose.yml" | \
        grep -v 'librenms/librenms' | \
        grep -v 'ntop/ntopng' | \
        grep -v 'grafana/grafana' | \
        grep -v 'osixia/openldap' | \
        grep -v 'osixia/phpldapadmin' | \
        grep -v 'oxidized/oxidized' || true)
    [ -z "$latest_tags" ]
}

@test "Dockerfile lints with hadolint" {
    require_docker
    docker run --rm -v "${PROJECT_DIR}:/mnt" \
        hadolint/hadolint:v2.12.0 \
        hadolint /mnt/Dockerfile /mnt/auth/Dockerfile \
        -c /mnt/.hadolint.yaml
}
