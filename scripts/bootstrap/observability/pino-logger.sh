#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="observability/pino-logger.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Pino logger"; exit 0; }

    log_info "=== Setting up Pino Logger ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "pino"

    ensure_dir "src/lib/logger"

    local logger='import pino from "pino";

const isProduction = process.env.NODE_ENV === "production";
const isDevelopment = process.env.NODE_ENV === "development";

export const logger = pino({
  level: process.env.LOG_LEVEL || (isDevelopment ? "debug" : "info"),
  ...(isDevelopment && {
    transport: {
      target: "pino-pretty",
      options: {
        colorize: true,
        ignore: "pid,hostname",
        translateTime: "SYS:standard",
      },
    },
  }),
  ...(isProduction && {
    formatters: {
      level: (label) => ({ level: label }),
    },
    timestamp: pino.stdTimeFunctions.isoTime,
  }),
  base: {
    env: process.env.NODE_ENV,
    app: process.env.APP_NAME || "app",
  },
});

export type Logger = typeof logger;

export function createChildLogger(bindings: Record<string, unknown>): Logger {
  return logger.child(bindings);
}

export const requestLogger = createChildLogger({ module: "request" });
export const dbLogger = createChildLogger({ module: "database" });
export const authLogger = createChildLogger({ module: "auth" });
export const jobLogger = createChildLogger({ module: "jobs" });
'
    write_file_if_missing "src/lib/logger/index.ts" "${logger}"

    local request_logging='import { NextRequest, NextResponse } from "next/server";
import { requestLogger } from "@/lib/logger";

export function withRequestLogging(
  handler: (req: NextRequest) => Promise<NextResponse>
) {
  return async (req: NextRequest): Promise<NextResponse> => {
    const startTime = Date.now();
    const requestId = crypto.randomUUID();

    requestLogger.info({
      requestId,
      method: req.method,
      url: req.url,
      userAgent: req.headers.get("user-agent"),
    }, "Request started");

    try {
      const response = await handler(req);

      requestLogger.info({
        requestId,
        method: req.method,
        url: req.url,
        status: response.status,
        duration: Date.now() - startTime,
      }, "Request completed");

      return response;
    } catch (error) {
      requestLogger.error({
        requestId,
        method: req.method,
        url: req.url,
        error: error instanceof Error ? error.message : "Unknown error",
        duration: Date.now() - startTime,
      }, "Request failed");

      throw error;
    }
  };
}
'
    write_file_if_missing "src/lib/logger/request.ts" "${request_logging}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Pino logger setup complete"
}

main "$@"
