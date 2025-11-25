#!/usr/bin/env bash
# =============================================================================
# lib/secrets.sh - Helpers for generating and managing app secrets
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SECRETS_LOADED:-}" ]] && return 0
_LIB_SECRETS_LOADED=1

APP_ENV_FILE="${APP_ENV_FILE:-.env}"
APP_ENV_LOCAL_FILE="${APP_ENV_LOCAL_FILE:-.env.local}"

# Resolve the absolute path to the primary app env file
secrets_resolve_env_file() {
    local env_file="${1:-${APP_ENV_FILE:-.env}}"

    if [[ "$env_file" != /* ]]; then
        local base_dir="${PROJECT_ROOT:-$(pwd)}"
        env_file="${base_dir%/}/${env_file}"
    fi

    printf '%s' "$env_file"
}

# Resolve the absolute path to the legacy env.local file
secrets_resolve_legacy_env_file() {
    local legacy_file="${1:-${APP_ENV_LOCAL_FILE:-.env.local}}"

    if [[ "$legacy_file" != /* ]]; then
        local base_dir="${PROJECT_ROOT:-$(pwd)}"
        legacy_file="${base_dir%/}/${legacy_file}"
    fi

    printf '%s' "$legacy_file"
}

# Merge legacy .env.local entries into the primary env file (missing keys only)
secrets_merge_legacy_env() {
    local env_file
    env_file="$(secrets_resolve_env_file "${1:-}")"
    local legacy_file
    legacy_file="$(secrets_resolve_legacy_env_file)"

    [[ ! -f "$legacy_file" ]] && return 0

    touch "$env_file"

    while IFS= read -r line; do
        [[ -z "$line" || "$line" =~ ^# ]] && continue
        [[ "$line" != *"="* ]] && continue

        local key="${line%%=*}"
        [[ -z "$key" ]] && continue

        if grep -q "^${key}=" "$env_file" 2>/dev/null; then
            continue
        fi

        echo "$line" >> "$env_file"
        log_debug "Merged ${key} from ${legacy_file} into ${env_file}"
    done < "$legacy_file"
}

# Generate a random secret (alphanumeric)
generate_secret() {
    local length="${1:-32}"

    if ! command -v openssl >/dev/null 2>&1; then
        log_error "openssl is required to generate secrets"
        return 1
    fi

    openssl rand -base64 $((length * 2)) | tr -dc 'A-Za-z0-9' | head -c "$length"
}

# Ensure a key/value exists in an env file without overwriting
ensure_env_var() {
    local key="$1"
    local value="$2"
    local file
    file="$(secrets_resolve_env_file "${3:-${APP_ENV_FILE}}")"

    touch "$file"

    if grep -q "^${key}=" "$file" 2>/dev/null; then
        return 0
    fi

    echo "${key}=${value}" >> "$file"
    log_debug "Set ${key} in ${file}"
}

# Ensure a random secret is present for the given key
ensure_random_secret() {
    local key="$1"
    local file
    file="$(secrets_resolve_env_file "${2:-${APP_ENV_FILE}}")"
    local length="${3:-32}"

    touch "$file"

    if grep -q "^${key}=" "$file" 2>/dev/null; then
        return 0
    fi

    local value
    value="$(generate_secret "$length")"
    echo "${key}=${value}" >> "$file"
    log_debug "Generated secret ${key} in ${file}"
}

# Get the value for a key from an env file
get_env_value() {
    local key="$1"
    local file
    file="$(secrets_resolve_env_file "${2:-${APP_ENV_FILE}}")"

    [[ -f "$file" ]] || return 1

    local line
    line=$(grep -m1 "^${key}=" "$file" 2>/dev/null || true)
    [[ -z "$line" ]] && return 1

    echo "${line#*=}"
}

# Ensure core app secrets are present and exported for this session
secrets_ensure_core_env() {
    local env_file
    env_file="$(secrets_resolve_env_file)"
    # Merge legacy .env.local without overwriting existing keys
    secrets_merge_legacy_env "$env_file"

    # Non-secret defaults
    ensure_env_var "DB_NAME" "${DB_NAME:-BloomDB}" "$env_file"
    ensure_env_var "DB_USER" "${DB_USER:-bloom}" "$env_file"
    ensure_env_var "DB_HOST" "${DB_HOST:-localhost}" "$env_file"
    ensure_env_var "DB_PORT" "${DB_PORT:-5432}" "$env_file"

    # Secrets
    ensure_random_secret "DB_PASSWORD" "$env_file" 32
    ensure_random_secret "ADMIN_INITIAL_PASSWORD" "$env_file" 12

    # Export current values into the shell for downstream scripts
    for key in DB_NAME DB_USER DB_HOST DB_PORT DB_PASSWORD ADMIN_INITIAL_PASSWORD; do
        local val
        val="$(get_env_value "$key" "$env_file" || true)"
        if [[ -n "$val" ]]; then
            export "${key}=${val}"
        fi
    done

    # Derive DATABASE_URL if missing (do not log secret values)
    if [[ -z "$(get_env_value "DATABASE_URL" "$env_file" || true)" ]]; then
        local db_url="postgresql://${DB_USER:-}:${DB_PASSWORD:-}@${DB_HOST:-localhost}:${DB_PORT:-5432}/${DB_NAME:-}"
        echo "DATABASE_URL=${db_url}" >> "$env_file"
        log_debug "Set DATABASE_URL in ${env_file}"
    fi

    log_info "Admin credentials seeded (user=admin, password var=ADMIN_INITIAL_PASSWORD in ${env_file})"
}
