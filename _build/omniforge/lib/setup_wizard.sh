#!/usr/bin/env bash
# =============================================================================
# lib/setup_wizard.sh - First-Run Setup Wizard
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Handles first-run configuration with multiple modes:
#   - Editor mode (micro, sublime, vscode, nano)
#   - Interactive mode (guided wizard)
#   - Defaults mode (quick start)
#   - Bakes mode (presets)
#
# Exports:
#   setup_run_first_time, setup_choose_mode, setup_run_interactive,
#   setup_launch_editor, setup_validate_config
#
# Dependencies:
#   lib/logging.sh, lib/utils.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SETUP_WIZARD_LOADED:-}" ]] && return 0
_LIB_SETUP_WIZARD_LOADED=1

# =============================================================================
# PROJECT CONFIGURATION WIZARD (Simplified)
# =============================================================================

# Configure project basics (APP_NAME, APP_DESCRIPTION)
# Shows auto-detected values, prompts for essentials
wizard_configure_project() {
    local config_file="${BOOTSTRAP_CONF}"

    _menu_header
    echo -e "  ${LOG_CYAN}OMNIFORGE SETUP WIZARD${LOG_NC}"
    _menu_line "─" 66
    echo ""
    echo "  Configure your OmniForge project settings."
    echo ""

    # Show auto-detected values (read-only)
    echo -e "  ${LOG_CYAN}Auto-Detected Settings:${LOG_NC}"
    echo "  ─────────────────────────────────────────"
    echo "  Project Name:  ${AUTO_DETECTED_PROJECT_NAME:-$(basename "$(pwd)")}"
    echo "  Project Root:  $(pwd)"
    if [[ -n "${AUTO_DETECTED_GIT_REMOTE}" ]]; then
        echo "  Git Remote:    ${AUTO_DETECTED_GIT_REMOTE}"
    else
        echo "  Git Remote:    (none detected)"
    fi
    echo ""

    # Prompt for essential configuration
    echo -e "  ${LOG_CYAN}Application Settings:${LOG_NC}"
    echo "  ─────────────────────────────────────────"
    echo ""

    local app_name app_description

    # APP_NAME
    local current_app_name="${APP_NAME:-${AUTO_DETECTED_PROJECT_NAME:-bloom2}}"
    read -rp "  Application name [$current_app_name]: " app_name
    app_name="${app_name:-$current_app_name}"

    # APP_DESCRIPTION
    local current_desc="${APP_DESCRIPTION:-Built with OmniForge}"
    read -rp "  Description [$current_desc]: " app_description
    app_description="${app_description:-$current_desc}"

    # Show summary
    echo ""
    echo -e "  ${LOG_CYAN}Configuration Summary:${LOG_NC}"
    echo "  ─────────────────────────────────────────"
    echo "  Name:         $app_name"
    echo "  Description:  $app_description"
    echo ""

    # Confirm
    echo "  [s] Save configuration"
    echo "  [e] Edit omni.config file"
    echo "  [c] Cancel"
    echo ""

    local choice
    read -rp "  Choice [s]: " choice

    case "${choice:-s}" in
        s|S)
            # Write to config file
            local sed_cmd="sed -i"
            [[ "$(uname)" == "Darwin" ]] && sed_cmd="sed -i ''"

            $sed_cmd "s/^APP_NAME=.*/APP_NAME=\"$app_name\"/" "$config_file"
            $sed_cmd "s/^APP_DESCRIPTION=.*/APP_DESCRIPTION=\"$app_description\"/" "$config_file"

            log_success "Configuration saved to $config_file"
            echo ""

            # Offer to edit full file
            read -rp "  Edit full configuration file? [y/N]: " edit_choice
            if [[ "${edit_choice,,}" == "y" ]]; then
                # Auto-detect an available editor for full config
                local available_editors
                available_editors=$(setup_detect_editors)
                local editor="${available_editors%% *}"  # Get first available
                if [[ -z "$editor" ]]; then
                    editor="nano"
                fi
                setup_launch_editor "$editor" "$config_file"
            fi

            return 0
            ;;
        e|E)
            # Auto-detect an available editor for full config
            local available_editors
            available_editors=$(setup_detect_editors)
            local editor="${available_editors%% *}"  # Get first available
            if [[ -z "$editor" ]]; then
                editor="nano"
            fi
            setup_launch_editor "$editor" "$config_file"
            return $?
            ;;
        *)
            log_warn "Configuration cancelled"
            return 1
            ;;
    esac
}

# =============================================================================
# EDITOR DETECTION
# =============================================================================

# Detect available text editors
# Returns space-separated list of available editors
setup_detect_editors() {
    local editors=()

    # Terminal editors (preferred for in-place editing)
    command -v micro &>/dev/null && editors+=("micro")
    command -v nano &>/dev/null && editors+=("nano")
    command -v vim &>/dev/null && editors+=("vim")
    command -v vi &>/dev/null && editors+=("vi")

    # GUI editors
    command -v subl &>/dev/null && editors+=("sublime")
    command -v code &>/dev/null && editors+=("vscode")
    [[ -d "/Applications/Sublime Text.app" ]] && editors+=("sublime")
    [[ -d "/Applications/Visual Studio Code.app" ]] && editors+=("vscode")

    echo "${editors[*]}"
}

# Get the actual command for an editor
_setup_editor_cmd() {
    local editor="$1"
    case "$editor" in
        micro)  echo "micro" ;;
        nano)   echo "nano" ;;
        vim)    echo "vim" ;;
        vi)     echo "vi" ;;
        sublime)
            if command -v subl &>/dev/null; then
                echo "subl -w"
            elif [[ -d "/Applications/Sublime Text.app" ]]; then
                echo "'/Applications/Sublime Text.app/Contents/SharedSupport/bin/subl' -w"
            fi
            ;;
        vscode)
            if command -v code &>/dev/null; then
                echo "code --wait"
            fi
            ;;
    esac
}

# =============================================================================
# MODE SELECTION
# =============================================================================

# Present setup mode choices to user
# Returns: micro, sublime, interactive, defaults, bakes
setup_choose_mode() {
    local config_file="$1"
    local available_editors
    available_editors=$(setup_detect_editors)

    echo ""
    log_section "OMNIFORGE SETUP"
    echo ""
    echo "No configuration found. How would you like to configure OmniForge?"
    echo ""

    # Build menu options based on available editors
    local options=()
    local option_keys=()

    if [[ "$available_editors" == *"micro"* ]]; then
        echo "  [m] Edit in micro (terminal editor)"
        options+=("micro")
        option_keys+=("m")
    fi

    if [[ "$available_editors" == *"sublime"* ]]; then
        echo "  [s] Open in Sublime Text"
        options+=("sublime")
        option_keys+=("s")
    fi

    if [[ "$available_editors" == *"vscode"* ]]; then
        echo "  [v] Open in VS Code"
        options+=("vscode")
        option_keys+=("v")
    fi

    if [[ "$available_editors" == *"nano"* ]]; then
        echo "  [n] Edit in nano (terminal editor)"
        options+=("nano")
        option_keys+=("n")
    fi

    echo "  [i] Interactive wizard (guided step-by-step)"
    echo "  [d] Use defaults (quick start)"
    echo "  [b] Choose a preset 'bake'"
    echo "  [q] Quit"
    echo ""

    local choice
    read -rp "Select option: " choice

    case "${choice,,}" in
        m) [[ "$available_editors" == *"micro"* ]] && echo "micro" || echo "interactive" ;;
        s) [[ "$available_editors" == *"sublime"* ]] && echo "sublime" || echo "interactive" ;;
        v) [[ "$available_editors" == *"vscode"* ]] && echo "vscode" || echo "interactive" ;;
        n) [[ "$available_editors" == *"nano"* ]] && echo "nano" || echo "interactive" ;;
        i) echo "interactive" ;;
        d) echo "defaults" ;;
        b) echo "bakes" ;;
        q) echo "quit" ;;
        *) echo "defaults" ;;
    esac
}

# =============================================================================
# EDITOR MODE
# =============================================================================

# Launch editor for manual config editing
# Usage: setup_launch_editor "sublime" "/path/to/bootstrap.conf"
setup_launch_editor() {
    local editor="$1"
    local config_file="$2"

    local cmd
    cmd=$(_setup_editor_cmd "$editor")

    if [[ -z "$cmd" ]]; then
        log_error "Editor '$editor' not available"
        return 1
    fi

    echo ""
    log_info "Opening $config_file in $editor..."
    log_info "Save and close the editor when done."
    echo ""

    # Store file hash before edit
    local hash_before
    hash_before=$(md5sum "$config_file" 2>/dev/null | cut -d' ' -f1)

    # Launch editor (blocking for terminal editors, -w flag for GUI)
    eval "$cmd \"$config_file\""

    # Check if file was modified
    local hash_after
    hash_after=$(md5sum "$config_file" 2>/dev/null | cut -d' ' -f1)

    if [[ "$hash_before" != "$hash_after" ]]; then
        log_success "Configuration saved"
        return 0
    else
        log_warn "No changes detected"
        return 0
    fi
}

# =============================================================================
# INTERACTIVE WIZARD
# =============================================================================

# Prompt for a single value with validation
# Usage: _wizard_prompt "APP_NAME" "Application name" "bloom2" "required"
_wizard_prompt() {
    local var_name="$1"
    local prompt_text="$2"
    local default_value="$3"
    local validation="${4:-}"

    local value
    read -rp "$prompt_text [$default_value]: " value
    value="${value:-$default_value}"

    # Basic validation
    case "$validation" in
        required)
            if [[ -z "$value" ]]; then
                log_error "Value is required"
                return 1
            fi
            ;;
        alphanumeric)
            if [[ ! "$value" =~ ^[a-zA-Z0-9_-]+$ ]]; then
                log_error "Value must be alphanumeric (letters, numbers, -, _)"
                return 1
            fi
            ;;
        port)
            if [[ ! "$value" =~ ^[0-9]+$ ]] || [[ "$value" -lt 1 ]] || [[ "$value" -gt 65535 ]]; then
                log_error "Value must be a valid port (1-65535)"
                return 1
            fi
            ;;
    esac

    echo "$value"
}

# Multi-select toggle menu for feature flags
# Usage: _wizard_feature_select
_wizard_feature_select() {
    local -n features_ref=$1

    echo ""
    log_section "Feature Selection"
    echo "Toggle features with number, press Enter when done:"
    echo ""

    while true; do
        local i=1
        for key in "${!features_ref[@]}"; do
            local enabled="${features_ref[$key]}"
            local marker="[ ]"
            [[ "$enabled" == "true" ]] && marker="[x]"
            echo "  $i) $marker $key"
            ((i++))
        done
        echo ""
        echo "  0) Done"
        echo ""

        local choice
        read -rp "Toggle (1-$((i-1))) or 0 to continue: " choice

        if [[ "$choice" == "0" ]] || [[ -z "$choice" ]]; then
            break
        fi

        # Convert choice to key and toggle
        local idx=1
        for key in "${!features_ref[@]}"; do
            if [[ "$idx" == "$choice" ]]; then
                if [[ "${features_ref[$key]}" == "true" ]]; then
                    features_ref[$key]="false"
                else
                    features_ref[$key]="true"
                fi
                break
            fi
            ((idx++))
        done

        # Clear and redraw
        echo ""
    done
}

# Run the interactive wizard
# Usage: setup_run_interactive "/path/to/bootstrap.conf"
setup_run_interactive() {
    local config_file="$1"

    echo ""
    log_section "Interactive Configuration Wizard"
    echo ""

    # ─────────────────────────────────────────────────────────────────────────
    # Section 1: Core Identity
    # ─────────────────────────────────────────────────────────────────────────
    echo "Step 1/4: Core Identity"
    echo ""

    local app_name
    app_name=$(_wizard_prompt "APP_NAME" "Application name" "bloom2" "alphanumeric") || return 1

    # Project root is assumed to be current directory
    local project_root="."

    # Stack profile already selected in bootstrap menu Step 1
    local stack_profile="${STACK_PROFILE:-full}"

    # ─────────────────────────────────────────────────────────────────────────
    # Section 2: Feature Flags (inherit from bootstrap menu selections)
    # ─────────────────────────────────────────────────────────────────────────
    declare -A features
    features=(
        ["ENABLE_AUTHJS"]="${ENABLE_AUTHJS:-true}"
        ["ENABLE_AI_SDK"]="${ENABLE_AI_SDK:-true}"
        ["ENABLE_PG_BOSS"]="${ENABLE_PG_BOSS:-true}"
        ["ENABLE_SHADCN"]="${ENABLE_SHADCN:-true}"
        ["ENABLE_ZUSTAND"]="${ENABLE_ZUSTAND:-true}"
        ["ENABLE_PDF_EXPORTS"]="${ENABLE_PDF_EXPORTS:-false}"
        ["ENABLE_TEST_INFRA"]="${ENABLE_TEST_INFRA:-true}"
        ["ENABLE_CODE_QUALITY"]="${ENABLE_CODE_QUALITY:-false}"
    )

    # Feature flags already selected in bootstrap menu Step 2, skip interactive selection

    # ─────────────────────────────────────────────────────────────────────────
    # Section 2: Database Configuration
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo "Step 2/4: PostgreSQL Database Configuration"
    echo ""

    local db_name db_user db_password db_host db_port
    db_name=$(_wizard_prompt "DB_NAME" "Database name" "${app_name}_db" "alphanumeric") || return 1
    db_user=$(_wizard_prompt "DB_USER" "Database user" "$app_name" "alphanumeric") || return 1

    echo -n "Database password [change_me]: "
    read -rs db_password
    echo ""
    db_password="${db_password:-change_me}"

    db_host=$(_wizard_prompt "DB_HOST" "PostgreSQL host" "localhost") || return 1
    db_port=$(_wizard_prompt "DB_PORT" "Database port" "5432" "port") || return 1

    # ─────────────────────────────────────────────────────────────────────────
    # Section 3: Backup Configuration
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    echo "Step 3/4: Backup Configuration"
    echo ""

    local backup_location enable_auto_backup
    backup_location=$(_wizard_prompt "BACKUP_LOCATION" "Backup directory" "./backups") || return 1

    echo "Enable automatic daily backups? [Y/n]: "
    read -r backup_prompt
    enable_auto_backup="true"
    [[ "${backup_prompt,,}" == "n" ]] && enable_auto_backup="false"

    # ─────────────────────────────────────────────────────────────────────────
    # Section 4: Summary & Confirmation
    # ─────────────────────────────────────────────────────────────────────────
    echo ""
    log_section "Configuration Summary"
    echo ""
    echo "  📦 Application"
    echo "      Name:         $app_name"
    echo "      Root:         $project_root"
    echo "      Profile:      $stack_profile"
    echo ""
    echo "  🐘 PostgreSQL Database"
    echo "      Name:         $db_name"
    echo "      User:         $db_user"
    echo "      Host:         $db_host"
    echo "      Port:         $db_port"
    echo "      Connection:   postgresql://$db_user@$db_host:$db_port/$db_name"
    echo ""
    echo "  💾 Backups"
    echo "      Location:     $backup_location"
    echo "      Auto-Backup:  $enable_auto_backup"
    echo ""

    if [[ "$stack_profile" == "full" ]]; then
        echo "  Features enabled:"
        for key in "${!features[@]}"; do
            [[ "${features[$key]}" == "true" ]] && echo "    - $key"
        done
        echo ""
    fi

    echo "  [s] Save and continue"
    echo "  [e] Edit again"
    echo "  [c] Cancel"
    echo ""

    local confirm
    read -rp "Choice [s]: " confirm

    case "${confirm:-s}" in
        s|S)
            # Apply to config file
            _wizard_apply_config "$config_file" \
                "$app_name" "$project_root" "$stack_profile" \
                "$db_name" "$db_user" "$db_password" "$db_host" "$db_port" \
                "$backup_location" "$enable_auto_backup" \
                features
            log_success "Configuration saved to $config_file"
            return 0
            ;;
        e|E)
            setup_run_interactive "$config_file"
            return $?
            ;;
        *)
            log_warn "Setup cancelled"
            return 1
            ;;
    esac
}

# Apply wizard values to config file
_wizard_apply_config() {
    local config_file="$1"
    local app_name="$2"
    local project_root="$3"
    local stack_profile="$4"
    local db_name="$5"
    local db_user="$6"
    local db_password="$7"
    local db_host="$8"
    local db_port="$9"
    local backup_location="${10}"
    local enable_auto_backup="${11}"
    local -n features_map=${12}

    # Use sed to update values in place
    local sed_cmd="sed -i"
    [[ "$(uname)" == "Darwin" ]] && sed_cmd="sed -i ''"

    # Update core values
    $sed_cmd "s/^APP_NAME=.*/APP_NAME=\"$app_name\"/" "$config_file"
    $sed_cmd "s/^PROJECT_ROOT=.*/PROJECT_ROOT=\"$project_root\"/" "$config_file"
    $sed_cmd "s/^STACK_PROFILE=.*/STACK_PROFILE=\"$stack_profile\"/" "$config_file"

    # Update database configuration
    $sed_cmd "s/^DB_NAME=.*/DB_NAME=\"$db_name\"/" "$config_file"
    $sed_cmd "s/^DB_USER=.*/DB_USER=\"$db_user\"/" "$config_file"
    $sed_cmd "s/^DB_PASSWORD=.*/DB_PASSWORD=\"$db_password\"/" "$config_file"
    $sed_cmd "s/^DB_HOST=.*/DB_HOST=\"$db_host\"/" "$config_file"
    $sed_cmd "s/^DB_PORT=.*/DB_PORT=\"$db_port\"/" "$config_file"

    # Update backup configuration
    $sed_cmd "s/^BACKUP_LOCATION=.*/BACKUP_LOCATION=\"$backup_location\"/" "$config_file"
    $sed_cmd "s/^ENABLE_AUTO_BACKUP=.*/ENABLE_AUTO_BACKUP=\"$enable_auto_backup\"/" "$config_file"

    # Update feature flags
    for key in "${!features_map[@]}"; do
        $sed_cmd "s/^${key}=.*/${key}=\"${features_map[$key]}\"/" "$config_file"
    done
}

# =============================================================================
# DEFAULTS MODE
# =============================================================================

# Apply sensible defaults without prompting
setup_apply_defaults() {
    local config_file="$1"

    log_info "Using default configuration..."
    log_info "You can customize later by editing: $config_file"

    # The example file already has good defaults, just copy it
    return 0
}

# =============================================================================
# VALIDATION
# =============================================================================

# Validate config file syntax after editing
setup_validate_config() {
    local config_file="$1"

    log_debug "Validating config syntax: $config_file"

    # Check bash syntax
    if ! bash -n "$config_file" 2>/dev/null; then
        log_error "Config file has syntax errors"
        bash -n "$config_file"  # Show the errors
        return 1
    fi

    # Source and check required variables
    (
        # Subshell to avoid polluting environment
        source "$config_file" 2>/dev/null || exit 1

        # Check required variables exist
        [[ -z "${APP_NAME:-}" ]] && exit 1
        [[ -z "${STACK_PROFILE:-}" ]] && exit 1

        exit 0
    )

    if [[ $? -ne 0 ]]; then
        log_error "Config file missing required variables"
        return 1
    fi

    log_debug "Config syntax valid"
    return 0
}

# =============================================================================
# MAIN ENTRY POINT
# =============================================================================

# Run first-time setup flow
# Usage: setup_run_first_time "/path/to/bootstrap.conf" "/path/to/example"
setup_run_first_time() {
    local config_file="$1"
    local example_file="$2"

    # Copy example to config location
    if [[ -f "$example_file" ]]; then
        cp "$example_file" "$config_file"
        log_debug "Copied example config to $config_file"
    else
        log_error "Example config not found: $example_file"
        return 1
    fi

    # Check for non-interactive mode
    if [[ "${NON_INTERACTIVE:-false}" == "true" ]]; then
        log_info "Non-interactive mode: using defaults"
        setup_apply_defaults "$config_file"
        return 0
    fi

    # Get user's preferred setup mode
    local mode
    mode=$(setup_choose_mode "$config_file")

    case "$mode" in
        micro|nano|vim|vi)
            setup_launch_editor "$mode" "$config_file"
            ;;
        sublime|vscode)
            setup_launch_editor "$mode" "$config_file"
            ;;
        interactive)
            setup_run_interactive "$config_file"
            ;;
        defaults)
            setup_apply_defaults "$config_file"
            ;;
        bakes)
            # Will be implemented in bakes.sh
            if type bakes_select &>/dev/null; then
                bakes_select "$config_file"
            else
                log_warn "Bakes not available, using defaults"
                setup_apply_defaults "$config_file"
            fi
            ;;
        quit)
            log_warn "Setup cancelled"
            rm -f "$config_file"  # Remove partial config
            return 1
            ;;
    esac

    # Validate the result
    if ! setup_validate_config "$config_file"; then
        log_error "Configuration validation failed"
        log_info "Would you like to edit again? [y/N]"
        read -r retry
        if [[ "${retry,,}" == "y" ]]; then
            setup_run_first_time "$config_file" "$example_file"
            return $?
        fi
        return 1
    fi

    return 0
}
