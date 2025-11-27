#!/usr/bin/env bash
# =============================================================================
# cleanup-run-artifacts.sh (deprecated)
# =============================================================================
# Delegates to cleanup-bootstrap.sh --mode run for light cleanup.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec "${SCRIPT_DIR}/cleanup-bootstrap.sh" --mode run "$@"
