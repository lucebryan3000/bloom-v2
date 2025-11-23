#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="db/drizzle-migrations.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Configure migration scripts"; exit 0; }

    log_info "=== Setting up Migrations ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/db/migrations"
    ensure_dir "scripts"

    local migrate_sh='#!/usr/bin/env bash
set -euo pipefail
echo "Running database migrations..."
MAX_RETRIES=30
for i in $(seq 1 $MAX_RETRIES); do
    if node -e "require(\"postgres\")(process.env.DATABASE_URL)\`SELECT 1\`.then(()=>process.exit(0)).catch(()=>process.exit(1))" 2>/dev/null; then
        break
    fi
    echo "Waiting for database... ($i/$MAX_RETRIES)"
    sleep 2
done
pnpm db:migrate
echo "Migrations complete!"
'
    write_file_if_missing "scripts/migrate.sh" "${migrate_sh}"
    [[ "${DRY_RUN:-false}" != "true" ]] && chmod +x scripts/migrate.sh 2>/dev/null || true

    add_npm_script "db:seed" "tsx src/db/seed.ts"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Migrations configured"
}

main "$@"
