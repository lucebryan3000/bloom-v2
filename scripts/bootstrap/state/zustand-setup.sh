#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="state/zustand-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Zustand state management"; exit 0; }

    if [[ "${ENABLE_ZUSTAND:-true}" != "true" ]]; then
        log_info "SKIP: Zustand disabled via ENABLE_ZUSTAND"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Zustand ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "zustand"

    ensure_dir "src/stores"

    local app_store='import { create } from "zustand";
import { devtools, persist } from "zustand/middleware";
import { immer } from "zustand/middleware/immer";

interface AppState {
  theme: "light" | "dark" | "system";
  sidebarOpen: boolean;
  notifications: Array<{
    id: string;
    type: "info" | "success" | "warning" | "error";
    message: string;
  }>;
}

interface AppActions {
  setTheme: (theme: AppState["theme"]) => void;
  toggleSidebar: () => void;
  addNotification: (notification: Omit<AppState["notifications"][0], "id">) => void;
  removeNotification: (id: string) => void;
  clearNotifications: () => void;
}

export const useAppStore = create<AppState & AppActions>()(
  devtools(
    persist(
      immer((set) => ({
        theme: "system",
        sidebarOpen: true,
        notifications: [],

        setTheme: (theme) =>
          set((state) => {
            state.theme = theme;
          }),

        toggleSidebar: () =>
          set((state) => {
            state.sidebarOpen = !state.sidebarOpen;
          }),

        addNotification: (notification) =>
          set((state) => {
            state.notifications.push({
              ...notification,
              id: crypto.randomUUID(),
            });
          }),

        removeNotification: (id) =>
          set((state) => {
            state.notifications = state.notifications.filter((n) => n.id !== id);
          }),

        clearNotifications: () =>
          set((state) => {
            state.notifications = [];
          }),
      })),
      { name: "app-store" }
    ),
    { name: "AppStore" }
  )
);
'
    write_file_if_missing "src/stores/appStore.ts" "${app_store}"

    add_dependency "immer"

    local stores_index='export { useAppStore } from "./appStore";
'
    write_file_if_missing "src/stores/index.ts" "${stores_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Zustand setup complete"
}

main "$@"
