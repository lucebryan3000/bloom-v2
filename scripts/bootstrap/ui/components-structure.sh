#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="ui/components-structure.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create components directory structure"; exit 0; }

    log_info "=== Creating Components Structure ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/components/ui"
    ensure_dir "src/components/layout"
    ensure_dir "src/components/forms"
    ensure_dir "src/components/data"
    ensure_dir "src/components/feedback"

    local layout_header='import { cn } from "@/lib/utils";

interface HeaderProps {
  className?: string;
  children?: React.ReactNode;
}

export function Header({ className, children }: HeaderProps) {
  return (
    <header className={cn("sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur", className)}>
      <div className="container flex h-14 items-center">
        {children}
      </div>
    </header>
  );
}
'
    write_file_if_missing "src/components/layout/Header.tsx" "${layout_header}"

    local layout_footer='import { cn } from "@/lib/utils";

interface FooterProps {
  className?: string;
  children?: React.ReactNode;
}

export function Footer({ className, children }: FooterProps) {
  return (
    <footer className={cn("border-t py-6 md:py-0", className)}>
      <div className="container flex flex-col items-center justify-between gap-4 md:h-16 md:flex-row">
        {children || (
          <p className="text-sm text-muted-foreground">
            &copy; {new Date().getFullYear()} All rights reserved.
          </p>
        )}
      </div>
    </footer>
  );
}
'
    write_file_if_missing "src/components/layout/Footer.tsx" "${layout_footer}"

    local layout_index='export { Header } from "./Header";
export { Footer } from "./Footer";
'
    write_file_if_missing "src/components/layout/index.ts" "${layout_index}"

    local loading_spinner='import { cn } from "@/lib/utils";

interface LoadingSpinnerProps {
  className?: string;
  size?: "sm" | "md" | "lg";
}

const sizeClasses = {
  sm: "h-4 w-4",
  md: "h-8 w-8",
  lg: "h-12 w-12",
};

export function LoadingSpinner({ className, size = "md" }: LoadingSpinnerProps) {
  return (
    <div
      className={cn(
        "animate-spin rounded-full border-2 border-current border-t-transparent",
        sizeClasses[size],
        className
      )}
      role="status"
      aria-label="Loading"
    >
      <span className="sr-only">Loading...</span>
    </div>
  );
}
'
    write_file_if_missing "src/components/feedback/LoadingSpinner.tsx" "${loading_spinner}"

    local error_boundary='"use client";

import { Component, type ReactNode } from "react";

interface Props {
  children: ReactNode;
  fallback?: ReactNode;
}

interface State {
  hasError: boolean;
  error?: Error;
}

export class ErrorBoundary extends Component<Props, State> {
  constructor(props: Props) {
    super(props);
    this.state = { hasError: false };
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error };
  }

  componentDidCatch(error: Error, errorInfo: React.ErrorInfo) {
    console.error("Error caught by boundary:", error, errorInfo);
  }

  render() {
    if (this.state.hasError) {
      return this.props.fallback || (
        <div className="flex flex-col items-center justify-center min-h-[200px] p-4">
          <h2 className="text-lg font-semibold text-destructive">Something went wrong</h2>
          <p className="text-sm text-muted-foreground mt-2">
            {this.state.error?.message || "An unexpected error occurred"}
          </p>
          <button
            onClick={() => this.setState({ hasError: false, error: undefined })}
            className="mt-4 px-4 py-2 text-sm bg-primary text-primary-foreground rounded-md hover:bg-primary/90"
          >
            Try again
          </button>
        </div>
      );
    }

    return this.props.children;
  }
}
'
    write_file_if_missing "src/components/feedback/ErrorBoundary.tsx" "${error_boundary}"

    local feedback_index='export { LoadingSpinner } from "./LoadingSpinner";
export { ErrorBoundary } from "./ErrorBoundary";
'
    write_file_if_missing "src/components/feedback/index.ts" "${feedback_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Components structure created"
}

main "$@"
