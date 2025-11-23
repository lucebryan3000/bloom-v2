#!/usr/bin/env bash
# =============================================================================
# File: phases/02-database/11-db-client-index.sh
# Purpose: Create src/db/index.ts with postgres.js client + Drizzle instance
# Assumes: Drizzle ORM installed, schema exists
# Creates: src/db/index.ts with typed database client
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="11"
readonly SCRIPT_NAME="db-client-index"
readonly SCRIPT_DESCRIPTION="Create database client with postgres.js and Drizzle"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Create DB client
    $(basename "$0") --dry-run    # Preview content

WHAT THIS SCRIPT DOES:
    1. Creates src/db/index.ts with postgres.js connection
    2. Configures connection pooling
    3. Exports typed Drizzle database instance
    4. Uses DATABASE_URL from environment

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting database client creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/db"

    # Step 2: Create database client
    log_step "Creating src/db/index.ts"

    local db_client='import { drizzle } from "drizzle-orm/postgres-js";
import postgres from "postgres";

import * as schema from "./schema";

/**
 * Database connection configuration
 *
 * Uses postgres.js for high-performance connection pooling.
 * Configuration is optimized for serverless/edge environments.
 */

// Validate DATABASE_URL is set
if (!process.env.DATABASE_URL) {
  throw new Error(
    "DATABASE_URL environment variable is not set. " +
      "Please configure your database connection."
  );
}

/**
 * postgres.js connection options
 *
 * @see https://github.com/porsager/postgres#connection-options
 */
const connectionOptions = {
  // Connection pool size (adjust based on your needs)
  max: process.env.NODE_ENV === "production" ? 10 : 3,

  // Idle timeout in seconds
  idle_timeout: 20,

  // Connection timeout in seconds
  connect_timeout: 10,

  // Prepare statements for better performance
  prepare: true,

  // SSL configuration for production
  ssl: process.env.NODE_ENV === "production" ? "require" : false,
};

/**
 * Raw postgres.js client
 *
 * Use this for raw SQL queries or advanced operations.
 * Prefer the `db` export for type-safe queries.
 */
export const sql = postgres(process.env.DATABASE_URL, connectionOptions);

/**
 * Drizzle ORM database instance
 *
 * This is the primary export for database operations.
 * Provides full type safety based on the schema.
 *
 * @example
 * ```ts
 * import { db } from "@/db";
 * import { users } from "@/db/schema";
 *
 * const allUsers = await db.select().from(users);
 * ```
 */
export const db = drizzle(sql, {
  schema,
  logger: process.env.NODE_ENV === "development",
});

/**
 * Database connection types
 */
export type Database = typeof db;

/**
 * Re-export schema for convenience
 */
export * from "./schema";

/**
 * Graceful shutdown helper
 *
 * Call this when shutting down the application to close
 * all database connections properly.
 */
export async function closeDatabase(): Promise<void> {
  await sql.end();
}

/**
 * Health check query
 *
 * Use this to verify database connectivity.
 */
export async function checkDatabaseHealth(): Promise<boolean> {
  try {
    await sql`SELECT 1`;
    return true;
  } catch {
    return false;
  }
}
'

    write_file "src/db/index.ts" "$db_client"

    # Step 3: Create types file
    log_step "Creating src/db/types.ts"

    local db_types='import type { InferSelectModel, InferInsertModel } from "drizzle-orm";
import type * as schema from "./schema";

/**
 * Database table types
 *
 * These types are inferred from the Drizzle schema and provide
 * type safety for database operations.
 */

// Re-export types from schema
export type {
  User,
  NewUser,
  AuditLogEntry,
  NewAuditLogEntry,
  FeatureFlag,
  NewFeatureFlag,
  AppSetting,
  NewAppSetting,
} from "./schema";

/**
 * Generic type helpers for Drizzle tables
 */
export type SelectModel<T extends keyof typeof schema> =
  (typeof schema)[T] extends { $inferSelect: infer S } ? S : never;

export type InsertModel<T extends keyof typeof schema> =
  (typeof schema)[T] extends { $inferInsert: infer I } ? I : never;

/**
 * Transaction type
 *
 * Use this when passing the database client to functions
 * that may be called within a transaction.
 */
export type Transaction = Parameters<
  Parameters<typeof import("./index").db.transaction>[0]
>[0];
'

    write_file "src/db/types.ts" "$db_types"

    # Step 4: Create health check API route
    log_step "Creating health check API route"

    ensure_dir "src/app/api/health"

    local health_route='import { NextResponse } from "next/server";
import { checkDatabaseHealth } from "@/db";

/**
 * Health check endpoint
 *
 * Used by Docker healthchecks and load balancers to verify
 * the application is running and can connect to the database.
 *
 * GET /api/health
 */
export async function GET() {
  const startTime = Date.now();

  try {
    const dbHealthy = await checkDatabaseHealth();

    const status = {
      status: dbHealthy ? "healthy" : "degraded",
      timestamp: new Date().toISOString(),
      uptime: process.uptime(),
      database: dbHealthy ? "connected" : "disconnected",
      responseTime: Date.now() - startTime,
    };

    return NextResponse.json(status, {
      status: dbHealthy ? 200 : 503,
    });
  } catch (error) {
    return NextResponse.json(
      {
        status: "unhealthy",
        timestamp: new Date().toISOString(),
        error: error instanceof Error ? error.message : "Unknown error",
        responseTime: Date.now() - startTime,
      },
      { status: 503 }
    );
  }
}
'

    write_file "src/app/api/health/route.ts" "$health_route"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
