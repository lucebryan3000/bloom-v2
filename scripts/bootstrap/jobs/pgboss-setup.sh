#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="jobs/pgboss-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup pg-boss job queue"; exit 0; }

    if [[ "${ENABLE_PG_BOSS:-true}" != "true" ]]; then
        log_info "SKIP: pg-boss disabled via ENABLE_PG_BOSS"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up pg-boss ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "pg-boss"

    ensure_dir "src/lib/jobs"

    local boss_client='import PgBoss from "pg-boss";

let boss: PgBoss | null = null;

export async function getBoss(): Promise<PgBoss> {
  if (boss) return boss;

  if (!process.env.DATABASE_URL) {
    throw new Error("DATABASE_URL environment variable is not set");
  }

  boss = new PgBoss({
    connectionString: process.env.DATABASE_URL,
    retryLimit: 3,
    retryDelay: 1000,
    retryBackoff: true,
    expireInHours: 24,
    archiveCompletedAfterSeconds: 3600,
    deleteAfterDays: 7,
  });

  boss.on("error", (error) => {
    console.error("pg-boss error:", error);
  });

  await boss.start();
  console.log("pg-boss started");

  return boss;
}

export async function stopBoss(): Promise<void> {
  if (boss) {
    await boss.stop({ graceful: true, timeout: 30000 });
    boss = null;
    console.log("pg-boss stopped");
  }
}

export type { PgBoss };
'
    write_file_if_missing "src/lib/jobs/client.ts" "${boss_client}"

    local job_types='export const JOB_QUEUES = {
  EMAIL: "email",
  NOTIFICATIONS: "notifications",
  REPORTS: "reports",
  CLEANUP: "cleanup",
} as const;

export type JobQueue = (typeof JOB_QUEUES)[keyof typeof JOB_QUEUES];

export interface EmailJobData {
  to: string;
  subject: string;
  template: string;
  data: Record<string, unknown>;
}

export interface NotificationJobData {
  userId: string;
  type: string;
  message: string;
  metadata?: Record<string, unknown>;
}

export interface ReportJobData {
  reportId: string;
  userId: string;
  format: "pdf" | "csv" | "xlsx";
}

export interface CleanupJobData {
  table: string;
  olderThanDays: number;
}

export type JobDataMap = {
  [JOB_QUEUES.EMAIL]: EmailJobData;
  [JOB_QUEUES.NOTIFICATIONS]: NotificationJobData;
  [JOB_QUEUES.REPORTS]: ReportJobData;
  [JOB_QUEUES.CLEANUP]: CleanupJobData;
};
'
    write_file_if_missing "src/lib/jobs/types.ts" "${job_types}"

    local jobs_index='export { getBoss, stopBoss, type PgBoss } from "./client";
export { JOB_QUEUES, type JobQueue, type JobDataMap } from "./types";
'
    write_file_if_missing "src/lib/jobs/index.ts" "${jobs_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "pg-boss setup complete"
}

main "$@"
