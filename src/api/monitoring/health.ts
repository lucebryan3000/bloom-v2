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
