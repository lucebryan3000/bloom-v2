#!/usr/bin/env bash
# =============================================================================
# File: phases/09-ui/29-components-structure.sh
# Purpose: Create src/components/ and basic layout components
# Creates: LayoutShell, PageHeader, etc.
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="29"
readonly SCRIPT_NAME="components-structure"
readonly SCRIPT_DESCRIPTION="Create base layout components"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Creating layout components"
    ensure_dir "src/components/layout"

    local layout_shell='"use client";

import { useSidebarOpen } from "@/lib/stores";
import { cn } from "@/lib/utils";

/**
 * Layout Shell
 *
 * Main application layout with sidebar and header.
 */

interface LayoutShellProps {
  children: React.ReactNode;
  sidebar?: React.ReactNode;
  header?: React.ReactNode;
}

export function LayoutShell({ children, sidebar, header }: LayoutShellProps) {
  const sidebarOpen = useSidebarOpen();

  return (
    <div className="min-h-screen flex flex-col">
      {header && (
        <header className="h-16 border-b border-gray-200 dark:border-gray-800 bg-white dark:bg-gray-900">
          {header}
        </header>
      )}

      <div className="flex flex-1">
        {sidebar && (
          <aside
            className={cn(
              "w-64 border-r border-gray-200 dark:border-gray-800 bg-gray-50 dark:bg-gray-900 transition-all",
              !sidebarOpen && "w-0 overflow-hidden"
            )}
          >
            {sidebar}
          </aside>
        )}

        <main className="flex-1 overflow-auto">{children}</main>
      </div>
    </div>
  );
}
'

    write_file "src/components/layout/LayoutShell.tsx" "$layout_shell"

    local page_header='interface PageHeaderProps {
  title: string;
  description?: string;
  actions?: React.ReactNode;
}

export function PageHeader({ title, description, actions }: PageHeaderProps) {
  return (
    <div className="flex items-center justify-between px-6 py-4 border-b border-gray-200 dark:border-gray-700">
      <div>
        <h1 className="text-2xl font-bold text-gray-900 dark:text-white">
          {title}
        </h1>
        {description && (
          <p className="mt-1 text-sm text-gray-500 dark:text-gray-400">
            {description}
          </p>
        )}
      </div>
      {actions && <div className="flex gap-2">{actions}</div>}
    </div>
  );
}
'

    write_file "src/components/layout/PageHeader.tsx" "$page_header"

    local layout_index='export { LayoutShell } from "./LayoutShell";
export { PageHeader } from "./PageHeader";
'
    write_file "src/components/layout/index.ts" "$layout_index"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
