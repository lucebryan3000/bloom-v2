#!/usr/bin/env bash
# claudeignore_optimization.sh — Menu-Driven Context Optimizer (entrypoint)
# Version: 1.1.1

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

trap 'cleanup_context_opt' EXIT INT TERM

print_help() {
cat <<'EOF'
claudeignore_optimization.sh — Optimize Claude context footprint safely

USAGE
  _AppModules-Luce/context-opt/claudeignore_optimization.sh [flags]

FLAGS
  -h, --help            Show help
  -V, --version         Show version/build info
  -n, --dry-run         Print previews/commands; execute nothing; no logs
  -v, --verbose         Verbose output
  -l, --log=MODE        Log mode: off|on|critical (default off)
  -a, --action=ID       Run one action non-interactively (still previews)
      --list-actions    List action IDs and exit
  -f, --force           Bypass confirmations (critical still previews)
      --yes             Auto-confirm non-critical prompts
      --budget=N        Override context budget tokens
      --root=PATH       Force project root
      --ci              CI mode (non-interactive; no applies unless --force)
      --json-report=F   Write JSON report to file

PRECEDENCE
  --dry-run > --log > --verbose

EXIT CODES
  0  OK
  8  Findings present (CI info)
 16  Policy invalid/missing (ABORT by policy)
 32  Runtime error (I/O, parse, unexpected)
EOF
}

print_version(){ echo "claudeignore_optimization v1.1.1 ($BUILD_DATE)"; }

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
      *) ui_warn "Unknown arg: $1" ;;
    esac; shift || true
  done
  if [[ "$DRY_RUN" -eq 1 ]]; then LOG_MODE="off"; fi
}

main() {
  parse_flags "$@"

  detect_and_confirm_root "$ROOT_HINT" || exit 32
  policy_load_or_abort || exit 16
  log_init "$LOG_MODE" || true

  ci_init_report

  if [[ -n "${ACTION_ID:-}" ]]; then
    run_action_id "$ACTION_ID"
    ci_finalize_and_exit
  fi

  menu_main
  ci_finalize_and_exit
}

main "$@"
