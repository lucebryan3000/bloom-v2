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
