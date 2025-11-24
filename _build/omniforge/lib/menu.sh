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

# Show a menu item
_menu_item() {
    local num="$1"
    local label="$2"
    local desc="${3:-}"
    local extra="${4:-}"

    # Format: "  1. Label" with optional description indented on next line
    printf "  %s. %s\n" "$num" "$label"
    if [[ -n "$desc" ]]; then
        printf "     %s" "${LOG_GRAY:-}$desc"
        if [[ -n "$extra" ]]; then
            printf " %s" "$extra"
        fi
        printf "%s\n" "${LOG_NC:-}"
    fi
}

# Show prompt and get input
_menu_prompt() {
    local prompt="${1:-Select}"
    local default="${2:-}"

    echo ""
    _menu_line "─" 66

    if [[ -n "$default" ]]; then
        read -rp "  $prompt [$default]: " _MENU_SELECTION
        _MENU_SELECTION="${_MENU_SELECTION:-$default}"
    else
        read -rp "  $prompt: " _MENU_SELECTION
    fi

    echo "  ${LOG_GRAY}(press any other key to go back)${LOG_NC}"
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
        echo ""
        _menu_item "2" "IDE Settings Manager" "Copy IDE/tool configs to project"
        echo ""
        _menu_item "3" "Purge Download Cache" "Clear cached packages [$cache_size]"
        echo ""
        _menu_item "4" "Options" "Preferences and defaults"
        echo ""
        _menu_item "5" "Help" "Usage guide and documentation"
        echo ""
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
    local total_steps=6

    while true; do
        case $step in
            1) _bootstrap_step_select_apps && ((step++)) || return ;;
            2) _bootstrap_step_download && ((step++)) || ((step--)) ;;
            3) _bootstrap_step_configure && ((step++)) || ((step--)) ;;
            4) _bootstrap_step_preflight && ((step++)) || ((step--)) ;;
            5) _bootstrap_step_install && ((step++)) || ((step--)) ;;
            6) _bootstrap_step_validate; return ;;
        esac
    done
}

# Step 1: Select Apps
_bootstrap_step_select_apps() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 1/6: Select Apps"
    echo ""
    echo "  Toggle features (enter number to toggle, 'done' when ready):"
    echo ""

    # Feature toggles - read current values from config or defaults
    local -A features=(
        ["1:Next.js + TypeScript"]="${ENABLE_NEXTJS:-true}"
        ["2:PostgreSQL + Drizzle ORM"]="${ENABLE_DATABASE:-true}"
        ["3:Authentication (Auth.js)"]="${ENABLE_AUTHJS:-true}"
        ["4:AI Integration (Vercel AI SDK)"]="${ENABLE_AI_SDK:-true}"
        ["5:Background Jobs (pg-boss)"]="${ENABLE_PG_BOSS:-false}"
        ["6:UI Components (shadcn/ui)"]="${ENABLE_SHADCN:-true}"
        ["7:PDF/Excel Exports"]="${ENABLE_PDF_EXPORTS:-false}"
        ["8:Testing (Vitest + Playwright)"]="${ENABLE_TEST_INFRA:-true}"
        ["9:Code Quality (ESLint + Prettier)"]="${ENABLE_CODE_QUALITY:-false}"
    )

    while true; do
        # Display current selections
        for key in $(echo "${!features[@]}" | tr ' ' '\n' | sort); do
            local num="${key%%:*}"
            local label="${key#*:}"
            local enabled="${features[$key]}"
            local marker="[ ]"
            [[ "$enabled" == "true" ]] && marker="[x]"
            echo "    $marker $num. $label"
        done

        echo ""
        echo "  Presets: [m]inimal [a]pi-only [f]ull [e]nterprise"
        echo ""
        _menu_line
        read -rp "  Toggle [1-9], preset, or 'done': " choice

        case "$choice" in
            [1-9])
                # Toggle the feature
                for key in "${!features[@]}"; do
                    if [[ "${key%%:*}" == "$choice" ]]; then
                        if [[ "${features[$key]}" == "true" ]]; then
                            features[$key]="false"
                        else
                            features[$key]="true"
                        fi
                        break
                    fi
                done
                _menu_header
                _menu_title "BOOTSTRAP PROJECT - Step 1/6: Select Apps"
                echo ""
                echo "  Toggle features (enter number to toggle, 'done' when ready):"
                echo ""
                ;;
            m|minimal)
                features["3:Authentication (Auth.js)"]="false"
                features["4:AI Integration (Vercel AI SDK)"]="false"
                features["5:Background Jobs (pg-boss)"]="false"
                features["6:UI Components (shadcn/ui)"]="false"
                features["7:PDF/Excel Exports"]="false"
                features["8:Testing (Vitest + Playwright)"]="false"
                features["9:Code Quality (ESLint + Prettier)"]="false"
                ;;
            a|api-only)
                features["6:UI Components (shadcn/ui)"]="false"
                features["7:PDF/Excel Exports"]="false"
                ;;
            f|full)
                for key in "${!features[@]}"; do
                    features[$key]="true"
                done
                features["7:PDF/Excel Exports"]="false"
                features["9:Code Quality (ESLint + Prettier)"]="false"
                ;;
            e|enterprise)
                for key in "${!features[@]}"; do
                    features[$key]="true"
                done
                ;;
            done|d|"")
                # Save selections to environment for next steps
                export ENABLE_AUTHJS="${features["3:Authentication (Auth.js)"]}"
                export ENABLE_AI_SDK="${features["4:AI Integration (Vercel AI SDK)"]}"
                export ENABLE_PG_BOSS="${features["5:Background Jobs (pg-boss)"]}"
                export ENABLE_SHADCN="${features["6:UI Components (shadcn/ui)"]}"
                export ENABLE_PDF_EXPORTS="${features["7:PDF/Excel Exports"]}"
                export ENABLE_TEST_INFRA="${features["8:Testing (Vitest + Playwright)"]}"
                export ENABLE_CODE_QUALITY="${features["9:Code Quality (ESLint + Prettier)"]}"
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

# Step 2: Download Packages
_bootstrap_step_download() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 2/6: Download Packages"
    echo ""
    echo "  Downloading required packages in background..."
    echo ""

    # Start background download if available
    if type downloads_start_for_config &>/dev/null; then
        downloads_start_for_config
        echo "  [OK] Download started in background"
    else
        echo "  [SKIP] Download cache not available"
    fi

    echo ""
    _menu_line
    read -rp "  Press Enter to continue, 'b' to go back: " choice

    [[ "$choice" == "b" ]] && return 1
    return 0
}

# Step 3: Configure Variables
_bootstrap_step_configure() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 3/6: Configure Variables"
    echo ""

    # Run interactive wizard or prompt for key values
    if type setup_run_interactive &>/dev/null; then
        setup_run_interactive "${BOOTSTRAP_CONF}"
        return $?
    fi

    # Fallback: basic prompts
    echo "  Configure your project settings:"
    echo ""

    read -rp "  App Name [${APP_NAME:-bloom2}]: " val
    [[ -n "$val" ]] && APP_NAME="$val"

    read -rp "  Database Name [${DB_NAME:-bloom2_db}]: " val
    [[ -n "$val" ]] && DB_NAME="$val"

    read -rp "  Database User [${DB_USER:-bloom2}]: " val
    [[ -n "$val" ]] && DB_USER="$val"

    echo -n "  Database Password [********]: "
    read -rs val
    echo ""
    [[ -n "$val" ]] && DB_PASSWORD="$val"

    echo ""
    _menu_line
    read -rp "  Press Enter to continue, 'b' to go back: " choice

    [[ "$choice" == "b" ]] && return 1
    return 0
}

# Step 4: Preflight Check
_bootstrap_step_preflight() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 4/6: Preflight Check"
    echo ""

    # Run preflight checks
    local errors=0

    echo "  Checking prerequisites..."
    echo ""

    # Check Node.js
    if command -v node &>/dev/null; then
        local node_ver=$(node --version)
        echo "  [OK] Node.js $node_ver"
    else
        echo "  [FAIL] Node.js not found"
        ((errors++))
    fi

    # Check pnpm
    if command -v pnpm &>/dev/null; then
        local pnpm_ver=$(pnpm --version)
        echo "  [OK] pnpm $pnpm_ver"
    else
        echo "  [FAIL] pnpm not found"
        ((errors++))
    fi

    # Check git
    if command -v git &>/dev/null; then
        echo "  [OK] git installed"
    else
        echo "  [FAIL] git not found"
        ((errors++))
    fi

    # Check Docker (optional)
    if command -v docker &>/dev/null; then
        echo "  [OK] Docker installed"
    else
        echo "  [WARN] Docker not found (optional)"
    fi

    echo ""

    # Validate config
    if type config_validate_all &>/dev/null; then
        if config_validate_all; then
            echo "  [OK] Configuration valid"
        else
            echo "  [FAIL] Configuration errors"
            ((errors++))
        fi
    fi

    echo ""
    _menu_line

    if [[ $errors -gt 0 ]]; then
        echo "  ${errors} error(s) found. Fix before continuing."
        read -rp "  Press Enter to retry, 'b' to go back: " choice
        [[ "$choice" == "b" ]] && return 1
        return 1  # Retry this step
    fi

    read -rp "  All checks passed! Press Enter to install, 'b' to go back: " choice
    [[ "$choice" == "b" ]] && return 1
    return 0
}

# Step 5: Install
_bootstrap_step_install() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 5/6: Installing"
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

# Step 6: Validate
_bootstrap_step_validate() {
    _menu_header
    _menu_title "BOOTSTRAP PROJECT - Step 6/6: Validation"
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
    while true; do
        _menu_header
        _menu_title "OPTIONS"
        echo ""

        _menu_item "1" "Install Target" "Choose test (./test/install-1) or prod (./app)" "[${INSTALL_TARGET:-test}]"
        _menu_item "2" "Default Profile" "Feature set: minimal, api-only, or full stack" "[${STACK_PROFILE:-full}]"
        _menu_item "3" "Log Level" "Verbosity: quiet, status, or verbose" "[${LOG_LEVEL:-status}]"
        _menu_item "4" "Logo Style" "Display style: block, gradient, shadow, simple, minimal" "[${OMNI_LOGO:-block}]"
        _menu_item "5" "Default Timeout" "Max seconds for operations" "[${MAX_CMD_SECONDS:-300}s]"
        _menu_item "6" "Git Safety" "Require clean git working tree before bootstrap" "[${GIT_SAFETY:-true}]"
        _menu_item "7" "Reset to Defaults" "Restore all settings to factory defaults"
        echo ""
        _menu_item "0" "Back"

        _menu_prompt "Select [0-7]"

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
                read -rp "  Timeout (seconds): " val
                [[ -n "$val" ]] && MAX_CMD_SECONDS="$val"
                ;;
            6)
                if [[ "${GIT_SAFETY:-true}" == "true" ]]; then
                    GIT_SAFETY="false"
                else
                    GIT_SAFETY="true"
                fi
                ;;
            7)
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
