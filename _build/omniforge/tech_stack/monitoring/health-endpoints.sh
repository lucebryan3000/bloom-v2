#!/usr/bin/env bash
# =============================================================================
# tech_stack/monitoring/health-endpoints.sh - Health Check Endpoints
# =============================================================================
# Part of OmniForge - The Factory That Builds Universes
#
# Purpose: Set up monitoring and health check endpoints
# Phase: 4
# Reference: PRD Section 6.13 - Monitoring & Observability
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

readonly SCRIPT_ID="monitoring/health-endpoints"
readonly SCRIPT_NAME="Health Endpoints Setup"

if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

# =============================================================================
# CREATE MONITORING DIRECTORY
# =============================================================================

MONITORING_DIR="${PROJECT_ROOT}/src/api/monitoring"
ensure_dir "${MONITORING_DIR}" "Monitoring API directory"

# =============================================================================
# HEALTH CHECK ROUTE
# =============================================================================

write_file "${MONITORING_DIR}/health.ts" <<'EOF'
/**
 * Health Check Endpoint
 * Provides system status and dependency health
 * GET /api/monitoring/health
 */

import { NextRequest, NextResponse } from 'next/server';

/**
 * Health status
 */
export interface HealthStatus {
  status: 'healthy' | 'degraded' | 'unhealthy';
  timestamp: string;
  uptime_seconds: number;
  version: string;

  // Dependency checks
  database: {
    status: 'connected' | 'disconnected';
    latency_ms?: number;
  };
  ai_service: {
    status: 'available' | 'unavailable';
    latency_ms?: number;
  };

  // System metrics
  memory: {
    used_mb: number;
    available_mb: number;
    usage_percent: number;
  };
  uptime: {
    process_seconds: number;
    system_seconds: number;
  };
}

/**
 * GET /api/monitoring/health
 * Returns current health status
 */
export async function GET(request: NextRequest) {
  const startTime = Date.now();

  try {
    // Check database connectivity
    let dbStatus: 'connected' | 'disconnected' = 'disconnected';
    let dbLatency: number | undefined;

    try {
      const dbStart = Date.now();
      // This would be your actual DB check (e.g., SELECT 1 for Postgres)
      // For now, we'll simulate with a simple query
      dbStatus = 'connected';
      dbLatency = Date.now() - dbStart;
    } catch (error) {
      dbStatus = 'disconnected';
    }

    // Check AI service availability
    let aiStatus: 'available' | 'unavailable' = 'unavailable';
    let aiLatency: number | undefined;

    try {
      const aiStart = Date.now();
      // This would be your actual AI service check (e.g., simple API call to Anthropic)
      // For now, we'll simulate availability
      aiStatus = 'available';
      aiLatency = Date.now() - aiStart;
    } catch (error) {
      aiStatus = 'unavailable';
    }

    // Collect memory info
    const memUsage = process.memoryUsage();
    const memAvailable = require('os').freemem();
    const memTotal = require('os').totalmem();

    const healthStatus: HealthStatus = {
      status:
        dbStatus === 'connected' && aiStatus === 'available'
          ? 'healthy'
          : dbStatus === 'disconnected' || aiStatus === 'unavailable'
            ? 'unhealthy'
            : 'degraded',
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.floor(process.uptime()),
      version: process.env.APP_VERSION || '1.0.0',

      database: {
        status: dbStatus,
        latency_ms: dbLatency,
      },
      ai_service: {
        status: aiStatus,
        latency_ms: aiLatency,
      },

      memory: {
        used_mb: Math.round(memUsage.heapUsed / 1024 / 1024),
        available_mb: Math.round(memAvailable / 1024 / 1024),
        usage_percent: Math.round((memUsage.heapUsed / memUsage.heapTotal) * 100),
      },
      uptime: {
        process_seconds: Math.floor(process.uptime()),
        system_seconds: Math.floor(require('os').uptime()),
      },
    };

    const statusCode = healthStatus.status === 'healthy' ? 200 : healthStatus.status === 'degraded' ? 503 : 503;

    return NextResponse.json(healthStatus, { status: statusCode });
  } catch (error) {
    const errorStatus: HealthStatus = {
      status: 'unhealthy',
      timestamp: new Date().toISOString(),
      uptime_seconds: Math.floor(process.uptime()),
      version: process.env.APP_VERSION || '1.0.0',
      database: { status: 'disconnected' },
      ai_service: { status: 'unavailable' },
      memory: {
        used_mb: 0,
        available_mb: 0,
        usage_percent: 0,
      },
      uptime: {
        process_seconds: Math.floor(process.uptime()),
        system_seconds: 0,
      },
    };

    return NextResponse.json(errorStatus, { status: 503 });
  }
}
EOF

log_success "Created health check endpoint"

# =============================================================================
# METRICS ENDPOINT
# =============================================================================

write_file "${MONITORING_DIR}/metrics.ts" <<'EOF'
/**
 * Metrics Endpoint
 * Provides performance and business metrics
 * GET /api/monitoring/metrics
 */

import { NextRequest, NextResponse } from 'next/server';

/**
 * Application metrics
 */
export interface AppMetrics {
  timestamp: string;

  // Session metrics
  sessions: {
    total_active: number;
    created_today: number;
    average_duration_minutes: number;
  };

  // Business case metrics
  business_cases: {
    total_created: number;
    created_today: number;
    average_confidence: number;
    awaiting_review: number;
    exported: number;
  };

  // AI interaction metrics
  ai_interactions: {
    total_messages: number;
    messages_today: number;
    average_response_time_ms: number;
    error_rate_percent: number;
  };

  // Export metrics
  exports: {
    total_count: number;
    by_format: {
      pdf: number;
      excel: number;
      json: number;
      markdown: number;
    };
    today: number;
  };

  // Review queue metrics
  review_queue: {
    pending_items: number;
    by_severity: {
      critical: number;
      warning: number;
      info: number;
    };
    average_resolution_time_hours: number;
  };

  // Performance metrics
  performance: {
    api_response_time_p50_ms: number;
    api_response_time_p95_ms: number;
    database_query_time_p50_ms: number;
    database_query_time_p95_ms: number;
    cache_hit_rate_percent: number;
  };
}

/**
 * GET /api/monitoring/metrics
 * Returns application metrics
 */
export async function GET(request: NextRequest) {
  try {
    // This would fetch actual metrics from your database/monitoring system
    // For now, returning structure with placeholder values

    const metrics: AppMetrics = {
      timestamp: new Date().toISOString(),

      sessions: {
        total_active: 0, // Would query from DB
        created_today: 0,
        average_duration_minutes: 0,
      },

      business_cases: {
        total_created: 0, // Would query from DB
        created_today: 0,
        average_confidence: 0,
        awaiting_review: 0,
        exported: 0,
      },

      ai_interactions: {
        total_messages: 0, // Would query from message logs
        messages_today: 0,
        average_response_time_ms: 0,
        error_rate_percent: 0,
      },

      exports: {
        total_count: 0, // Would query from export logs
        by_format: {
          pdf: 0,
          excel: 0,
          json: 0,
          markdown: 0,
        },
        today: 0,
      },

      review_queue: {
        pending_items: 0, // Would query from review queue
        by_severity: {
          critical: 0,
          warning: 0,
          info: 0,
        },
        average_resolution_time_hours: 0,
      },

      performance: {
        api_response_time_p50_ms: 0, // Would aggregate from monitoring system
        api_response_time_p95_ms: 0,
        database_query_time_p50_ms: 0,
        database_query_time_p95_ms: 0,
        cache_hit_rate_percent: 0,
      },
    };

    return NextResponse.json(metrics);
  } catch (error) {
    return NextResponse.json(
      {
        error: 'Failed to fetch metrics',
        timestamp: new Date().toISOString(),
      },
      { status: 500 }
    );
  }
}
EOF

log_success "Created metrics endpoint"

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_success "${SCRIPT_NAME} completed"

exit 0
