#!/usr/bin/env bash
#!meta
# id: path/to/script.sh
# name: script-name
# phase: X
# phase_name: <Phase Name>
# profile_tags:
#   - tech_stack
# uses_from_omni_config:
#   - FILL_ME
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="path/to/script"
readonly SCRIPT_NAME="Script Name"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME} - Preflight"
# ... script body ...

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
