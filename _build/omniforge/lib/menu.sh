#!/usr/bin/env bash
# =============================================================================
# lib/menu.sh - Interactive Menu Framework
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Provides the interactive menu system for OmniForge.
# Main menu with submenus for Bootstrap, Settings, Options, etc.
#
# Exports:
#   menu_main, menu_bootstrap, menu_settings, menu_options, menu_help
#
# Dependencies:
#   lib/logging.sh, lib/ascii.sh, lib/downloads.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_MENU_LOADED:-}" ]] && return 0
_LIB_MENU_LOADED=1

# =============================================================================
# MENU CONFIGURATION
# =============================================================================

# Menu state
declare -g _MENU_SELECTION=""
declare -g _MENU_RUNNING=true

# =============================================================================
# MENU DISPLAY HELPERS
# =============================================================================

# Clear screen and show header
_menu_header() {
    clear
    ascii_show_logo
    ascii_show_tagline
}

# Draw a horizontal line
_menu_line() {
    local char="${1:-─}"
    local width="${2:-66}"
    printf '%*s\n' "$width" '' | tr ' ' "$char"
}

# Show menu title
_menu_title() {
    local title="$1"
    echo -e "  ${LOG_CYAN}${title}${LOG_NC}"
    _menu_line "─" 66
}

# Show a menu item with label and optional description on same line
_menu_item() {
    local num="$1"
    local label="$2"
    local desc="${3:-}"
    local extra="${4:-}"

    # Calculate spacing: label width is ~30 chars, then one tab to description
    if [[ -n "$desc" ]]; then
        printf "  %s. %-30s %s" "$num" "$label" "${LOG_GRAY:-}$desc"
        if [[ -n "$extra" ]]; then
            # Color all bracket values [*] in yellow
            extra="${extra//\[/${LOG_YELLOW}[}"
            extra="${extra//\]/${LOG_NC}]}"
            printf " %s" "$extra"
        fi
        printf "%s\n" "${LOG_NC:-}"
    else
        printf "  %s. %s\n" "$num" "$label"
    fi
}

# Read a single key, detecting escape sequences
_read_key() {
    local key
    IFS= read -rsn1 key 2>/dev/null || return

    # Check for escape sequence
    if [[ "$key" == $'\x1b' ]]; then
        # Read additional characters for escape sequences
        read -rsn2 -t 0.1 key2 2>/dev/null || true
        if [[ -z "$key2" ]]; then
            # Just escape key pressed
            echo "ESC"
        else
            # Arrow keys etc - treat as back
            echo "ESC"
        fi
    else
        echo "$key"
    fi
}

# Show prompt and get input (supports ESC to go back)
_menu_prompt() {
    local prompt="${1:-Select}"
    local default="${2:-}"

    echo ""
    _menu_line "─" 66
    printf "  %s: " "$prompt"

    # Read input character by character to detect ESC
    _MENU_SELECTION=""
    while true; do
        local key
        key=$(_read_key)

        if [[ "$key" == "ESC" ]]; then
            _MENU_SELECTION="ESC"
            echo ""
            return
        elif [[ "$key" == "" || "$key" == $'\n' ]]; then
            # Enter pressed
            echo ""
            if [[ -z "$_MENU_SELECTION" && -n "$default" ]]; then
                _MENU_SELECTION="$default"
            fi
            return
        elif [[ "$key" == $'\x7f' || "$key" == $'\b' ]]; then
            # Backspace
            if [[ -n "$_MENU_SELECTION" ]]; then
                _MENU_SELECTION="${_MENU_SELECTION%?}"
                printf "\b \b"
            fi
        else
            _MENU_SELECTION+="$key"
            printf "%s" "$key"
        fi
    done
}

# =============================================================================
# PHASE & PACKAGE DISPLAY HELPERS
# =============================================================================

# Display a phase with its scripts
_display_phase() {
    local phase_num="$1"
    local phase_name="$2"
    local phase_desc="$3"

    echo ""
    echo "  ${LOG_CYAN}Phase $phase_num: $phase_name${LOG_NC}"
    echo "  $phase_desc"
    echo ""
}

# Display enabled features for current profile
_display_features() {
    echo "  ${LOG_CYAN}Features Enabled:${LOG_NC}"
    echo ""

    local features=(
        "ENABLE_NEXTJS:Next.js + TypeScript"
        "ENABLE_DATABASE:PostgreSQL + Drizzle ORM"
        "ENABLE_AUTHJS:Authentication (Auth.js)"
        "ENABLE_AI_SDK:AI Integration (Vercel AI SDK)"
        "ENABLE_PG_BOSS:Background Jobs (pg-boss)"
        "ENABLE_SHADCN:UI Components (shadcn/ui)"
        "ENABLE_PDF_EXPORTS:PDF/Excel Exports"
        "ENABLE_TEST_INFRA:Testing (Vitest + Playwright)"
        "ENABLE_CODE_QUALITY:Code Quality (ESLint + Prettier)"
    )

    for feature in "${features[@]}"; do
        local var="${feature%%:*}"
        local desc="${feature#*:}"
        local val="${!var:-false}"

        if [[ "$val" == "true" ]]; then
            echo "    ✓ $desc"
        fi
    done
    echo ""
}

# Build a short feature summary for a profile using its metadata flags
_profile_feature_summary() {
    local profile="$1"
    local flags=(
        "ENABLE_NEXTJS:Next.js+TypeScript"
        "ENABLE_DATABASE:PostgreSQL+Drizzle"
        "ENABLE_AUTHJS:Auth.js"
        "ENABLE_AI_SDK:AI SDK"
        "ENABLE_PG_BOSS:pg-boss"
        "ENABLE_SHADCN:shadcn/ui"
        "ENABLE_ZUSTAND:Zustand"
        "ENABLE_PDF_EXPORTS:Exports"
        "ENABLE_TEST_INFRA:Testing"
        "ENABLE_CODE_QUALITY:Code Quality"
    )
    local enabled=()
    for entry in "${flags[@]}"; do
        local key="${entry%%:*}"
        local label="${entry#*:}"
        local val
        val=$(get_profile_metadata "$profile" "$key")
        if [[ "$val" == "true" ]]; then
            enabled+=("$label")
        fi
    done
    local IFS=", "
    echo "${enabled[*]}"
}

# Display installation phases overview
_display_installation_plan() {
    echo ""
    echo "  ${LOG_CYAN}Installation Plan${LOG_NC}"
    _menu_line "─" 66
    echo ""

    echo "  Phase 0: Project Foundation (5m)"
    echo "    • Initialize Next.js & TypeScript"
    echo "    • Setup project structure"
    echo ""

    echo "  Phase 1: Infrastructure & Database (20m)"
    echo "    • Docker configuration"
    echo "    • PostgreSQL & Drizzle ORM"
    echo "    • Environment variables"
    echo ""

    echo "  Phase 2: Core Features (15m)"
    echo "    • Authentication (Auth.js)"
    echo "    • AI/LLM Integration"
    echo "    • State Management (Zustand)"
    echo "    • Background Jobs (pg-boss)"
    echo "    • Logging (Pino)"
    echo ""

    echo "  Phase 3: User Interface (10m)"
    echo "    • shadcn/ui Components"
    echo "    • Tailwind CSS"
    echo "    • Component Organization"
    echo ""

    echo "  Phase 4: Extensions & Quality (30m optional)"
    echo "    • Export System (PDF/Excel/Markdown)"
    echo "    • Testing (Vitest + Playwright)"
    echo "    • Code Quality (ESLint + Prettier)"
    echo ""

    echo "  ${LOG_GREEN}Total Estimated Time: ~80 minutes${LOG_NC}"
    echo ""
}

# Append deployment notes as we collect them
_write_deployment_notes() {
    local notes_file="${PROJECT_ROOT:-.}/README-AppDeployment.md"
    local ts
    ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
    if [[ ! -f "$notes_file" ]]; then
        cat > "$notes_file" <<'EOF'
# App Deployment Notes

EOF
    fi

    local features=()
    [[ "${ENABLE_NEXTJS:-true}" == "true" ]] && features+=("Next.js + TypeScript")
    [[ "${ENABLE_DATABASE:-true}" == "true" ]] && features+=("PostgreSQL + Drizzle")
    [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && features+=("Authentication (Auth.js)")
    [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && features+=("AI Integration (Vercel AI SDK)")
    [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && features+=("Background Jobs (pg-boss)")
    [[ "${ENABLE_SHADCN:-true}" == "true" ]] && features+=("UI Components (shadcn/ui)")
    [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && features+=("Exports (PDF/Excel)")
    [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && features+=("Testing (Vitest + Playwright)")
    [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && features+=("Code Quality (ESLint + Prettier)")

    {
        echo "## Deployment Snapshot - ${ts}"
        echo ""
        echo "Database:"
        echo "  - Name: ${DB_NAME}"
        echo "  - User: ${DB_USER}"
        echo "  - Password: ${DB_PASSWORD:-<unset>}"
        echo "  - Host: ${DB_HOST}"
        echo "  - Port: ${DB_PORT}"
        echo ""
        echo "Features Enabled:"
        for f in "${features[@]}"; do
            echo "  - ${f}"
        done
        echo ""
    } >> "$notes_file"
}

# =============================================================================
# MAIN MENU
# =============================================================================

# Show main menu
menu_main() {
    _MENU_RUNNING=true

    while $_MENU_RUNNING; do
        _menu_header

        # Get cache size for display
        local cache_size=""
        if type downloads_get_cache_size &>/dev/null; then
            cache_size=$(downloads_get_cache_size 2>/dev/null || echo "0")
            [[ "$cache_size" != "0" ]] && cache_size="${cache_size} MB" || cache_size="empty"
        fi

        echo -e "  ${LOG_CYAN}MAIN MENU${LOG_NC}"
        _menu_line "─" 66
        echo ""

        _menu_item "1" "OmniForge Setup Wizard" "Configure project settings (name, description)"
        _menu_item "2" "Bootstrap Project" "Deploy apps and install stack"
        _menu_item "3" "Docker Tools and Cleanup" "Inspect + deploy scan/wipe + app clean/cache"
        _menu_item "4" "IDE Settings Manager" "Copy IDE/tool configs to project"
        _menu_item "5" "OmniForge Options" "Preferences and defaults"
        _menu_item "6" "Help" "Usage guide and documentation"

        _menu_prompt "Select [1-6] (any other key exits)"

        case "$_MENU_SELECTION" in
            1) wizard_configure_project ;;
            2) menu_bootstrap ;;
            3) menu_docker_tools ;;
            4) menu_settings ;;
            5) menu_options ;;
            6) menu_help ;;
            *) _MENU_RUNNING=false ;;  # Any other key exits
        esac
    done

    echo ""
}

# =============================================================================
# BOOTSTRAP MENU (Workflow)
# =============================================================================

menu_bootstrap() {
    local step=1
    local total_steps=7

    while true; do
        case $step in
            1) _bootstrap_step_select_profile && ((step++)) || return ;;
            2) _bootstrap_step_customize_apps && ((step++)) || ((step--)) ;;
            3) _bootstrap_step_download && ((step++)) || ((step--)) ;;
            4) _bootstrap_step_configure && ((step++)) || ((step--)) ;;
            5) _bootstrap_step_preflight && ((step++)) || ((step--)) ;;
            6) _bootstrap_step_install && ((step++)) || ((step--)) ;;
            7) _bootstrap_step_validate; return ;;
        esac
    done
}

# Step 1: Select Stack Profile
_bootstrap_step_select_profile() {
    local total_profiles=${#AVAILABLE_PROFILES[@]}
    if (( total_profiles == 0 )); then
        log_error "No profiles defined (AVAILABLE_PROFILES is empty)"
        return 1
    fi

    # Determine default profile number from STACK_PROFILE dynamically
    local default_profile="${STACK_PROFILE:-asset_manager}"
    local default_num=1
    local idx=1
    local found_default=false
    for profile in "${AVAILABLE_PROFILES[@]}"; do
        if [[ "$profile" == "$default_profile" ]]; then
            default_num=$idx
            found_default=true
            break
        fi
        ((idx++))
    done
    if [[ "$found_default" == "false" ]]; then
        default_profile="${AVAILABLE_PROFILES[0]}"
        default_num=1
    fi

    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 1/7: Select Stack Profile"
    echo ""
    echo "  Choose a stack profile to set your baseline configuration:"
    echo ""

    # Display profiles from AVAILABLE_PROFILES array
    local profile_num=1
    for profile in "${AVAILABLE_PROFILES[@]}"; do
        local name=$(get_profile_metadata "$profile" "name")
        local tagline=$(get_profile_metadata "$profile" "tagline")
        local description=$(get_profile_metadata "$profile" "description")
        local recommended=$(get_profile_metadata "$profile" "recommended")
        local features="$(_profile_feature_summary "$profile")"

        # Format with current selection and recommendation indicators
        local marker=""
        [[ "$recommended" == "true" ]] && marker=" ⭐"
        [[ "$profile" == "$default_profile" ]] && marker="${marker} ${LOG_GREEN}[current]${LOG_NC}"

        echo "  ${LOG_CYAN}${profile_num}) ${name}${marker}${LOG_NC} ${LOG_NC}- ${LOG_WHITE:-}${tagline}${LOG_NC}"
        echo "     ${description}"
        if [[ -n "$features" ]]; then
            echo "     ${LOG_GRAY:-}Packages/Features:${LOG_NC} ${features}"
        fi
        echo ""

        ((profile_num++))
    done

    echo ""
    _menu_line
    read -rp "  Select profile [1-${#AVAILABLE_PROFILES[@]}] (default: ${default_num}=${default_profile}): " choice

    local selected_profile=""
    if [[ -z "$choice" ]]; then
        selected_profile="$default_profile"
    elif [[ "$choice" =~ ^[0-9]+$ ]]; then
        if (( choice >= 1 && choice <= total_profiles )); then
            selected_profile=$(get_profile_by_number "$choice")
        else
            log_error "Invalid profile number: $choice (must be 1-${total_profiles})"
            return 1
        fi
    elif [[ "$choice" == "custom_bos" ]]; then
        log_warn "Profile 'custom_bos' was renamed to 'tech_stack'; using tech_stack."
        selected_profile="tech_stack"
    else
        for profile in "${AVAILABLE_PROFILES[@]}"; do
            if [[ "$choice" == "$profile" ]]; then
                selected_profile="$choice"
                break
            fi
        done
        if [[ -z "$selected_profile" ]]; then
            log_warn "Invalid selection. Using ${default_profile} profile as default."
            selected_profile="$default_profile"
        fi
    fi

    export STACK_PROFILE="$selected_profile"
    apply_stack_profile "$selected_profile" || return 1

    # Show installation plan after profile selection
    _display_installation_plan

    echo "  You can customize individual features in the next step."
    echo ""
    _menu_line

    return 0
}

# Step 2: Customize Apps (optional tweaks to profile)
_bootstrap_step_customize_apps() {
    # Feature toggles - use simple variables for reliable toggling
    local f1="${ENABLE_NEXTJS:-true}"
    local f2="${ENABLE_DATABASE:-true}"
    local f3="${ENABLE_AUTHJS:-true}"
    local f4="${ENABLE_AI_SDK:-true}"
    local f5="${ENABLE_PG_BOSS:-false}"
    local f6="${ENABLE_SHADCN:-true}"
    local f7="${ENABLE_PDF_EXPORTS:-false}"
    local f8="${ENABLE_TEST_INFRA:-true}"
    local f9="${ENABLE_CODE_QUALITY:-false}"

    # Helper to display menu
    _customize_show() {
        _menu_header
        _menu_title "BOOTSTRAP PROJECT - Step 2/7: Customize Features"
        echo ""
        echo "  ${LOG_CYAN}Phase 0: Project Foundation${LOG_NC}"
        echo "    (Always installed)"
        echo ""
        [[ "$f1" == "true" ]] && echo "    [x] 1. Next.js + TypeScript" || echo "    [ ] 1. Next.js + TypeScript"
        [[ "$f2" == "true" ]] && echo "    [x] 2. PostgreSQL + Drizzle ORM" || echo "    [ ] 2. PostgreSQL + Drizzle ORM"
        echo ""

        echo "  ${LOG_CYAN}Phase 1 & 2: Core Features${LOG_NC}"
        [[ "$f3" == "true" ]] && echo "    [x] 3. Authentication (Auth.js)" || echo "    [ ] 3. Authentication (Auth.js)"
        [[ "$f4" == "true" ]] && echo "    [x] 4. AI Integration (Vercel AI SDK)" || echo "    [ ] 4. AI Integration (Vercel AI SDK)"
        [[ "$f5" == "true" ]] && echo "    [x] 5. Background Jobs (pg-boss)" || echo "    [ ] 5. Background Jobs (pg-boss)"
        echo ""

        echo "  ${LOG_CYAN}Phase 3: User Interface${LOG_NC}"
        [[ "$f6" == "true" ]] && echo "    [x] 6. UI Components (shadcn/ui)" || echo "    [ ] 6. UI Components (shadcn/ui)"
        echo ""

        echo "  ${LOG_CYAN}Phase 4: Extensions & Quality${LOG_NC}"
        [[ "$f7" == "true" ]] && echo "    [x] 7. PDF/Excel Exports" || echo "    [ ] 7. PDF/Excel Exports"
        [[ "$f8" == "true" ]] && echo "    [x] 8. Testing (Vitest + Playwright)" || echo "    [ ] 8. Testing (Vitest + Playwright)"
        [[ "$f9" == "true" ]] && echo "    [x] 9. Code Quality (ESLint + Prettier)" || echo "    [ ] 9. Code Quality (ESLint + Prettier)"
        echo ""

        echo "  ${LOG_GRAY}Quick Presets:${LOG_NC}"
        echo "    [m]inimal  [a]pi-only  [f]ull  [e]nterprise"
        echo ""
        echo "  Enter feature number to toggle or preset letter; press Enter when ready."
        echo ""
        _menu_line
    }

    _customize_show

    while true; do
        read -rp "  Toggle [1-9], preset (m/a/f/e), or Enter to finish: " choice

        case "$choice" in
            1) [[ "$f1" == "true" ]] && f1="false" || f1="true"; _customize_show ;;
            2) [[ "$f2" == "true" ]] && f2="false" || f2="true"; _customize_show ;;
            3) [[ "$f3" == "true" ]] && f3="false" || f3="true"; _customize_show ;;
            4) [[ "$f4" == "true" ]] && f4="false" || f4="true"; _customize_show ;;
            5) [[ "$f5" == "true" ]] && f5="false" || f5="true"; _customize_show ;;
            6) [[ "$f6" == "true" ]] && f6="false" || f6="true"; _customize_show ;;
            7) [[ "$f7" == "true" ]] && f7="false" || f7="true"; _customize_show ;;
            8) [[ "$f8" == "true" ]] && f8="false" || f8="true"; _customize_show ;;
            9) [[ "$f9" == "true" ]] && f9="false" || f9="true"; _customize_show ;;
            m|minimal)
                f1="true"; f2="true"
                f3="false"; f4="false"; f5="false"; f6="false"; f7="false"; f8="false"; f9="false"
                _customize_show
                ;;
            a|api-only)
                f1="true"; f2="true"; f3="true"; f4="true"; f5="true"
                f6="false"; f7="false"; f8="true"; f9="false"
                _customize_show
                ;;
            f|full)
                f1="true"; f2="true"; f3="true"; f4="true"; f5="true"; f6="true"
                f7="false"; f8="true"; f9="false"
                _customize_show
                ;;
            e|enterprise)
                f1="true"; f2="true"; f3="true"; f4="true"; f5="true"; f6="true"; f7="true"; f8="true"; f9="true"
                _customize_show
                ;;
            ""|done|d)
                # Save selections to environment for next steps
                export ENABLE_NEXTJS="$f1"
                export ENABLE_DATABASE="$f2"
                export ENABLE_AUTHJS="$f3"
                export ENABLE_AI_SDK="$f4"
                export ENABLE_PG_BOSS="$f5"
                export ENABLE_SHADCN="$f6"
                export ENABLE_PDF_EXPORTS="$f7"
                export ENABLE_TEST_INFRA="$f8"
                export ENABLE_CODE_QUALITY="$f9"
                return 0
                ;;
            b|back)
                return 1
                ;;
            q|quit)
                return 1
                ;;
        esac
    done
}

# Step 3: Initialize Database
_bootstrap_step_download() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 3/7: Initialize Database"
    echo ""

    # Database type and configuration
    echo "  ${LOG_CYAN}Database Type:${LOG_NC}          PostgreSQL 16"

    # Determine OS-specific PostgreSQL paths
    local pg_install_path pg_data_path pg_socket
    if [[ "$OSTYPE" == "darwin"* ]]; then
        # macOS with Homebrew
        pg_install_path="/usr/local/var/postgres"
        pg_data_path="/usr/local/var/postgres/data"
        pg_socket="/tmp/.s.PGSQL.5432"
    else
        # Linux
        pg_install_path="/var/lib/postgresql"
        pg_data_path="/var/lib/postgresql/16/main"
        pg_socket="/var/run/postgresql/.s.PGSQL.5432"
    fi

    echo "  ${LOG_CYAN}Installation Path:${LOG_NC}      ${pg_install_path}"
    echo "  ${LOG_CYAN}Data Directory:${LOG_NC}         ${pg_data_path}"
    echo "  ${LOG_CYAN}Socket Location:${LOG_NC}        ${pg_socket}"
    echo ""

    # Show download cache location
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    local cache_dir="${OMNIFORGE_CACHE_DIR:-${omniforge_dir}/.download-cache}"
    echo "  ${LOG_CYAN}Dependency Cache:${LOG_NC}       ${cache_dir}"
    echo ""

    # Start background download immediately when step loads
    echo "  Starting background dependency download..."
    if type downloads_start_for_config &>/dev/null; then
        downloads_start_for_config
        echo ""
        echo "  ${LOG_GREEN}[OK]${LOG_NC} Download running in background"
        echo "  Database initialization will proceed in next steps."
    else
        echo "  ${LOG_YELLOW}[SKIP]${LOG_NC} Download cache not available"
    fi

    echo ""
    sleep 1  # Brief pause to show status
    return 0  # Auto-continue to next step
}

# Step 4: Configure PostgreSQL & Application
_bootstrap_step_configure() {
    # Load configuration from omni.* if available
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    local config_path="${OMNI_CONFIG_PATH:-${omniforge_dir}/omni.config}"
    local settings_path="${OMNI_SETTINGS_PATH:-${omniforge_dir}/omni.settings.sh}"

    if [[ -f "$config_path" ]]; then
        # shellcheck source=/dev/null
        source "$config_path"
    fi
    if [[ -f "$settings_path" ]]; then
        # shellcheck source=/dev/null
        source "$settings_path"
    fi

    # Initialize with values from omni.* (or defaults if not set)
    APP_NAME="${APP_NAME:-bloom2}"
    DB_NAME="${DB_NAME:-bloom2_db}"
    DB_USER="${DB_USER:-bloom2}"
    DB_PASSWORD="${DB_PASSWORD:-change_me}"
    DB_PORT="${DB_PORT:-5432}"
    DB_HOST="${DB_HOST:-localhost}"
    BACKUP_LOCATION="${BACKUP_LOCATION:-./backups}"
    ENABLE_AUTO_BACKUP="${ENABLE_AUTO_BACKUP:-true}"

    # Log configuration summary to log file (called when user confirms)
    _log_config_summary() {
        # Ensure log file is available
        if [[ -z "${LOG_FILE:-}" ]]; then
            local log_dir="${LOG_DIR:-${TMPDIR:-/tmp}}"
            mkdir -p "$log_dir"
            LOG_FILE="${log_dir}/omniforge_$(date +%Y%m%d_%H%M%S).log"
        fi

        {
            echo "================================================================================"
            echo "OMNIFORGE CONFIGURATION SUMMARY - $(date '+%Y-%m-%d %H:%M:%S')"
            echo "================================================================================"
            echo ""
            echo "APPLICATION"
            echo "  Name:             ${APP_NAME}"
            echo "  Root Directory:   ${PROJECT_ROOT:-.}"
            echo "  Install Path:     ${INSTALL_DIR:-./test/install-1}"
            echo "  Stack Profile:    ${STACK_PROFILE:-standard}"
            echo ""
            echo "POSTGRESQL DATABASE"
            echo "  Name:             ${DB_NAME}"
            echo "  User:             ${DB_USER}"
            echo "  Host:             ${DB_HOST}"
            echo "  Port:             ${DB_PORT}"
            echo "  Connection:       postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
            echo ""
            echo "BACKUPS"
            echo "  Location:         ${BACKUP_LOCATION}"
            echo "  Auto-Backup:      ${ENABLE_AUTO_BACKUP}"
            echo ""
            echo "ENABLED FEATURES"
            [[ "${ENABLE_NEXTJS:-true}" == "true" ]] && echo "  ✓ ENABLE_NEXTJS"
            [[ "${ENABLE_DATABASE:-true}" == "true" ]] && echo "  ✓ ENABLE_DATABASE"
            [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && echo "  ✓ ENABLE_AUTHJS (Authentication)"
            [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && echo "  ✓ ENABLE_AI_SDK (AI Integration)"
            [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "  ✓ ENABLE_PG_BOSS (Job Queue)"
            [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "  ✓ ENABLE_SHADCN (UI Components)"
            [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "  ✓ ENABLE_PDF_EXPORTS"
            [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && echo "  ✓ ENABLE_TEST_INFRA (Testing)"
            [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "  ✓ ENABLE_CODE_QUALITY (Linting)"
            echo ""
            echo "INSTALLATION PLAN"
            echo "  Phase 0: Project Foundation (Next.js, TypeScript)"
            [[ "${ENABLE_DATABASE:-true}" == "true" ]] && echo "  Phase 1: Infrastructure & Database (Docker, PostgreSQL, Drizzle)"
            echo "  Phase 2: Core Features (Auth, AI, Jobs, State, Logging)"
            [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "  Phase 3: User Interface (shadcn/ui)"
            echo "  Phase 4: Extensions & Quality (PDF, Testing, Linting)"
            echo ""
            local total_time="~80m"
            [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && total_time="~110m"
            echo "  Total Installation Time: ${total_time}"
            echo ""
            echo "================================================================================"
        } >> "$LOG_FILE"

        log_info "Configuration saved to log: $LOG_FILE"
    }

    _show_config() {
        _menu_header
        _menu_title "BOOTSTRAP PROJECT - Step 4/7: Configure PostgreSQL & Application"
        echo ""
        echo "  ${LOG_CYAN}PostgreSQL Connection Details${LOG_NC}"
        _menu_line "─" 66
        echo ""

        echo "  ${LOG_CYAN}Step 1/4: Application Identity${LOG_NC}"
        echo ""
        echo "    Application Name [${APP_NAME}]"
        echo "    Project Root:              ${PROJECT_ROOT:-.}"
        echo ""

        echo "  ${LOG_CYAN}Step 2/4: PostgreSQL Database${LOG_NC}"
        echo ""
        if [[ -z "${DB_PASSWORD:-}" ]]; then
            DB_PASSWORD="$(openssl rand -base64 16 | tr -d '=+/')"
            echo "    ${LOG_YELLOW}Generated DB password (note this down):${LOG_NC} ${DB_PASSWORD}"
        else
            echo "    Database Password:        ••••••••"
        fi
        echo "    Database Name [${DB_NAME}]"
        echo "    Database User [${DB_USER}]"
        echo "    Database Port [${DB_PORT}]"
        echo "    PostgreSQL Host [${DB_HOST}]"
        echo ""

        echo "  ${LOG_CYAN}Step 3/4: Data & Backups${LOG_NC}"
        echo ""
        echo "    Backup Location [${BACKUP_LOCATION}]"
        echo "    Enable Auto-Backups? [${ENABLE_AUTO_BACKUP}]"
        echo ""

        echo "  ${LOG_CYAN}Step 4/4: Application Features${LOG_NC}"
        echo ""
        echo "    ${LOG_GRAY:-}Features enabled:${LOG_NC}"
        [[ "${ENABLE_NEXTJS:-true}" == "true" ]] && echo "      ✓ Next.js + TypeScript" || echo "      ✗ Next.js + TypeScript"
        [[ "${ENABLE_DATABASE:-true}" == "true" ]] && echo "      ✓ PostgreSQL + Drizzle" || echo "      ✗ PostgreSQL + Drizzle"
        [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && echo "      ✓ Authentication (Auth.js)" || echo "      ✗ Authentication (Auth.js)"
        [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && echo "      ✓ AI Integration (Vercel AI SDK)" || echo "      ✗ AI Integration (Vercel AI SDK)"
        [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "      ✓ Background Jobs (pg-boss)" || echo "      ✗ Background Jobs (pg-boss)"
        [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "      ✓ UI Components (shadcn/ui)" || echo "      ✗ UI Components (shadcn/ui)"
        [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "      ✓ Exports (PDF/Excel)" || echo "      ✗ Exports (PDF/Excel)"
        [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && echo "      ✓ Testing (Vitest + Playwright)" || echo "      ✗ Testing (Vitest + Playwright)"
        [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "      ✓ Code Quality (ESLint + Prettier)" || echo "      ✗ Code Quality (ESLint + Prettier)"
        echo ""
        echo ""

        # Write/update deployment notes with current DB creds + features
        _write_deployment_notes

        # Write/update deployment notes with current DB creds + features
        _write_deployment_notes

        echo "  ${LOG_CYAN}Configuration Summary${LOG_NC}"
        _menu_line "─" 66
        echo ""
        echo "  📦 Application"
        echo "      Name:             ${APP_NAME}"
        echo "      Root Directory:   ${PROJECT_ROOT:-.}"
        echo ""
        echo "  🐘 PostgreSQL Database"
        echo "      Name:             ${DB_NAME}"
        echo "      User:             ${DB_USER}"
        echo "      Host:             ${DB_HOST}"
        echo "      Port:             ${DB_PORT}"
        echo "      Data Path:        ${pg_data_path:-/var/lib/postgresql/16/main}/${DB_NAME}"
        echo "      Connection (placeholder):"
        echo "        Hostname: postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}"
        echo "        Host IP:  postgresql://${DB_USER}@<host-ip>:${DB_PORT}/${DB_NAME}"
        echo ""
        echo "  💾 Backups"
        echo "      Location:         ${BACKUP_LOCATION}"
        echo "      Auto-Backup:      $([ "$ENABLE_AUTO_BACKUP" == "true" ] && echo "Enabled (Daily)" || echo "Disabled")"
        echo ""

        echo ""
        echo "  ${LOG_CYAN}Installation Plan (By Phase)${LOG_NC}"
        _menu_line "─" 66
        echo ""

        echo "  ${LOG_CYAN}Phase 0: Project Foundation${LOG_NC}"
        if [[ "${ENABLE_NEXTJS:-true}" == "true" ]]; then
            echo "    ✓ Initialize Next.js & TypeScript"
            echo "    ✓ Setup project structure"
        fi
        echo ""

        echo "  ${LOG_CYAN}Phase 1: Infrastructure & Database${LOG_NC}"
        if [[ "${ENABLE_DATABASE:-true}" == "true" ]]; then
            echo "    ✓ Docker configuration"
            echo "    ✓ PostgreSQL 16 setup"
            echo "    ✓ Drizzle ORM & migrations"
            echo "    ✓ Environment variables"
        fi
        echo ""

        echo "  ${LOG_CYAN}Phase 2: Core Features${LOG_NC}"
        [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && echo "    ✓ Authentication (Auth.js)"
        [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && echo "    ✓ AI/LLM Integration"
        [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "    ✓ Background Jobs (pg-boss)"
        echo "    ✓ State Management (Zustand)"
        echo "    ✓ Logging (Pino)"
        echo ""

        echo "  ${LOG_CYAN}Phase 3: User Interface${LOG_NC}"
        [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "    ✓ shadcn/ui Components" || echo "    ✗ UI Components (skipped)"
        echo ""

        echo "  ${LOG_CYAN}Phase 4: Extensions & Quality${LOG_NC}"
        [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "    ✓ PDF/Excel Export System"
        [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && echo "    ✓ Testing (Vitest + Playwright)"
        [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "    ✓ Code Quality (ESLint + Prettier)"
        echo ""
        echo "  ${LOG_YELLOW}Install Path: ${INSTALL_DIR:-./test/install-1}${LOG_NC}"
        echo ""
        _menu_line "─" 66
        echo ""
        echo "  [ENTER] Continue  [e] Edit omni.config  [r] Refresh  [b] Back"
        echo ""
    }

    # Show initial config
    _show_config

    # Main loop: display config and wait for action
    while true; do
        read -rp "  Choice [ENTER to continue]: " action
        action="${action:-continue}"

        case "$action" in
            e|edit)
                # Edit omni.config directly
                if command -v micro &>/dev/null; then
                    micro "$config_path"
                elif command -v nano &>/dev/null; then
                    nano "$config_path"
                else
                    log_warn "No editor found (tried micro, nano)"
                    read -rp "  Press Enter to continue: " _
                fi
                # Reload configuration
                [[ -f "$config_path" ]] && source "$config_path" 2>/dev/null
                APP_NAME="${APP_NAME:-bloom2}"
                DB_NAME="${DB_NAME:-bloom2_db}"
                DB_USER="${DB_USER:-bloom2}"
                DB_PASSWORD="${DB_PASSWORD:-change_me}"
                DB_PORT="${DB_PORT:-5432}"
                DB_HOST="${DB_HOST:-localhost}"
                BACKUP_LOCATION="${BACKUP_LOCATION:-./backups}"
                ENABLE_AUTO_BACKUP="${ENABLE_AUTO_BACKUP:-true}"
                _show_config
                ;;
            r|refresh)
                # Reload from omni.config / omni.settings.sh
                [[ -f "$config_path" ]] && source "$config_path" 2>/dev/null
                [[ -f "$settings_path" ]] && source "$settings_path" 2>/dev/null
                APP_NAME="${APP_NAME:-bloom2}"
                DB_NAME="${DB_NAME:-bloom2_db}"
                DB_USER="${DB_USER:-bloom2}"
                DB_PASSWORD="${DB_PASSWORD:-change_me}"
                DB_PORT="${DB_PORT:-5432}"
                DB_HOST="${DB_HOST:-localhost}"
                BACKUP_LOCATION="${BACKUP_LOCATION:-./backups}"
                ENABLE_AUTO_BACKUP="${ENABLE_AUTO_BACKUP:-true}"
                _show_config
                ;;
            b|back)
                return 1
                ;;
            ""|continue|c)
                # Show edit menu
                break
                ;;
            *)
                _show_config
                ;;
        esac
    done

    # Configuration editing loop
    while true; do
        echo ""
        echo "  ${LOG_CYAN}Edit Configuration${LOG_NC}"
        echo ""
        echo "    [1] Application Name"
        echo "    [2] Database Name"
        echo "    [3] Database User"
        echo "    [4] Database Password"
        echo "    [5] Database Port"
        echo "    [6] Database Host"
        echo "    [7] Backup Location"
        echo "    [8] Auto-Backup (toggle)"
        echo ""
        echo "    [c] Continue with configuration"
        echo "    [e] Edit stack features"
        echo "    [b] Back to previous step"
        echo ""

        read -rp "  Choice [c]: " choice
        choice="${choice:-c}"

        case "$choice" in
            1)
                read -rp "  Application Name [${APP_NAME}]: " val
                [[ -n "$val" ]] && APP_NAME="$val"
                _show_config
                ;;
            2)
                read -rp "  Database Name [${DB_NAME}]: " val
                [[ -n "$val" ]] && DB_NAME="$val"
                _show_config
                ;;
            3)
                read -rp "  Database User [${DB_USER}]: " val
                [[ -n "$val" ]] && DB_USER="$val"
                _show_config
                ;;
            4)
                echo -n "  Database Password [$([ -n "$DB_PASSWORD" ] && echo "••••••••" || echo "not set")]: "
                read -rs val
                echo ""
                [[ -n "$val" ]] && DB_PASSWORD="$val"
                _show_config
                ;;
            5)
                read -rp "  Database Port [${DB_PORT}]: " val
                [[ -n "$val" ]] && DB_PORT="$val"
                _show_config
                ;;
            6)
                read -rp "  PostgreSQL Host [${DB_HOST}]: " val
                [[ -n "$val" ]] && DB_HOST="$val"
                _show_config
                ;;
            7)
                read -rp "  Backup Location [${BACKUP_LOCATION}]: " val
                [[ -n "$val" ]] && BACKUP_LOCATION="$val"
                _show_config
                ;;
            8)
                if [[ "$ENABLE_AUTO_BACKUP" == "true" ]]; then
                    ENABLE_AUTO_BACKUP="false"
                else
                    ENABLE_AUTO_BACKUP="true"
                fi
                _show_config
                ;;
            e|edit)
                return 1  # Go back to step 2 to edit features
                ;;
            c|continue|"")
                # Save all configuration to exports
                export APP_NAME DB_NAME DB_USER DB_PASSWORD DB_PORT DB_HOST
                export BACKUP_LOCATION ENABLE_AUTO_BACKUP

                # Update omni.config (Section 1 fields)
                if [[ -f "$config_path" ]]; then
                    local temp_conf="${config_path}.tmp.$$"
                    cp "$config_path" "$temp_conf"
                    sed -i.bak "s/^APP_NAME=.*/APP_NAME=\"${APP_NAME}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_NAME=.*/DB_NAME=\"${DB_NAME}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_USER=.*/DB_USER=\"${DB_USER}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_PASSWORD=.*/DB_PASSWORD=\"${DB_PASSWORD}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_PORT=.*/DB_PORT=\"${DB_PORT}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_HOST=.*/DB_HOST=\"${DB_HOST}\"/" "$temp_conf"
                    rm -f "${temp_conf}.bak"
                    mv "$temp_conf" "$config_path"
                fi

                # Update omni.settings.sh for backup settings
                if [[ -f "$settings_path" ]]; then
                    local temp_settings="${settings_path}.tmp.$$"
                    cp "$settings_path" "$temp_settings"
                    sed -i.bak "s/^BACKUP_LOCATION=.*/BACKUP_LOCATION=\"${BACKUP_LOCATION}\"/" "$temp_settings"
                    sed -i.bak "s/^ENABLE_AUTO_BACKUP=.*/ENABLE_AUTO_BACKUP=\"${ENABLE_AUTO_BACKUP}\"/" "$temp_settings"
                    rm -f "${temp_settings}.bak"
                    mv "$temp_settings" "$settings_path"
                fi

                # Log the configuration summary to log file
                _log_config_summary

                return 0
                ;;
            b|back)
                return 1
                ;;
            *)
                _show_config
                ;;
        esac
    done
}

# Step 5: Preflight Check
_bootstrap_step_preflight() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 5/7: Preflight Check"
    echo ""

    local errors=0
    local warnings=0
    local scripts_dir="${SCRIPTS_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}"

    # -------------------------------------------------------------------------
    # Section 1: Required Tools
    # -------------------------------------------------------------------------
    echo "  ${LOG_CYAN}1. Required Tools${LOG_NC}"
    echo ""

    # Check Node.js
    if command -v node &>/dev/null; then
        local node_ver=$(node --version)
        echo "     ${LOG_GREEN}✓${LOG_NC} Node.js ${node_ver}"
    else
        echo "     ${LOG_RED}✗${LOG_NC} Node.js not found (v${NODE_VERSION:-20}+ required)"
        ((errors++))
    fi

    # Check pnpm
    if command -v pnpm &>/dev/null; then
        local pnpm_ver=$(pnpm --version)
        echo "     ${LOG_GREEN}✓${LOG_NC} pnpm ${pnpm_ver}"
    else
        echo "     ${LOG_RED}✗${LOG_NC} pnpm not found (npm install -g pnpm)"
        ((errors++))
    fi

    # Check git
    if command -v git &>/dev/null; then
        echo "     ${LOG_GREEN}✓${LOG_NC} git installed"
    else
        echo "     ${LOG_RED}✗${LOG_NC} git not found"
        ((errors++))
    fi

    # Check Docker (optional)
    if command -v docker &>/dev/null; then
        echo "     ${LOG_GREEN}✓${LOG_NC} Docker installed"
    else
        echo "     ${LOG_YELLOW}○${LOG_NC} Docker not found (optional - for PostgreSQL container)"
        ((warnings++))
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Section 2: Framework Files
    # -------------------------------------------------------------------------
    echo "  ${LOG_CYAN}2. Framework Files${LOG_NC}"
    echo ""

    local framework_ok=0
    local framework_total=0

    # Check core libraries
    local core_libs=("common.sh" "logging.sh" "config_bootstrap.sh" "phases.sh" "state.sh" "utils.sh" "ascii.sh" "menu.sh")
    for lib in "${core_libs[@]}"; do
        ((framework_total++))
        if [[ -f "${scripts_dir}/lib/${lib}" ]]; then
            ((framework_ok++))
        fi
    done

    # Check bin scripts
    local bin_scripts=("omni" "forge" "status")
    for bin in "${bin_scripts[@]}"; do
        ((framework_total++))
        if [[ -f "${scripts_dir}/bin/${bin}" ]]; then
            ((framework_ok++))
        fi
    done

    if [[ $framework_ok -eq $framework_total ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} Core libraries: ${framework_ok}/${framework_total} files"
    else
        echo "     ${LOG_RED}✗${LOG_NC} Core libraries: ${framework_ok}/${framework_total} files (missing: $((framework_total - framework_ok)))"
        ((errors++))
    fi

    # Check omni config files
    local config_errors=0
    if [[ -f "${scripts_dir}/omni.config" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} omni.config present"
    else
        echo "     ${LOG_RED}✗${LOG_NC} omni.config missing"
        ((config_errors++))
    fi
    if [[ -f "${scripts_dir}/omni.settings.sh" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} omni.settings.sh present"
    else
        echo "     ${LOG_YELLOW}○${LOG_NC} omni.settings.sh missing"
        ((warnings++))
    fi
    if [[ -f "${scripts_dir}/omni.profiles.sh" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} omni.profiles.sh present"
    else
        echo "     ${LOG_RED}✗${LOG_NC} omni.profiles.sh missing"
        ((config_errors++))
    fi
    if [[ -f "${scripts_dir}/omni.phases.sh" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} omni.phases.sh present"
    else
        echo "     ${LOG_RED}✗${LOG_NC} omni.phases.sh missing"
        ((config_errors++))
    fi
    ((errors+=config_errors))
    echo ""

    # -------------------------------------------------------------------------
    # Section 3: Template & Settings Files
    # -------------------------------------------------------------------------
    echo "  ${LOG_CYAN}3. Template & Settings Files${LOG_NC}"
    echo ""

    # Count example files
    local example_count=0
    if [[ -d "${scripts_dir}/example-files" ]]; then
        example_count=$(find "${scripts_dir}/example-files" -type f -name "*.example" 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ $example_count -gt 0 ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} Example files: ${example_count} templates"
    else
        echo "     ${LOG_YELLOW}○${LOG_NC} Example files: none found"
        ((warnings++))
    fi

    # Count settings files
    local settings_count=0
    if [[ -d "${scripts_dir}/settings-files" ]]; then
        settings_count=$(find "${scripts_dir}/settings-files" -type f 2>/dev/null | wc -l | tr -d ' ')
    fi
    if [[ $settings_count -gt 0 ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} Settings files: ${settings_count} configs"
    else
        echo "     ${LOG_YELLOW}○${LOG_NC} Settings files: none found"
        ((warnings++))
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Section 4: Profile Scripts (based on selected profile)
    # -------------------------------------------------------------------------
    echo "  ${LOG_CYAN}4. Profile Scripts [${STACK_PROFILE:-standard}]${LOG_NC}"
    echo ""

    local tech_stack_dir="${scripts_dir}/tech_stack"
    local profile="${STACK_PROFILE:-standard}"

    # Define which scripts each profile needs
    # Core scripts are always required, features depend on profile
    local -a core_scripts=("core/nextjs.sh" "core/database.sh")
    local -a feature_scripts=()

    case "$profile" in
        minimal)
            # Core only
            ;;
        starter)
            # + Auth + UI
            core_scripts+=("core/auth.sh" "core/ui.sh")
            ;;
        standard)
            # + State + Testing
            core_scripts+=("core/auth.sh" "core/ui.sh")
            feature_scripts=("features/state.sh" "features/testing.sh")
            ;;
        advanced)
            # + AI SDK
            core_scripts+=("core/auth.sh" "core/ui.sh")
            feature_scripts=("features/state.sh" "features/testing.sh" "features/ai-sdk.sh")
            ;;
        enterprise)
            # Full stack + Code Quality
            core_scripts+=("core/auth.sh" "core/ui.sh")
            feature_scripts=("features/state.sh" "features/testing.sh" "features/ai-sdk.sh" "features/code-quality.sh")
            ;;
    esac

    # Check tech_stack directory exists
    if [[ ! -d "$tech_stack_dir" ]]; then
        echo "     ${LOG_RED}✗${LOG_NC} tech_stack/ directory missing"
        ((errors++))
    else
        # Check core scripts
        local core_ok=0
        local core_missing=()
        for script in "${core_scripts[@]}"; do
            if [[ -f "${tech_stack_dir}/${script}" ]]; then
                ((core_ok++))
            else
                core_missing+=("$script")
            fi
        done

        if [[ $core_ok -eq ${#core_scripts[@]} ]]; then
            echo "     ${LOG_GREEN}✓${LOG_NC} Core scripts: ${core_ok}/${#core_scripts[@]} ready"
        else
            echo "     ${LOG_RED}✗${LOG_NC} Core scripts: ${core_ok}/${#core_scripts[@]} (missing: ${core_missing[*]})"
            ((errors++))
        fi

        # Check feature scripts (if any)
        if [[ ${#feature_scripts[@]} -eq 0 ]]; then
            echo "     ${LOG_GREEN}✓${LOG_NC} Feature scripts: none required"
        else
            local feat_ok=0
            local feat_missing=()
            for script in "${feature_scripts[@]}"; do
                if [[ -f "${tech_stack_dir}/${script}" ]]; then
                    ((feat_ok++))
                else
                    feat_missing+=("$script")
                fi
            done

            if [[ $feat_ok -eq ${#feature_scripts[@]} ]]; then
                echo "     ${LOG_GREEN}✓${LOG_NC} Feature scripts: ${feat_ok}/${#feature_scripts[@]} ready"
            else
                echo "     ${LOG_YELLOW}○${LOG_NC} Feature scripts: ${feat_ok}/${#feature_scripts[@]} (missing: ${feat_missing[*]})"
                ((warnings++))
            fi
        fi

        # Check package installer utility
        if [[ -f "${tech_stack_dir}/_lib/pkg-install.sh" ]]; then
            echo "     ${LOG_GREEN}✓${LOG_NC} Package installer: ready"
        else
            echo "     ${LOG_RED}✗${LOG_NC} Package installer: _lib/pkg-install.sh missing"
            ((errors++))
        fi
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Section 5: Configuration Validation
    # -------------------------------------------------------------------------
    echo "  ${LOG_CYAN}5. Configuration Validation${LOG_NC}"
    echo ""

    # Validate config
    if type config_validate_all &>/dev/null; then
        if config_validate_all 2>/dev/null; then
            echo "     ${LOG_GREEN}✓${LOG_NC} configuration validated"
        else
            echo "     ${LOG_RED}✗${LOG_NC} configuration has errors"
            ((errors++))
        fi
    else
        echo "     ${LOG_YELLOW}○${LOG_NC} Config validation skipped"
    fi

    # Check key variables
    if [[ -n "${APP_NAME:-}" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} APP_NAME: ${APP_NAME}"
    else
        echo "     ${LOG_RED}✗${LOG_NC} APP_NAME not set"
        ((errors++))
    fi

    if [[ -n "${INSTALL_DIR:-}" ]]; then
        echo "     ${LOG_GREEN}✓${LOG_NC} INSTALL_DIR: ${INSTALL_DIR}"
    else
        echo "     ${LOG_RED}✗${LOG_NC} INSTALL_DIR not set"
        ((errors++))
    fi
    echo ""

    # -------------------------------------------------------------------------
    # Summary
    # -------------------------------------------------------------------------
    _menu_line "─" 66

    local total_checks=$((errors + warnings))
    if [[ $errors -eq 0 && $warnings -eq 0 ]]; then
        echo ""
        echo "  ${LOG_GREEN}PREFLIGHT COMPLETE${LOG_NC} - All systems ready"
        echo ""
        echo "  Ready to install ${LOG_CYAN}${STACK_PROFILE:-standard}${LOG_NC} stack:"
        echo "    • App: ${APP_NAME} → ${INSTALL_DIR}"
        echo "    • DB: ${DB_NAME} (${DB_USER}@${DB_HOST}:${DB_PORT})"
        echo ""
    elif [[ $errors -eq 0 ]]; then
        echo ""
        echo "  ${LOG_YELLOW}PREFLIGHT COMPLETE${LOG_NC} - ${warnings} warning(s)"
        echo ""
        echo "  Ready to install ${LOG_CYAN}${STACK_PROFILE:-standard}${LOG_NC} stack:"
        echo "    • App: ${APP_NAME} → ${INSTALL_DIR}"
        echo "    • DB: ${DB_NAME} (${DB_USER}@${DB_HOST}:${DB_PORT})"
        echo ""
    else
        echo ""
        echo "  ${LOG_RED}PREFLIGHT FAILED${LOG_NC} - ${errors} error(s), ${warnings} warning(s)"
        echo ""
        echo "  Please fix the errors above before continuing."
        echo ""
        read -rp "  Press Enter to retry, 'b' to go back: " choice
        [[ "$choice" == "b" ]] && return 1
        return 1  # Retry this step
    fi

    _menu_line

    echo ""
    read -rp "  Press Enter to begin installation, 'b' to go back: " choice
    [[ "$choice" == "b" ]] && return 1
    return 0
}

# Step 6: Install
_bootstrap_step_install() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 6/7: Installing"
    echo ""
    echo "  Starting installation (this may take several minutes)..."
    echo ""

    local previous_command="${COMMAND:-}"
    COMMAND="run"
    _maybe_reexec_in_docker "${ORIGINAL_ARGS[@]}"
    COMMAND="${previous_command}"

    # Initialize stats
    if type phase_stats_init &>/dev/null; then
        phase_stats_init
    fi

    # Run phase execution
    local tech_stack_dir="${SCRIPTS_DIR:-}/tech_stack"

    if type phase_execute_all &>/dev/null; then
        if phase_execute_all "$tech_stack_dir"; then
            echo ""
            echo "  [OK] Installation completed successfully!"
        else
            echo ""
            echo "  [WARN] Installation completed with some errors"
        fi
    else
        echo "  [ERROR] Phase execution not available"
    fi

    echo ""
    _menu_line
    read -rp "  Press Enter to continue: " _
    return 0
}

# Step 7: Validate
_bootstrap_step_validate() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 7/7: Validation"
    echo ""

    # Show recap
    if type phase_show_recap &>/dev/null; then
        phase_show_recap
    fi

    echo ""
    _menu_line
    read -rp "  Press Enter to return to main menu: " _
}

# =============================================================================
# SETTINGS MENU
# =============================================================================

menu_settings() {
    _menu_header
    _menu_title "IDE SETTINGS MANAGER"
    echo ""
    echo "  Copy configuration templates to your project:"
    echo ""

    local -A settings=(
        ["1"]="vscode|VS Code|.vscode/settings.json, extensions"
        ["2"]="cursor|Cursor|.cursor/rules"
        ["3"]="github|GitHub|.github/workflows, CODEOWNERS"
        ["4"]="drizzle|Drizzle|drizzle.config.ts"
        ["5"]="playwright|Playwright|playwright.config.ts"
        ["6"]="vitest|Vitest|vitest.config.ts"
    )

    for num in $(seq 1 6); do
        local data="${settings[$num]}"
        local id="${data%%|*}"
        local rest="${data#*|}"
        local name="${rest%%|*}"
        local desc="${rest#*|}"
        _menu_item "$num" "$name" "$desc"
    done

    echo ""
    _menu_item "7" "All of the above"
    echo ""

    _menu_prompt "Select [1-7] (any other key returns)"

    case "$_MENU_SELECTION" in
        [1-6])
            local data="${settings[$_MENU_SELECTION]}"
            local id="${data%%|*}"
            _settings_copy "$id"
            ;;
        7)
            for num in $(seq 1 6); do
                local data="${settings[$num]}"
                local id="${data%%|*}"
                _settings_copy "$id"
            done
            ;;
        *) return ;;  # Any other key returns to parent
    esac

    read -rp "  Press Enter to continue: " _
}

_settings_copy() {
    local setting_id="$1"
    local manifest="${SCRIPTS_DIR:-}/settings-files/manifest.conf"
    local settings_base="${SCRIPTS_DIR:-}/settings-files"
    local project_root="${PROJECT_ROOT:-.}"
    local copied=0
    local failed=0
    local temp_file="/tmp/settings_copy_$$.txt"

    if [[ ! -f "$manifest" ]]; then
        echo "  [FAIL] Settings manifest not found at $manifest"
        return 1
    fi

    # Filter manifest for matching entries and process
    grep "^${setting_id}:" "$manifest" | while IFS=: read -r id src dest_dir dest_file; do
        # Trim whitespace
        src="${src// /}"
        dest_dir="${dest_dir// /}"
        dest_file="${dest_file// /}"

        local src_file="$settings_base/$id/$src"

        if [[ ! -f "$src_file" ]]; then
            echo "$((failed++))" >> "$temp_file"
            continue
        fi

        # Construct destination path
        local full_dest
        if [[ "$dest_dir" == "." ]]; then
            full_dest="$project_root/$dest_file"
        else
            full_dest="$project_root/$dest_dir/$dest_file"
            # Create destination directory if needed
            mkdir -p "$project_root/$dest_dir" 2>/dev/null || {
                echo "  [FAIL] Could not create directory: $project_root/$dest_dir"
                echo "$((failed++))" >> "$temp_file"
                continue
            }
        fi

        # Copy file, stripping .example extension
        if cp "$src_file" "$full_dest" 2>/dev/null; then
            echo "  [OK] $(basename "$full_dest")"
            echo "$((copied++))" >> "$temp_file"
        else
            echo "  [FAIL] Could not copy $(basename "$src_file")"
            echo "$((failed++))" >> "$temp_file"
        fi
    done

    # Count the results from temp file
    if [[ -f "$temp_file" ]]; then
        copied=$(wc -l < "$temp_file")
        failed=0
        rm -f "$temp_file"
    fi

    if [[ $copied -gt 0 ]]; then
        echo "  [OK] $setting_id settings copied ($copied files)"
    else
        echo "  [SKIP] No settings found for $setting_id"
    fi
}

# =============================================================================
# PURGE MENU
# =============================================================================

menu_purge() {
    _menu_header
    _menu_title "PURGE DOWNLOAD CACHE"
    echo ""

    local cache_size="0"
    if type downloads_get_cache_size &>/dev/null; then
        cache_size=$(downloads_get_cache_size 2>/dev/null || echo "0")
    fi

    echo "  Current cache size: ${cache_size} MB"
    echo ""
    echo "  This will delete all cached packages."
    echo "  They will be re-downloaded on next install."
    echo ""

    _menu_line
    read -rp "  Purge cache? [Y/n]: " choice

    if [[ "${choice,,}" != "n" ]]; then
        if type downloads_purge &>/dev/null; then
            downloads_purge
            echo "  [OK] Cache purged"
        else
            echo "  [SKIP] Download cache not available"
        fi
    else
        echo "  [SKIP] Cache not purged"
    fi

    read -rp "  Press Enter to continue: " _
}

# =============================================================================
# MAINTENANCE / CLEANUP MENU
# =============================================================================

menu_maintenance() {
    _menu_header
    _menu_title "MAINTENANCE / CLEANUP"
    echo ""
    echo "  Choose a cleanup task:"
    echo ""
    local docker_available="true"
    local docker_note=""
    if ! command -v docker >/dev/null 2>&1; then
        docker_available="false"
        docker_note="(Docker not available on host)"
    elif [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
        docker_available="false"
        docker_note="(host Docker required; currently inside container)"
    fi

    _menu_item "1" "Clean Installation" "Delete/reset a previous deployment"
    _menu_item "2" "Wipe/Erase Docker Bootstrap" "Uses deploy scan reports to fully clean ${docker_note}"
    _menu_item "3" "Purge Download Cache" "Clear cached packages"
    echo ""

    _menu_prompt "Select [1-3] (any other key returns)"
    case "$_MENU_SELECTION" in
        1) menu_clean ;;
        2)
            if [[ "$docker_available" != "true" ]]; then
                echo ""
                echo "  ${LOG_YELLOW}Docker-dependent wipe requires host Docker. ${docker_note}${LOG_NC}"
                echo "  Run from host with Docker running, or generate scan reports first."
                echo ""
                read -rp "  Press Enter to continue: " _
                return
            fi
            menu_docker_wipe
            ;;
        3) menu_purge ;;
        *) return ;;
    esac
}

# =============================================================================
# DOCKER TOOLS AND CLEANUP
# =============================================================================

menu_docker_tools() {
    local docker_scan_script="${SCRIPT_DIR}/scripts/docker-scan.sh"
    local deploy_scan_script="${SCRIPT_DIR}/scripts/docker-deploy-scan.sh"
    local deploy_wipe_cmd="${SCRIPT_DIR}/omni.sh"
    local docker_available="true"
    local docker_note=""
    if ! command -v docker >/dev/null 2>&1; then
        docker_available="false"
        docker_note="(Docker not available)"
    elif [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
        docker_available="false"
        docker_note="(host Docker required; currently inside container)"
    fi

    while true; do
        _menu_header
        _menu_title "DOCKER TOOLS & CLEANUP"
        echo ""
        _menu_item "1" "Docker Inventory" "Inspect containers/images/volumes/networks ${docker_note}"
        _menu_item "2" "Deploy Mount Scan" "Run docker-deploy-scan.sh (pick from detected containers)"
        _menu_item "3" "Deploy Wipe" "Full clean via docker-wipe (dry-run by default)"
        _menu_item "4" "App Clean / Cache Purge" "App clean levels + purge download cache"
        _menu_item "5" "Back"
        echo ""

        _menu_prompt "Select [1-5] (any other key returns)"
        case "$_MENU_SELECTION" in
            1)
                if [[ "$docker_available" != "true" ]]; then
                    echo ""
                    echo "  ${LOG_YELLOW}Docker scan requires host Docker. ${docker_note}${LOG_NC}"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                if [[ ! -f "$docker_scan_script" ]]; then
                    echo ""
                    echo "  ${LOG_YELLOW}Docker scan script not found:${LOG_NC} $docker_scan_script"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                echo ""
                bash "$docker_scan_script" || true
                echo ""
                read -rp "  Press Enter to continue: " _
                ;;
            2)
                if [[ "$docker_available" != "true" ]]; then
                    echo ""
                    echo "  ${LOG_YELLOW}Deploy scan requires host Docker. ${docker_note}${LOG_NC}"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                if [[ ! -f "$deploy_scan_script" ]]; then
                    echo ""
                    echo "  ${LOG_YELLOW}Deploy scan script not found:${LOG_NC} $deploy_scan_script"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                echo ""
                echo "  Detecting containers..."
                mapfile -t docker_containers < <(docker ps -a --format '{{.Names}}' || true)
                if [[ ${#docker_containers[@]} -eq 0 ]]; then
                    echo "  ${LOG_YELLOW}No containers found.${LOG_NC}"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                local idx=1
                for c in "${docker_containers[@]}"; do
                    echo "    ${idx}) ${c}"
                    ((idx++))
                done
                echo ""
                read -rp "  Select container [1-${#docker_containers[@]}] (any other key to cancel): " choice
                if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#docker_containers[@]} )); then
                    echo "  ${LOG_YELLOW}Cancelled${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                local target="${docker_containers[$((choice-1))]}"
                echo ""
                bash "$deploy_scan_script" "$target" || true
                echo ""
                read -rp "  Press Enter to continue: " _
                ;;
            3)
                if [[ "$docker_available" != "true" ]]; then
                    echo ""
                    echo "  ${LOG_YELLOW}Deploy wipe requires host Docker. ${docker_note}${LOG_NC}"
                    echo ""
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                echo ""
                echo "  Detecting containers..."
                mapfile -t docker_containers < <(docker ps -a --format '{{.Names}}' || true)
                if [[ ${#docker_containers[@]} -eq 0 ]]; then
                    echo "  ${LOG_YELLOW}No containers found.${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                local idx=1
                for c in "${docker_containers[@]}"; do
                    echo "    ${idx}) ${c}"
                    ((idx++))
                done
                echo ""
                read -rp "  Select container [1-${#docker_containers[@]}] (any other key to cancel): " choice
                if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#docker_containers[@]} )); then
                    echo "  ${LOG_YELLOW}Cancelled${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                local target="${docker_containers[$((choice-1))]}"
                echo ""
                echo "  ${LOG_RED}Are you sure you want to WIPE container '${target}' and its artifacts?${LOG_NC}"
                echo "  This will delete host files from the latest deploy scan, remove the container,"
                echo "  named volumes, non-default networks, and the report directory."
                read -rp "  Type '${target}' to confirm full wipe (or anything else to cancel): " confirm
                if [[ "$confirm" != "$target" ]]; then
                    echo "  ${LOG_YELLOW}Cancelled${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                    continue
                fi
                echo ""
                "${deploy_wipe_cmd}" docker-wipe --container "$target" --force || true
                echo ""
                read -rp "  Press Enter to continue: " _
                ;;
            4)
                menu_clean
                ;;
            *) return ;;
        esac
    done
}

# =============================================================================
# CLEAN INSTALLATION MENU
# =============================================================================

menu_clean() {
    _menu_header
    _menu_title "CLEAN INSTALLATION"
    echo ""
    echo "  ${LOG_CYAN}Select Installation to Clean${LOG_NC}"
    echo ""

    # Define known installation paths
    local install_paths=(
        "./test/install-1"
        "./test/install-2"
        "./test/install-3"
        "./app"
    )

    # Check which paths exist and have content
    local existing_paths=()
    local path_num=1
    for path in "${install_paths[@]}"; do
        if [[ -d "$path" ]]; then
            local size=$(du -sh "$path" 2>/dev/null | cut -f1 || echo "?")
            local node_modules=""
            [[ -d "$path/node_modules" ]] && node_modules=" (has node_modules)"
            echo "  ${path_num}) ${LOG_YELLOW}${path}${LOG_NC} [${size}]${node_modules}"
            existing_paths+=("$path")
            ((path_num++))
        fi
    done

    if [[ ${#existing_paths[@]} -eq 0 ]]; then
        echo "  ${LOG_GRAY}No installations found.${LOG_NC}"
        echo ""
        read -rp "  Press Enter to return: " _
        return
    fi

    echo ""
    echo "  ${path_num}) Enter custom path"
    echo ""
    _menu_line

    read -rp "  Select [1-${path_num}] or 'b' to go back: " choice

    local target_path=""
    if [[ "$choice" == "b" || "$choice" == "back" ]]; then
        return
    elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -lt $path_num ]]; then
        target_path="${existing_paths[$((choice-1))]}"
    elif [[ "$choice" == "$path_num" ]]; then
        read -rp "  Enter path to clean: " target_path
    else
        echo "  [WARN] Invalid selection"
        sleep 1
        return
    fi

    if [[ -z "$target_path" || ! -d "$target_path" ]]; then
        echo "  [WARN] Path does not exist: $target_path"
        sleep 1
        return
    fi

    # Show what will be cleaned
    _menu_header
    _menu_title "CLEAN: ${target_path}"
    echo ""

    echo "  ${LOG_CYAN}Installation Artifacts${LOG_NC}"
    _menu_line "─" 66
    echo ""

    # App folder contents
    echo "  ${LOG_YELLOW}[APP FOLDER]${LOG_NC} ${target_path}/"
    if [[ -d "$target_path" ]]; then
        local app_size=$(du -sh "$target_path" 2>/dev/null | cut -f1 || echo "?")
        local file_count=$(find "$target_path" -type f 2>/dev/null | wc -l | tr -d ' ')
        echo "    Size: ${app_size}, Files: ${file_count}"
        [[ -d "$target_path/node_modules" ]] && echo "    ✓ node_modules/ present"
        [[ -d "$target_path/.next" ]] && echo "    ✓ .next/ build cache present"
        [[ -f "$target_path/package.json" ]] && echo "    ✓ package.json present"
    fi
    echo ""

    # State file in project root
    local state_file="${PROJECT_ROOT:-.}/.bootstrap_state"
    echo "  ${LOG_YELLOW}[STATE FILES]${LOG_NC}"
    if [[ -f "$state_file" ]]; then
        local state_entries=$(grep -c "=success:" "$state_file" 2>/dev/null || echo "0")
        echo "    ✓ .bootstrap_state (${state_entries} completed entries)"
    else
        echo "    ○ .bootstrap_state (not found)"
    fi

    # Index file
    local index_file="${PROJECT_ROOT:-.}/.omniforge_index"
    if [[ -f "$index_file" ]]; then
        echo "    ✓ .omniforge_index present"
    fi
    echo ""

    # Docker resources
    echo "  ${LOG_YELLOW}[DOCKER RESOURCES]${LOG_NC}"
    local docker_found=false
    if command -v docker &>/dev/null; then
        # Check for containers with app name
        local app_name=$(basename "$target_path")
        local containers=$(docker ps -a --filter "name=${app_name}" --format "{{.Names}}" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $containers -gt 0 ]]; then
            echo "    ✓ ${containers} container(s) matching '${app_name}'"
            docker_found=true
        fi
        # Check for postgres containers
        local pg_containers=$(docker ps -a --filter "name=postgres" --format "{{.Names}}" 2>/dev/null | head -3)
        if [[ -n "$pg_containers" ]]; then
            echo "    ✓ PostgreSQL containers found:"
            echo "$pg_containers" | while read -r name; do echo "      - $name"; done
            docker_found=true
        fi
        # Check for volumes
        local volumes=$(docker volume ls --filter "name=${app_name}" --format "{{.Name}}" 2>/dev/null | wc -l | tr -d ' ')
        if [[ $volumes -gt 0 ]]; then
            echo "    ✓ ${volumes} volume(s) matching '${app_name}'"
            docker_found=true
        fi
    fi
    [[ "$docker_found" == "false" ]] && echo "    ○ No Docker resources found"
    echo ""

    # OmniForge cache (always in omniforge dir)
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    echo "  ${LOG_YELLOW}[OMNIFORGE CACHE]${LOG_NC}"
    if [[ -d "${omniforge_dir}/.download-cache" ]]; then
        local cache_size=$(du -sh "${omniforge_dir}/.download-cache" 2>/dev/null | cut -f1 || echo "?")
        echo "    ✓ .download-cache/ [${cache_size}]"
    else
        echo "    ○ .download-cache/ (not found)"
    fi
    if [[ -d "${omniforge_dir}/logs" ]]; then
        local log_count=$(find "${omniforge_dir}/logs" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
        echo "    ✓ logs/ [${log_count} files]"
    fi
    echo ""

    _menu_line "─" 66
    echo ""
    echo "  ${LOG_CYAN}Clean Options${LOG_NC}"
    echo ""
    echo "    1) Quick Clean  - Delete app folder only"
    echo "    2) Full Clean   - App folder + state files + index"
    echo "    3) Deep Clean   - Full + Docker containers/volumes"
    echo "    4) Nuclear      - Everything including download cache"
    echo ""
    echo "  Press any other key to return."
    echo ""

    read -rp "  Select clean level [1-4]: " clean_level

    case "$clean_level" in
        1)
            echo ""
            echo "  ${LOG_YELLOW}Quick Clean: Deleting ${target_path}/${LOG_NC}"
            read -rp "  Confirm? (y/N): " confirm
            if [[ "${confirm,,}" == "y" ]]; then
                rm -rf "$target_path"
                echo "  [OK] Deleted ${target_path}/"
            else
                echo "  [SKIP] Cancelled"
            fi
            ;;
        2)
            echo ""
            echo "  ${LOG_YELLOW}Full Clean:${LOG_NC}"
            echo "    - ${target_path}/"
            echo "    - .bootstrap_state"
            echo "    - .omniforge_index"
            read -rp "  Confirm? (y/N): " confirm
            if [[ "${confirm,,}" == "y" ]]; then
                rm -rf "$target_path"
                rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
                rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
                echo "  [OK] Full clean completed"
            else
                echo "  [SKIP] Cancelled"
            fi
            ;;
        3)
            echo ""
            echo "  ${LOG_YELLOW}Deep Clean (includes Docker):${LOG_NC}"
            echo "    - ${target_path}/"
            echo "    - .bootstrap_state"
            echo "    - .omniforge_index"
            echo "    - Docker containers/volumes"
            read -rp "  Confirm? (y/N): " confirm
            if [[ "${confirm,,}" == "y" ]]; then
                rm -rf "$target_path"
                rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
                rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
                # Docker cleanup
                if command -v docker &>/dev/null; then
                    local app_name=$(basename "$target_path")
                    echo "  Stopping containers..."
                    docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                    docker ps -a --filter "name=postgres" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                    echo "  Removing containers..."
                    docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker rm 2>/dev/null || true
                    echo "  Removing volumes..."
                    docker volume ls --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true
                fi
                echo "  [OK] Deep clean completed"
            else
                echo "  [SKIP] Cancelled"
            fi
            ;;
        4)
            echo ""
            echo "  ${LOG_RED}Nuclear Clean (EVERYTHING):${LOG_NC}"
            echo "    - ${target_path}/"
            echo "    - .bootstrap_state"
            echo "    - .omniforge_index"
            echo "    - Docker containers/volumes"
            echo "    - Download cache"
            echo "    - OmniForge logs"
            read -rp "  Type 'NUKE' to confirm: " confirm
            if [[ "$confirm" == "NUKE" ]]; then
                rm -rf "$target_path"
                rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
                rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
                rm -rf "${PROJECT_ROOT:-.}/.omniforge-backup"
                # Docker cleanup
                if command -v docker &>/dev/null; then
                    local app_name=$(basename "$target_path")
                    docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                    docker ps -a --filter "name=postgres" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                    docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker rm 2>/dev/null || true
                    docker volume ls --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true
                fi
                # Cache and logs
                rm -rf "${omniforge_dir}/.download-cache"
                rm -rf "${omniforge_dir}/logs"
                echo "  [OK] Nuclear clean completed - all artifacts removed"
            else
                echo "  [SKIP] Cancelled (did not type NUKE)"
            fi
            ;;
        b|back|*)
            return
            ;;
    esac

    echo ""
    read -rp "  Press Enter to continue: " _
}

# =============================================================================
# DOCKER BOOTSTRAP WIPE (uses docker-deploy scan reports)
# =============================================================================

menu_docker_wipe() {
    local omni_root="${SCRIPTS_DIR:-$(cd -- "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
    local project_root="${PROJECT_ROOT:-$(cd "${omni_root}/../.." && pwd)}"
    local scan_root="${project_root}/_build/docker-deploy"
    local clean_script="${project_root}/_build/scripts/docker-deploy-clean.sh"
    local scan_script="${project_root}/_build/omniforge/scripts/docker-deploy-scan.sh"
    local max_report_age="${MAX_REPORT_AGE_SECONDS:-3600}"
    local docker_available="true"

    if ! command -v docker >/dev/null 2>&1; then
        docker_available="false"
    elif [[ -n "${INSIDE_OMNI_DOCKER:-}" ]]; then
        docker_available="false"
    fi

    _menu_header
    _menu_title "WIPE / ERASE DOCKER BOOTSTRAP"
    echo ""
    echo "  Uses docker-deploy-clean.sh + latest scan report to delete host files"
    echo "  and remove the container, volumes, networks, and report directory."
    echo ""
    if [[ "$docker_available" != "true" ]]; then
        echo "  ${LOG_YELLOW}Docker not available (or running inside container).${LOG_NC} Host Docker is required"
        echo "  for container/volume/network removal. File deletion from reports will still work."
        echo ""
    fi

    if [[ ! -x "$clean_script" ]]; then
        echo "  ${LOG_RED}Clean script not found:${LOG_NC} $clean_script"
        echo "  Run _build/omniforge/scripts/docker-deploy-scan.sh first to generate reports."
        echo ""
        read -rp "  Press Enter to return: " _
        return
    fi

    if [[ ! -d "$scan_root" ]]; then
        echo "  ${LOG_YELLOW}No scan reports found at:${LOG_NC} $scan_root"
        if [[ "$docker_available" == "true" && -f "$scan_script" ]]; then
            echo ""
            read -rp "  Enter container name/id to run a new deploy scan (or leave blank to return): " target
            if [[ -n "$target" ]]; then
                echo ""
                bash "$scan_script" "$target" || true
            fi
        fi
        echo ""
        read -rp "  Press Enter to return: " _
        return
    fi

    local containers=()
    while IFS= read -r dir; do
        containers+=("$(basename "$dir")")
    done < <(find "$scan_root" -maxdepth 1 -mindepth 1 -type d -print 2>/dev/null | sort)

    if [[ ${#containers[@]} -eq 0 ]]; then
        echo "  ${LOG_YELLOW}No container report folders found under${LOG_NC} $scan_root"
        if [[ "$docker_available" == "true" && -f "$scan_script" ]]; then
            echo ""
            read -rp "  Enter container name/id to run a new deploy scan (or leave blank to return): " target
            if [[ -n "$target" ]]; then
                echo ""
                bash "$scan_script" "$target" || true
            fi
        fi
        echo ""
        read -rp "  Press Enter to return: " _
        return
    fi

    echo "  Containers with scan reports:"
    local idx=1
    declare -A CONTAINER_DISPLAY_MAP=()
    for name in "${containers[@]}"; do
        local latest_report
        latest_report="$(ls -1 "$scan_root/$name"/files-created-*.txt 2>/dev/null | sort | tail -n 1 || true)"
        local display="$name"
        if command -v docker >/dev/null 2>&1; then
            local docker_name
            docker_name="$(docker ps -a --format '{{.Names}}' --filter "id=$name" --filter "name=$name" | head -n1 || true)"
            [[ -n "$docker_name" ]] && display="$docker_name"
        fi
        CONTAINER_DISPLAY_MAP["$idx"]="$name|$display|$latest_report"
        if [[ -n "$latest_report" ]]; then
            echo "    ${idx}) ${LOG_CYAN}${display}${LOG_NC}  [latest: $(basename "$latest_report")]"
        else
            echo "    ${idx}) ${LOG_CYAN}${display}${LOG_NC}  [no report files detected]"
        fi
        ((idx++))
    done
    echo ""

    read -rp "  Select container [1-${#containers[@]}] (any other key returns): " choice
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#containers[@]} )); then
        return
    fi

    local map_entry="${CONTAINER_DISPLAY_MAP[$choice]}"
    IFS='|' read -r target target_display latest_report <<<"$map_entry"
    local target_dir="${scan_root}/${target}"
    if [[ -z "$latest_report" ]]; then
        latest_report="$(ls -1 "$target_dir"/files-created-*.txt 2>/dev/null | sort | tail -n 1 || true)"
    fi
    local report_age=""
    local report_age_seconds=""
    local now_epoch
    now_epoch="$(date +%s)"
    if [[ -n "$latest_report" ]]; then
        local mtime
        mtime="$(stat -c '%Y' "$latest_report" 2>/dev/null || echo "")"
        if [[ -n "$mtime" ]]; then
            report_age_seconds=$(( now_epoch - mtime ))
            local h=$(( report_age_seconds / 3600 ))
            local m=$(( (report_age_seconds % 3600) / 60 ))
            local s=$(( report_age_seconds % 60 ))
            report_age=$(printf "%dh %02dm %02ds" "$h" "$m" "$s")
        fi
    fi

    # Offer to run scan if missing or stale
    if [[ -z "$latest_report" || ( -n "$report_age_seconds" && "$report_age_seconds" -gt "$max_report_age" ) ]]; then
        echo ""
        if [[ -z "$latest_report" ]]; then
            echo "  ${LOG_YELLOW}No report found for ${target}.${LOG_NC}"
        else
            echo "  ${LOG_YELLOW}Latest report is stale (${report_age}); max age ${max_report_age}s.${LOG_NC}"
        fi
        if [[ -x "$scan_script" ]]; then
            read -rp "  Run docker-deploy-scan.sh for ${target} now? (y/N): " rescan
            if [[ "${rescan,,}" == "y" || "${rescan,,}" == "yes" ]]; then
                echo ""
                echo "  Running scan for ${target}..."
                if ! "$scan_script" "$target"; then
                    echo "  ${LOG_RED}Scan failed; aborting wipe.${LOG_NC}"
                    read -rp "  Press Enter to return: " _
                    return
                fi
                # Recompute latest report after scan
                latest_report="$(ls -1 "$target_dir"/files-created-*.txt 2>/dev/null | sort | tail -n 1 || true)"
                report_age_seconds=""
                report_age=""
                if [[ -n "$latest_report" ]]; then
                    local mtime_after
                    mtime_after="$(stat -c '%Y' "$latest_report" 2>/dev/null || echo "")"
                    if [[ -n "$mtime_after" ]]; then
                        local now2
                        now2="$(date +%s)"
                        report_age_seconds=$(( now2 - mtime_after ))
                        local h=$(( report_age_seconds / 3600 ))
                        local m=$(( (report_age_seconds % 3600) / 60 ))
                        local s=$(( report_age_seconds % 60 ))
                        report_age=$(printf "%dh %02dm %02ds" "$h" "$m" "$s")
                    fi
                fi
            fi
        else
            echo "  Scan script not found or not executable: $scan_script"
        fi
    fi

    if [[ -z "$latest_report" ]]; then
        echo ""
        echo "  ${LOG_YELLOW}No usable report found; cannot proceed with wipe.${LOG_NC}"
        read -rp "  Press Enter to return: " _
        return
    fi

    echo ""
    echo "  Selected container: ${LOG_CYAN}${target_display:-$target}${LOG_NC}"
    if [[ -n "$latest_report" ]]; then
        if [[ -n "$report_age" ]]; then
            echo "  Latest report: ${latest_report} (age: ${report_age})"
        else
            echo "  Latest report: ${latest_report}"
        fi
    else
        echo "  ${LOG_YELLOW}Warning:${LOG_NC} No files-created-*.txt found for this container."
    fi
    echo ""
    echo "  Planned actions:"
    echo "    - Delete host files listed in latest report"
    echo "    - Stop/remove container"
    echo "    - Remove named volumes"
    echo "    - Remove non-default networks"
    echo "    - Remove report directory"
    echo ""
    echo "  Command:"
    echo "    ${clean_script} --force --remove-docker --remove-networks --remove-report ${target}"
    echo ""

    read -rp "  Type '${target}' to confirm full wipe (or anything else to cancel): " confirm
    if [[ "$confirm" != "$target" ]]; then
        echo "  ${LOG_YELLOW}Cancelled${LOG_NC}"
    else
        echo ""
        "${clean_script}" --force --remove-docker --remove-networks --remove-report "${target}"
    fi

    echo ""
    read -rp "  Press Enter to continue: " _
}

# Non-interactive clean for CLI usage
# Usage: _run_clean_noninteractive <path> <level>
# Levels: 1=quick (app only), 2=full (+state), 3=deep (+docker), 4=nuclear (+cache)
_run_clean_noninteractive() {
    local target_path="$1"
    local clean_level="${2:-1}"

    # Validate path
    if [[ -z "$target_path" ]]; then
        echo "[ERR] No path specified. Use --path <dir>"
        exit 1
    fi

    if [[ ! -d "$target_path" ]]; then
        echo "[ERR] Path does not exist: $target_path"
        exit 1
    fi

    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"

    echo "[INFO] Clean level: $clean_level"
    echo "[INFO] Target: $target_path"

    case "$clean_level" in
        1)
            echo "[INFO] Quick Clean: Deleting app folder only"
            rm -rf "$target_path"
            echo "[OK] Deleted $target_path/"
            ;;
        2)
            echo "[INFO] Full Clean: App folder + state files"
            rm -rf "$target_path"
            rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
            rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
            echo "[OK] Full clean completed"
            ;;
        3)
            echo "[INFO] Deep Clean: Full + Docker resources"
            rm -rf "$target_path"
            rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
            rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
            if command -v docker &>/dev/null; then
                local app_name=$(basename "$target_path")
                echo "[INFO] Stopping Docker containers..."
                docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                docker ps -a --filter "name=postgres" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                echo "[INFO] Removing Docker containers..."
                docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker rm 2>/dev/null || true
                echo "[INFO] Removing Docker volumes..."
                docker volume ls --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true
            fi
            echo "[OK] Deep clean completed"
            ;;
        4)
            echo "[INFO] Nuclear Clean: Everything"
            rm -rf "$target_path"
            rm -f "${PROJECT_ROOT:-.}/.bootstrap_state"
            rm -f "${PROJECT_ROOT:-.}/.omniforge_index"
            rm -rf "${PROJECT_ROOT:-.}/.omniforge-backup"
            if command -v docker &>/dev/null; then
                local app_name=$(basename "$target_path")
                docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                docker ps -a --filter "name=postgres" -q 2>/dev/null | xargs -r docker stop 2>/dev/null || true
                docker ps -a --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker rm 2>/dev/null || true
                docker volume ls --filter "name=${app_name}" -q 2>/dev/null | xargs -r docker volume rm 2>/dev/null || true
            fi
            rm -rf "${omniforge_dir}/.download-cache"
            rm -rf "${omniforge_dir}/logs"
            echo "[OK] Nuclear clean completed"
            ;;
        *)
            echo "[ERR] Invalid clean level: $clean_level (use 1-4)"
            exit 1
            ;;
    esac
}

# =============================================================================
# OPTIONS MENU
# =============================================================================

menu_options() {
    # Initialize log file if not already initialized
    if [[ -z "${LOG_FILE:-}" ]]; then
        if type phase_init_logging &>/dev/null; then
            phase_init_logging
        else
            # Manual initialization if phase function not available
            LOG_DIR="${LOG_DIR:-${TMPDIR:-/tmp}}"
            mkdir -p "$LOG_DIR"
            LOG_FILE="${LOG_DIR}/omniforge_$(date +%Y%m%d_%H%M%S).log"
            touch "$LOG_FILE"
        fi
    fi

    # Config paths for updates
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    local config_path="${OMNI_CONFIG_PATH:-${omniforge_dir}/omni.config}"
    local settings_path="${OMNI_SETTINGS_PATH:-${omniforge_dir}/omni.settings.sh}"

    while true; do
        _menu_header
        _menu_title "OPTIONS"
        echo ""

        # Show install target with path in yellow
        local target_display="${INSTALL_TARGET:-test}"
        local path_display
        if [[ "$target_display" == "prod" ]]; then
            path_display="${LOG_YELLOW}${INSTALL_DIR_PROD:-./app}${LOG_NC}"
        else
            path_display="${LOG_YELLOW}${INSTALL_DIR_TEST:-./test/install-1}${LOG_NC}"
        fi
        echo -e "  1. Install Target              ${target_display} → ${path_display}"

        _menu_item "2" "Default Profile" "BOS profiles: ai_automation, fpa_dashboard, asset_manager..." "[${STACK_PROFILE:-asset_manager}]"
        _menu_item "3" "Log Level" "Verbosity: quiet, status, or verbose" "[${LOG_LEVEL:-status}]"
        _menu_item "4" "Logo Style" "Display style: block, gradient, shadow, simple, minimal" "[${OMNI_LOGO:-block}]"
        _menu_item "5" "Default Timeout" "Max minutes for operations" "[$(( (${MAX_CMD_SECONDS:-300} / 60) )).$(( (${MAX_CMD_SECONDS:-300} % 60) / 6 ))m]"
        _menu_item "6" "Git Safety" "Require clean git working tree before bootstrap" "[${GIT_SAFETY:-true}]"
        _menu_item "7" "View Logs" "Open log file with micro editor" "[$([ -f "${LOG_FILE:-}" ] && wc -l < "${LOG_FILE}" | tr -d ' ' || echo 'empty')]"
        _menu_item "8" "Clear Logs" "Delete all log files" "[$([ -f "${LOG_FILE:-}" ] && basename "${LOG_FILE}" || echo 'empty')]"
        _menu_item "9" "Reset to Defaults" "Restore: test target, asset_manager profile, status log, block logo, 5.0m timeout"
        echo ""
        _menu_item "0" "Back"

        _menu_prompt "Select [0-9]"

        case "$_MENU_SELECTION" in
            1)
                echo ""
                echo "  Current: ${INSTALL_TARGET:-test}"
                echo ""
                echo "  ${LOG_CYAN}1)${LOG_NC} test → ${LOG_YELLOW}${INSTALL_DIR_TEST:-./test/install-1}${LOG_NC}"
                echo "  ${LOG_CYAN}2)${LOG_NC} prod → ${LOG_YELLOW}${INSTALL_DIR_PROD:-./app}${LOG_NC}"
                echo ""
                read -rp "  Select [1-2]: " val
                case "$val" in
                    1|test)
                        INSTALL_TARGET="test"
                        INSTALL_DIR="${INSTALL_DIR_TEST:-./test/install-1}"
                        # Update omni.config
                        if [[ -f "$config_path" ]]; then
                            sed -i.bak 's/^INSTALL_TARGET=.*/INSTALL_TARGET="test"/' "$config_path"
                            rm -f "${config_path}.bak"
                        fi
                        echo "  [OK] Install target set to test"
                        ;;
                    2|prod)
                        INSTALL_TARGET="prod"
                        INSTALL_DIR="${INSTALL_DIR_PROD:-./app}"
                        # Update omni.config
                        if [[ -f "$config_path" ]]; then
                            sed -i.bak 's/^INSTALL_TARGET=.*/INSTALL_TARGET="prod"/' "$config_path"
                            rm -f "${config_path}.bak"
                        fi
                        echo "  [OK] Install target set to prod"
                        ;;
                    *)
                        echo "  [SKIP] No change"
                        ;;
                esac
                sleep 1
                ;;
            2)
                echo ""
                echo "  Current: ${STACK_PROFILE:-asset_manager}"
                echo ""
                local num=1
                for profile in "${AVAILABLE_PROFILES[@]}"; do
                    local name=$(get_profile_metadata "$profile" "name")
                    local tagline=$(get_profile_metadata "$profile" "tagline")
                    local marker=""
                    [[ "$profile" == "${STACK_PROFILE:-}" ]] && marker=" ${LOG_GREEN}[current]${LOG_NC}"
                    echo "  ${LOG_CYAN}${num})${LOG_NC} ${profile}${marker} - ${name:-$profile}"
                    [[ -n "$tagline" ]] && echo "     ${tagline}"
                    ((num++))
                done
                echo ""
                read -rp "  Select [1-${#AVAILABLE_PROFILES[@]}] or name: " val
                local selected=""
                if [[ -z "$val" ]]; then
                    selected="${STACK_PROFILE:-${AVAILABLE_PROFILES[0]}}"
                elif [[ "$val" =~ ^[0-9]+$ ]] && (( val >= 1 && val <= ${#AVAILABLE_PROFILES[@]} )); then
                    selected=$(get_profile_by_number "$val")
                elif [[ "$val" == "custom_bos" ]]; then
                    log_warn "Profile 'custom_bos' was renamed to 'tech_stack'; using tech_stack."
                    selected="tech_stack"
                else
                    for profile in "${AVAILABLE_PROFILES[@]}"; do
                        if [[ "$val" == "$profile" ]]; then
                            selected="$profile"
                            break
                        fi
                    done
                fi
                if [[ -z "$selected" ]]; then
                    echo "  [SKIP] No change"
                    sleep 1
                    continue
                fi
                STACK_PROFILE="$selected"
                # Update omni.config
                if [[ -f "$config_path" ]]; then
                    sed -i.bak "s/^STACK_PROFILE=.*/STACK_PROFILE=\"${STACK_PROFILE}\"/" "$config_path"
                    rm -f "${config_path}.bak"
                fi
                echo "  [OK] Profile set to ${STACK_PROFILE}"
                sleep 1
                ;;
            3)
                echo ""
                echo "  Current: ${LOG_LEVEL:-status}"
                echo ""
                echo "  ${LOG_CYAN}1)${LOG_NC} quiet   - Errors only"
                echo "  ${LOG_CYAN}2)${LOG_NC} status  - Progress updates"
                echo "  ${LOG_CYAN}3)${LOG_NC} verbose - Detailed output"
                echo ""
                read -rp "  Select [1-3]: " val
                case "$val" in
                    1) LOG_LEVEL="quiet" ;;
                    2) LOG_LEVEL="status" ;;
                    3) LOG_LEVEL="verbose" ;;
                    *) echo "  [SKIP] No change"; sleep 1; continue ;;
                esac
                if [[ -f "$settings_path" ]]; then
                    sed -i.bak "s/^LOG_LEVEL=.*/LOG_LEVEL=\"${LOG_LEVEL}\"/" "$settings_path"
                    rm -f "${settings_path}.bak"
                fi
                echo "  [OK] Log level set to ${LOG_LEVEL}"
                sleep 1
                ;;
            4)
                echo ""
                echo "  Current: ${OMNI_LOGO:-block}"
                echo ""
                echo "  ${LOG_CYAN}1)${LOG_NC} block    - Full ASCII art"
                echo "  ${LOG_CYAN}2)${LOG_NC} gradient - Gradient effect"
                echo "  ${LOG_CYAN}3)${LOG_NC} shadow   - Shadow effect"
                echo "  ${LOG_CYAN}4)${LOG_NC} simple   - Simple text"
                echo "  ${LOG_CYAN}5)${LOG_NC} minimal  - Minimal text"
                echo "  ${LOG_CYAN}6)${LOG_NC} none     - No logo"
                echo ""
                read -rp "  Select [1-6]: " val
                case "$val" in
                    1) OMNI_LOGO="block" ;;
                    2) OMNI_LOGO="gradient" ;;
                    3) OMNI_LOGO="shadow" ;;
                    4) OMNI_LOGO="simple" ;;
                    5) OMNI_LOGO="minimal" ;;
                    6) OMNI_LOGO="none" ;;
                    *) echo "  [SKIP] No change"; sleep 1; continue ;;
                esac
                if [[ -f "$settings_path" ]]; then
                    sed -i.bak "s/^OMNI_LOGO=.*/OMNI_LOGO=\"${OMNI_LOGO}\"/" "$settings_path"
                    rm -f "${settings_path}.bak"
                fi
                echo "  [OK] Logo style set to ${OMNI_LOGO}"
                sleep 1
                ;;
            5)
                echo ""
                echo "  Current: $(( (${MAX_CMD_SECONDS:-300} / 60) )) minutes"
                echo ""
                echo "  ${LOG_CYAN}1)${LOG_NC} 2 min   - Quick operations"
                echo "  ${LOG_CYAN}2)${LOG_NC} 5 min   - Standard (default)"
                echo "  ${LOG_CYAN}3)${LOG_NC} 10 min  - Extended"
                echo "  ${LOG_CYAN}4)${LOG_NC} 15 min  - Long running"
                echo "  ${LOG_CYAN}5)${LOG_NC} Custom  - Enter value"
                echo ""
                read -rp "  Select [1-5]: " val
                case "$val" in
                    1) MAX_CMD_SECONDS=120 ;;
                    2) MAX_CMD_SECONDS=300 ;;
                    3) MAX_CMD_SECONDS=600 ;;
                    4) MAX_CMD_SECONDS=900 ;;
                    5)
                        read -rp "  Enter minutes (e.g., 7.5): " mins
                        if [[ -n "$mins" ]]; then
                            MAX_CMD_SECONDS=$(echo "$mins * 60" | bc 2>/dev/null || echo "300")
                        fi
                        ;;
                    *) echo "  [SKIP] No change"; sleep 1; continue ;;
                esac
                if [[ -f "$settings_path" ]]; then
                    sed -i.bak "s/^MAX_CMD_SECONDS=.*/MAX_CMD_SECONDS=\"${MAX_CMD_SECONDS}\"/" "$settings_path"
                    rm -f "${settings_path}.bak"
                fi
                echo "  [OK] Timeout set to $(( MAX_CMD_SECONDS / 60 )) min"
                sleep 1
                ;;
            6)
                echo ""
                echo "  Current: ${GIT_SAFETY:-true}"
                echo ""
                echo "  ${LOG_CYAN}1)${LOG_NC} true  - Require clean git state"
                echo "  ${LOG_CYAN}2)${LOG_NC} false - Skip git check"
                echo ""
                read -rp "  Select [1-2]: " val
                case "$val" in
                    1) GIT_SAFETY="true" ;;
                    2) GIT_SAFETY="false" ;;
                    *) echo "  [SKIP] No change"; sleep 1; continue ;;
                esac
                if [[ -f "$settings_path" ]]; then
                    sed -i.bak "s/^GIT_SAFETY=.*/GIT_SAFETY=\"${GIT_SAFETY}\"/" "$settings_path"
                    rm -f "${settings_path}.bak"
                fi
                echo "  [OK] Git safety set to ${GIT_SAFETY}"
                sleep 1
                ;;
            7)
                # View Logs - submenu to select log file
                echo ""
                echo "  ${LOG_CYAN}Select Log File${LOG_NC}"
                echo ""

                # Collect all log files from various locations
                local log_files=()
                local log_num=1

                # Current session log
                if [[ -n "${LOG_FILE:-}" && -f "$LOG_FILE" ]]; then
                    local lines=$(wc -l < "$LOG_FILE" | tr -d ' ')
                    echo "  ${LOG_CYAN}${log_num})${LOG_NC} ${LOG_GREEN}[current]${LOG_NC} $(basename "$LOG_FILE") (${lines} lines)"
                    log_files+=("$LOG_FILE")
                    ((log_num++))
                fi

                # OmniForge logs directory
                if [[ -d "${omniforge_dir}/logs" ]]; then
                    while IFS= read -r -d '' logfile; do
                        # Skip if it's the current log (already listed)
                        [[ "$logfile" == "${LOG_FILE:-}" ]] && continue
                        local fname=$(basename "$logfile")
                        local flines=$(wc -l < "$logfile" 2>/dev/null | tr -d ' ')
                        local fsize=$(du -h "$logfile" 2>/dev/null | cut -f1)
                        echo "  ${LOG_CYAN}${log_num})${LOG_NC} ${fname} (${flines} lines, ${fsize})"
                        log_files+=("$logfile")
                        ((log_num++))
                    done < <(find "${omniforge_dir}/logs" -name "*.log" -type f -print0 2>/dev/null | sort -z)
                fi

                # Temp directory logs
                local temp_log_dir="${LOG_DIR:-${TMPDIR:-/tmp}}"
                if [[ -d "$temp_log_dir" ]]; then
                    while IFS= read -r -d '' logfile; do
                        # Skip if already listed
                        [[ " ${log_files[*]} " == *" $logfile "* ]] && continue
                        local fname=$(basename "$logfile")
                        local flines=$(wc -l < "$logfile" 2>/dev/null | tr -d ' ')
                        echo "  ${LOG_CYAN}${log_num})${LOG_NC} ${LOG_YELLOW}[temp]${LOG_NC} ${fname} (${flines} lines)"
                        log_files+=("$logfile")
                        ((log_num++))
                    done < <(find "$temp_log_dir" -maxdepth 1 -name "omniforge_*.log" -type f -print0 2>/dev/null | sort -z)
                fi

                if [[ ${#log_files[@]} -eq 0 ]]; then
                    echo "  ${LOG_GRAY}No log files found.${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                else
                    echo ""
                    echo "  b) Back"
                    echo ""
                    read -rp "  Select [1-$((log_num-1))]: " val

                    if [[ "$val" =~ ^[0-9]+$ ]] && [[ $val -ge 1 ]] && [[ $val -lt $log_num ]]; then
                        local selected_log="${log_files[$((val-1))]}"
                        if command -v micro &>/dev/null; then
                            micro "$selected_log"
                        elif [[ "$OSTYPE" == "darwin"* ]]; then
                            open "$selected_log"
                        elif command -v xdg-open &>/dev/null; then
                            xdg-open "$selected_log"
                        else
                            less "$selected_log"
                        fi
                    fi
                fi
                ;;
            8)
                # Clear Logs - all log types
                echo ""
                echo "  ${LOG_CYAN}Clear Log Files${LOG_NC}"
                echo ""

                # Count logs in each location
                local temp_log_dir="${LOG_DIR:-${TMPDIR:-/tmp}}"
                local temp_count=$(find "$temp_log_dir" -maxdepth 1 -name "omniforge_*.log" 2>/dev/null | wc -l | tr -d ' ')
                local omni_count=0
                local download_count=0

                if [[ -d "${omniforge_dir}/logs" ]]; then
                    omni_count=$(find "${omniforge_dir}/logs" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
                fi

                # Check for download logs in various locations
                if [[ -d "${omniforge_dir}/.download-cache" ]]; then
                    download_count=$(find "${omniforge_dir}/.download-cache" -name "*.log" 2>/dev/null | wc -l | tr -d ' ')
                fi

                local total=$((temp_count + omni_count + download_count))

                if [[ $total -eq 0 ]]; then
                    echo "  ${LOG_GRAY}No log files found.${LOG_NC}"
                    read -rp "  Press Enter to continue: " _
                else
                    echo "  Found log files:"
                    [[ $temp_count -gt 0 ]] && echo "    - ${temp_count} session log(s) in temp"
                    [[ $omni_count -gt 0 ]] && echo "    - ${omni_count} log(s) in _build/omniforge/logs/"
                    [[ $download_count -gt 0 ]] && echo "    - ${download_count} download log(s)"
                    echo ""
                    echo "  ${LOG_CYAN}1)${LOG_NC} Clear session logs only (${temp_count})"
                    echo "  ${LOG_CYAN}2)${LOG_NC} Clear omniforge logs only (${omni_count})"
                    echo "  ${LOG_CYAN}3)${LOG_NC} Clear download logs only (${download_count})"
                    echo "  ${LOG_CYAN}4)${LOG_NC} Clear ALL logs (${total})"
                    echo ""
                    echo "  b) Back"
                    echo ""
                    read -rp "  Select [1-4]: " val

                    case "$val" in
                        1)
                            find "$temp_log_dir" -maxdepth 1 -name "omniforge_*.log" -delete 2>/dev/null
                            echo "  [OK] Session logs cleared"
                            ;;
                        2)
                            [[ -d "${omniforge_dir}/logs" ]] && find "${omniforge_dir}/logs" -name "*.log" -delete 2>/dev/null
                            echo "  [OK] OmniForge logs cleared"
                            ;;
                        3)
                            [[ -d "${omniforge_dir}/.download-cache" ]] && find "${omniforge_dir}/.download-cache" -name "*.log" -delete 2>/dev/null
                            echo "  [OK] Download logs cleared"
                            ;;
                        4)
                            find "$temp_log_dir" -maxdepth 1 -name "omniforge_*.log" -delete 2>/dev/null
                            [[ -d "${omniforge_dir}/logs" ]] && find "${omniforge_dir}/logs" -name "*.log" -delete 2>/dev/null
                            [[ -d "${omniforge_dir}/.download-cache" ]] && find "${omniforge_dir}/.download-cache" -name "*.log" -delete 2>/dev/null
                            echo "  [OK] All logs cleared"
                            ;;
                        *)
                            echo "  [SKIP] No change"
                            ;;
                    esac
                fi
                sleep 1
                ;;
            9)
                INSTALL_TARGET="test"
                STACK_PROFILE="standard"
                LOG_LEVEL="status"
                OMNI_LOGO="block"
                MAX_CMD_SECONDS="300"
                GIT_SAFETY="true"
                INSTALL_DIR="${INSTALL_DIR_TEST:-./test/install-1}"
                # Update omni.config and omni.settings with defaults
                if [[ -f "$config_path" ]]; then
                    sed -i.bak 's/^INSTALL_TARGET=.*/INSTALL_TARGET="test"/' "$config_path"
                    sed -i.bak 's/^STACK_PROFILE=.*/STACK_PROFILE="standard"/' "$config_path"
                    rm -f "${config_path}.bak"
                fi
                if [[ -f "$settings_path" ]]; then
                    sed -i.bak 's/^LOG_LEVEL=.*/LOG_LEVEL="status"/' "$settings_path"
                    sed -i.bak 's/^OMNI_LOGO=.*/OMNI_LOGO="block"/' "$settings_path"
                    sed -i.bak 's/^MAX_CMD_SECONDS=.*/MAX_CMD_SECONDS="300"/' "$settings_path"
                    sed -i.bak 's/^GIT_SAFETY=.*/GIT_SAFETY="true"/' "$settings_path"
                    rm -f "${settings_path}.bak"
                fi
                echo "  [OK] Reset to defaults"
                sleep 1
                ;;
            *) return ;;  # Any other key returns to parent
        esac
    done
}

# =============================================================================
# HELP MENU
# =============================================================================

menu_help() {
    _menu_header
    _menu_title "HELP"
    echo ""
    echo "  ${LOG_CYAN}CLI Help (omni.sh --help):${LOG_NC}"
    echo "    COMMANDS:"
    echo "      menu            Interactive menu (default)"
    echo "      run             Execute bootstrap phases (omni.phases.sh)"
    echo "      clean           Clean/reset an installation (levels 1-4)"
    echo "      list            List all phases (read-only)"
    echo "      status          Show completion status/config"
    echo "      stack           Docker helpers: up/down/ps (host)"
    echo "      docker-wipe     Full wipe using latest deploy scan (host files + docker resources + report)"
    echo "      build           Build/verify project"
    echo "      reset           Reset last deployment"
    echo ""
    echo "    OPTIONS:"
    echo "      -h, --help      Show CLI help"
    echo "      -n, --dry-run   Preview bootstrap/build without executing"
    echo "      -v, --verbose   Verbose output"
    echo "      -p, --phase N   Run only phase N (0-5)"
    echo "      -f, --force     Force re-run (ignore state)"
    echo "      --path <dir>    Target path (clean)"
    echo "      --level <1-4>   Clean level"
    echo "      --yes           Skip confirmations (reset)"
    echo "      --container <c> Container (docker-wipe)"
    echo ""
    echo "    EXAMPLES:"
    echo "      omni --run"
    echo "      omni --run --dry-run"
    echo "      omni run --phase 0"
    echo "      omni clean --path ./test/install-1 --level 2"
    echo "      omni docker-wipe --container bloom2_app --force"
    echo ""
    echo "  Docs:"
    echo "    - _build/omniforge/OMNIFORGE.md (entry point)"
    echo "    - _build/omniforge/docs/ (feature docs)"
    echo ""

    _menu_line
    read -rp "  Press Enter to return to menu: " _
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/common.sh" 2>/dev/null || {
        echo "Error: Could not load common.sh"
        exit 1
    }
    menu_main
fi
