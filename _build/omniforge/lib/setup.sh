#!/usr/bin/env bash
# =============================================================================
# lib/setup.sh - OmniForge Project Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# One-time project initialization tasks that prepare a project for OmniForge:
#   - Deploy template files (.toolsrc.example, etc.)
#   - Create project directory structure
#   - Verify OmniForge prerequisites
#
# This runs AFTER local tools installation but BEFORE deployment preflight.
#
# Philosophy:
#   - Setup happens once (idempotent via marker file)
#   - Setup != Build (this prepares, build deploys)
#   - Setup can be re-run safely (checks before acting)
#
# Exports:
#   setup_omniforge_project, setup_is_complete, setup_validate_environment
#
# Dependencies:
#   lib/logging.sh, lib/scaffold.sh, bootstrap.conf (OMNIFORGE_SETUP_MARKER)
# =============================================================================

# Guard against double-sourcing
[[ -n "${_LIB_SETUP_LOADED:-}" ]] && return 0
_LIB_SETUP_LOADED=1

# =============================================================================
# SETUP ORCHESTRATION
# =============================================================================

# Main setup function - runs all project initialization tasks
# Usage: setup_omniforge_project
setup_omniforge_project() {
    local setup_needed=false

    # Check if any setup tasks are needed
    if ! setup_is_complete; then
        setup_needed=true
        log_step "OmniForge project setup"
        echo ""
    fi

    # Validate environment can run OmniForge
    if ! setup_validate_environment; then
        log_error "Environment validation failed"
        return 1
    fi

    # Deploy template files
    if ! scaffold_deploy_all; then
        log_warn "Some templates failed to deploy (non-fatal)"
    fi

    # Create project directories
    if ! setup_create_directories; then
        log_error "Failed to create project directories"
        return 1
    fi

    # Mark setup as complete
    if [[ "$setup_needed" == "true" ]]; then
        setup_mark_complete
        echo ""
        log_success "OmniForge project setup complete"
        echo ""
    fi

    return 0
}

# Check if setup has been completed
# Usage: setup_is_complete
setup_is_complete() {
    # Check for marker file
    if [[ ! -f "${OMNIFORGE_SETUP_MARKER}" ]]; then
        log_debug "Setup marker not found: ${OMNIFORGE_SETUP_MARKER}"
        return 1
    fi

    # Verify critical templates exist (light validation)
    if [[ ! -f "${PROJECT_ROOT}/.toolsrc.example" ]]; then
        log_debug "Critical template missing: .toolsrc.example"
        return 1
    fi

    log_debug "Setup already complete"
    return 0
}

# Mark setup as complete
# Usage: setup_mark_complete
setup_mark_complete() {
    local marker="${OMNIFORGE_SETUP_MARKER}"

    # Create marker file with metadata
    cat > "$marker" << EOF
# OmniForge Setup Marker
# This file indicates that OmniForge project setup has completed successfully.
# Created: $(date -u +"%Y-%m-%d %H:%M:%S UTC")
# Version: $(git -C "${OMNIFORGE_DIR}" describe --tags 2>/dev/null || echo "unknown")

SETUP_COMPLETED=true
SETUP_TIMESTAMP=$(date +%s)
EOF

    log_debug "Created setup marker: ${marker}"
}

# Create required project directories
# Usage: setup_create_directories
setup_create_directories() {
    local dirs=(
        "${TOOLS_DIR}"
        "${LOG_DIR}"
    )

    local created=0

    for dir in "${dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            if mkdir -p "$dir"; then
                log_debug "Created directory: $dir"
                ((created++))
            else
                log_error "Failed to create directory: $dir"
                return 1
            fi
        fi
    done

    if [[ $created -gt 0 ]]; then
        log_info "Created $created director(ies)"
    fi

    return 0
}

# =============================================================================
# VALIDATION
# =============================================================================

# Verify OmniForge can run in this environment
# Usage: setup_validate_environment
setup_validate_environment() {
    local errors=0

    # Check bash version (require 4.0+)
    if [[ "${BASH_VERSINFO[0]}" -lt 4 ]]; then
        log_error "Bash 4.0+ required (found: ${BASH_VERSION})"
        ((errors++))
    fi

    # Check required commands
    local required_cmds=(curl tar mkdir chmod)
    for cmd in "${required_cmds[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            ((errors++))
        fi
    done

    # Check PROJECT_ROOT is set and exists
    if [[ -z "${PROJECT_ROOT:-}" ]]; then
        log_error "PROJECT_ROOT not set"
        ((errors++))
    elif [[ ! -d "${PROJECT_ROOT}" ]]; then
        log_error "PROJECT_ROOT does not exist: ${PROJECT_ROOT}"
        ((errors++))
    fi

    # Check OMNIFORGE_DIR is set and exists
    if [[ -z "${OMNIFORGE_DIR:-}" ]]; then
        log_error "OMNIFORGE_DIR not set"
        ((errors++))
    elif [[ ! -d "${OMNIFORGE_DIR}" ]]; then
        log_error "OMNIFORGE_DIR does not exist: ${OMNIFORGE_DIR}"
        ((errors++))
    fi

    if [[ $errors -eq 0 ]]; then
        log_debug "Environment validation passed"
        return 0
    else
        log_error "Environment validation failed ($errors error(s))"
        return 1
    fi
}

# =============================================================================
# STATUS REPORTING
# =============================================================================

# Show setup status (for debugging)
# Usage: setup_show_status
setup_show_status() {
    echo "=== OmniForge Setup Status ==="
    echo ""

    if setup_is_complete; then
        echo "✓ Setup: Complete"
        if [[ -f "${OMNIFORGE_SETUP_MARKER}" ]]; then
            echo "  Marker: ${OMNIFORGE_SETUP_MARKER}"
            local timestamp
            timestamp=$(grep "^SETUP_TIMESTAMP=" "${OMNIFORGE_SETUP_MARKER}" 2>/dev/null | cut -d= -f2)
            if [[ -n "$timestamp" ]]; then
                echo "  Date: $(date -d "@${timestamp}" 2>/dev/null || date -r "${timestamp}" 2>/dev/null || echo "unknown")"
            fi
        fi
    else
        echo "✗ Setup: Incomplete"
        echo "  Run: omni --run (setup will run automatically)"
    fi

    echo ""

    # Check templates
    if [[ -f "${PROJECT_ROOT}/.toolsrc.example" ]]; then
        echo "✓ Template: .toolsrc.example"
    else
        echo "✗ Template: .toolsrc.example (missing)"
    fi

    echo ""
    echo "=============================="
}
