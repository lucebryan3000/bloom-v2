#!/usr/bin/env bash
#!meta
# id: jobs/job-worker-template.sh
# name: job worker template
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - jobs
# uses_from_omni_config:
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - WORKERS_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# jobs/job-worker-template.sh - Job Worker Templates
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Core Features)
# Purpose: Creates job worker templates in src/jobs/workers/
#
# Creates:
#   - src/jobs/workers/email.worker.ts (email sending worker)
#   - src/jobs/workers/index.ts (worker registration)
# =============================================================================
#
# Dependencies:
#   - pg-boss (queue client)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="jobs/job-worker-template"
readonly SCRIPT_NAME="Job Worker Templates"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

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
# DIRECTORY SETUP
# =============================================================================

log_step "Creating worker templates"

WORKERS_DIR="${INSTALL_DIR}/src/jobs/workers"
mkdir -p "${WORKERS_DIR}"

# =============================================================================
# EMAIL WORKER
# =============================================================================

if [[ ! -f "${WORKERS_DIR}/email.worker.ts" ]]; then
    cat > "${WORKERS_DIR}/email.worker.ts" <<'EOF'
/**
 * Email Worker
 *
 * Processes email sending jobs from the queue.
 */

import { registerWorker, JobNames, type SendEmailPayload } from '../index';

// =============================================================================
// Email Sending Logic
// =============================================================================

async function sendEmail(payload: SendEmailPayload): Promise<void> {
  const { to, subject, body, templateId, templateData } = payload;

  // TODO: Integrate with your email provider (Resend, SendGrid, etc.)
  // Example with Resend:
  // import { Resend } from 'resend';
  // const resend = new Resend(env.RESEND_API_KEY);
  //
  // await resend.emails.send({
  //   from: 'noreply@yourdomain.com',
  //   to,
  //   subject,
  //   html: body,
  // });

  console.log(`[EmailWorker] Sending email to: ${to}`);
  console.log(`[EmailWorker] Subject: ${subject}`);

  if (templateId) {
    console.log(`[EmailWorker] Using template: ${templateId}`);
    console.log(`[EmailWorker] Template data:`, templateData);
  }

  // Simulate email sending delay
  await new Promise((resolve) => setTimeout(resolve, 100));

  console.log(`[EmailWorker] Email sent successfully to: ${to}`);
}

// =============================================================================
// Worker Handler
// =============================================================================

export async function handleSendEmail(job: {
  id: string;
  data: SendEmailPayload;
}): Promise<void> {
  console.log(`[EmailWorker] Processing job ${job.id}`);

  await sendEmail(job.data);
}

// =============================================================================
// Worker Registration
// =============================================================================

export async function registerEmailWorker(): Promise<void> {
  await registerWorker(JobNames.SEND_EMAIL, handleSendEmail, {
    teamSize: 2, // Number of concurrent workers
    teamConcurrency: 1, // Jobs per worker at a time
  });

  console.log('[EmailWorker] Registered and ready');
}
EOF
    log_ok "Created ${WORKERS_DIR}/email.worker.ts"
else
    log_skip "${WORKERS_DIR}/email.worker.ts already exists"
fi

# =============================================================================
# WORKER INDEX
# =============================================================================

if [[ ! -f "${WORKERS_DIR}/index.ts" ]]; then
    cat > "${WORKERS_DIR}/index.ts" <<'EOF'
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
EOF
    log_ok "Created ${WORKERS_DIR}/index.ts"
else
    log_skip "${WORKERS_DIR}/index.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"