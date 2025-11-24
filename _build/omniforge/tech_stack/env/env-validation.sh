#!/usr/bin/env bash
# =============================================================================
# env/env-validation.sh - Environment Variable Validation
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 1 (Infrastructure)
# Purpose: Create Zod-based environment validation with T3 Env pattern
#
# Creates:
#   - src/env.ts (environment validation schema)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="env/env-validation"
readonly SCRIPT_NAME="Environment Validation"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$PROJECT_ROOT"

# Create env validation file
if [[ ! -f "src/env.ts" ]]; then
    cat > src/env.ts << 'EOF'
/**
 * Environment Variable Validation
 * Uses Zod for runtime validation of environment variables
 *
 * @see https://env.t3.gg for the T3 Env pattern
 */

import { z } from 'zod';

/**
 * Server-side environment variables schema
 */
const serverSchema = z.object({
  // Node environment
  NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),

  // Database
  DB_HOST: z.string().default('localhost'),
  DB_PORT: z.coerce.number().default(5432),
  DB_NAME: z.string().min(1),
  DB_USER: z.string().min(1),
  DB_PASSWORD: z.string().min(1),
  DATABASE_URL: z.string().url().optional(),

  // Auth (optional - enabled when using Auth.js)
  AUTH_SECRET: z.string().min(32).optional(),

  // AI (optional - enabled when using AI SDK)
  OPENAI_API_KEY: z.string().startsWith('sk-').optional(),
  ANTHROPIC_API_KEY: z.string().startsWith('sk-ant-').optional(),
});

/**
 * Client-side environment variables schema
 * Only NEXT_PUBLIC_* variables are exposed to client
 */
const clientSchema = z.object({
  NEXT_PUBLIC_APP_URL: z.string().url().optional(),
});

/**
 * Validate and export typed environment variables
 */
const processEnv = {
  NODE_ENV: process.env.NODE_ENV,
  DB_HOST: process.env.DB_HOST,
  DB_PORT: process.env.DB_PORT,
  DB_NAME: process.env.DB_NAME,
  DB_USER: process.env.DB_USER,
  DB_PASSWORD: process.env.DB_PASSWORD,
  DATABASE_URL: process.env.DATABASE_URL,
  AUTH_SECRET: process.env.AUTH_SECRET,
  OPENAI_API_KEY: process.env.OPENAI_API_KEY,
  ANTHROPIC_API_KEY: process.env.ANTHROPIC_API_KEY,
  NEXT_PUBLIC_APP_URL: process.env.NEXT_PUBLIC_APP_URL,
};

// Parse and validate
const serverEnv = serverSchema.safeParse(processEnv);
const clientEnv = clientSchema.safeParse(processEnv);

if (!serverEnv.success) {
  console.error('❌ Invalid server environment variables:');
  console.error(serverEnv.error.flatten().fieldErrors);
  throw new Error('Invalid server environment variables');
}

if (!clientEnv.success) {
  console.error('❌ Invalid client environment variables:');
  console.error(clientEnv.error.flatten().fieldErrors);
  throw new Error('Invalid client environment variables');
}

/**
 * Validated server environment variables
 */
export const env = {
  ...serverEnv.data,
  ...clientEnv.data,
};

export type Env = typeof env;
EOF
    log_ok "Created src/env.ts"
else
    log_skip "src/env.ts already exists"
fi

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
