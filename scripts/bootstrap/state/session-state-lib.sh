#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="state/session-state-lib.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create session state library"; exit 0; }

    if [[ "${ENABLE_ZUSTAND:-true}" != "true" ]]; then
        log_info "SKIP: Zustand disabled via ENABLE_ZUSTAND"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Creating Session State Library ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/lib/state"

    local session_store='import { create } from "zustand";
import { devtools } from "zustand/middleware";
import { immer } from "zustand/middleware/immer";

interface User {
  id: string;
  email: string;
  name?: string;
  image?: string;
}

interface SessionState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
  error: string | null;
}

interface SessionActions {
  setUser: (user: User | null) => void;
  setLoading: (loading: boolean) => void;
  setError: (error: string | null) => void;
  logout: () => void;
}

export const useSessionStore = create<SessionState & SessionActions>()(
  devtools(
    immer((set) => ({
      user: null,
      isAuthenticated: false,
      isLoading: true,
      error: null,

      setUser: (user) =>
        set((state) => {
          state.user = user;
          state.isAuthenticated = !!user;
          state.isLoading = false;
        }),

      setLoading: (loading) =>
        set((state) => {
          state.isLoading = loading;
        }),

      setError: (error) =>
        set((state) => {
          state.error = error;
          state.isLoading = false;
        }),

      logout: () =>
        set((state) => {
          state.user = null;
          state.isAuthenticated = false;
          state.error = null;
        }),
    })),
    { name: "SessionStore" }
  )
);
'
    write_file_if_missing "src/lib/state/sessionStore.ts" "${session_store}"

    local hydration_helper='"use client";

import { useEffect, useState } from "react";

export function useHydration() {
  const [hydrated, setHydrated] = useState(false);

  useEffect(() => {
    setHydrated(true);
  }, []);

  return hydrated;
}

export function HydrationBoundary({ children }: { children: React.ReactNode }) {
  const hydrated = useHydration();

  if (!hydrated) {
    return null;
  }

  return <>{children}</>;
}
'
    write_file_if_missing "src/lib/state/hydration.tsx" "${hydration_helper}"

    local state_index='export { useSessionStore } from "./sessionStore";
export { useHydration, HydrationBoundary } from "./hydration";
'
    write_file_if_missing "src/lib/state/index.ts" "${state_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Session state library created"
}

main "$@"
