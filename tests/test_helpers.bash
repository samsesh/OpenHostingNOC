# =============================================================================
# OpenHostingNOC - Test Helpers
# =============================================================================

export BATS_LIB_PATH="${BATS_LIB_PATH:+${BATS_LIB_PATH}:}${BATS_TEST_DIRNAME}/.."

# Detect environment
is_ci() {
    [[ -n "${CI:-}" ]]
}

# Skip test if Docker is not available
require_docker() {
    if ! command -v docker &>/dev/null; then
        skip "Docker not available"
    fi
}

# Run a script and check exit code
run_script() {
    local script="$1"
    shift
    bash "$script" "$@" 2>/dev/null
    return $?
}
