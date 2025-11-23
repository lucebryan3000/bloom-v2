#!/usr/bin/env bash
# =============================================================================
# File: phases/07-jobs/24-job-worker-template.sh
# Purpose: Create job worker entrypoint template
# Creates: src/lib/jobs/worker.ts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="24"
readonly SCRIPT_NAME="job-worker-template"
readonly SCRIPT_DESCRIPTION="Create job worker template"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Creating job worker"
    ensure_dir "src/lib/jobs"

    local worker='import { getJobQueue, JobTypes, stopJobQueue } from "./queue";

/**
 * Job Worker
 *
 * Processes background jobs. Can run standalone or via instrumentation.ts.
 */

interface JobHandlers {
  [key: string]: (data: unknown) => Promise<void>;
}

const handlers: JobHandlers = {
  [JobTypes.PERSIST_SESSION]: async (data) => {
    console.log("Persisting session:", data);
    // TODO: Implement session persistence
  },

  [JobTypes.COMPUTE_ROI]: async (data) => {
    console.log("Computing ROI:", data);
    // TODO: Implement ROI computation
  },

  [JobTypes.GENERATE_REPORT]: async (data) => {
    console.log("Generating report:", data);
    // TODO: Implement report generation
  },
};

export async function startWorker(): Promise<void> {
  const queue = await getJobQueue();

  for (const [jobType, handler] of Object.entries(handlers)) {
    await queue.work(jobType, { teamConcurrency: 2 }, async (job) => {
      console.log(`Processing job ${job.id} (${jobType})`);
      try {
        await handler(job.data);
      } catch (error) {
        console.error(`Job ${job.id} failed:`, error);
        throw error;
      }
    });
  }

  console.log("Job worker started");
}

// Graceful shutdown
async function shutdown(): Promise<void> {
  console.log("Shutting down worker...");
  await stopJobQueue();
  process.exit(0);
}

process.on("SIGTERM", shutdown);
process.on("SIGINT", shutdown);

// Run if executed directly
if (require.main === module) {
  startWorker().catch(console.error);
}
'

    write_file "src/lib/jobs/worker.ts" "$worker"

    local jobs_index='export { getJobQueue, stopJobQueue, publishJob, JobTypes } from "./queue";
export { startWorker } from "./worker";
'
    write_file "src/lib/jobs/index.ts" "$jobs_index"

    add_npm_script "jobs:worker" "tsx src/lib/jobs/worker.ts"
    log_success "Script $SCRIPT_ID completed"
}

main "$@"
