#!/usr/bin/env bash
# token_headroom.sh — TokenHeadroom: The Cognitive Capacity Manager (entrypoint)
# Version: 1.1.1 (Rebranded)
#
# TokenHeadroom = Raw Context Tokens - Optimized Context Tokens
# A high TokenHeadroom means your LLM is not wasting tokens reading irrelevant data.

set -Eeuo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"

# Defaults
DRY_RUN=0; VERBOSE=0; FORCE=0; YES_ALL=0
LOG_MODE="off"            # off|on|critical
CONTEXT_BUDGET=200000
CI_MODE=0
JSON_REPORT=""
ACTION_ID=""
ROOT_HINT="${CONTEXT_ROOT:-}"

# Load libs & registry
source "${SCRIPT_DIR}/lib/ui.sh"
source "${SCRIPT_DIR}/lib/run.sh"
source "${SCRIPT_DIR}/lib/policy.sh"
source "${SCRIPT_DIR}/lib/ci.sh"
source "${SCRIPT_DIR}/registry.sh"    # loads menus + verbs

trap 'cleanup_token_headroom' EXIT INT TERM

print_help() {
cat <<'HELP'
TokenHeadroom: The Cognitive Capacity Manager

TokenHeadroom is the diagnostic and optimization layer that helps maximize Claude's
effective "headroom" by minimizing irrelevant token count.

  TokenHeadroom = Raw Context Tokens - Optimized Context Tokens

The Four Pillars:
  1) Analysis    - Diagnose token costs & relevance
  2) Suggestions - Find optimization targets
  3) Application - Safely apply configuration changes
  4) Tools       - Direct config file utilities

USAGE
  token_headroom.sh [flags]

FLAGS
  -h, --help            Show help (The Four Pillars)
  -V, --version         Show version/build info
  -n, --dry-run         Print previews/commands; execute nothing; no logs
  -v, --verbose         Verbose output
  -l, --log=MODE        Log mode: off|on|critical (default: off)
  -a, --action=ID       Run a non-interactive action by ID (e.g., suggest.ignores)
      --list-actions    List all available non-interactive action IDs
  -f, --force           Force apply operations without interactive confirmation
      --yes             Alias for --force / Assume Yes to all questions
      --budget=N        Set token budget target (default 200000)
      --root=P          Set the source project root
      --ci              CI mode (non-interactive; no applies unless --force)
      --json-report=F   Write JSON report to file

PRECEDENCE
  --dry-run > --log > --verbose

EXIT CODES
  0   OK
  8   Findings present (CI info)
  16  Policy invalid/missing (ABORT by policy)
  32  Runtime error (I/O, parse, unexpected)

EXAMPLES
  # Interactive mode
  ./token_headroom.sh

  # Quick analysis
  ./token_headroom.sh -a analyze.quick

  # CI mode with JSON report
  ./token_headroom.sh --ci --json-report=report.json

  # Apply all optimizations non-interactively
  ./token_headroom.sh -a apply.ignores --force
HELP
}

print_version() {
  echo "TokenHeadroom v1.1.1 ($BUILD_DATE)"
  echo "The Cognitive Capacity Manager for Claude"
}

parse_flags() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -h|--help) print_help; exit 0 ;;
      -V|--version) print_version; exit 0 ;;
      -n|--dry-run) DRY_RUN=1 ;;
      -v|--verbose) VERBOSE=1 ;;
      -l|--log) shift; LOG_MODE="${1:-off}" ;;
      --log=*) LOG_MODE="${1#*=}" ;;
      -a|--action) shift; ACTION_ID="${1:-}" ;;
      --action=*) ACTION_ID="${1#*=}" ;;
      --list-actions) list_actions; exit 0 ;;
      -f|--force) FORCE=1 ;;
      --yes) YES_ALL=1 ;;
      --budget=*) CONTEXT_BUDGET="${1#*=}" ;;
      --root=*) ROOT_HINT="${1#*=}" ;;
      --ci) CI_MODE=1; YES_ALL=1 ;;
      --json-report=*) JSON_REPORT="${1#*=}" ;;
      *) ui_error "Unknown flag: $1"; exit 1 ;;
    esac
    shift
  done

  # Precedence: dry-run disables logging
  if [[ "$DRY_RUN" -eq 1 ]]; then
    LOG_MODE="off"
  fi
}

main() {
  parse_flags "$@"

  # Initialize: find context root, load policy
  detect_and_confirm_root "$ROOT_HINT" || exit 32
  policy_load_or_abort || exit 16
  log_init "$LOG_MODE" || true

  ci_init_report

  if [[ -n "${ACTION_ID:-}" ]]; then
    # Run non-interactive action
    run_action_id "$ACTION_ID"
    ci_finalize_and_exit
  fi

  # Run interactive menu
  menu_main
  ci_finalize_and_exit
}

main "$@"
