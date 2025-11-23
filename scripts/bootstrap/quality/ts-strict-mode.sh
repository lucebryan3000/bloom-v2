#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="quality/ts-strict-mode.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Enable TypeScript strict mode"; exit 0; }

    if [[ "${ENABLE_CODE_QUALITY:-true}" != "true" ]]; then
        log_info "SKIP: Code quality disabled via ENABLE_CODE_QUALITY"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Enabling TypeScript Strict Mode ==="
    cd "${PROJECT_ROOT:-.}"

    if [[ ! -f "tsconfig.json" ]]; then
        log_warn "tsconfig.json not found, skipping strict mode configuration"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    if [[ "${DRY_RUN:-false}" == "true" ]]; then
        log_info "DRY RUN: Would update tsconfig.json with strict settings"
    else
        if command -v node >/dev/null 2>&1; then
            node -e "
const fs = require('fs');
const config = JSON.parse(fs.readFileSync('tsconfig.json', 'utf8'));

config.compilerOptions = config.compilerOptions || {};

// Enable strict mode options
config.compilerOptions.strict = true;
config.compilerOptions.noUncheckedIndexedAccess = true;
config.compilerOptions.noImplicitOverride = true;
config.compilerOptions.noPropertyAccessFromIndexSignature = true;
config.compilerOptions.exactOptionalPropertyTypes = false; // Can be too strict for some libs
config.compilerOptions.noFallthroughCasesInSwitch = true;
config.compilerOptions.forceConsistentCasingInFileNames = true;

fs.writeFileSync('tsconfig.json', JSON.stringify(config, null, 2) + '\n');
console.log('Updated tsconfig.json with strict settings');
"
            log_info "Updated tsconfig.json with strict TypeScript settings"
        else
            log_warn "Node.js not found, cannot update tsconfig.json"
        fi
    fi

    ensure_dir "src/types"

    local global_types='// Global type declarations

declare global {
  namespace NodeJS {
    interface ProcessEnv {
      NODE_ENV: "development" | "production" | "test";
      DATABASE_URL: string;
      NEXTAUTH_SECRET: string;
      NEXTAUTH_URL: string;
      ANTHROPIC_API_KEY?: string;
    }
  }
}

// Utility types
export type Prettify<T> = {
  [K in keyof T]: T[K];
} & {};

export type Nullable<T> = T | null;

export type Optional<T> = T | undefined;

export type AsyncReturnType<T extends (...args: unknown[]) => Promise<unknown>> =
  T extends (...args: unknown[]) => Promise<infer R> ? R : never;

export {};
'
    write_file_if_missing "src/types/global.d.ts" "${global_types}"

    local utils_types='// Common utility types for the application

export type Id = string;

export type Timestamp = string;

export interface BaseEntity {
  id: Id;
  createdAt: Timestamp;
  updatedAt: Timestamp;
}

export interface PaginatedResponse<T> {
  data: T[];
  total: number;
  page: number;
  pageSize: number;
  hasMore: boolean;
}

export interface ApiResponse<T> {
  success: boolean;
  data?: T;
  error?: {
    code: string;
    message: string;
  };
}

export type SortDirection = "asc" | "desc";

export interface SortOptions {
  field: string;
  direction: SortDirection;
}
'
    write_file_if_missing "src/types/utils.ts" "${utils_types}"

    local types_index='export * from "./utils";
'
    write_file_if_missing "src/types/index.ts" "${types_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "TypeScript strict mode enabled"
}

main "$@"
