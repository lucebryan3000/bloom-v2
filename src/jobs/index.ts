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
