#!/usr/bin/env bash
# =============================================================================
# lib/manifest.sh - OmniForge manifest writer
# =============================================================================

if [[ -n "${_OMNI_MANIFEST_LIB_LOADED:-}" ]]; then
    return 0 2>/dev/null || exit 0
fi
_OMNI_MANIFEST_LIB_LOADED=1

: "${SCRIPTS_DIR:=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Load profile helpers if not already available
if ! declare -f omni_profile_get_field >/dev/null 2>&1; then
    # shellcheck source=/dev/null
    source "${SCRIPTS_DIR}/lib/omni_profiles.sh"
fi

_json_quote() {
    local raw="${1:-}"
    raw="${raw//\\/\\\\}"
    raw="${raw//\"/\\\"}"
    echo "\"${raw}\""
}

_json_array_raw() {
    local items=("$@")
    local out="["
    local first=1
    for item in "${items[@]}"; do
        [[ -z "$item" ]] && continue
        if [[ $first -eq 0 ]]; then
            out+=", "
        fi
        out+="${item}"
        first=0
    done
    out+="]"
    echo "${out}"
}

_bool_from_string() {
    case "${1,,}" in
        1|true|yes|on) echo "true" ;;
        *) echo "false" ;;
    esac
}

_collect_feature_flags_json() {
    local entries=()
    while IFS='=' read -r key val; do
        [[ -z "$key" ]] && continue
        entries+=("{\"key\":$(_json_quote "$key"),\"enabled\":$(_bool_from_string "$val")}")
    done < <(env | LC_ALL=C sort | grep '^ENABLE_' || true)

    _json_array_raw "${entries[@]}"
}

omni_write_manifest() {
    # Skip when not appropriate
    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "[manifest] Skipping manifest write (dry-run)"
        return 0
    fi
    if [[ -n "${SINGLE_PHASE:-}" ]]; then
        log_info "[manifest] Skipping manifest write (single-phase run)"
        return 0
    fi

    local root="${PROJECT_ROOT:-.}"
    if [[ "${root}" == "." ]]; then
        root="$(cd "${SCRIPTS_DIR}/../.." && pwd)"
    fi
    local manifest_path="${root%/}/omni.manifest.json"

    ensure_dir "$(dirname "${manifest_path}")"

    local profile_key="${STACK_PROFILE:-unknown}"
    local profile_name profile_tagline profile_description profile_mode profile_resources profile_dry_default
    profile_name="$(omni_profile_get_field "$profile_key" "name" "$profile_key")"
    profile_tagline="$(omni_profile_get_field "$profile_key" "tagline" "")"
    profile_description="$(omni_profile_get_field "$profile_key" "description" "")"
    profile_mode="$(omni_profile_get_field "$profile_key" "mode" "")"
    if declare -p PROFILE_RESOURCES >/dev/null 2>&1; then
        profile_resources="${PROFILE_RESOURCES[${profile_key}]:-}"
    fi
    if declare -p PROFILE_DRY_RUN >/dev/null 2>&1; then
        profile_dry_default="${PROFILE_DRY_RUN[${profile_key}]:-}"
    fi

    local features_json
    features_json="$(_collect_feature_flags_json)"

    local stack_runtime stack_database stack_auth stack_ai stack_jobs stack_logging stack_ui stack_state stack_exports stack_testing stack_quality
    stack_runtime="Next.js ${NEXT_VERSION:-} · Node ${NODE_VERSION:-} · pnpm ${PNPM_VERSION:-}"
    stack_database=$([[ "${ENABLE_DATABASE:-false}" == "true" ]] && echo "Postgres/Drizzle" || echo "")
    stack_auth=$([[ "${ENABLE_AUTHJS:-false}" == "true" ]] && echo "NextAuth" || echo "")
    stack_ai=$([[ "${ENABLE_AI_SDK:-false}" == "true" ]] && echo "@ai-sdk/react" || echo "")
    stack_jobs=$([[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "pg-boss" || echo "")
    stack_logging="pino"
    stack_ui=$([[ "${ENABLE_SHADCN:-false}" == "true" ]] && echo "App Router + shadcn" || echo "App Router")
    stack_state=$([[ "${ENABLE_ZUSTAND:-false}" == "true" ]] && echo "zustand" || echo "")
    stack_exports=$([[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "pdf · excel · markdown · json" || echo "")
    stack_testing=$([[ "${ENABLE_TEST_INFRA:-false}" == "true" ]] && echo "vitest · playwright" || echo "")
    stack_quality=$([[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "eslint · prettier · husky · lint-staged" || echo "")

    local generated_at
    generated_at="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"

    local deployed_by_json omni_version_json generated_at_json
    deployed_by_json=$(_json_quote "OmniForge")
    omni_version_json=$(_json_quote "${OMNI_VERSION:-}")
    generated_at_json=$(_json_quote "${generated_at}")

    local profile_key_json profile_name_json profile_tagline_json profile_description_json profile_mode_json profile_resources_json
    profile_key_json=$(_json_quote "${profile_key}")
    profile_name_json=$(_json_quote "${profile_name}")
    profile_tagline_json=$(_json_quote "${profile_tagline}")
    profile_description_json=$(_json_quote "${profile_description}")
    profile_mode_json=$(_json_quote "${profile_mode}")
    profile_resources_json=$(_json_quote "${profile_resources:-}")

    local stack_runtime_json stack_database_json stack_auth_json stack_ai_json stack_jobs_json stack_logging_json stack_ui_json stack_state_json stack_exports_json stack_testing_json stack_quality_json
    stack_runtime_json=$(_json_quote "${stack_runtime}")
    stack_database_json=$(_json_quote "${stack_database}")
    stack_auth_json=$(_json_quote "${stack_auth}")
    stack_ai_json=$(_json_quote "${stack_ai}")
    stack_jobs_json=$(_json_quote "${stack_jobs}")
    stack_logging_json=$(_json_quote "${stack_logging}")
    stack_ui_json=$(_json_quote "${stack_ui}")
    stack_state_json=$(_json_quote "${stack_state}")
    stack_exports_json=$(_json_quote "${stack_exports}")
    stack_testing_json=$(_json_quote "${stack_testing}")
    stack_quality_json=$(_json_quote "${stack_quality}")

    local dev_local_url_json dev_container_url_json
    dev_local_url_json=$(_json_quote "${DEV_SERVER_URL:-http://localhost:3000}")
    dev_container_url_json=$(_json_quote "${CONTAINER_URL:-http://<container-ip>:3000}")

    local log_lines_json="[]"
    local log_path_json="\"\""
    if [[ -n "${LOG_FILE:-}" && -f "${LOG_FILE}" ]]; then
        local log_lines=()
        mapfile -t log_lines < <(tail -n 200 "${LOG_FILE}")
        if (( ${#log_lines[@]} > 0 )); then
            local quoted_lines=()
            for line in "${log_lines[@]}"; do
                quoted_lines+=("$(_json_quote "${line}")")
            done
            log_lines_json="$(_json_array_raw "${quoted_lines[@]}")"
        fi
        if [[ "${LOG_FILE}" == ${root%/}/* ]]; then
            log_path_json=$(_json_quote "${LOG_FILE#${root%/}/}")
        else
            log_path_json=$(_json_quote "${LOG_FILE}")
        fi
    fi

    local env_files_quoted=()
    env_files_quoted+=("$(_json_quote ".env")")
    env_files_quoted+=("$(_json_quote ".env.local")")
    local commands_quoted=(
        "$(_json_quote "pnpm dev")"
        "$(_json_quote "pnpm build")"
        "$(_json_quote "pnpm lint")"
        "$(_json_quote "pnpm typecheck")"
        "$(_json_quote "pnpm test")"
        "$(_json_quote "pnpm test:e2e")"
    )
    local endpoints_json
    endpoints_json="$(_json_array_raw \
        "{\"label\":$(_json_quote "Health"),\"path\":$(_json_quote "/api/monitoring/health")}" \
        "{\"label\":$(_json_quote "Metrics"),\"path\":$(_json_quote "/api/monitoring/metrics")}" \
        "{\"label\":$(_json_quote "Chat"),\"path\":$(_json_quote "/chat")}" \
        "{\"label\":$(_json_quote "Auth"),\"path\":$(_json_quote "/signin · /signout")}" \
    )"

    local manifest_tmp=""
    local manifest_dir
    manifest_dir="$(dirname "${manifest_path}")"
    if manifest_tmp="$(mktemp -p "${manifest_dir}" "omni.manifest.json.XXXXXX" 2>/dev/null)"; then
        :
    else
        log_warn "[manifest] mktemp failed in ${manifest_dir}, falling back to /tmp"
        manifest_tmp="$(mktemp -p "/tmp" "omni.manifest.json.XXXXXX")" || {
            log_error "[manifest] Unable to create temporary manifest file"
            return 1
        }
    fi

    cat > "${manifest_tmp}" <<EOF
{
  "deployedBy": ${deployed_by_json},
  "omniVersion": ${omni_version_json},
  "generatedAt": ${generated_at_json},
  "profile": {
    "key": ${profile_key_json},
    "name": ${profile_name_json},
    "tagline": ${profile_tagline_json},
    "description": ${profile_description_json},
    "mode": ${profile_mode_json},
    "dryRunDefault": $(_bool_from_string "${profile_dry_default:-false}"),
    "resources": ${profile_resources_json}
  },
  "features": ${features_json},
  "stack": {
    "runtime": ${stack_runtime_json},
    "database": ${stack_database_json},
    "auth": ${stack_auth_json},
    "ai": ${stack_ai_json},
    "jobs": ${stack_jobs_json},
    "logging": ${stack_logging_json},
    "ui": ${stack_ui_json},
    "state": ${stack_state_json},
    "exports": ${stack_exports_json},
    "testing": ${stack_testing_json},
    "quality": ${stack_quality_json}
  },
  "devQuickStart": {
    "localUrl": ${dev_local_url_json},
    "containerUrl": ${dev_container_url_json},
    "envFiles": $(_json_array_raw "${env_files_quoted[@]}"),
    "commands": $(_json_array_raw "${commands_quoted[@]}"),
    "endpoints": ${endpoints_json},
    "nextStepsUrl": ""
  },
  "logPath": ${log_path_json},
  "logLines": ${log_lines_json},
  "container": {}
}
EOF

    if mv "${manifest_tmp}" "${manifest_path}"; then
        log_info "[manifest] Wrote ${manifest_path}"
    else
        log_error "[manifest] Failed to write ${manifest_path}"
        rm -f "${manifest_tmp}" 2>/dev/null || true
        return 1
    fi
}
