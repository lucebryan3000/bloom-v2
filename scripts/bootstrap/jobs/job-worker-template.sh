#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="jobs/job-worker-template.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create job worker templates"; exit 0; }

    if [[ "${ENABLE_PG_BOSS:-true}" != "true" ]]; then
        log_info "SKIP: pg-boss disabled via ENABLE_PG_BOSS"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Creating Job Worker Templates ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/lib/jobs/workers"

    local base_worker='import type { Job } from "pg-boss";
import { getBoss } from "../client";
import type { JobQueue, JobDataMap } from "../types";

export abstract class BaseWorker<Q extends JobQueue> {
  protected queue: Q;

  constructor(queue: Q) {
    this.queue = queue;
  }

  abstract process(job: Job<JobDataMap[Q]>): Promise<void>;

  async register(): Promise<void> {
    const boss = await getBoss();

    await boss.work<JobDataMap[Q]>(
      this.queue,
      { teamSize: 5, teamConcurrency: 2 },
      async (job) => {
        const startTime = Date.now();
        console.log(`[${this.queue}] Processing job ${job.id}`);

        try {
          await this.process(job);
          console.log(
            `[${this.queue}] Job ${job.id} completed in ${Date.now() - startTime}ms`
          );
        } catch (error) {
          console.error(`[${this.queue}] Job ${job.id} failed:`, error);
          throw error;
        }
      }
    );

    console.log(`[${this.queue}] Worker registered`);
  }
}
'
    write_file_if_missing "src/lib/jobs/workers/base.ts" "${base_worker}"

    local email_worker='import type { Job } from "pg-boss";
import { BaseWorker } from "./base";
import { JOB_QUEUES, type EmailJobData } from "../types";

export class EmailWorker extends BaseWorker<typeof JOB_QUEUES.EMAIL> {
  constructor() {
    super(JOB_QUEUES.EMAIL);
  }

  async process(job: Job<EmailJobData>): Promise<void> {
    const { to, subject, template, data } = job.data;

    // TODO: Implement email sending logic
    console.log(`Sending email to ${to}: ${subject}`);
    console.log(`Template: ${template}`, data);

    // Simulate email sending
    await new Promise((resolve) => setTimeout(resolve, 100));
  }
}
'
    write_file_if_missing "src/lib/jobs/workers/email.ts" "${email_worker}"

    local scheduler='import { getBoss } from "./client";
import { JOB_QUEUES, type JobQueue, type JobDataMap } from "./types";

interface ScheduleOptions {
  startAfter?: Date | string;
  retryLimit?: number;
  expireInSeconds?: number;
  singletonKey?: string;
}

export async function scheduleJob<Q extends JobQueue>(
  queue: Q,
  data: JobDataMap[Q],
  options?: ScheduleOptions
): Promise<string | null> {
  const boss = await getBoss();

  const jobId = await boss.send(queue, data, {
    startAfter: options?.startAfter,
    retryLimit: options?.retryLimit ?? 3,
    expireInSeconds: options?.expireInSeconds ?? 3600,
    singletonKey: options?.singletonKey,
  });

  console.log(`Scheduled job ${jobId} in queue ${queue}`);
  return jobId;
}

export async function scheduleCronJob<Q extends JobQueue>(
  queue: Q,
  cron: string,
  data: JobDataMap[Q]
): Promise<void> {
  const boss = await getBoss();

  await boss.schedule(queue, cron, data);
  console.log(`Scheduled cron job in queue ${queue}: ${cron}`);
}
'
    write_file_if_missing "src/lib/jobs/scheduler.ts" "${scheduler}"

    local workers_index='export { BaseWorker } from "./base";
export { EmailWorker } from "./email";
'
    write_file_if_missing "src/lib/jobs/workers/index.ts" "${workers_index}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Job worker templates created"
}

main "$@"
