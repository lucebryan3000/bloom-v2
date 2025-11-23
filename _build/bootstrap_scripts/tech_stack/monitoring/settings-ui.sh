#!/usr/bin/env bash
# =============================================================================
# Script: monitoring/settings-ui.sh
# Purpose: Set up user settings and preferences UI
# Reference: PRD Section 6.13 - Settings & User Preferences
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"

readonly SCRIPT_ID="monitoring/settings-ui"
readonly SCRIPT_NAME="Settings UI Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# CREATE SETTINGS DIRECTORY
# =============================================================================

SETTINGS_DIR="${PROJECT_ROOT}/src/lib/settings"
ensure_dir "${SETTINGS_DIR}" "Settings library directory"

SETTINGS_COMPONENTS="${PROJECT_ROOT}/src/components/settings"
ensure_dir "${SETTINGS_COMPONENTS}" "Settings components directory"

# =============================================================================
# SETTINGS SCHEMA & TYPES
# =============================================================================

write_file "${SETTINGS_DIR}/types.ts" <<'EOF'
/**
 * User Settings & Preferences
 * Defines the shape of all user-configurable settings
 */

import { z } from 'zod';

/**
 * Export preferences
 */
export const ExportPreferencesSchema = z.object({
  default_format: z.enum(['pdf', 'excel', 'json', 'markdown']).default('pdf'),
  include_logo: z.boolean().default(true),
  include_charts: z.boolean().default(true),
  include_appendix: z.boolean().default(true),
  page_orientation: z.enum(['portrait', 'landscape']).default('portrait'),
  footer_text: z.string().optional(),
});

export type ExportPreferences = z.infer<typeof ExportPreferencesSchema>;

/**
 * Notification preferences
 */
export const NotificationPreferencesSchema = z.object({
  email_on_business_case_ready: z.boolean().default(true),
  email_on_review_needed: z.boolean().default(true),
  email_on_export_complete: z.boolean().default(false),
  daily_digest: z.boolean().default(false),
  digest_time: z.string().regex(/^\d{2}:\d{2}$/).default('09:00'),
});

export type NotificationPreferences = z.infer<typeof NotificationPreferencesSchema>;

/**
 * Display preferences
 */
export const DisplayPreferencesSchema = z.object({
  theme: z.enum(['light', 'dark', 'system']).default('system'),
  language: z.enum(['en', 'es', 'fr', 'de']).default('en'),
  timezone: z.string().default('UTC'),
  date_format: z.enum(['MM/DD/YYYY', 'DD/MM/YYYY', 'YYYY-MM-DD']).default('MM/DD/YYYY'),
  currency: z.enum(['USD', 'EUR', 'GBP', 'CAD', 'AUD']).default('USD'),
});

export type DisplayPreferences = z.infer<typeof DisplayPreferencesSchema>;

/**
 * Analysis preferences
 */
export const AnalysisPreferencesSchema = z.object({
  confidence_threshold_for_review: z.number().min(0).max(1).default(0.6),
  confidence_threshold_for_export: z.number().min(0).max(1).default(0.75),
  default_roi_scenarios: z.enum(['conservative', 'base', 'aggressive']).array().default(['base']),
  enable_contradiction_detection: z.boolean().default(true),
  enable_outlier_detection: z.boolean().default(true),
});

export type AnalysisPreferences = z.infer<typeof AnalysisPreferencesSchema>;

/**
 * Complete user settings
 */
export const UserSettingsSchema = z.object({
  user_id: z.string().uuid(),
  export_preferences: ExportPreferencesSchema,
  notification_preferences: NotificationPreferencesSchema,
  display_preferences: DisplayPreferencesSchema,
  analysis_preferences: AnalysisPreferencesSchema,
  updated_at: z.date(),
});

export type UserSettings = z.infer<typeof UserSettingsSchema>;

/**
 * Default settings
 */
export function createDefaultSettings(userId: string): UserSettings {
  return {
    user_id: userId,
    export_preferences: ExportPreferencesSchema.parse({}),
    notification_preferences: NotificationPreferencesSchema.parse({}),
    display_preferences: DisplayPreferencesSchema.parse({}),
    analysis_preferences: AnalysisPreferencesSchema.parse({}),
    updated_at: new Date(),
  };
}
EOF

log_success "Created settings types and schemas"

# =============================================================================
# SETTINGS MANAGEMENT LOGIC
# =============================================================================

write_file "${SETTINGS_DIR}/manager.ts" <<'EOF'
/**
 * Settings Manager
 * Handles loading, saving, and validating user settings
 */

import type { UserSettings, ExportPreferences, NotificationPreferences, DisplayPreferences, AnalysisPreferences } from './types';
import { UserSettingsSchema } from './types';

/**
 * Get user settings (from database or cache)
 */
export async function getUserSettings(userId: string): Promise<UserSettings> {
  try {
    // In production, this would fetch from database
    // For now, returning structure with ability to implement DB call
    const settings = {
      user_id: userId,
      export_preferences: {
        default_format: 'pdf' as const,
        include_logo: true,
        include_charts: true,
        include_appendix: true,
        page_orientation: 'portrait' as const,
      },
      notification_preferences: {
        email_on_business_case_ready: true,
        email_on_review_needed: true,
        email_on_export_complete: false,
        daily_digest: false,
        digest_time: '09:00',
      },
      display_preferences: {
        theme: 'system' as const,
        language: 'en' as const,
        timezone: 'UTC',
        date_format: 'MM/DD/YYYY' as const,
        currency: 'USD' as const,
      },
      analysis_preferences: {
        confidence_threshold_for_review: 0.6,
        confidence_threshold_for_export: 0.75,
        default_roi_scenarios: ['base' as const],
        enable_contradiction_detection: true,
        enable_outlier_detection: true,
      },
      updated_at: new Date(),
    };

    return UserSettingsSchema.parse(settings);
  } catch (error) {
    throw new Error(`Failed to load user settings: ${String(error)}`);
  }
}

/**
 * Update user settings
 */
export async function updateUserSettings(userId: string, updates: Partial<Omit<UserSettings, 'user_id' | 'updated_at'>>): Promise<UserSettings> {
  try {
    const current = await getUserSettings(userId);

    const updated: UserSettings = {
      ...current,
      ...updates,
      user_id: userId,
      updated_at: new Date(),
    };

    // Validate updated settings
    const validated = UserSettingsSchema.parse(updated);

    // In production, save to database here
    // await db.userSettings.update(userId, validated);

    return validated;
  } catch (error) {
    throw new Error(`Failed to update user settings: ${String(error)}`);
  }
}

/**
 * Update export preferences
 */
export async function updateExportPreferences(userId: string, preferences: Partial<ExportPreferences>): Promise<UserSettings> {
  const current = await getUserSettings(userId);
  return updateUserSettings(userId, {
    export_preferences: {
      ...current.export_preferences,
      ...preferences,
    },
  });
}

/**
 * Update notification preferences
 */
export async function updateNotificationPreferences(userId: string, preferences: Partial<NotificationPreferences>): Promise<UserSettings> {
  const current = await getUserSettings(userId);
  return updateUserSettings(userId, {
    notification_preferences: {
      ...current.notification_preferences,
      ...preferences,
    },
  });
}

/**
 * Update display preferences
 */
export async function updateDisplayPreferences(userId: string, preferences: Partial<DisplayPreferences>): Promise<UserSettings> {
  const current = await getUserSettings(userId);
  return updateUserSettings(userId, {
    display_preferences: {
      ...current.display_preferences,
      ...preferences,
    },
  });
}

/**
 * Update analysis preferences
 */
export async function updateAnalysisPreferences(userId: string, preferences: Partial<AnalysisPreferences>): Promise<UserSettings> {
  const current = await getUserSettings(userId);
  return updateUserSettings(userId, {
    analysis_preferences: {
      ...current.analysis_preferences,
      ...preferences,
    },
  });
}

/**
 * Reset to defaults
 */
export async function resetToDefaults(userId: string): Promise<UserSettings> {
  const { createDefaultSettings } = await import('./types');
  const defaults = createDefaultSettings(userId);
  return updateUserSettings(userId, defaults);
}
EOF

log_success "Created settings manager"

# =============================================================================
# SETTINGS API ROUTE
# =============================================================================

write_file "${PROJECT_ROOT}/src/api/settings/route.ts" <<'EOF'
/**
 * Settings API Endpoint
 * GET /api/settings - Retrieve user settings
 * POST /api/settings - Update user settings
 */

import { NextRequest, NextResponse } from 'next/server';
import { getUserSettings, updateUserSettings } from '@/lib/settings/manager';

/**
 * GET /api/settings
 */
export async function GET(request: NextRequest) {
  try {
    // In production, get userId from session/auth
    const userId = request.headers.get('x-user-id') || 'default-user';

    const settings = await getUserSettings(userId);
    return NextResponse.json(settings);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to load settings' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/settings
 */
export async function POST(request: NextRequest) {
  try {
    const userId = request.headers.get('x-user-id') || 'default-user';
    const updates = await request.json();

    const settings = await updateUserSettings(userId, updates);
    return NextResponse.json(settings);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update settings' },
      { status: 500 }
    );
  }
}
EOF

log_success "Created settings API endpoint"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
