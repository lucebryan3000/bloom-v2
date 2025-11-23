#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="ui/react-to-print.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup react-to-print"; exit 0; }

    if [[ "${ENABLE_PDF_EXPORTS:-true}" != "true" ]]; then
        log_info "SKIP: PDF exports disabled via ENABLE_PDF_EXPORTS"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up react-to-print ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "react-to-print"

    ensure_dir "src/components/print"

    local print_button='"use client";

import { useRef, type ReactNode } from "react";
import { useReactToPrint } from "react-to-print";
import { Button } from "@/components/ui/button";

interface PrintButtonProps {
  children: ReactNode;
  documentTitle?: string;
  buttonText?: string;
  className?: string;
}

export function PrintButton({
  children,
  documentTitle = "Document",
  buttonText = "Print",
  className,
}: PrintButtonProps) {
  const contentRef = useRef<HTMLDivElement>(null);

  const handlePrint = useReactToPrint({
    contentRef,
    documentTitle,
    onBeforePrint: async () => {
      console.log("Preparing to print...");
    },
    onAfterPrint: () => {
      console.log("Print completed");
    },
  });

  return (
    <div className={className}>
      <Button onClick={() => handlePrint()} variant="outline" size="sm">
        {buttonText}
      </Button>
      <div style={{ display: "none" }}>
        <div ref={contentRef}>{children}</div>
      </div>
    </div>
  );
}
'
    write_file_if_missing "src/components/print/PrintButton.tsx" "${print_button}"

    local printable_wrapper='"use client";

import { forwardRef, type ReactNode } from "react";
import { cn } from "@/lib/utils";

interface PrintableContentProps {
  children: ReactNode;
  className?: string;
  pageBreakBefore?: boolean;
}

export const PrintableContent = forwardRef<HTMLDivElement, PrintableContentProps>(
  ({ children, className, pageBreakBefore }, ref) => {
    return (
      <div
        ref={ref}
        className={cn(
          "print:block print:bg-white print:text-black",
          pageBreakBefore && "print:break-before-page",
          className
        )}
      >
        {children}
      </div>
    );
  }
);

PrintableContent.displayName = "PrintableContent";

export function PrintOnly({ children }: { children: ReactNode }) {
  return <div className="hidden print:block">{children}</div>;
}

export function NoPrint({ children }: { children: ReactNode }) {
  return <div className="print:hidden">{children}</div>;
}
'
    write_file_if_missing "src/components/print/PrintableContent.tsx" "${printable_wrapper}"

    local print_index='export { PrintButton } from "./PrintButton";
export { PrintableContent, PrintOnly, NoPrint } from "./PrintableContent";
'
    write_file_if_missing "src/components/print/index.ts" "${print_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "react-to-print setup complete"
}

main "$@"
