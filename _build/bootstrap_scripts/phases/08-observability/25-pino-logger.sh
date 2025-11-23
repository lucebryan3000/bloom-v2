#!/usr/bin/env bash
# =============================================================================
# File: phases/08-observability/25-pino-logger.sh
# Purpose: Install and configure Pino logger
# Creates: src/lib/logger.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="25"
readonly SCRIPT_NAME="pino-logger"
readonly SCRIPT_DESCRIPTION="Install and configure Pino structured logger"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing Pino"
    require_pnpm
    add_dependency "pino"
    add_dependency "pino-pretty" "true"

    log_step "Creating logger configuration"

    local logger='import pino from "pino";

/**
 * Pino Logger Configuration
 *
 * Structured JSON logging for production,
 * pretty-printed for development.
 */

const isDev = process.env.NODE_ENV === "development";

export const logger = pino({
  level: process.env.LOG_LEVEL || (isDev ? "debug" : "info"),
  ...(isDev && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        translateTime: "SYS:standard",
        ignore: "pid,hostname",
      },
    },
  }),
  base: {
    env: process.env.NODE_ENV,
  },
  formatters: {
    level: (label) => ({ level: label }),
  },
});

// Convenience methods with context
export const createLogger = (context: Record<string, unknown>) =>
  logger.child(context);

// Pre-configured loggers for common contexts
export const dbLogger = createLogger({ module: "database" });
export const aiLogger = createLogger({ module: "ai" });
export const authLogger = createLogger({ module: "auth" });
export const jobLogger = createLogger({ module: "jobs" });

export type Logger = typeof logger;
'

    write_file "src/lib/logger.ts" "$logger"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
