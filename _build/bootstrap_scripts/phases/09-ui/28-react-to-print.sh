#!/usr/bin/env bash
# =============================================================================
# File: phases/09-ui/28-react-to-print.sh
# Purpose: Install react-to-print for PDF exports
# Creates: Print utility component
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="28"
readonly SCRIPT_NAME="react-to-print"
readonly SCRIPT_DESCRIPTION="Install react-to-print for PDF exports"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing react-to-print"
    require_pnpm
    add_dependency "react-to-print"

    log_step "Creating print button component"
    ensure_dir "src/components"

    local print_button='"use client";

import { useRef } from "react";
import { useReactToPrint } from "react-to-print";

/**
 * Print Button Component
 *
 * Triggers browser print dialog for PDF generation.
 *
 * @example
 * ```tsx
 * <PrintButton contentRef={reportRef}>
 *   Export PDF
 * </PrintButton>
 * ```
 */

interface PrintButtonProps {
  contentRef: React.RefObject<HTMLElement | null>;
  documentTitle?: string;
  children: React.ReactNode;
  className?: string;
}

export function PrintButton({
  contentRef,
  documentTitle = "Bloom2 Report",
  children,
  className,
}: PrintButtonProps) {
  const handlePrint = useReactToPrint({
    contentRef,
    documentTitle,
  });

  return (
    <button
      onClick={() => handlePrint()}
      className={className}
      type="button"
    >
      {children}
    </button>
  );
}
'

    write_file "src/components/PrintButton.tsx" "$print_button"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
