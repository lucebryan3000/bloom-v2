#!/usr/bin/env bash
# =============================================================================
# state/session-state-lib.sh - Session State Utilities
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Purpose: Creates session state utilities in src/lib/state/
#
# Creates:
#   - src/lib/state/session.ts (session state management)
#   - src/lib/state/index.ts (exports)
# =============================================================================
#
# Dependencies:
#   - none
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="state/session-state-lib"
readonly SCRIPT_NAME="Session State Utilities"

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
# DIRECTORY SETUP
# =============================================================================

log_step "Creating session state structure"

STATE_LIB_DIR="${INSTALL_DIR}/src/lib/state"
mkdir -p "${STATE_LIB_DIR}"

# =============================================================================
# SESSION STATE
# =============================================================================

if [[ ! -f "${STATE_LIB_DIR}/session.ts" ]]; then
    cat > "${STATE_LIB_DIR}/session.ts" <<'EOF'
/**
 * Session State Management
 *
 * Provides utilities for managing ephemeral session state that
 * doesn't need to persist across browser refreshes.
 */

import { create } from 'zustand';

// =============================================================================
// Session State Types
// =============================================================================

interface SessionState {
  // Session metadata
  sessionId: string | null;
  startedAt: Date | null;
  lastActivityAt: Date | null;

  // Ephemeral UI state
  activeModal: string | null;
  pendingActions: string[];
  notifications: Notification[];

  // Actions
  initSession: () => void;
  updateActivity: () => void;
  setActiveModal: (modal: string | null) => void;
  addPendingAction: (action: string) => void;
  removePendingAction: (action: string) => void;
  addNotification: (notification: Omit<Notification, 'id' | 'timestamp'>) => void;
  dismissNotification: (id: string) => void;
  clearSession: () => void;
}

interface Notification {
  id: string;
  type: 'info' | 'success' | 'warning' | 'error';
  message: string;
  timestamp: Date;
  autoDismiss?: boolean;
}

// =============================================================================
// Session Store
// =============================================================================

export const useSessionStore = create<SessionState>((set, get) => ({
  // Initial state
  sessionId: null,
  startedAt: null,
  lastActivityAt: null,
  activeModal: null,
  pendingActions: [],
  notifications: [],

  // Actions
  initSession: () => {
    const sessionId = crypto.randomUUID();
    const now = new Date();
    set({
      sessionId,
      startedAt: now,
      lastActivityAt: now,
    });
  },

  updateActivity: () => {
    set({ lastActivityAt: new Date() });
  },

  setActiveModal: (modal) => {
    set({ activeModal: modal });
  },

  addPendingAction: (action) => {
    set((state) => ({
      pendingActions: [...state.pendingActions, action],
    }));
  },

  removePendingAction: (action) => {
    set((state) => ({
      pendingActions: state.pendingActions.filter((a) => a !== action),
    }));
  },

  addNotification: (notification) => {
    const newNotification: Notification = {
      ...notification,
      id: crypto.randomUUID(),
      timestamp: new Date(),
    };
    set((state) => ({
      notifications: [...state.notifications, newNotification],
    }));

    // Auto-dismiss after 5 seconds if enabled
    if (notification.autoDismiss !== false) {
      setTimeout(() => {
        get().dismissNotification(newNotification.id);
      }, 5000);
    }
  },

  dismissNotification: (id) => {
    set((state) => ({
      notifications: state.notifications.filter((n) => n.id !== id),
    }));
  },

  clearSession: () => {
    set({
      sessionId: null,
      startedAt: null,
      lastActivityAt: null,
      activeModal: null,
      pendingActions: [],
      notifications: [],
    });
  },
}));

// =============================================================================
// Selectors
// =============================================================================

export const selectSessionId = (state: SessionState) => state.sessionId;
export const selectIsSessionActive = (state: SessionState) => state.sessionId !== null;
export const selectActiveModal = (state: SessionState) => state.activeModal;
export const selectPendingActions = (state: SessionState) => state.pendingActions;
export const selectHasPendingActions = (state: SessionState) => state.pendingActions.length > 0;
export const selectNotifications = (state: SessionState) => state.notifications;
EOF
    log_ok "Created ${STATE_LIB_DIR}/session.ts"
else
    log_skip "${STATE_LIB_DIR}/session.ts already exists"
fi

# =============================================================================
# INDEX EXPORTS
# =============================================================================

if [[ ! -f "${STATE_LIB_DIR}/index.ts" ]]; then
    cat > "${STATE_LIB_DIR}/index.ts" <<'EOF'
/**
 * State Management Exports
 */

export * from './session';
EOF
    log_ok "Created ${STATE_LIB_DIR}/index.ts"
else
    log_skip "${STATE_LIB_DIR}/index.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
