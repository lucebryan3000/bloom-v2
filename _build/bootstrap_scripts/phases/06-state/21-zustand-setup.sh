#!/usr/bin/env bash
# =============================================================================
# File: phases/06-state/21-zustand-setup.sh
# Purpose: Install and configure Zustand state management
# Assumes: Next.js project exists
# Creates: Base store configuration
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="21"
readonly SCRIPT_NAME="zustand-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Zustand state management"

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Zustand setup"
    require_pnpm
    require_file "package.json"

    log_step "Installing Zustand"
    add_dependency "zustand"
    add_dependency "immer"

    log_step "Creating app store"
    ensure_dir "src/lib/stores"

    local app_store='import { create } from "zustand";
import { immer } from "zustand/middleware/immer";

/**
 * Global App Store
 *
 * Manages application-wide state like user preferences,
 * UI state, and feature flags.
 */

interface AppState {
  // UI State
  sidebarOpen: boolean;
  theme: "light" | "dark" | "system";

  // Feature flags (cached from server)
  featureFlags: Record<string, boolean>;

  // Actions
  toggleSidebar: () => void;
  setTheme: (theme: "light" | "dark" | "system") => void;
  setFeatureFlags: (flags: Record<string, boolean>) => void;
}

export const useAppStore = create<AppState>()(
  immer((set) => ({
    sidebarOpen: true,
    theme: "system",
    featureFlags: {},

    toggleSidebar: () =>
      set((state) => {
        state.sidebarOpen = !state.sidebarOpen;
      }),

    setTheme: (theme) =>
      set((state) => {
        state.theme = theme;
      }),

    setFeatureFlags: (flags) =>
      set((state) => {
        state.featureFlags = flags;
      }),
  }))
);

// Selectors
export const useSidebarOpen = () => useAppStore((s) => s.sidebarOpen);
export const useTheme = () => useAppStore((s) => s.theme);
export const useFeatureFlag = (key: string) =>
  useAppStore((s) => s.featureFlags[key] ?? false);
'

    write_file "src/lib/stores/app.ts" "$app_store"

    local stores_index='export { useAppStore, useSidebarOpen, useTheme, useFeatureFlag } from "./app";
'
    write_file "src/lib/stores/index.ts" "$stores_index"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
