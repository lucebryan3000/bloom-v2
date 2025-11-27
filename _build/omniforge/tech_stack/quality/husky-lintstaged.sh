#!/usr/bin/env bash
#!meta
# id: quality/husky-lintstaged.sh
# name: husky lintstaged
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - quality
# uses_from_omni_config:
#   - ENABLE_CODE_QUALITY
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages:
#     - husky
#     - lint-staged
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/quality/husky-lintstaged.sh - Husky + Lint-Staged Git Hooks
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 4 (Extensions & Quality)
# Purpose: Creates husky + lint-staged git hooks setup for pre-commit quality checks
# =============================================================================
#
# Dependencies:
#   - husky
#   - lint-staged
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="quality/husky-lintstaged"
readonly SCRIPT_NAME="Husky + Lint-Staged Git Hooks"

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

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Create .husky directory
log_info "Setting up Husky git hooks..."

if [[ ! -d ".husky" ]]; then
    mkdir -p .husky
    log_ok "Created .husky directory"
else
    log_skip ".husky directory already exists"
fi

# Create pre-commit hook
if [[ ! -f ".husky/pre-commit" ]]; then
    cat > .husky/pre-commit <<'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Run lint-staged to check and fix staged files
npx lint-staged
EOF
    chmod +x .husky/pre-commit
    log_ok "Created .husky/pre-commit hook"
else
    log_skip ".husky/pre-commit already exists"
fi

# Create commit-msg hook (for conventional commits)
if [[ ! -f ".husky/commit-msg" ]]; then
    cat > .husky/commit-msg <<'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Validate commit message format (optional - uncomment to enable)
# npx --no -- commitlint --edit "$1"

# Basic commit message validation
commit_msg=$(cat "$1")
if [ -z "$commit_msg" ]; then
    echo "Error: Empty commit message"
    exit 1
fi
EOF
    chmod +x .husky/commit-msg
    log_ok "Created .husky/commit-msg hook"
else
    log_skip ".husky/commit-msg already exists"
fi

# Create .lintstagedrc if it doesn't exist
if [[ ! -f ".lintstagedrc" ]]; then
    log_info "Creating lint-staged configuration..."
    cat > .lintstagedrc <<'EOF'
{
  "*.{ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{js,jsx,mjs,cjs}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,yml,yaml}": [
    "prettier --write"
  ],
  "*.css": [
    "prettier --write"
  ]
}
EOF
    log_ok "Created .lintstagedrc"
else
    log_skip ".lintstagedrc already exists"
fi

# Create husky internal directory structure
if [[ ! -d ".husky/_" ]]; then
    mkdir -p .husky/_
    # Create husky.sh helper
    cat > .husky/_/husky.sh <<'EOF'
#!/bin/sh
if [ -z "$husky_skip_init" ]; then
  debug () {
    if [ "$HUSKY_DEBUG" = "1" ]; then
      echo "husky (debug) - $1"
    fi
  }

  readonly hook_name="$(basename "$0")"
  debug "starting $hook_name..."

  if [ "$HUSKY" = "0" ]; then
    debug "HUSKY env variable is set to 0, skipping hook"
    exit 0
  fi

  if [ -f ~/.huskyrc ]; then
    debug "sourcing ~/.huskyrc"
    . ~/.huskyrc
  fi

  export readonly husky_skip_init=1
  sh -e "$0" "$@"
  exitCode="$?"

  if [ $exitCode != 0 ]; then
    echo "husky - $hook_name hook exited with code $exitCode (error)"
  fi

  exit $exitCode
fi
EOF
    chmod +x .husky/_/husky.sh
    log_ok "Created .husky/_/husky.sh helper"
fi

# Add .gitignore for husky
if [[ ! -f ".husky/.gitignore" ]]; then
    cat > .husky/.gitignore <<'EOF'
_
EOF
    log_ok "Created .husky/.gitignore"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
