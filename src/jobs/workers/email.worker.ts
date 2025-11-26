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
  await registerWorker(JobNames.SEND_EMAIL, handleSendEmail);

  console.log('[EmailWorker] Registered and ready');
}
