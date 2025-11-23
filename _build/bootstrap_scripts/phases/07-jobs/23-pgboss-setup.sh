#!/usr/bin/env bash
# =============================================================================
# File: phases/07-jobs/23-pgboss-setup.sh
# Purpose: Install and configure pg-boss job queue
# Creates: src/lib/jobs/queue.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="23"
readonly SCRIPT_NAME="pgboss-setup"
readonly SCRIPT_DESCRIPTION="Install and configure pg-boss job queue"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing pg-boss"
    require_pnpm
    add_dependency "pg-boss"

    log_step "Creating job queue configuration"
    ensure_dir "src/lib/jobs"

    local queue='import PgBoss from "pg-boss";

/**
 * PG-Boss Job Queue
 *
 * Postgres-native job queue for background tasks.
 */

let boss: PgBoss | null = null;

export async function getJobQueue(): Promise<PgBoss> {
  if (boss) return boss;

  boss = new PgBoss({
    connectionString: process.env.DATABASE_URL!,
    retryLimit: 3,
    retryDelay: 5000,
    expireInHours: 24,
  });

  boss.on("error", (error) => {
    console.error("PgBoss error:", error);
  });

  await boss.start();
  return boss;
}

export async function stopJobQueue(): Promise<void> {
  if (boss) {
    await boss.stop();
    boss = null;
  }
}

// Job type definitions
export const JobTypes = {
  PERSIST_SESSION: "persist-session-state",
  COMPUTE_ROI: "compute-roi-confidence",
  GENERATE_REPORT: "generate-report-cache",
} as const;

export type JobType = typeof JobTypes[keyof typeof JobTypes];

// Type-safe job publishing
export async function publishJob<T>(
  type: JobType,
  data: T,
  options?: PgBoss.PublishOptions
): Promise<string | null> {
  const queue = await getJobQueue();
  return queue.publish(type, data, options);
}
'

    write_file "src/lib/jobs/queue.ts" "$queue"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
