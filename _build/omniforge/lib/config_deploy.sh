#!/usr/bin/env bash
# =============================================================================
# lib/config_deploy.sh - Configuration Deployment & Template Management
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Handles the copying of .example templates to live configuration files,
# performing variable substitution, and updating .gitignore.
#
# Exports:
#   configure_file_from_template
#
# Dependencies:
#   lib/logging.sh, lib/utils.sh, lib/config_bootstrap.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_CONFIG_DEPLOY_LOADED:-}" ]] && return 0
_LIB_CONFIG_DEPLOY_LOADED=1

# =============================================================================
# CONSTANTS & PATHS
# =============================================================================

# Directory containing the source .example files
# Assumes structure: _build/omniforge/example-files/ and _build/omniforge/settings-files/
CONFIG_TEMPLATES_DIR="${PROJECT_ROOT}/_build/omniforge/example-files"
CONFIG_SETTINGS_DIR="${PROJECT_ROOT}/_build/omniforge/settings-files"

# Detect OS for sed compatibility (macOS requires empty string arg for -i)
if [[ "$(uname)" == "Darwin" ]]; then
    SED_INPLACE="sed -i ''"
else
    SED_INPLACE="sed -i"
fi

# =============================================================================
# CORE FUNCTIONS
# =============================================================================

# -----------------------------------------------------------------------------
# Function: configure_file_from_template
# -----------------------------------------------------------------------------
# Copies a template, replaces placeholders, and updates .gitignore.
#
# Usage:
#   configure_file_from_template "folder/file.example" "dest/file.ts" "MODULE_NAME"
#
# Arguments:
#   $1: Source path relative to config_examples/ (e.g., "drizzle/drizzle.config.ts.example")
#   $2: Destination path relative to PROJECT_ROOT (e.g., "drizzle.config.ts")
#   $3: Module ID for .gitignore comments (e.g., "DB_DRIZZLE")
# -----------------------------------------------------------------------------
configure_file_from_template() {
    local rel_source="$1"
    local rel_dest="$2"
    local module_id="$3"

    local source_path="${CONFIG_TEMPLATES_DIR}/${rel_source}"
    local dest_path="${PROJECT_ROOT}/${rel_dest}"

    # Define the path for the gitignore append file based on the source name
    # e.g., drizzle.config.ts.example -> drizzle.config.ts.gitignore.append.example
    # OR simply define it as a sibling file in the source directory if strict naming is used.
    # Strategy: Look for the specific append file or a generic one in that folder.
    local ignore_append_specific="${source_path%.example}.gitignore.append.example"
    local ignore_append_generic="$(dirname "${source_path}")/.gitignore.append.example"
    local ignore_file=""

    # 1. Validation
    if [[ ! -f "$source_path" ]]; then
        log_error "Template not found: ${rel_source}"
        log_debug "Searched at: ${source_path}"
        return 1
    fi

    log_step "Deploying configuration: ${rel_dest}"

    # 2. Ensure destination directory exists
    ensure_dir "$(dirname "${dest_path}")"

    # 3. Copy file
    if cp "$source_path" "$dest_path"; then
        log_detail "Copied template to destination."
    else
        log_error "Failed to copy template to ${dest_path}"
        return 1
    fi

    # 4. Variable Substitution
    # Replaces __PLACEHOLDERS__ with values loaded from bootstrap.conf
    # We use eval to execute the specific sed command string determined by OS
    log_debug "Performing variable substitution..."

    eval "$SED_INPLACE" \
        -e "s|__APP_NAME__|${APP_NAME}|g" \
        -e "s|__PROJECT_ROOT__|${PROJECT_ROOT}|g" \
        -e "s|__DB_NAME__|${DB_NAME}|g" \
        -e "s|__DB_USER__|${DB_USER}|g" \
        -e "s|__DB_PASSWORD__|${DB_PASSWORD}|g" \
        -e "s|__DB_PORT__|${DB_PORT}|g" \
        -e "s|__POSTGRES_VERSION__|${POSTGRES_VERSION}|g" \
        -e "s|__NODE_VERSION__|${NODE_VERSION}|g" \
        -e "s|__NEXT_VERSION__|${NEXT_VERSION}|g" \
        "$dest_path"

    # 5. Gitignore Updates
    # Determine which ignore file to use (Specific takes precedence over Generic)
    if [[ -f "$ignore_append_specific" ]]; then
        ignore_file="$ignore_append_specific"
    elif [[ -f "$ignore_append_generic" ]]; then
        ignore_file="$ignore_append_generic"
    fi

    local root_gitignore="${PROJECT_ROOT}/.gitignore"

    if [[ -n "$ignore_file" ]]; then
        # Check if we've already added this module to avoid duplicates
        if grep -q "BOOTSTRAP MODULE: ${module_id}" "$root_gitignore" 2>/dev/null; then
            log_debug "Ignore rules for ${module_id} already exist. Skipping."
        else
            log_detail "Appending ignore rules for ${module_id}..."

            # Ensure .gitignore exists
            if [[ ! -f "$root_gitignore" ]]; then
                touch "$root_gitignore"
            fi

            # Append with safety spacing
            echo -e "\n\n# --- BEGIN BOOTSTRAP MODULE: ${module_id} ---" >> "$root_gitignore"
            cat "$ignore_file" >> "$root_gitignore"
            echo -e "# --- END BOOTSTRAP MODULE: ${module_id} ---" >> "$root_gitignore"

            log_success "Updated .gitignore."
        fi
    else
        log_debug "No .gitignore.append.example found for this template."
    fi

    log_success "Configured ${rel_dest}"
    return 0
}
