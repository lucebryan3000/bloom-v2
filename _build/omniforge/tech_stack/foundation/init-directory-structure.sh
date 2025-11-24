#!/usr/bin/env bash
# =============================================================================
# foundation/init-directory-structure.sh - Project Directory Structure
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Purpose: Create standard project directory structure
#
# Creates all directories defined in PROJECT_DIRECTORIES from bootstrap.conf.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="foundation/init-directory-structure"
readonly SCRIPT_NAME="Project Directory Structure"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# Verify PROJECT_ROOT
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$PROJECT_ROOT"

# Create directories from bootstrap.conf PROJECT_DIRECTORIES
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
        ((skipped_count++))
    else
        mkdir -p "$dir"
        log_debug "Created: $dir"
        ((created_count++))
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
