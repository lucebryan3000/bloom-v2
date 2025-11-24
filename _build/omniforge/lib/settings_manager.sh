#!/usr/bin/env bash
# =============================================================================
# lib/settings_manager.sh - Project Settings Manager
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Manages IDE and tool configuration files. Copies preset configurations
# from settings-files/ to the project directory.
#
# Exports:
#   settings_list, settings_copy, settings_copy_all, settings_preview,
#   settings_backup, settings_restore
#
# Dependencies:
#   lib/logging.sh
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SETTINGS_LOADED:-}" ]] && return 0
_LIB_SETTINGS_LOADED=1

# =============================================================================
# CONFIGURATION
# =============================================================================

# Settings files location (default: relative to this script)
: "${SETTINGS_SOURCE_DIR:=${SCRIPTS_DIR:-$(dirname "${BASH_SOURCE[0]}")/..}/settings-files}"

# Backup directory
: "${SETTINGS_BACKUP_DIR:=${PROJECT_ROOT:-.}/.omniforge-backup}"

# =============================================================================
# AVAILABLE SETTINGS
# =============================================================================

# Define available settings presets
# Format: ID|Name|Description|Files
declare -g -A _SETTINGS_PRESETS=(
    ["vscode"]="VS Code|Editor settings, extensions, tasks|.vscode/"
    ["cursor"]="Cursor|AI rules and prompts|.cursor/"
    ["github"]="GitHub|Workflows, CODEOWNERS, templates|.github/"
    ["drizzle"]="Drizzle ORM|Database configuration|drizzle.config.ts"
    ["playwright"]="Playwright|E2E test configuration|playwright.config.ts"
    ["vitest"]="Vitest|Unit test configuration|vitest.config.ts"
    ["prettier"]="Prettier|Code formatting|.prettierrc, .prettierignore"
    ["eslint"]="ESLint|Code linting|.eslintrc.js, .eslintignore"
    ["tailwind"]="Tailwind CSS|Styling configuration|tailwind.config.ts, postcss.config.js"
    ["docker"]="Docker|Container configuration|Dockerfile, docker-compose.yml"
    ["env"]="Environment|Environment templates|.env.example, .env.local.example"
)

# =============================================================================
# LISTING AND DISCOVERY
# =============================================================================

# List all available settings presets
# Usage: settings_list
settings_list() {
    echo ""
    log_section "Available Settings Presets"
    echo ""

    local num=0
    for id in $(echo "${!_SETTINGS_PRESETS[@]}" | tr ' ' '\n' | sort); do
        ((num++))
        local data="${_SETTINGS_PRESETS[$id]}"
        local name="${data%%|*}"
        local rest="${data#*|}"
        local desc="${rest%%|*}"
        local files="${rest#*|}"

        local installed=""
        if _settings_is_installed "$id"; then
            installed="${LOG_GREEN:-}[installed]${LOG_NC:-}"
        fi

        printf "  %2d. %-15s %s\n" "$num" "$name" "$installed"
        printf "      %s\n" "${LOG_GRAY:-}$desc${LOG_NC:-}"
        printf "      %s\n" "${LOG_GRAY:-}Files: $files${LOG_NC:-}"
        echo ""
    done
}

# Check if settings are already installed
_settings_is_installed() {
    local id="$1"
    local source_dir="${SETTINGS_SOURCE_DIR}/$id"

    [[ ! -d "$source_dir" ]] && return 1

    # Check if any file from this preset exists in project
    for file in "$source_dir"/*; do
        [[ ! -e "$file" ]] && continue
        local basename
        basename=$(basename "$file")
        if [[ -e "${PROJECT_ROOT:-.}/$basename" ]]; then
            return 0
        fi
    done

    return 1
}

# Get list of preset IDs
settings_get_ids() {
    echo "${!_SETTINGS_PRESETS[@]}" | tr ' ' '\n' | sort
}

# =============================================================================
# COPY OPERATIONS
# =============================================================================

# Copy a settings preset to the project
# Usage: settings_copy "vscode" [--force]
settings_copy() {
    local id="$1"
    local force="${2:-}"

    if [[ -z "${_SETTINGS_PRESETS[$id]:-}" ]]; then
        log_error "Unknown settings preset: $id"
        return 1
    fi

    local source_dir="${SETTINGS_SOURCE_DIR}/$id"

    if [[ ! -d "$source_dir" ]]; then
        log_warn "Settings directory not found: $source_dir"
        return 1
    fi

    local data="${_SETTINGS_PRESETS[$id]}"
    local name="${data%%|*}"

    log_debug "Copying $name settings..."

    # Check for existing files (unless force)
    if [[ "$force" != "--force" ]] && _settings_is_installed "$id"; then
        log_warn "$name settings already exist. Use --force to overwrite."
        return 1
    fi

    # Backup existing files if they exist
    if _settings_is_installed "$id"; then
        settings_backup "$id"
    fi

    # Copy files
    local copied=0
    for item in "$source_dir"/*; do
        [[ ! -e "$item" ]] && continue

        local basename
        basename=$(basename "$item")
        local dest="${PROJECT_ROOT:-.}/$basename"

        if [[ -d "$item" ]]; then
            # Copy directory
            cp -r "$item" "$dest"
        else
            # Copy file
            cp "$item" "$dest"
        fi

        ((copied++))
        log_debug "  Copied: $basename"
    done

    if [[ $copied -gt 0 ]]; then
        log_success "$name settings installed ($copied files)"
        return 0
    else
        log_warn "No files to copy for $name"
        return 1
    fi
}

# Copy all settings presets
# Usage: settings_copy_all [--force]
settings_copy_all() {
    local force="${1:-}"
    local installed=0
    local skipped=0

    for id in $(settings_get_ids); do
        if settings_copy "$id" "$force"; then
            ((installed++))
        else
            ((skipped++))
        fi
    done

    echo ""
    log_info "Installed: $installed, Skipped: $skipped"
}

# =============================================================================
# PREVIEW
# =============================================================================

# Preview what would be copied
# Usage: settings_preview "vscode"
settings_preview() {
    local id="$1"

    if [[ -z "${_SETTINGS_PRESETS[$id]:-}" ]]; then
        log_error "Unknown settings preset: $id"
        return 1
    fi

    local source_dir="${SETTINGS_SOURCE_DIR}/$id"

    if [[ ! -d "$source_dir" ]]; then
        log_warn "Settings directory not found: $source_dir"
        return 1
    fi

    local data="${_SETTINGS_PRESETS[$id]}"
    local name="${data%%|*}"

    echo ""
    log_section "$name Settings Preview"
    echo ""
    echo "  Source: $source_dir"
    echo "  Target: ${PROJECT_ROOT:-.}"
    echo ""
    echo "  Files to copy:"

    for item in "$source_dir"/*; do
        [[ ! -e "$item" ]] && continue

        local basename
        basename=$(basename "$item")
        local dest="${PROJECT_ROOT:-.}/$basename"

        local status="NEW"
        if [[ -e "$dest" ]]; then
            status="OVERWRITE"
        fi

        if [[ -d "$item" ]]; then
            local file_count
            file_count=$(find "$item" -type f | wc -l)
            printf "    [%s] %s/ (%d files)\n" "$status" "$basename" "$file_count"
        else
            local size
            size=$(du -h "$item" 2>/dev/null | cut -f1)
            printf "    [%s] %s (%s)\n" "$status" "$basename" "$size"
        fi
    done

    echo ""
}

# =============================================================================
# BACKUP & RESTORE
# =============================================================================

# Backup existing settings before overwriting
# Usage: settings_backup "vscode"
settings_backup() {
    local id="$1"

    local source_dir="${SETTINGS_SOURCE_DIR}/$id"
    [[ ! -d "$source_dir" ]] && return 0

    local backup_dir="${SETTINGS_BACKUP_DIR}/${id}_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"

    local backed_up=0

    for item in "$source_dir"/*; do
        [[ ! -e "$item" ]] && continue

        local basename
        basename=$(basename "$item")
        local existing="${PROJECT_ROOT:-.}/$basename"

        if [[ -e "$existing" ]]; then
            if [[ -d "$existing" ]]; then
                cp -r "$existing" "$backup_dir/"
            else
                cp "$existing" "$backup_dir/"
            fi
            ((backed_up++))
        fi
    done

    if [[ $backed_up -gt 0 ]]; then
        log_debug "Backed up $backed_up files to: $backup_dir"
    fi
}

# List available backups
# Usage: settings_list_backups
settings_list_backups() {
    if [[ ! -d "${SETTINGS_BACKUP_DIR}" ]]; then
        echo "No backups found"
        return
    fi

    echo ""
    log_section "Available Backups"
    echo ""

    for backup in "${SETTINGS_BACKUP_DIR}"/*; do
        [[ ! -d "$backup" ]] && continue

        local name
        name=$(basename "$backup")
        local file_count
        file_count=$(find "$backup" -type f | wc -l)

        echo "  $name ($file_count files)"
    done
}

# Restore from backup
# Usage: settings_restore "vscode_20240101_120000"
settings_restore() {
    local backup_name="$1"
    local backup_dir="${SETTINGS_BACKUP_DIR}/$backup_name"

    if [[ ! -d "$backup_dir" ]]; then
        log_error "Backup not found: $backup_name"
        return 1
    fi

    log_info "Restoring from: $backup_name"

    local restored=0
    for item in "$backup_dir"/*; do
        [[ ! -e "$item" ]] && continue

        local basename
        basename=$(basename "$item")
        local dest="${PROJECT_ROOT:-.}/$basename"

        if [[ -d "$item" ]]; then
            rm -rf "$dest"
            cp -r "$item" "$dest"
        else
            cp "$item" "$dest"
        fi

        ((restored++))
        log_debug "  Restored: $basename"
    done

    log_success "Restored $restored files"
}

# =============================================================================
# INTERACTIVE MODE
# =============================================================================

# Interactive settings selection
# Usage: settings_interactive
settings_interactive() {
    while true; do
        clear
        settings_list

        echo ""
        echo "  Commands:"
        echo "    [number] - Copy specific preset"
        echo "    [a]ll    - Copy all presets"
        echo "    [p]review - Preview a preset"
        echo "    [b]ackups - List backups"
        echo "    [q]uit   - Return to menu"
        echo ""

        read -rp "  Select: " choice

        case "$choice" in
            [0-9]*)
                # Get ID by number
                local num=0
                local target_id=""
                for id in $(settings_get_ids); do
                    ((num++))
                    if [[ $num -eq $choice ]]; then
                        target_id="$id"
                        break
                    fi
                done

                if [[ -n "$target_id" ]]; then
                    settings_copy "$target_id"
                    read -rp "  Press Enter to continue: " _
                fi
                ;;
            a|all)
                settings_copy_all
                read -rp "  Press Enter to continue: " _
                ;;
            p|preview)
                read -rp "  Enter preset name or number: " preset
                # Handle number input
                if [[ "$preset" =~ ^[0-9]+$ ]]; then
                    local num=0
                    for id in $(settings_get_ids); do
                        ((num++))
                        if [[ $num -eq $preset ]]; then
                            preset="$id"
                            break
                        fi
                    done
                fi
                settings_preview "$preset"
                read -rp "  Press Enter to continue: " _
                ;;
            b|backups)
                settings_list_backups
                read -rp "  Press Enter to continue: " _
                ;;
            q|quit|0)
                return 0
                ;;
        esac
    done
}

# =============================================================================
# STANDALONE EXECUTION
# =============================================================================

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Minimal logging if not available
    if ! type log_debug &>/dev/null; then
        log_debug() { [[ "${VERBOSE:-}" == "true" ]] && echo "[DEBUG] $1"; }
        log_info() { echo "[INFO] $1"; }
        log_warn() { echo "[WARN] $1"; }
        log_error() { echo "[ERROR] $1"; }
        log_success() { echo "[OK] $1"; }
        log_section() { echo ""; echo "=== $1 ==="; }
        LOG_GREEN='\033[0;32m'
        LOG_GRAY='\033[0;90m'
        LOG_NC='\033[0m'
    fi

    case "${1:-}" in
        --list)
            settings_list
            ;;
        --copy)
            shift
            settings_copy "$@"
            ;;
        --copy-all)
            settings_copy_all "$2"
            ;;
        --preview)
            settings_preview "$2"
            ;;
        --backups)
            settings_list_backups
            ;;
        --restore)
            settings_restore "$2"
            ;;
        --interactive|-i)
            settings_interactive
            ;;
        *)
            echo "Usage: $0 {--list|--copy ID|--copy-all|--preview ID|--backups|--restore NAME|--interactive}"
            exit 1
            ;;
    esac
fi
