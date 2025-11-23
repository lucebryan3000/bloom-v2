#!/usr/bin/env bash
# =============================================================================
# File: phases/02-database/09-drizzle-schema-base.sh
# Purpose: Generate base src/db/schema.ts with core table definitions
# Assumes: Drizzle ORM installed, src/db directory exists
# Creates: src/db/schema.ts with base tables
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="09"
readonly SCRIPT_NAME="drizzle-schema-base"
readonly SCRIPT_DESCRIPTION="Generate base Drizzle schema with core tables"

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
    $(basename "$0")              # Create base schema
    $(basename "$0") --dry-run    # Preview schema content

WHAT THIS SCRIPT DOES:
    1. Creates src/db/schema.ts with base table definitions
    2. Includes: users, audit_log, feature_flags, app_settings
    3. All tables include version column for optimistic locking
    4. Includes timestamps (createdAt, updatedAt)

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting base schema generation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/db"

    # Step 2: Generate base schema
    log_step "Generating src/db/schema.ts"

    local schema_content='import {
  pgTable,
  uuid,
  varchar,
  text,
  timestamp,
  integer,
  boolean,
  jsonb,
  pgEnum,
} from "drizzle-orm/pg-core";
import { relations } from "drizzle-orm";

// =============================================================================
// ENUMS
// =============================================================================

/**
 * User roles for authorization
 */
export const userRoleEnum = pgEnum("user_role", ["editor", "viewer", "admin"]);

// =============================================================================
// CORE TABLES
// =============================================================================

/**
 * Users table - authentication and authorization
 *
 * Stores user accounts with role-based access control.
 */
export const users = pgTable("users", {
  id: uuid("id").primaryKey().defaultRandom(),
  email: varchar("email", { length: 255 }).notNull().unique(),
  name: varchar("name", { length: 255 }),
  passwordHash: text("password_hash"),
  role: userRoleEnum("role").notNull().default("viewer"),
  emailVerified: timestamp("email_verified", { withTimezone: true }),
  image: text("image"),
  // Optimistic locking
  version: integer("version").notNull().default(1),
  // Timestamps
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

/**
 * Audit log - immutable change tracking
 *
 * Records all significant changes for compliance and debugging.
 * This table is append-only; entries should never be updated or deleted.
 */
export const auditLog = pgTable("audit_log", {
  id: uuid("id").primaryKey().defaultRandom(),
  // Who made the change
  userId: uuid("user_id").references(() => users.id),
  userEmail: varchar("user_email", { length: 255 }),
  // What changed
  entityType: varchar("entity_type", { length: 100 }).notNull(),
  entityId: uuid("entity_id").notNull(),
  action: varchar("action", { length: 50 }).notNull(), // create, update, delete
  // Change details
  fieldName: varchar("field_name", { length: 100 }),
  oldValue: jsonb("old_value"),
  newValue: jsonb("new_value"),
  // Context
  reason: text("reason"),
  metadata: jsonb("metadata"),
  // Timestamp (no updatedAt - immutable)
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
});

/**
 * Feature flags - runtime feature toggles
 *
 * Allows enabling/disabling features without redeployment.
 */
export const featureFlags = pgTable("feature_flags", {
  id: uuid("id").primaryKey().defaultRandom(),
  key: varchar("key", { length: 100 }).notNull().unique(),
  name: varchar("name", { length: 255 }).notNull(),
  description: text("description"),
  enabled: boolean("enabled").notNull().default(false),
  // Optional: percentage rollout, user targeting, etc.
  config: jsonb("config"),
  // Optimistic locking
  version: integer("version").notNull().default(1),
  // Timestamps
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

/**
 * App settings - application-level configuration
 *
 * Stores configurable settings that can be changed at runtime.
 */
export const appSettings = pgTable("app_settings", {
  id: uuid("id").primaryKey().defaultRandom(),
  key: varchar("key", { length: 100 }).notNull().unique(),
  value: jsonb("value").notNull(),
  description: text("description"),
  // Type hint for UI rendering
  valueType: varchar("value_type", { length: 50 }).notNull().default("string"),
  // Optimistic locking
  version: integer("version").notNull().default(1),
  // Timestamps
  createdAt: timestamp("created_at", { withTimezone: true }).notNull().defaultNow(),
  updatedAt: timestamp("updated_at", { withTimezone: true }).notNull().defaultNow(),
});

// =============================================================================
// RELATIONS
// =============================================================================

export const usersRelations = relations(users, ({ many }) => ({
  auditLogs: many(auditLog),
}));

export const auditLogRelations = relations(auditLog, ({ one }) => ({
  user: one(users, {
    fields: [auditLog.userId],
    references: [users.id],
  }),
}));

// =============================================================================
// TYPE EXPORTS
// =============================================================================

export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;

export type AuditLogEntry = typeof auditLog.$inferSelect;
export type NewAuditLogEntry = typeof auditLog.$inferInsert;

export type FeatureFlag = typeof featureFlags.$inferSelect;
export type NewFeatureFlag = typeof featureFlags.$inferInsert;

export type AppSetting = typeof appSettings.$inferSelect;
export type NewAppSetting = typeof appSettings.$inferInsert;

// =============================================================================
// TODO: Add Bloom2-specific tables
// =============================================================================
// The following tables should be added for Bloom2 functionality:
//
// - projects: Logical container for Baseline/Retro sessions
// - sessions: Per-workshop state with lifecycle management
// - messages: Full chat log (user ↔ Melissa)
// - sessionMetrics: Normalized metrics with confidence scores
// - valuePerspectives: Four pillars (Financial, Cultural, Customer, Employee)
// - roiResults: Computed ROI numbers
// - confidenceSnapshots: Historical confidence per session
// - jobs: Background job queue (pg-boss will handle this)
//
// See: docs/ARCHITECTURE-README.md section 2.2
'

    write_file "src/db/schema.ts" "$schema_content"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
