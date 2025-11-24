#!/usr/bin/env bash
# =============================================================================
# lib/bakes.sh - Configuration Presets ("Bakes")
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Bakes are pre-configured profiles that set up bootstrap.conf for common
# use cases. Users can select a bake during first-run setup.
#
# Available Bakes:
#   minimal     - Next.js + TypeScript only (fastest setup)
#   api-only    - Backend API without UI components
#   full-stack  - Complete stack (default, recommended)
#   ai-focused  - AI/LLM heavy, minimal UI
#   enterprise  - Full + testing + quality + monitoring
#
# Exports:
#   bakes_list, bakes_select, bakes_apply, bakes_preview, bakes_save_custom
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_BAKES_LOADED:-}" ]] && return 0
_LIB_BAKES_LOADED=1

# =============================================================================
# BAKE DEFINITIONS
# =============================================================================

# Each bake defines which features/phases to enable
# Format: "FEATURE=value|FEATURE=value|..."

declare -A BAKE_DEFINITIONS=(
    ["minimal"]="STACK_PROFILE=minimal|ENABLE_AUTHJS=false|ENABLE_AI_SDK=false|ENABLE_PG_BOSS=false|ENABLE_SHADCN=false|ENABLE_ZUSTAND=false|ENABLE_PDF_EXPORTS=false|ENABLE_TEST_INFRA=false|ENABLE_CODE_QUALITY=false"

    ["api-only"]="STACK_PROFILE=api-only|ENABLE_AUTHJS=true|ENABLE_AI_SDK=true|ENABLE_PG_BOSS=true|ENABLE_SHADCN=false|ENABLE_ZUSTAND=false|ENABLE_PDF_EXPORTS=false|ENABLE_TEST_INFRA=true|ENABLE_CODE_QUALITY=false"

    ["full-stack"]="STACK_PROFILE=full|ENABLE_AUTHJS=true|ENABLE_AI_SDK=true|ENABLE_PG_BOSS=true|ENABLE_SHADCN=true|ENABLE_ZUSTAND=true|ENABLE_PDF_EXPORTS=false|ENABLE_TEST_INFRA=true|ENABLE_CODE_QUALITY=false"

    ["ai-focused"]="STACK_PROFILE=full|ENABLE_AUTHJS=true|ENABLE_AI_SDK=true|ENABLE_PG_BOSS=true|ENABLE_SHADCN=false|ENABLE_ZUSTAND=true|ENABLE_PDF_EXPORTS=false|ENABLE_TEST_INFRA=false|ENABLE_CODE_QUALITY=false"

    ["enterprise"]="STACK_PROFILE=full|ENABLE_AUTHJS=true|ENABLE_AI_SDK=true|ENABLE_PG_BOSS=true|ENABLE_SHADCN=true|ENABLE_ZUSTAND=true|ENABLE_PDF_EXPORTS=true|ENABLE_TEST_INFRA=true|ENABLE_CODE_QUALITY=true"
)

declare -A BAKE_DESCRIPTIONS=(
    ["minimal"]="Next.js + TypeScript only (fastest setup)"
    ["api-only"]="Backend API without UI components"
    ["full-stack"]="Complete stack (recommended)"
    ["ai-focused"]="AI/LLM heavy, minimal UI"
    ["enterprise"]="Full + testing + quality + monitoring"
)

declare -A BAKE_PHASES=(
    ["minimal"]="0"
    ["api-only"]="0,1,2"
    ["full-stack"]="0,1,2,3,4"
    ["ai-focused"]="0,1,2"
    ["enterprise"]="0,1,2,3,4"
)

# =============================================================================
# BAKE LISTING
# =============================================================================

# List all available bakes with descriptions
# Usage: bakes_list
bakes_list() {
    echo ""
    log_section "Available Configuration Bakes"
    echo ""

    local i=1
    for bake in minimal api-only full-stack ai-focused enterprise; do
        local desc="${BAKE_DESCRIPTIONS[$bake]}"
        local phases="${BAKE_PHASES[$bake]}"
        printf "  %d) %-12s - %s\n" "$i" "$bake" "$desc"
        printf "     %sPhases: %s%s\n" "${LOG_GRAY:-}" "$phases" "${LOG_NC:-}"
        ((i++))
    done
    echo ""
}

# =============================================================================
# BAKE SELECTION
# =============================================================================

# Interactive bake selection
# Usage: bakes_select "/path/to/bootstrap.conf"
bakes_select() {
    local config_file="$1"

    bakes_list

    echo "  0) Back to setup menu"
    echo ""

    local choice
    read -rp "Select bake (1-5): " choice

    local bake_name
    case "$choice" in
        1) bake_name="minimal" ;;
        2) bake_name="api-only" ;;
        3) bake_name="full-stack" ;;
        4) bake_name="ai-focused" ;;
        5) bake_name="enterprise" ;;
        0|"") return 1 ;;  # Go back
        *)
            log_warn "Invalid choice, using full-stack"
            bake_name="full-stack"
            ;;
    esac

    # Show preview
    bakes_preview "$bake_name"

    echo ""
    echo "  [a] Apply this bake"
    echo "  [p] Preview another"
    echo "  [c] Cancel"
    echo ""

    local confirm
    read -rp "Choice [a]: " confirm

    case "${confirm:-a}" in
        a|A)
            bakes_apply "$bake_name" "$config_file"
            return 0
            ;;
        p|P)
            bakes_select "$config_file"
            return $?
            ;;
        *)
            return 1
            ;;
    esac
}

# =============================================================================
# BAKE PREVIEW
# =============================================================================

# Show what a bake will configure
# Usage: bakes_preview "full-stack"
bakes_preview() {
    local bake_name="$1"

    if [[ -z "${BAKE_DEFINITIONS[$bake_name]:-}" ]]; then
        log_error "Unknown bake: $bake_name"
        return 1
    fi

    echo ""
    log_section "Bake: $bake_name"
    echo "${BAKE_DESCRIPTIONS[$bake_name]}"
    echo ""
    echo "Phases: ${BAKE_PHASES[$bake_name]}"
    echo ""
    echo "Features:"

    local settings="${BAKE_DEFINITIONS[$bake_name]}"
    local OLD_IFS="$IFS"
    IFS='|'
    for setting in $settings; do
        local key="${setting%%=*}"
        local value="${setting#*=}"

        # Format nicely
        local display_key="${key#ENABLE_}"
        display_key="${display_key//_/ }"

        if [[ "$value" == "true" ]]; then
            echo "  [x] $display_key"
        else
            echo "  [ ] $display_key"
        fi
    done
    IFS="$OLD_IFS"
}

# =============================================================================
# BAKE APPLICATION
# =============================================================================

# Apply a bake to the config file
# Usage: bakes_apply "full-stack" "/path/to/bootstrap.conf"
bakes_apply() {
    local bake_name="$1"
    local config_file="$2"

    if [[ -z "${BAKE_DEFINITIONS[$bake_name]:-}" ]]; then
        log_error "Unknown bake: $bake_name"
        return 1
    fi

    log_info "Applying bake: $bake_name"

    local settings="${BAKE_DEFINITIONS[$bake_name]}"
    local sed_cmd="sed -i"
    [[ "$(uname)" == "Darwin" ]] && sed_cmd="sed -i ''"

    local OLD_IFS="$IFS"
    IFS='|'
    for setting in $settings; do
        local key="${setting%%=*}"
        local value="${setting#*=}"

        # Update the config file
        $sed_cmd "s/^${key}=.*/${key}=\"${value}\"/" "$config_file"
        log_debug "Set $key=$value"
    done
    IFS="$OLD_IFS"

    log_success "Applied bake: $bake_name"
    return 0
}

# =============================================================================
# CUSTOM BAKES
# =============================================================================

# Save current config as a custom bake
# Usage: bakes_save_custom "my-project" "/path/to/bootstrap.conf"
bakes_save_custom() {
    local bake_name="$1"
    local config_file="$2"

    # Get bakes directory relative to this script
    local bakes_dir
    bakes_dir="$(dirname "${BASH_SOURCE[0]}")/../bakes"

    if [[ ! -d "$bakes_dir" ]]; then
        mkdir -p "$bakes_dir"
    fi

    local custom_file="${bakes_dir}/${bake_name}.conf"

    # Extract feature settings from current config
    local settings=""
    for key in STACK_PROFILE ENABLE_AUTHJS ENABLE_AI_SDK ENABLE_PG_BOSS \
               ENABLE_SHADCN ENABLE_ZUSTAND ENABLE_PDF_EXPORTS \
               ENABLE_TEST_INFRA ENABLE_CODE_QUALITY; do
        local value
        value=$(grep "^${key}=" "$config_file" | cut -d'=' -f2 | tr -d '"')
        if [[ -n "$value" ]]; then
            settings="${settings}${key}=${value}|"
        fi
    done

    # Remove trailing pipe
    settings="${settings%|}"

    # Write to custom bake file
    cat > "$custom_file" << EOF
# Custom Bake: $bake_name
# Generated: $(date '+%Y-%m-%d %H:%M:%S')
BAKE_DEFINITION="$settings"
BAKE_DESCRIPTION="Custom bake saved from project"
EOF

    log_success "Saved custom bake: $custom_file"
    return 0
}

# =============================================================================
# BAKE LOADING FROM FILES
# =============================================================================

# Load custom bakes from bakes/ directory
bakes_load_custom() {
    local bakes_dir
    bakes_dir="$(dirname "${BASH_SOURCE[0]}")/../bakes"

    if [[ ! -d "$bakes_dir" ]]; then
        return 0
    fi

    for bake_file in "$bakes_dir"/*.conf; do
        [[ ! -f "$bake_file" ]] && continue

        local bake_name
        bake_name=$(basename "$bake_file" .conf)

        # Skip if already defined
        [[ -n "${BAKE_DEFINITIONS[$bake_name]:-}" ]] && continue

        # Source the bake file
        local BAKE_DEFINITION=""
        local BAKE_DESCRIPTION=""
        source "$bake_file"

        if [[ -n "$BAKE_DEFINITION" ]]; then
            BAKE_DEFINITIONS["$bake_name"]="$BAKE_DEFINITION"
            BAKE_DESCRIPTIONS["$bake_name"]="${BAKE_DESCRIPTION:-Custom bake}"
            log_debug "Loaded custom bake: $bake_name"
        fi
    done
}

# Load custom bakes on source
bakes_load_custom
