#!/usr/bin/env bash
#!meta
# id: foundation/init-directory-structure.sh
# name: init-directory-structure
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - foundation
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PROJECT_DIRECTORIES
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PROJECT_DIRECTORIES
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# foundation/init-directory-structure.sh - Project Directory Structure
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Purpose: Create standard project directory structure
#
# Creates all directories defined in PROJECT_DIRECTORIES from omni.settings.sh.
# =============================================================================
#
# Dependencies:
#   - none
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="foundation/init-directory-structure"
readonly SCRIPT_NAME="Project Directory Structure"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Verify PROJECT_ROOT
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Create directories from omni.settings PROJECT_DIRECTORIES
log_info "Creating project directories..."

# Use PROJECT_DIRECTORIES if defined, otherwise use defaults
DIRS_TO_CREATE="${PROJECT_DIRECTORIES:-
src/app
src/components
src/lib
src/db
src/styles
src/hooks
src/types
public
}"

created_count=0
skipped_count=0

while IFS= read -r dir; do
    # Skip empty lines
    [[ -z "${dir// }" ]] && continue

    if [[ -d "$dir" ]]; then
        skipped_count=$((skipped_count + 1))
    else
        mkdir -p "$dir"
        log_debug "Created: $dir"
        created_count=$((created_count + 1))
    fi
done <<< "$DIRS_TO_CREATE"

log_ok "Created ${created_count} directories (${skipped_count} already existed)"

# Create .gitkeep files in empty directories
for dir in $DIRS_TO_CREATE; do
    [[ -z "${dir// }" ]] && continue
    if [[ -d "$dir" ]] && [[ -z "$(ls -A "$dir" 2>/dev/null)" ]]; then
        touch "${dir}/.gitkeep"
    fi
done

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
