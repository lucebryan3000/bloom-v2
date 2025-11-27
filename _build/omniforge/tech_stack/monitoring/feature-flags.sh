#!/usr/bin/env bash
#!meta
# id: monitoring/feature-flags.sh
# name: feature flags
# phase: 4
# phase_name: Extensions & Quality
# profile_tags:
#   - tech_stack
#   - monitoring
# uses_from_omni_config:
#   - ENABLE_FEATURE_FLAGS
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/monitoring/feature-flags.sh - Feature Flag System
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Purpose: Set up feature flag system for controlled rollout and A/B testing
# Phase: 4
# Reference: PRD Section 6.13 - Feature Flags & Experimentation
#
# Required: PROJECT_ROOT
#
# Dependencies:
#   lib/common.sh
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="monitoring/feature-flags"
readonly SCRIPT_NAME="Feature Flags System Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# CREATE FEATURE FLAGS DIRECTORY
# =============================================================================

FLAGS_DIR="${INSTALL_DIR}/src/lib/flags"
ensure_dir "${FLAGS_DIR}" "Feature flags library directory"

# =============================================================================
# FEATURE FLAG TYPES & SCHEMAS
# =============================================================================

write_file "${FLAGS_DIR}/types.ts" <<'EOF'
/**
 * Feature Flag System
 * Controls feature rollout, A/B testing, and experimental features
 */

import { z } from 'zod';

/**
 * Feature flag status
 */
export const FeatureFlagStatusSchema = z.enum(['disabled', 'enabled', 'rollout', 'experiment']);

/**
 * Rollout strategy
 */
export const RolloutStrategySchema = z.object({
  type: z.enum(['percentage', 'user_list', 'user_segment']).default('percentage'),
  percentage: z.number().min(0).max(100).optional(),
  user_ids: z.array(z.string()).optional(),
  segment_rules: z.record(z.string(), z.boolean()).optional(),
});

export type RolloutStrategy = z.infer<typeof RolloutStrategySchema>;

/**
 * Feature flag definition
 */
export const FeatureFlagSchema = z.object({
  id: z.string(),
  name: z.string().min(3),
  description: z.string(),
  status: FeatureFlagStatusSchema,

  // Rollout control
  rollout_strategy: RolloutStrategySchema.optional(),

  // Targeting
  enabled_for_users: z.array(z.string()).default([]),
  disabled_for_users: z.array(z.string()).default([]),
  targeting_rules: z.array(z.object({
    name: z.string(),
    condition: z.string(),
    enabled: z.boolean(),
  })).default([]),

  // Metadata
  owner: z.string(),
  created_at: z.date(),
  updated_at: z.date(),
  enabled_at: z.date().optional(),
  disabled_at: z.date().optional(),

  // Tracking
  track_usage: z.boolean().default(true),
  track_performance: z.boolean().default(false),

  // Tags
  tags: z.array(z.string()).default([]),
});

export type FeatureFlag = z.infer<typeof FeatureFlagSchema>;

/**
 * Feature flag context (for evaluation)
 */
export const FeatureFlagContextSchema = z.object({
  user_id: z.string(),
  organization_id: z.string().optional(),
  email: z.string().email().optional(),
  traits: z.record(z.any()).optional(),
  custom_properties: z.record(z.any()).optional(),
});

export type FeatureFlagContext = z.infer<typeof FeatureFlagContextSchema>;

/**
 * Feature flag evaluation result
 */
export const FeatureFlagResultSchema = z.object({
  flag_id: z.string(),
  enabled: z.boolean(),
  variant: z.string().optional(),
  reason: z.enum(['disabled', 'rollout_percentage', 'targeting_rule', 'experiment_variant', 'user_list']),
  evaluation_time_ms: z.number().optional(),
});

export type FeatureFlagResult = z.infer<typeof FeatureFlagResultSchema>;

/**
 * Common features
 */
export const BLOOM_FEATURES = {
  // Core features
  MELISSA_AI: 'melissa-ai',
  ROI_ENGINE: 'roi-engine',
  CONFIDENCE_SCORING: 'confidence-scoring',
  HITL_REVIEW: 'hitl-review-queue',

  // Export features
  EXPORT_PDF: 'export-pdf',
  EXPORT_EXCEL: 'export-excel',
  EXPORT_JSON: 'export-json',
  EXPORT_MARKDOWN: 'export-markdown',

  // Advanced features
  ADVANCED_ROI_MODELING: 'advanced-roi-modeling',
  SCENARIO_ANALYSIS: 'scenario-analysis',
  COLLABORATIVE_REVIEW: 'collaborative-review',
  API_ACCESS: 'api-access',
} as const;
EOF

log_success "Created feature flag types and schemas"

# =============================================================================
# FEATURE FLAG MANAGER
# =============================================================================

write_file "${FLAGS_DIR}/manager.ts" <<'EOF'
/**
 * Feature Flag Manager
 * Evaluates flags, manages state, and tracks usage
 */

import type { FeatureFlag, FeatureFlagContext, FeatureFlagResult } from './types';
import { FeatureFlagSchema, FeatureFlagContextSchema, BLOOM_FEATURES } from './types';

/**
 * In-memory feature flag store (would be replaced with database)
 */
const FLAGS_STORE = new Map<string, FeatureFlag>();

/**
 * Initialize built-in features
 */
export function initializeDefaultFlags() {
  const defaultFlags: FeatureFlag[] = [
    {
      id: BLOOM_FEATURES.MELISSA_AI,
      name: 'Melissa AI Assistant',
      description: 'AI-powered business case discovery and validation',
      status: 'enabled',
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      enabled_at: new Date(),
      track_usage: true,
      track_performance: true,
      tags: ['core', 'ai'],
    },
    {
      id: BLOOM_FEATURES.ROI_ENGINE,
      name: 'ROI Calculation Engine',
      description: 'Deterministic ROI and value calculation',
      status: 'enabled',
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      enabled_at: new Date(),
      track_usage: true,
      tags: ['core', 'analytics'],
    },
    {
      id: BLOOM_FEATURES.CONFIDENCE_SCORING,
      name: 'Confidence & Uncertainty Scoring',
      description: 'Data quality and confidence assessment',
      status: 'enabled',
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      enabled_at: new Date(),
      track_usage: true,
      tags: ['core', 'analytics'],
    },
    {
      id: BLOOM_FEATURES.HITL_REVIEW,
      name: 'Human-in-the-Loop Review Queue',
      description: 'Review and governance of AI-extracted metrics',
      status: 'enabled',
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      enabled_at: new Date(),
      track_usage: true,
      tags: ['core', 'governance'],
    },
    {
      id: BLOOM_FEATURES.EXPORT_PDF,
      name: 'PDF Export',
      description: 'Export business cases as PDF documents',
      status: 'enabled',
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      enabled_at: new Date(),
      tags: ['export'],
    },
    {
      id: BLOOM_FEATURES.SCENARIO_ANALYSIS,
      name: 'Scenario Analysis',
      description: 'Explore different ROI scenarios and sensitivities',
      status: 'rollout',
      rollout_strategy: { type: 'percentage', percentage: 50 },
      owner: 'product',
      created_at: new Date(),
      updated_at: new Date(),
      track_usage: true,
      track_performance: true,
      tags: ['beta', 'analytics'],
    },
  ];

  defaultFlags.forEach((flag) => {
    FLAGS_STORE.set(flag.id, flag);
  });
}

/**
 * Get feature flag by ID
 */
export async function getFeatureFlag(flagId: string): Promise<FeatureFlag | null> {
  return FLAGS_STORE.get(flagId) || null;
}

/**
 * Evaluate flag for user
 */
export async function evaluateFlag(flagId: string, context: FeatureFlagContext): Promise<FeatureFlagResult> {
  const startTime = Date.now();
  const flag = FLAGS_STORE.get(flagId);

  if (!flag) {
    return {
      flag_id: flagId,
      enabled: false,
      reason: 'disabled',
      evaluation_time_ms: Date.now() - startTime,
    };
  }

  // Check if disabled
  if (flag.status === 'disabled') {
    return {
      flag_id: flagId,
      enabled: false,
      reason: 'disabled',
      evaluation_time_ms: Date.now() - startTime,
    };
  }

  // Check explicit user disable
  if (flag.disabled_for_users.includes(context.user_id)) {
    return {
      flag_id: flagId,
      enabled: false,
      reason: 'targeting_rule',
      evaluation_time_ms: Date.now() - startTime,
    };
  }

  // Check explicit user enable
  if (flag.enabled_for_users.includes(context.user_id)) {
    return {
      flag_id: flagId,
      enabled: true,
      reason: 'user_list',
      evaluation_time_ms: Date.now() - startTime,
    };
  }

  // Handle enabled status
  if (flag.status === 'enabled') {
    return {
      flag_id: flagId,
      enabled: true,
      reason: 'disabled',
      evaluation_time_ms: Date.now() - startTime,
    };
  }

  // Handle rollout
  if (flag.status === 'rollout' && flag.rollout_strategy) {
    const strategy = flag.rollout_strategy;

    if (strategy.type === 'percentage' && strategy.percentage !== undefined) {
      const hash = hashUserId(context.user_id);
      const enabled = (hash % 100) < strategy.percentage;
      return {
        flag_id: flagId,
        enabled,
        reason: 'rollout_percentage',
        evaluation_time_ms: Date.now() - startTime,
      };
    }

    if (strategy.type === 'user_list' && strategy.user_ids) {
      const enabled = strategy.user_ids.includes(context.user_id);
      return {
        flag_id: flagId,
        enabled,
        reason: 'user_list',
        evaluation_time_ms: Date.now() - startTime,
      };
    }
  }

  return {
    flag_id: flagId,
    enabled: false,
    reason: 'disabled',
    evaluation_time_ms: Date.now() - startTime,
  };
}

/**
 * Simple hash function for consistent user assignment
 */
function hashUserId(userId: string): number {
  let hash = 0;
  for (let i = 0; i < userId.length; i++) {
    const char = userId.charCodeAt(i);
    hash = (hash << 5) - hash + char;
    hash = hash & hash; // Convert to 32-bit integer
  }
  return Math.abs(hash);
}

/**
 * Create or update flag
 */
export async function upsertFeatureFlag(flag: FeatureFlag): Promise<FeatureFlag> {
  const validated = FeatureFlagSchema.parse(flag);
  FLAGS_STORE.set(flag.id, validated);
  return validated;
}

/**
 * List all flags
 */
export async function listFeatureFlags(): Promise<FeatureFlag[]> {
  return Array.from(FLAGS_STORE.values());
}

/**
 * Delete flag
 */
export async function deleteFeatureFlag(flagId: string): Promise<boolean> {
  return FLAGS_STORE.delete(flagId);
}
EOF

log_success "Created feature flag manager"

# =============================================================================
# FEATURE FLAG API ROUTE
# =============================================================================

write_file "${INSTALL_DIR}/src/api/flags/route.ts" <<'EOF'
/**
 * Feature Flags API
 * GET /api/flags - List all flags
 * GET /api/flags/evaluate - Evaluate flag for user
 * POST /api/flags - Create/update flag (admin only)
 */

import { NextRequest, NextResponse } from 'next/server';
import { evaluateFlag, listFeatureFlags, upsertFeatureFlag } from '@/lib/flags/manager';

/**
 * GET /api/flags
 */
export async function GET(request: NextRequest) {
  try {
    // Check for evaluate query
    const url = new URL(request.url);
    if (url.searchParams.has('evaluate')) {
      const flagId = url.searchParams.get('flag_id');
      const userId = url.searchParams.get('user_id');

      if (!flagId || !userId) {
        return NextResponse.json(
          { error: 'Missing flag_id or user_id' },
          { status: 400 }
        );
      }

      const result = await evaluateFlag(flagId, { user_id: userId });
      return NextResponse.json(result);
    }

    // List all flags
    const flags = await listFeatureFlags();
    return NextResponse.json(flags);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to fetch flags' },
      { status: 500 }
    );
  }
}

/**
 * POST /api/flags
 */
export async function POST(request: NextRequest) {
  try {
    // TODO: Add auth check (admin only)
    const flag = await request.json();
    const updated = await upsertFeatureFlag(flag);
    return NextResponse.json(updated);
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to update flag' },
      { status: 500 }
    );
  }
}
EOF

log_success "Created feature flags API endpoint"

# =============================================================================
# REACT HOOK FOR FLAG EVALUATION
# =============================================================================

write_file "${INSTALL_DIR}/src/hooks/useFeatureFlag.ts" <<'EOF'
/**
 * useFeatureFlag Hook
 * Client-side hook for evaluating feature flags
 */

import { useEffect, useState } from 'react';

export function useFeatureFlag(flagId: string, userId: string) {
  const [enabled, setEnabled] = useState<boolean | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  useEffect(() => {
    async function evaluateFlag() {
      try {
        const response = await fetch(
          `/api/flags?evaluate=1&flag_id=${encodeURIComponent(flagId)}&user_id=${encodeURIComponent(userId)}`
        );

        if (!response.ok) {
          throw new Error('Failed to evaluate flag');
        }

        const result = await response.json();
        setEnabled(result.enabled);
      } catch (err) {
        setError(String(err));
        setEnabled(false);
      } finally {
        setLoading(false);
      }
    }

    evaluateFlag();
  }, [flagId, userId]);

  return { enabled, loading, error };
}

/**
 * Feature Flag Guard Component
 */
export function FeatureFlagGuard({
  flagId,
  userId,
  children,
  fallback = null,
}: {
  flagId: string;
  userId: string;
  children: React.ReactNode;
  fallback?: React.ReactNode;
}) {
  const { enabled, loading } = useFeatureFlag(flagId, userId);

  if (loading) return null;
  if (enabled) return <>{children}</>;
  return <>{fallback}</>;
}
EOF

log_success "Created useFeatureFlag hook"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
