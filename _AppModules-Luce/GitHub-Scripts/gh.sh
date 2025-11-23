#!/usr/bin/env bash
# Git & GitHub Interactive Manager
#
# A menu-driven tool for Git operations, branch management, and GitHub Actions control.
# Modularized into library components for maintainability and extensibility.
#
# Usage: ./gh.sh  (or alias: cs-gh)
#
# Architecture:
#   - gh.sh: Thin orchestrator (this file) - handles menu and routing
#   - lib/common.sh: Shared utilities, colors, logging, bootstrap functions
#   - lib/core.sh: All 48+ operational functions organized by concern
#   - gh.conf: Optional project-level configuration
#
# See README.md for full feature list and examples.

set -e

# ============================================================================
# BOOTSTRAP: Load Libraries and Configuration
# ============================================================================

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LIB_DIR="${GH_LIB_DIR:-"$SCRIPT_DIR/lib"}"

# Load shared utilities (colors, logging, validation helpers)
# shellcheck source=/dev/null
source "$LIB_DIR/common.sh"

# Load all operational functions (git, branch, github actions, etc.)
# shellcheck source=/dev/null
source "$LIB_DIR/core.sh"

# Bootstrap environment paths and load project configuration
gh_bootstrap_paths
gh_load_config

# Apply editor preference (can be disabled per-project via config)
prefer_micro_editor

# ============================================================================
# MAIN MENU & ROUTING
# ============================================================================





























# ============================================================================
# main()
#
# Interactive menu loop that provides access to all Git, branch, and GitHub
# Actions operations organized into 7 main menu options + 1 advanced submenu.
#
# Menu Categories:
#   Dashboard:  Single main box with metrics, Status Snapshot list, Recent Commits list
#   1:          Quick Actions (commit [dynamic/yellow])
#   2:          Branch manager (list, merge, delete branches)
#   3:          Workflow sync (push/pull/cleanup for multi-session)
#   4:          Claude Code Web (session merge & cleanup)
#   5-7:        Help & Documentation (Claude guide, gh CLI ref, healthcheck)
#   8:          Configuration (git config)
#   9:          Advanced Commands → Submenu
#
# Advanced Submenu (option 9):
#   1-2:        Quick Actions (view diff code, generate PR command)
#   3-5:        Stash Management (stash, manage, discard)
#   6-7:        Branch Operations (cleanup merged branches)
#   8-12:       GitHub Actions (status, commits, workflows, toggle, account-wide)
#   13:         System (check for updates)
#   Other:      Any other key returns to main menu
#
# Behavior:
#   - Loops until user exits with invalid option or Ctrl+C
#   - Validates git repo and gh CLI before starting
#   - Displays gh version and user on startup
#   - Displays menu with dashboard info after each operation
#   - Routes to lib/core.sh function implementations
#   - Advanced submenu returns to main menu on any invalid option
# ============================================================================

main() {
    # Preflight checks: ensure we're in a git repo with gh CLI available
    check_git_repo
    check_gh_cli

    # Interactive menu loop
    while true; do
        show_menu
        read -p "Select option: " option

        # Route to appropriate function based on menu selection
        case $option in
            # Quick Actions
            1)  commit_changes_unified ;;
            2)  branch_manager_unified ;;

            # Claude Code Web
            3)  quick_sync ;;
            4)  claude_session_merge_and_cleanup ;;

            # Help & Documentation
            5)  show_claude_web_help ;;
            6)  show_github_cli_reference ;;
            7)  github_healthcheck ;;

            # Configuration
            8)  setup_git_config ;;

            # Advanced Commands Submenu
            9) advanced_menu_handler ;;

            *)
                # Invalid option: exit cleanly
                exit 0
                ;;
        esac





        echo ""
        read -p "Press Enter to continue..." _
    done
}

# Start the interactive menu
main