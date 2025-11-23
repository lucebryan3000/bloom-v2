#!/usr/bin/env bash
# =============================================================================
# File: phases/03-security/12-env-validation.sh
# Purpose: Set up environment validation using @t3-oss/env-nextjs + Zod
# Assumes: Next.js project exists
# Creates: src/env.ts with validated environment variables
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="12"
readonly SCRIPT_NAME="env-validation"
readonly SCRIPT_DESCRIPTION="Set up environment variable validation with Zod"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Set up env validation
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Installs @t3-oss/env-nextjs and zod
    2. Creates src/env.ts with validated environment schema
    3. Configures required vars: DATABASE_URL, AUTH_SECRET, etc.
    4. Fails fast on missing or invalid environment variables

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting environment validation setup"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_pnpm
    require_file "package.json" "Initialize project first"

    # Step 2: Install dependencies
    log_step "Installing @t3-oss/env-nextjs and zod"

    add_dependency "@t3-oss/env-nextjs"
    add_dependency "zod"

    # Step 3: Create env.ts
    log_step "Creating src/env.ts"

    ensure_dir "src"

    local env_content='import { createEnv } from "@t3-oss/env-nextjs";
import { z } from "zod";

/**
 * Environment variable validation
 *
 * All environment variables are validated at build time and runtime.
 * The application will fail fast if required variables are missing.
 *
 * @see https://env.t3.gg/docs/nextjs
 */
export const env = createEnv({
  /**
   * Server-side environment variables
   * These are only available on the server and will not be exposed to the client.
   */
  server: {
    // Database
    DATABASE_URL: z
      .string()
      .url()
      .refine(
        (url) => url.startsWith("postgresql://") || url.startsWith("postgres://"),
        "DATABASE_URL must be a PostgreSQL connection string"
      ),

    // Authentication
    AUTH_SECRET: z
      .string()
      .min(32, "AUTH_SECRET must be at least 32 characters"),
    AUTH_TRUST_HOST: z
      .string()
      .optional()
      .transform((val) => val === "true"),

    // AI Provider
    ANTHROPIC_API_KEY: z
      .string()
      .startsWith("sk-ant-", "ANTHROPIC_API_KEY must start with sk-ant-")
      .optional(),

    // Node environment
    NODE_ENV: z
      .enum(["development", "test", "production"])
      .default("development"),
  },

  /**
   * Client-side environment variables
   * These are exposed to the client and must be prefixed with NEXT_PUBLIC_.
   */
  client: {
    NEXT_PUBLIC_APP_URL: z.string().url().optional(),
    NEXT_PUBLIC_APP_NAME: z.string().default("Bloom2"),
  },

  /**
   * Runtime environment variables
   *
   * In Next.js, environment variables are replaced at build time.
   * This maps the actual values to the schema for runtime validation.
   */
  runtimeEnv: {
    // Server
    DATABASE_URL: process.env.DATABASE_URL,
    AUTH_SECRET: process.env.AUTH_SECRET,
    AUTH_TRUST_HOST: process.env.AUTH_TRUST_HOST,
    ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
    NODE_ENV: process.env.NODE_ENV,

    // Client
    NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
    NEXT_PUBLIC_APP_NAME: process.env.NEXT_PUBLIC_APP_NAME,
  },

  /**
   * Skip validation in certain environments
   */
  skipValidation: !!process.env.SKIP_ENV_VALIDATION,

  /**
   * Treat empty strings as undefined
   */
  emptyStringAsUndefined: true,
});

/**
 * Type-safe environment access
 *
 * @example
 * ```ts
 * import { env } from "@/env";
 *
 * console.log(env.DATABASE_URL); // Type-safe access
 * ```
 */
export type Env = typeof env;
'

    write_file "src/env.ts" "$env_content"

    # Step 4: Update next.config to use env validation
    log_step "Creating env import helper"

    local env_import='/**
 * Import this file at the top of your application entry points
 * to ensure environment variables are validated early.
 *
 * @example
 * ```ts
 * // In layout.tsx or instrumentation.ts
 * import "@/env";
 * ```
 */
import "./env";
'

    # Just log a note about importing env
    log_info "Note: Import '@/env' in your root layout.tsx to validate environment on startup"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
