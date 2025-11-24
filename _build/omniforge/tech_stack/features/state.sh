#!/usr/bin/env bash
# =============================================================================
# tech_stack/features/state.sh - Zustand State Management
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: Features
# Profile: standard+
#
# Installs:
#   - zustand (lightweight state management)
#
# Creates:
#   - src/stores/index.ts (example store with typed state)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="features/state"
readonly SCRIPT_NAME="Zustand State Management"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Project directory does not exist: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing Zustand"

DEPS=("${PKG_ZUSTAND}")

# Show cache status
pkg_preflight_check "${DEPS[@]}"

# Install dependencies
log_info "Installing ${PKG_ZUSTAND}..."
pkg_install "${DEPS[@]}" || {
    log_error "Failed to install ${PKG_ZUSTAND}"
    exit 1
}

# Verify installation
log_info "Verifying installation..."
pkg_verify "${PKG_ZUSTAND}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "Zustand installed"

# =============================================================================
# STORE SETUP
# =============================================================================

log_step "Creating store structure"

mkdir -p "${SRC_STORES_DIR}"

# Example store with typed state
if [[ ! -f "${SRC_STORES_DIR}/index.ts" ]]; then
    cat > "${SRC_STORES_DIR}/index.ts" <<'EOF'
import { create } from 'zustand';
import { devtools, persist } from 'zustand/middleware';

// =============================================================================
// App Store - Global application state
// =============================================================================

interface AppState {
  // UI State
  sidebarOpen: boolean;
  theme: 'light' | 'dark' | 'system';

  // User State
  user: {
    id: string;
    email: string;
    name: string;
  } | null;

  // Actions
  toggleSidebar: () => void;
  setTheme: (theme: 'light' | 'dark' | 'system') => void;
  setUser: (user: AppState['user']) => void;
  clearUser: () => void;
}

export const useAppStore = create<AppState>()(
  devtools(
    persist(
      (set) => ({
        // Initial state
        sidebarOpen: true,
        theme: 'system',
        user: null,

        // Actions
        toggleSidebar: () =>
          set((state) => ({ sidebarOpen: !state.sidebarOpen })),

        setTheme: (theme) => set({ theme }),

        setUser: (user) => set({ user }),

        clearUser: () => set({ user: null }),
      }),
      {
        name: 'app-storage',
        partialize: (state) => ({
          theme: state.theme,
          sidebarOpen: state.sidebarOpen,
        }),
      }
    ),
    { name: 'AppStore' }
  )
);

// =============================================================================
// Selectors - For optimized re-renders
// =============================================================================

export const selectSidebarOpen = (state: AppState) => state.sidebarOpen;
export const selectTheme = (state: AppState) => state.theme;
export const selectUser = (state: AppState) => state.user;
export const selectIsAuthenticated = (state: AppState) => state.user !== null;
EOF
    log_ok "Created ${SRC_STORES_DIR}/index.ts"
else
    log_skip "${SRC_STORES_DIR}/index.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
