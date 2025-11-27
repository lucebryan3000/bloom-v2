#!/usr/bin/env bash
#!meta
# id: ui/react-to-print.sh
# name: react to print
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ui
# uses_from_omni_config:
#   - ENABLE_SHADCN
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages:
#     - lucide-react
#     - clsx
#     - tailwind-merge
#     - class-variance-authority
#     - react-to-print
#   dev_packages:
#     - tailwindcss
#     - postcss
#     - autoprefixer
#!endmeta

# =============================================================================
# tech_stack/ui/react-to-print.sh - Print Functionality Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3 (User Interface)
# Purpose: Adds react-to-print library and print utilities for document printing
# =============================================================================
#
# Dependencies:
#   - react-to-print
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="ui/react-to-print"
readonly SCRIPT_NAME="Print Functionality (react-to-print)"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_info "Installing react-to-print..."
pkg_install "react-to-print" || {
    log_error "Failed to install react-to-print"
    exit 1
}
log_ok "Installed react-to-print"

# =============================================================================
# CREATE PRINT UTILITIES
# =============================================================================

log_step "Creating print utilities"

mkdir -p src/lib

cat > src/lib/print.ts <<'EOF'
/**
 * Print utilities for document printing functionality
 * Uses react-to-print for component-based printing
 */

import { useRef, useCallback } from 'react';
import { useReactToPrint } from 'react-to-print';

/**
 * Print configuration options
 */
export interface PrintOptions {
  /** Document title shown in print dialog */
  documentTitle?: string;
  /** Callback before print starts */
  onBeforePrint?: () => Promise<void> | void;
  /** Callback after print completes */
  onAfterPrint?: () => void;
  /** Callback on print error */
  onPrintError?: (errorLocation: string, error: Error) => void;
  /** Remove links from printed output */
  removeAfterPrint?: boolean;
  /** Page style overrides for print */
  pageStyle?: string;
}

/**
 * Default print page styles
 * Optimized for clean document output
 */
export const defaultPrintStyles = `
  @page {
    size: auto;
    margin: 20mm;
  }

  @media print {
    body {
      -webkit-print-color-adjust: exact;
      print-color-adjust: exact;
    }

    .no-print {
      display: none !important;
    }

    .print-break-before {
      break-before: page;
    }

    .print-break-after {
      break-after: page;
    }

    .print-avoid-break {
      break-inside: avoid;
    }
  }
`;

/**
 * Hook for printing a component
 *
 * @example
 * ```tsx
 * const { contentRef, handlePrint } = usePrint({
 *   documentTitle: 'My Report',
 * });
 *
 * return (
 *   <>
 *     <div ref={contentRef}>Content to print</div>
 *     <button onClick={handlePrint}>Print</button>
 *   </>
 * );
 * ```
 */
export function usePrint<T extends HTMLElement = HTMLDivElement>(
  options: PrintOptions = {}
) {
  const contentRef = useRef<T>(null);

  const {
    documentTitle = 'Document',
    onBeforePrint,
    onAfterPrint,
    onPrintError,
    pageStyle = defaultPrintStyles,
  } = options;

  const handlePrint = useReactToPrint({
    contentRef,
    documentTitle,
    onBeforePrint: onBeforePrint ? async () => { await onBeforePrint(); } : undefined,
    onAfterPrint,
    onPrintError: onPrintError
      ? (errorLocation, error) => onPrintError(errorLocation, error)
      : undefined,
    pageStyle,
  });

  return {
    contentRef,
    handlePrint,
  };
}

/**
 * Utility to trigger browser print dialog for current page
 */
export function printCurrentPage(): void {
  window.print();
}

/**
 * Check if print is supported in current environment
 */
export function isPrintSupported(): boolean {
  return typeof window !== 'undefined' && typeof window.print === 'function';
}

/**
 * Format date for print headers
 */
export function formatPrintDate(date: Date = new Date()): string {
  return new Intl.DateTimeFormat('en-US', {
    year: 'numeric',
    month: 'long',
    day: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  }).format(date);
}
EOF

log_ok "Created src/lib/print.ts"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"