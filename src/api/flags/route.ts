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
