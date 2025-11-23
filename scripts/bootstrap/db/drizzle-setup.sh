#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="db/drizzle-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Install and configure Drizzle ORM + postgres.js"; exit 0; }

    log_info "=== Setting up Drizzle ORM ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "${PKG_DRIZZLE_ORM}"
    add_dependency "${PKG_POSTGRES_JS}"
    add_dependency "${PKG_DRIZZLE_KIT}" true
    add_dependency "${PKG_TSX}" true

    local drizzle_config='import type { Config } from "drizzle-kit";

export default {
  schema: "./src/db/schema.ts",
  out: "./src/db/migrations",
  dialect: "postgresql",
  dbCredentials: { url: process.env.DATABASE_URL! },
  verbose: true,
  strict: true,
} satisfies Config;
'

    write_file_if_missing "drizzle.config.ts" "${drizzle_config}"

    add_npm_script "db:generate" "drizzle-kit generate"
    add_npm_script "db:migrate" "drizzle-kit migrate"
    add_npm_script "db:push" "drizzle-kit push"
    add_npm_script "db:studio" "drizzle-kit studio"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Drizzle ORM setup complete"
}

main "$@"
