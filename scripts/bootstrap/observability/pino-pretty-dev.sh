#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="observability/pino-pretty-dev.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup pino-pretty for development"; exit 0; }

    log_info "=== Setting up pino-pretty for Development ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "pino-pretty" "true"

    ensure_dir "src/lib/logger"

    local dev_config='export const pinoPrettyConfig = {
  colorize: true,
  ignore: "pid,hostname",
  translateTime: "SYS:standard",
  messageFormat: "{msg}",
  singleLine: false,
  levelFirst: true,
  customColors: "error:red,warn:yellow,info:green,debug:blue,trace:gray",
} as const;

export const logLevels = {
  fatal: 60,
  error: 50,
  warn: 40,
  info: 30,
  debug: 20,
  trace: 10,
} as const;

export type LogLevel = keyof typeof logLevels;
'
    write_file_if_missing "src/lib/logger/config.ts" "${dev_config}"

    local console_utils='import { logger } from "./index";

export function logError(message: string, error: unknown, context?: Record<string, unknown>): void {
  logger.error({
    ...context,
    error: error instanceof Error ? {
      name: error.name,
      message: error.message,
      stack: error.stack,
    } : error,
  }, message);
}

export function logWithDuration<T>(
  operation: string,
  fn: () => T | Promise<T>,
  context?: Record<string, unknown>
): T | Promise<T> {
  const start = Date.now();
  logger.debug({ ...context, operation }, `Starting ${operation}`);

  const result = fn();

  if (result instanceof Promise) {
    return result.then((value) => {
      logger.info({ ...context, operation, duration: Date.now() - start }, `Completed ${operation}`);
      return value;
    }).catch((error) => {
      logger.error({ ...context, operation, duration: Date.now() - start, error }, `Failed ${operation}`);
      throw error;
    });
  }

  logger.info({ ...context, operation, duration: Date.now() - start }, `Completed ${operation}`);
  return result;
}
'
    write_file_if_missing "src/lib/logger/utils.ts" "${console_utils}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "pino-pretty development setup complete"
}

main "$@"
