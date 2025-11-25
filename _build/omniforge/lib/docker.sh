#!/usr/bin/env bash
# =============================================================================
# lib/docker.sh - Docker helper functions for OmniForge
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_DOCKER_LOADED:-}" ]] && return 0
_LIB_DOCKER_LOADED=1

# Resolve the absolute path to the docker-compose file
omni_resolve_compose_file() {
    local compose_file="${DOCKER_COMPOSE_FILE:-docker-compose.yml}"
    if [[ "$compose_file" != /* ]]; then
        local base_dir="${PROJECT_ROOT:-$(pwd)}"
        compose_file="${base_dir%/}/${compose_file}"
    fi

    printf '%s' "$compose_file"
}

# Wrapper around docker compose/docker-compose using the configured compose file
omni_docker_compose() {
    local compose_file
    compose_file="$(omni_resolve_compose_file)"

    if [[ ! -f "$compose_file" ]]; then
        log_error "Docker compose file not found: $compose_file"
        log_error "Generate Docker templates from tech_stack/docker before running Docker commands."
        return 1
    fi

    if command -v docker compose >/dev/null 2>&1; then
        docker compose -f "$compose_file" "$@"
    elif command -v docker-compose >/dev/null 2>&1; then
        docker-compose -f "$compose_file" "$@"
    else
        log_error "Docker Compose not found. Install Docker Compose v2 or docker-compose."
        return 1
    fi
}

# Exec inside the configured app service
omni_docker_exec_app() {
    omni_docker_compose exec "${APP_SERVICE_NAME:-app}" "$@"
}

# Run a one-off command inside the configured app service
omni_docker_run_app() {
    omni_docker_compose run --rm "${APP_SERVICE_NAME:-app}" "$@"
}
