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
