/**
 * Worker Registration
 *
 * Centralizes registration of all job workers.
 * Call this once during application startup.
 */

import { registerEmailWorker } from './email.worker';

// =============================================================================
// Register All Workers
// =============================================================================

export async function registerAllWorkers(): Promise<void> {
  console.log('[Workers] Registering all workers...');

  await Promise.all([
    registerEmailWorker(),
    // Add more workers here as needed:
    // registerUploadWorker(),
    // registerReportWorker(),
  ]);

  console.log('[Workers] All workers registered');
}

// =============================================================================
// Re-exports
// =============================================================================

export { registerEmailWorker } from './email.worker';
