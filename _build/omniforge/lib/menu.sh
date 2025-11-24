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

        _menu_item "1" "Bootstrap Project" "Select apps, configure, install"
        _menu_item "2" "IDE Settings Manager" "Copy IDE/tool configs to project"
        _menu_item "3" "Purge Download Cache" "Clear cached packages" "[$cache_size]"
        _menu_item "4" "OmniForge Options" "Preferences and defaults"
        _menu_item "5" "Help" "Usage guide and documentation"
        _menu_item "0" "Exit"

        _menu_prompt "Select [0-5]"

        case "$_MENU_SELECTION" in
            1) menu_bootstrap ;;
            2) menu_settings ;;
            3) menu_purge ;;
            4) menu_options ;;
            5) menu_help ;;
            *) _MENU_RUNNING=false ;;  # Any other key exits
        esac
    done

    echo ""
    log_info "Goodbye!"
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
    # Load profile definitions from bootstrap.conf
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    local bootstrap_conf="${omniforge_dir}/bootstrap.conf"

    if [[ -f "$bootstrap_conf" ]]; then
        source "$bootstrap_conf"
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
        local time=$(get_profile_metadata "$profile" "time_estimate")
        local recommended=$(get_profile_metadata "$profile" "recommended")

        # Format with recommendation indicator
        local marker=""
        [[ "$recommended" == "true" ]] && marker=" ⭐"

        echo "  ${LOG_CYAN}${profile_num}) ${name}${marker}${LOG_NC} - ${tagline}"
        echo "     ${description}"
        echo "     Time: ${time}"
        echo ""

        ((profile_num++))
    done

    _display_installation_plan

    echo "  You can customize individual features in the next step."
    echo ""
    _menu_line
    read -rp "  Select profile [1-${#AVAILABLE_PROFILES[@]}] (default: 3): " choice

    case "$choice" in
        [1-5])
            # Numeric input: convert to profile name and apply
            local selected_profile
            selected_profile=$(get_profile_by_number "$choice")
            if [[ -z "$selected_profile" ]]; then
                log_error "Invalid profile number: $choice"
                return 1
            fi
            export STACK_PROFILE="$selected_profile"
            apply_stack_profile "$selected_profile" || return 1
            ;;
        minimal|api-only|full|ai-focused|enterprise)
            # Direct profile name input
            export STACK_PROFILE="$choice"
            apply_stack_profile "$choice" || return 1
            ;;
        "")
            # Default to full profile
            export STACK_PROFILE="full"
            apply_stack_profile "full" || return 1
            ;;
        b|back|q|quit)
            return 1
            ;;
        *)
            log_warn "Invalid selection. Using full profile as default."
            export STACK_PROFILE="full"
            apply_stack_profile "full" || return 1
            ;;
    esac

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
        echo "  Enter feature number to toggle, preset letter, or 'done' when ready:"
        echo ""
        _menu_line
    }

    _customize_show

    while true; do
        read -rp "  Toggle [1-9], preset, or 'done': " choice

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
            done|d|"")
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
    # Load configuration from bootstrap.conf if available
    local script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    local omniforge_dir="$(cd "${script_dir}/.." && pwd)"
    local bootstrap_conf="${omniforge_dir}/bootstrap.conf"

    if [[ -f "$bootstrap_conf" ]]; then
        source "$bootstrap_conf"
    fi

    # Initialize with values from bootstrap.conf (or defaults if not set)
    APP_NAME="${APP_NAME:-bloom2}"
    DB_NAME="${DB_NAME:-bloom2_db}"
    DB_USER="${DB_USER:-bloom2}"
    DB_PASSWORD="${DB_PASSWORD:-change_me}"
    DB_PORT="${DB_PORT:-5432}"
    DB_HOST="${DB_HOST:-localhost}"
    BACKUP_LOCATION="${BACKUP_LOCATION:-./backups}"
    ENABLE_AUTO_BACKUP="${ENABLE_AUTO_BACKUP:-true}"

    _show_config() {
        _menu_header
        _menu_title "BOOTSTRAP PROJECT - Step 4/7: Configure PostgreSQL & Application"
        echo ""
        echo "  ${LOG_CYAN}PostgreSQL Connection Details${LOG_NC}"
        _menu_line "─" 66
        echo ""

        echo "  Step 1/4: Application Identity"
        echo ""
        echo "    Application Name [${APP_NAME}]"
        echo "    Project Root:              ${PROJECT_ROOT:-.}"
        echo ""

        echo "  Step 2/4: PostgreSQL Database"
        echo ""
        echo "    Database Name [${DB_NAME}]"
        echo "    Database User [${DB_USER}]"
        echo "    Database Password:        $([ -n "$DB_PASSWORD" ] && echo "••••••••" || echo "[not set]")"
        echo "    Database Port [${DB_PORT}]"
        echo "    PostgreSQL Host [${DB_HOST}]"
        echo ""

        echo "  Step 3/4: Data & Backups"
        echo ""
        echo "    Backup Location [${BACKUP_LOCATION}]"
        echo "    Enable Auto-Backups? [${ENABLE_AUTO_BACKUP}]"
        echo ""

        echo "  Step 4/4: Application Features"
        echo ""
        echo "    Features enabled:"
        [[ "${ENABLE_NEXTJS:-true}" == "true" ]] && echo "      ✓ ENABLE_NEXTJS" || echo "      ✗ ENABLE_NEXTJS"
        [[ "${ENABLE_DATABASE:-true}" == "true" ]] && echo "      ✓ ENABLE_DATABASE" || echo "      ✗ ENABLE_DATABASE"
        [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && echo "      ✓ ENABLE_AUTHJS          (Authentication)" || echo "      ✗ ENABLE_AUTHJS"
        [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && echo "      ✓ ENABLE_AI_SDK          (AI Integration)" || echo "      ✗ ENABLE_AI_SDK"
        [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "      ✓ ENABLE_PG_BOSS         (Job Queue)" || echo "      ✗ ENABLE_PG_BOSS"
        [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "      ✓ ENABLE_SHADCN          (UI Components)" || echo "      ✗ ENABLE_SHADCN"
        [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "      ✓ ENABLE_PDF_EXPORTS" || echo "      ✗ ENABLE_PDF_EXPORTS"
        [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && echo "      ✓ ENABLE_TEST_INFRA      (Testing)" || echo "      ✗ ENABLE_TEST_INFRA"
        [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "      ✓ ENABLE_CODE_QUALITY    (Linting & Formatting)" || echo "      ✗ ENABLE_CODE_QUALITY"
        echo ""
        echo ""

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
        echo "      Connection:       ${LOG_GREEN}postgresql://${DB_USER}@${DB_HOST}:${DB_PORT}/${DB_NAME}${LOG_NC}"
        echo ""
        echo "  💾 Backups"
        echo "      Location:         ${BACKUP_LOCATION}"
        echo "      Auto-Backup:      $([ "$ENABLE_AUTO_BACKUP" == "true" ] && echo "Enabled (Daily)" || echo "Disabled")"
        echo ""

        echo ""
        echo "  ${LOG_CYAN}Installation Plan (By Phase)${LOG_NC}"
        _menu_line "─" 66
        echo ""

        echo "  ${LOG_CYAN}Phase 0: Project Foundation${LOG_NC} (5m)"
        if [[ "${ENABLE_NEXTJS:-true}" == "true" ]]; then
            echo "    ✓ Initialize Next.js & TypeScript"
            echo "    ✓ Setup project structure"
        fi
        echo ""

        echo "  ${LOG_CYAN}Phase 1: Infrastructure & Database${LOG_NC} (20m)"
        if [[ "${ENABLE_DATABASE:-true}" == "true" ]]; then
            echo "    ✓ Docker configuration"
            echo "    ✓ PostgreSQL 16 setup"
            echo "    ✓ Drizzle ORM & migrations"
            echo "    ✓ Environment variables"
        fi
        echo ""

        echo "  ${LOG_CYAN}Phase 2: Core Features${LOG_NC} (15m)"
        [[ "${ENABLE_AUTHJS:-true}" == "true" ]] && echo "    ✓ Authentication (Auth.js)"
        [[ "${ENABLE_AI_SDK:-true}" == "true" ]] && echo "    ✓ AI/LLM Integration"
        [[ "${ENABLE_PG_BOSS:-false}" == "true" ]] && echo "    ✓ Background Jobs (pg-boss)"
        echo "    ✓ State Management (Zustand)"
        echo "    ✓ Logging (Pino)"
        echo ""

        echo "  ${LOG_CYAN}Phase 3: User Interface${LOG_NC} (10m)"
        [[ "${ENABLE_SHADCN:-true}" == "true" ]] && echo "    ✓ shadcn/ui Components" || echo "    ✗ UI Components (skipped)"
        echo ""

        echo "  ${LOG_CYAN}Phase 4: Extensions & Quality${LOG_NC} (30m optional)"
        [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && echo "    ✓ PDF/Excel Export System"
        [[ "${ENABLE_TEST_INFRA:-true}" == "true" ]] && echo "    ✓ Testing (Vitest + Playwright)"
        [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && echo "    ✓ Code Quality (ESLint + Prettier)"
        echo ""

        local total_time="~80m"
        [[ "${ENABLE_PDF_EXPORTS:-false}" == "true" ]] && [[ "${ENABLE_CODE_QUALITY:-false}" == "true" ]] && total_time="~110m"
        echo "  ${LOG_GREEN}Total Installation Time: ${total_time}${LOG_NC}"
        echo ""

        echo ""
        _menu_line "─" 66
        echo ""
        echo "  [ENTER] Continue  [e] Edit bootstrap.conf  [r] Refresh  [b] Back"
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
                # Edit bootstrap.conf directly
                if command -v micro &>/dev/null; then
                    micro "$bootstrap_conf"
                elif command -v nano &>/dev/null; then
                    nano "$bootstrap_conf"
                else
                    log_warn "No editor found (tried micro, nano)"
                    read -rp "  Press Enter to continue: " _
                fi
                # Reload configuration
                source "$bootstrap_conf" 2>/dev/null
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
                # Reload from bootstrap.conf
                source "$bootstrap_conf" 2>/dev/null
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

                # Update bootstrap.conf with new values
                if [[ -f "$bootstrap_conf" ]]; then
                    # Create a temporary file with updated values
                    local temp_conf="${bootstrap_conf}.tmp.$$"
                    cp "$bootstrap_conf" "$temp_conf"

                    # Update each variable in the temporary file
                    sed -i.bak "s/^APP_NAME=.*/APP_NAME=\"${APP_NAME}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_NAME=.*/DB_NAME=\"${DB_NAME}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_USER=.*/DB_USER=\"${DB_USER}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_PASSWORD=.*/DB_PASSWORD=\"${DB_PASSWORD}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_PORT=.*/DB_PORT=\"${DB_PORT}\"/" "$temp_conf"
                    sed -i.bak "s/^DB_HOST=.*/DB_HOST=\"${DB_HOST}\"/" "$temp_conf"
                    sed -i.bak "s/^BACKUP_LOCATION=.*/BACKUP_LOCATION=\"${BACKUP_LOCATION}\"/" "$temp_conf"
                    sed -i.bak "s/^ENABLE_AUTO_BACKUP=.*/ENABLE_AUTO_BACKUP=\"${ENABLE_AUTO_BACKUP}\"/" "$temp_conf"

                    # Remove backup files and move temp to actual config
                    rm -f "${temp_conf}.bak"
                    mv "$temp_conf" "$bootstrap_conf"
                fi

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

    # Run preflight checks
    local errors=0

    echo "  ${LOG_CYAN}Required Tools${LOG_NC}"
    echo ""

    # Check Node.js
    if command -v node &>/dev/null; then
        local node_ver=$(node --version)
        echo "  [OK] Node.js ${node_ver}"
        echo "       → Required for: Next.js framework"
    else
        echo "  [FAIL] Node.js not found - Required (v${NODE_VERSION:-20}+)"
        echo "       → Download: https://nodejs.org"
        ((errors++))
    fi
    echo ""

    # Check pnpm
    if command -v pnpm &>/dev/null; then
        local pnpm_ver=$(pnpm --version)
        echo "  [OK] pnpm ${pnpm_ver}"
        echo "       → Required for: Package management (faster than npm)"
    else
        echo "  [FAIL] pnpm not found - Required"
        echo "       → Install: npm install -g pnpm"
        ((errors++))
    fi
    echo ""

    # Check git
    if command -v git &>/dev/null; then
        echo "  [OK] git installed"
        echo "       → Required for: Version control & .gitignore"
    else
        echo "  [FAIL] git not found - Required"
        echo "       → Download: https://git-scm.com"
        ((errors++))
    fi
    echo ""

    # Check Docker (optional)
    if command -v docker &>/dev/null; then
        echo "  [OK] Docker installed"
        echo "       → Required for: PostgreSQL container (Phase 1)"
    else
        echo "  [WARN] Docker not found - Optional"
        echo "       → If skipped: install PostgreSQL 16 locally"
        echo "       → Download: https://www.docker.com"
    fi
    echo ""

    echo "  ${LOG_CYAN}Configuration Validation${LOG_NC}"
    echo ""

    # Validate config
    if type config_validate_all &>/dev/null; then
        if config_validate_all; then
            echo "  [OK] bootstrap.conf is valid"
            echo "       → APP_NAME, DB config, features loaded"
        else
            echo "  [FAIL] Configuration errors in bootstrap.conf"
            ((errors++))
        fi
    else
        echo "  [SKIP] Config validation not available"
    fi

    echo ""
    echo "  ${LOG_CYAN}Installation Summary${LOG_NC}"
    _menu_line "─" 66
    echo ""
    echo "  Ready to install ${STACK_PROFILE:-full} stack:"
    echo "    • App: ${APP_NAME} → ${INSTALL_DIR}"
    echo "    • DB: ${DB_NAME} (${DB_USER}@${DB_HOST}:${DB_PORT})"
    echo "    • Backups: ${BACKUP_LOCATION}"
    echo ""
    _menu_line

    if [[ $errors -gt 0 ]]; then
        echo ""
        echo "  ⚠️  ${errors} error(s) found. Please fix before continuing."
        echo ""
        read -rp "  Press Enter to retry, 'b' to go back: " choice
        [[ "$choice" == "b" ]] && return 1
        return 1  # Retry this step
    fi

    echo ""
    read -rp "  ✓ All checks passed! Press Enter to begin installation, 'b' to go back: " choice
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
    _menu_item "0" "Back"

    _menu_prompt "Select [0-7]"

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

    while true; do
        _menu_header
        _menu_title "OPTIONS"
        echo ""

        _menu_item "1" "Install Target" "Choose test (./test/install-1) or prod (./app)" "[${INSTALL_TARGET:-test}]"
        _menu_item "2" "Default Profile" "Feature set: minimal, api-only, or full stack" "[${STACK_PROFILE:-full}]"
        _menu_item "3" "Log Level" "Verbosity: quiet, status, or verbose" "[${LOG_LEVEL:-status}]"
        _menu_item "4" "Logo Style" "Display style: block, gradient, shadow, simple, minimal" "[${OMNI_LOGO:-block}]"
        _menu_item "5" "Default Timeout" "Max minutes for operations" "[$(( (${MAX_CMD_SECONDS:-300} / 60) )).$(( (${MAX_CMD_SECONDS:-300} % 60) / 6 ))m]"
        _menu_item "6" "Git Safety" "Require clean git working tree before bootstrap" "[${GIT_SAFETY:-true}]"
        _menu_item "7" "View Logs" "Open log file with micro editor" "[$([ -f "${LOG_FILE:-}" ] && wc -l < "${LOG_FILE}" | tr -d ' ' || echo 'empty')]"
        _menu_item "8" "Clear Logs" "Delete all log files" "[$([ -f "${LOG_FILE:-}" ] && basename "${LOG_FILE}" || echo 'empty')]"
        _menu_item "9" "Reset to Defaults" "Restore: test target, full profile, status log, block logo, 5.0m timeout, git safety on"
        echo ""
        _menu_item "0" "Back"

        _menu_prompt "Select [0-9]"

        case "$_MENU_SELECTION" in
            1)
                echo ""
                echo "  Targets: test (./test/install-1), prod (./app)"
                read -rp "  New target: " val
                if [[ "$val" == "test" || "$val" == "prod" ]]; then
                    INSTALL_TARGET="$val"
                    [[ "$val" == "prod" ]] && INSTALL_DIR="./app" || INSTALL_DIR="./test/install-1"
                fi
                ;;
            2)
                echo ""
                echo "  Profiles: minimal, api-only, full"
                read -rp "  New profile: " val
                [[ -n "$val" ]] && STACK_PROFILE="$val"
                ;;
            3)
                echo ""
                echo "  Levels: quiet, status, verbose"
                read -rp "  New level: " val
                [[ -n "$val" ]] && LOG_LEVEL="$val"
                ;;
            4)
                echo ""
                echo "  Styles: block, gradient, shadow, simple, minimal, none"
                read -rp "  New style: " val
                [[ -n "$val" ]] && OMNI_LOGO="$val"
                ;;
            5)
                read -rp "  Timeout (minutes, e.g., 5.5): " val
                if [[ -n "$val" ]]; then
                    # Convert minutes to seconds: multiply by 60
                    MAX_CMD_SECONDS=$(echo "$val * 60" | bc 2>/dev/null || echo "300")
                fi
                ;;
            6)
                if [[ "${GIT_SAFETY:-true}" == "true" ]]; then
                    GIT_SAFETY="false"
                else
                    GIT_SAFETY="true"
                fi
                ;;
            7)
                # View Logs
                if [[ -z "${LOG_FILE:-}" ]]; then
                    echo ""
                    echo "  [WARN] No log file initialized"
                    read -rp "  Press Enter to continue: " _
                else
                    echo ""
                    if [[ -f "$LOG_FILE" ]]; then
                        if command -v micro &>/dev/null; then
                            micro "$LOG_FILE"
                        else
                            # Fallback to default viewer
                            if [[ "$OSTYPE" == "darwin"* ]]; then
                                open "$LOG_FILE"
                            elif command -v xdg-open &>/dev/null; then
                                xdg-open "$LOG_FILE"
                            else
                                less "$LOG_FILE"
                            fi
                        fi
                    else
                        echo "  [WARN] Log file not found: $LOG_FILE"
                        read -rp "  Press Enter to continue: " _
                    fi
                fi
                ;;
            8)
                # Clear Logs
                echo ""
                if [[ -z "${LOG_DIR:-}" ]]; then
                    LOG_DIR="${TMPDIR:-/tmp}"
                fi

                log_count=$(find "$LOG_DIR" -name "omniforge_*.log" 2>/dev/null | wc -l)
                if [[ $log_count -eq 0 ]]; then
                    echo "  [INFO] No log files to clear"
                else
                    echo "  Found $log_count log file(s) in $LOG_DIR"
                    read -rp "  Delete all omniforge logs? (y/N): " confirm
                    if [[ "${confirm,,}" == "y" ]]; then
                        find "$LOG_DIR" -name "omniforge_*.log" -delete 2>/dev/null
                        echo "  [OK] Log files cleared"
                    else
                        echo "  [SKIP] Operation cancelled"
                    fi
                fi
                sleep 1
                ;;
            9)
                INSTALL_TARGET="test"
                STACK_PROFILE="full"
                LOG_LEVEL="status"
                OMNI_LOGO="block"
                MAX_CMD_SECONDS="300"
                GIT_SAFETY="true"
                INSTALL_DIR="./test/install-1"
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
    echo "  OmniForge is a project initialization framework that sets up"
    echo "  a Next.js + TypeScript + PostgreSQL + AI stack."
    echo ""
    echo "  WORKFLOWS:"
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  1. Bootstrap - Full project setup workflow"
    echo "     • Select which features to install"
    echo "     • Configure project variables"
    echo "     • Run preflight checks"
    echo "     • Install all components"
    echo ""
    echo "  2. IDE Settings Manager - Copy IDE/tool configurations"
    echo "     • VS Code, Cursor, GitHub workflows"
    echo "     • Test configs (Playwright, Vitest)"
    echo ""
    echo "  3. Options - Customize defaults"
    echo "     • Change logo style, log level"
    echo "     • Set default profile"
    echo ""
    echo "  CLI USAGE:"
    echo "  ─────────────────────────────────────────────────────────────"
    echo "  omni              # Interactive menu (default)"
    echo "  omni --init       # Direct bootstrap (skip menu)"
    echo "  omni --settings   # Direct settings manager"
    echo "  omni --help       # Show help"
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
