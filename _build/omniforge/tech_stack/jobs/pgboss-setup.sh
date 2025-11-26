#!/usr/bin/env bash
#!meta
# id: jobs/pgboss-setup.sh
# name: pgboss-setup
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - jobs
# uses_from_omni_config:
# uses_from_omni_settings:
#   - INSTALL_DIR
#   - JOBS_DIR
#   - PGBOSS_PKG
#   - PROJECT_ROOT
# top_flags:
#   - --dry-run
#   - --skip-install
#   - --dev-only
#   - --no-dev
#   - --force
#   - --no-verify
# dependencies:
#   packages:
#     - pgboss
#   dev_packages:
#     -
#!endmeta


# =============================================================================
# jobs/pgboss-setup.sh - PG-Boss Background Job Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Purpose: Creates pg-boss background job initialization in src/jobs/
#
# Creates:
#   - src/jobs/index.ts (pg-boss initialization and queue management)
#   - src/jobs/types.ts (job type definitions)
#
# Dependencies:
#   - pg-boss
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="jobs/pgboss-setup"
readonly SCRIPT_NAME="PG-Boss Background Jobs"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_error "Project directory does not exist: $INSTALL_DIR"
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing pg-boss"

# pg-boss package (check if PKG_PGBOSS is defined, otherwise use default)
PGBOSS_PKG="${PKG_PGBOSS:-pg-boss}"

DEPS=("${PGBOSS_PKG}")

# Show cache status
pkg_preflight_check "${DEPS[@]}"

# Install dependencies
log_info "Installing ${PGBOSS_PKG}..."
if ! pkg_verify_all "${DEPS[@]}"; then
    if ! pkg_install_retry "${DEPS[@]}"; then
        log_error "Failed to install ${PGBOSS_PKG}"
        exit 1
    fi
else
    log_skip "${PGBOSS_PKG} already installed"
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify "${PGBOSS_PKG}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "pg-boss installed"

# =============================================================================
# DIRECTORY SETUP
# =============================================================================

log_step "Creating jobs structure"

JOBS_DIR="${INSTALL_DIR}/src/jobs"
mkdir -p "${JOBS_DIR}"
mkdir -p "${JOBS_DIR}/workers"

# =============================================================================
# JOB TYPES
# =============================================================================

if [[ ! -f "${JOBS_DIR}/types.ts" ]]; then
    cat > "${JOBS_DIR}/types.ts" <<'EOF'
/**
 * Background Job Type Definitions
 */

// =============================================================================
// Job Names
// =============================================================================

export const JobNames = {
  SEND_EMAIL: 'send-email',
  PROCESS_UPLOAD: 'process-upload',
  GENERATE_REPORT: 'generate-report',
  SYNC_DATA: 'sync-data',
  CLEANUP_EXPIRED: 'cleanup-expired',
} as const;

export type JobName = (typeof JobNames)[keyof typeof JobNames];

// =============================================================================
// Job Payloads
// =============================================================================

export interface SendEmailPayload {
  to: string;
  subject: string;
  body: string;
  templateId?: string;
  templateData?: Record<string, unknown>;
}

export interface ProcessUploadPayload {
  fileId: string;
  userId: string;
  processingType: 'image' | 'document' | 'video';
}

export interface GenerateReportPayload {
  reportType: string;
  userId: string;
  parameters: Record<string, unknown>;
  outputFormat: 'pdf' | 'csv' | 'xlsx';
}

export interface SyncDataPayload {
  sourceId: string;
  targetId: string;
  syncType: 'full' | 'incremental';
}

export interface CleanupExpiredPayload {
  resourceType: string;
  olderThanDays: number;
}

// =============================================================================
// Job Payload Map
// =============================================================================

export interface JobPayloadMap {
  [JobNames.SEND_EMAIL]: SendEmailPayload;
  [JobNames.PROCESS_UPLOAD]: ProcessUploadPayload;
  [JobNames.GENERATE_REPORT]: GenerateReportPayload;
  [JobNames.SYNC_DATA]: SyncDataPayload;
  [JobNames.CLEANUP_EXPIRED]: CleanupExpiredPayload;
}

// =============================================================================
// Job Options
// =============================================================================

export interface JobOptions {
  /** Unique job ID for deduplication */
  singletonKey?: string;
  /** Delay before job becomes available (seconds) */
  startAfter?: number;
  /** Number of retry attempts */
  retryLimit?: number;
  /** Delay between retries (seconds) */
  retryDelay?: number;
  /** Job expires after this many seconds */
  expireInSeconds?: number;
  /** Job priority (higher = more priority) */
  priority?: number;
}
EOF
    log_ok "Created ${JOBS_DIR}/types.ts"
else
    log_skip "${JOBS_DIR}/types.ts already exists"
fi

# =============================================================================
# MAIN INDEX
# =============================================================================

if [[ ! -f "${JOBS_DIR}/index.ts" ]]; then
    cat > "${JOBS_DIR}/index.ts" <<'EOF'
/**
 * PG-Boss Background Job Queue
 *
 * Provides a PostgreSQL-backed job queue for reliable background processing.
 */

import PgBoss from 'pg-boss';
import { env } from '@/lib/env';
import type { JobName, JobPayloadMap, JobOptions } from './types';

// =============================================================================
// Singleton Instance
// =============================================================================

let boss: PgBoss | null = null;

/**
 * Get or create the PgBoss instance
 */
export async function getJobQueue(): Promise<PgBoss> {
  if (boss) {
    return boss;
  }

  boss = new PgBoss({
    connectionString: env.DATABASE_URL,
    // Recommended production settings
    retryLimit: 3,
    retryDelay: 60, // 1 minute between retries
    expireInHours: 24,
    archiveCompletedAfterSeconds: 60 * 60 * 24 * 7, // 7 days
    deleteAfterDays: 30,
    // Monitoring
    monitorStateIntervalSeconds: 30,
  });

  // Handle errors
  boss.on('error', (error) => {
    console.error('[JobQueue] Error:', error);
  });

  // Start the boss
  await boss.start();
  console.log('[JobQueue] Started successfully');

  return boss;
}

/**
 * Stop the job queue gracefully
 */
export async function stopJobQueue(): Promise<void> {
  if (boss) {
    await boss.stop({ graceful: true, timeout: 30000 });
    boss = null;
    console.log('[JobQueue] Stopped');
  }
}

// =============================================================================
// Job Scheduling
// =============================================================================

/**
 * Schedule a job for background processing
 */
export async function scheduleJob<T extends JobName>(
  name: T,
  payload: JobPayloadMap[T],
  options?: JobOptions
): Promise<string | null> {
  const queue = await getJobQueue();

  const jobId = await queue.send(name, payload as object, {
    singletonKey: options?.singletonKey,
    startAfter: options?.startAfter,
    retryLimit: options?.retryLimit,
    retryDelay: options?.retryDelay,
    expireInSeconds: options?.expireInSeconds,
    priority: options?.priority,
  });

  if (jobId) {
    console.log(`[JobQueue] Scheduled job: ${name} (${jobId})`);
  }

  return jobId;
}

/**
 * Schedule a recurring job (cron-style)
 */
export async function scheduleRecurringJob<T extends JobName>(
  name: T,
  cron: string,
  payload: JobPayloadMap[T],
  options?: { tz?: string }
): Promise<void> {
  const queue = await getJobQueue();

  await queue.schedule(name, cron, payload as object, {
    tz: options?.tz ?? 'UTC',
  });

  console.log(`[JobQueue] Scheduled recurring job: ${name} (${cron})`);
}

// =============================================================================
// Worker Registration
// =============================================================================

export type JobHandler<T> = (job: { id: string; data: T }) => Promise<void>;

/**
 * Register a worker to process jobs
 */
export async function registerWorker<T extends JobName>(
  name: T,
  handler: JobHandler<JobPayloadMap[T]>,
  options?: { teamSize?: number; teamConcurrency?: number }
): Promise<void> {
  const queue = await getJobQueue();

  await queue.work(
    name,
    {
      teamSize: options?.teamSize ?? 1,
      teamConcurrency: options?.teamConcurrency ?? 1,
    },
    async (job) => {
      console.log(`[Worker:${name}] Processing job: ${job.id}`);
      try {
        await handler({ id: job.id, data: job.data as JobPayloadMap[T] });
        console.log(`[Worker:${name}] Completed job: ${job.id}`);
      } catch (error) {
        console.error(`[Worker:${name}] Failed job: ${job.id}`, error);
        throw error; // Re-throw to trigger retry
      }
    }
  );

  console.log(`[JobQueue] Registered worker: ${name}`);
}

// =============================================================================
// Re-exports
// =============================================================================

export * from './types';
EOF
    log_ok "Created ${JOBS_DIR}/index.ts"
else
    log_skip "${JOBS_DIR}/index.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
