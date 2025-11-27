#!/usr/bin/env bash
#!meta
# id: observability/pino-logger.sh
# name: pino logger
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - observability
# uses_from_omni_config:
#   - ENABLE_OBSERVABILITY
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PKG_PINO
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - PKG_PINO
# top_flags:
# dependencies:
#   packages:
#     - pino
#   dev_packages: []
#!endmeta


# =============================================================================
# observability/pino-logger.sh - Pino Logger Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Purpose: Creates Pino logger setup in src/lib/logger.ts
#
# Creates:
#   - src/lib/logger.ts (Pino logger configuration)
#
# Dependencies:
#   - pino
#   - pino-pretty (dev, optional)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="observability/pino-logger"
readonly SCRIPT_NAME="Pino Logger Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Project directory does not exist: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing Pino"

# Pino packages (check if PKG_PINO is defined, otherwise use default)
PINO_PKG="${PKG_PINO:-pino}"

DEPS=("${PINO_PKG}")

# Show cache status
pkg_preflight_check "${DEPS[@]}"

# Install dependencies
log_info "Installing ${PINO_PKG}..."
if ! pkg_verify_all "${DEPS[@]}"; then
    if ! pkg_install_retry "${DEPS[@]}"; then
        log_error "Failed to install ${PINO_PKG}"
        exit 1
    fi
else
    log_skip "${PINO_PKG} already installed"
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify "${PINO_PKG}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "Pino installed"

# =============================================================================
# LOGGER SETUP
# =============================================================================

log_step "Creating logger configuration"

LIB_DIR="${INSTALL_DIR}/src/lib"
mkdir -p "${LIB_DIR}"

if [[ ! -f "${LIB_DIR}/logger.ts" ]]; then
    cat > "${LIB_DIR}/logger.ts" <<'EOF'
/**
 * Pino Logger Configuration
 *
 * Provides structured JSON logging for production and pretty-printed
 * output for development.
 */

import pino from 'pino';

// =============================================================================
// Environment Detection
// =============================================================================

const isDevelopment = process.env.NODE_ENV === 'development';
const isTest = process.env.NODE_ENV === 'test';
const logLevel = process.env.LOG_LEVEL ?? (isDevelopment ? 'debug' : 'info');

// =============================================================================
// Logger Configuration
// =============================================================================

const devTransport = {
  target: 'pino-pretty',
  options: {
    colorize: true,
    translateTime: 'SYS:standard',
    ignore: 'pid,hostname',
  },
};

export const logger = pino({
  level: isTest ? 'silent' : logLevel,
  // Use pretty printing in development (requires pino-pretty dev dependency)
  ...(isDevelopment && {
    transport: devTransport,
  }),
  // Base properties included in every log
  base: {
    env: process.env.NODE_ENV,
  },
  // Customize serializers for common objects
  serializers: {
    err: pino.stdSerializers.err,
    req: pino.stdSerializers.req,
    res: pino.stdSerializers.res,
  },
  // Redact sensitive fields
  redact: {
    paths: [
      'password',
      'secret',
      'token',
      'apiKey',
      'authorization',
      'req.headers.authorization',
      'req.headers.cookie',
    ],
    censor: '[REDACTED]',
  },
});

// =============================================================================
// Child Loggers for Different Contexts
// =============================================================================

/**
 * Create a child logger with additional context
 */
export function createLogger(name: string, bindings?: Record<string, unknown>) {
  return logger.child({ name, ...bindings });
}

// Pre-configured loggers for common use cases
export const dbLogger = createLogger('database');
export const apiLogger = createLogger('api');
export const authLogger = createLogger('auth');
export const jobLogger = createLogger('jobs');

// =============================================================================
// Request Logger Middleware (for API routes)
// =============================================================================

/**
 * Log an API request with timing information
 */
export function logRequest(
  req: { method: string; url: string; headers?: Record<string, unknown> },
  res: { statusCode: number },
  responseTime: number
) {
  const level = res.statusCode >= 500 ? 'error' : res.statusCode >= 400 ? 'warn' : 'info';

  apiLogger[level]({
    msg: `${req.method} ${req.url}`,
    method: req.method,
    url: req.url,
    statusCode: res.statusCode,
    responseTime: `${responseTime}ms`,
  });
}

// =============================================================================
// Utility Functions
// =============================================================================

/**
 * Log an error with stack trace
 */
export function logError(error: Error, context?: Record<string, unknown>) {
  logger.error({
    err: error,
    ...context,
  });
}

/**
 * Log a warning
 */
export function logWarn(message: string, context?: Record<string, unknown>) {
  logger.warn({
    msg: message,
    ...context,
  });
}

/**
 * Log debug information (only in development)
 */
export function logDebug(message: string, context?: Record<string, unknown>) {
  logger.debug({
    msg: message,
    ...context,
  });
}

// =============================================================================
// Default Export
// =============================================================================

export default logger;
EOF
    log_ok "Created ${LIB_DIR}/logger.ts"
else
    log_skip "${LIB_DIR}/logger.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
