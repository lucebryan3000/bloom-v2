#!/usr/bin/env bash
# =============================================================================
# lib/ascii.sh - ASCII Art Logos and Branding
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Provides ASCII art logos for the menu system.
# Logo selection controlled by OMNI_LOGO in omni.settings.sh (env overrides win)
#
# Options: block, gradient, shadow, simple, minimal
#
# Exports:
#   ascii_show_logo, ascii_show_tagline, ascii_preview_all
#
# Dependencies:
#   lib/logging.sh (for colors)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_ASCII_LOADED:-}" ]] && return 0
_LIB_ASCII_LOADED=1

# =============================================================================
# LOGO DEFINITIONS
# =============================================================================

# Block style - solid Unicode blocks
_ascii_logo_block() {
    cat << 'EOF'
    ███████                                ███
  ███░░░░░███                             ░░░
 ███     ░░███ █████████████   ████████   ████
░███      ░███░░███░░███░░███ ░░███░░███ ░░███
░███      ░███ ░███ ░███ ░███  ░███ ░███  ░███
░░███     ███  ░███ ░███ ░███  ░███ ░███  ░███
 ░░░███████░   █████░███ █████ ████ █████ █████
   ░░░░░░░    ░░░░░ ░░░ ░░░░░ ░░░░ ░░░░░ ░░░░░
                     ___  __   __   __   ___
                    |__  /  \ |__) / _` |__
                    |    \__/ |  \ \__> |___
EOF
}

# Gradient style - varying density characters
_ascii_logo_gradient() {
    cat << 'EOF'
 ░▒▓██████▓▒░░▒▓██████████████▓▒░░▒▓███████▓▒░░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
 ░▒▓██████▓▒░░▒▓█▓▒░░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░░▒▓█▓▒░▒▓█▓▒░
EOF
}

# Shadow style - 3D effect with backslashes
_ascii_logo_shadow() {
    cat << 'EOF'
        _____         ______  _______    _____   ______    ____
   ____|\    \       |      \/       \  |\    \ |\     \  |    |
  /     /\    \     /          /\     \  \\    \| \     \ |    |
 /     /  \    \   /     /\   / /\     |  \|    \  \     ||    |
|     |    |    | /     /\ \_/ / /    /|   |     \  |    ||    |
|     |    |    ||     |  \|_|/ /    / |   |      \ |    ||    |
|\     \  /    /||     |       |    |  |   |    |\ \|    ||    |
| \_____\/____/ ||\____\       |____|  /   |____||\_____/||____|
 \ |    ||    | /| |    |      |    | /    |    |/ \|   |||    |
  \|____||____|/  \|____|      |____|/     |____|   |___|/|____|
     \(    )/        \(          )/          \(       )/    \(
      '    '          '          '            '       '      '
EOF
}

# Simple style - clean ASCII only
_ascii_logo_simple() {
    cat << 'EOF'
 ,-----.                      ,--.
'  .-.  ' ,--,--,--. ,--,--,  `--'
|  | |  | |        | |      \ ,--.
'  '-'  ' |  |  |  | |  ||  | |  |
 `-----'  `--`--`--' `--''--' `--'
EOF
}

# Minimal style - light Unicode
_ascii_logo_minimal() {
    cat << 'EOF'
  ░██████                              ░██
 ░██   ░██
░██     ░██ ░█████████████  ░████████  ░██
░██     ░██ ░██   ░██   ░██ ░██    ░██ ░██
░██     ░██ ░██   ░██   ░██ ░██    ░██ ░██
 ░██   ░██  ░██   ░██   ░██ ░██    ░██ ░██
  ░██████   ░██   ░██   ░██ ░██    ░██ ░██
EOF
}

# =============================================================================
# PUBLIC FUNCTIONS
# =============================================================================

# Show the configured logo
# Usage: ascii_show_logo
ascii_show_logo() {
    local logo_style="${OMNI_LOGO:-block}"

    echo ""
    case "$logo_style" in
        block)    _ascii_logo_block ;;
        gradient) _ascii_logo_gradient ;;
        shadow)   _ascii_logo_shadow ;;
        simple)   _ascii_logo_simple ;;
        minimal)  _ascii_logo_minimal ;;
        none)     return 0 ;;
        *)        _ascii_logo_block ;;
    esac
    echo ""
}

# Show the tagline
# Usage: ascii_show_tagline
ascii_show_tagline() {
    local tagline="${OMNI_TAGLINE:-Infinite Architectures. Instant Foundation.}"
    local version="${OMNI_VERSION:-3.0.0}"

    echo -e "${LOG_GRAY:-}  ${tagline}${LOG_NC:-}"
    echo -e "${LOG_GRAY:-}  v${version}${LOG_NC:-}"
    echo ""
}

# Show logo with tagline (main banner)
# Usage: ascii_show_banner
ascii_show_banner() {
    ascii_show_logo
    ascii_show_tagline
}

# Preview all logo styles (for selection)
# Usage: ascii_preview_all
ascii_preview_all() {
    echo ""
    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  LOGO STYLE: block"
    echo "═══════════════════════════════════════════════════════════════════════"
    _ascii_logo_block
    echo ""

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  LOGO STYLE: gradient"
    echo "═══════════════════════════════════════════════════════════════════════"
    _ascii_logo_gradient
    echo ""

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  LOGO STYLE: shadow"
    echo "═══════════════════════════════════════════════════════════════════════"
    _ascii_logo_shadow
    echo ""

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  LOGO STYLE: simple"
    echo "═══════════════════════════════════════════════════════════════════════"
    _ascii_logo_simple
    echo ""

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  LOGO STYLE: minimal"
    echo "═══════════════════════════════════════════════════════════════════════"
    _ascii_logo_minimal
    echo ""

    echo "═══════════════════════════════════════════════════════════════════════"
    echo "  Set OMNI_LOGO in bootstrap.conf to choose a style"
    echo "  Options: block, gradient, shadow, simple, minimal, none"
    echo "═══════════════════════════════════════════════════════════════════════"
}

# =============================================================================
# STANDALONE EXECUTION (for preview)
# =============================================================================

# If run directly, show preview
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Try to source logging for colors
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    [[ -f "${SCRIPT_DIR}/logging.sh" ]] && source "${SCRIPT_DIR}/logging.sh"

    # Check for preview flag
    if [[ "${1:-}" == "--preview" || "${1:-}" == "-p" ]]; then
        ascii_preview_all
    elif [[ "${1:-}" == "--help" || "${1:-}" == "-h" ]]; then
        echo "Usage: ascii.sh [OPTIONS]"
        echo ""
        echo "Options:"
        echo "  --preview, -p    Show all logo styles"
        echo "  --help, -h       Show this help"
        echo "  <style>          Show specific style (block, gradient, shadow, simple, minimal)"
        echo ""
        echo "Example:"
        echo "  ./ascii.sh --preview"
        echo "  ./ascii.sh gradient"
    elif [[ -n "${1:-}" ]]; then
        OMNI_LOGO="$1"
        ascii_show_banner
    else
        ascii_show_banner
    fi
fi
