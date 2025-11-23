#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="db/db-client-index.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create database client"; exit 0; }

    log_info "=== Creating DB Client ==="
    cd "${PROJECT_ROOT:-.}"

    local client='import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";
import * as schema from "./schema";

if (!process.env.DATABASE_URL) throw new Error("DATABASE_URL not set");

const sql = postgres(process.env.DATABASE_URL, {
  max: process.env.NODE_ENV === "production" ? 10 : 3,
  idle_timeout: 20,
});

export const db = drizzle(sql, { schema, logger: process.env.NODE_ENV === "development" });
export type Database = typeof db;
export * from "./schema";

export async function checkDatabaseHealth(): Promise<boolean> {
  try { await sql`SELECT 1`; return true; } catch { return false; }
}
'
    write_file_if_missing "src/db/index.ts" "${client}"

    ensure_dir "src/app/api/health"
    local health='import { NextResponse } from "next/server";
import { checkDatabaseHealth } from "@/db";

export async function GET() {
  const dbHealthy = await checkDatabaseHealth();
  return NextResponse.json({ status: dbHealthy ? "healthy" : "unhealthy", timestamp: new Date().toISOString() }, { status: dbHealthy ? 200 : 503 });
}
'
    write_file_if_missing "src/app/api/health/route.ts" "${health}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "DB client created"
}

main "$@"
