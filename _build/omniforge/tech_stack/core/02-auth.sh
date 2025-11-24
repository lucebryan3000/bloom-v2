#!/usr/bin/env bash
# =============================================================================
# tech_stack/core/02-auth.sh - Auth.js Authentication
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (Authentication)
# Profile: starter, standard, advanced, enterprise
#
# Installs:
#   - next-auth (Auth.js for Next.js)
#   - @auth/drizzle-adapter (Drizzle ORM adapter)
#
# Creates:
#   - src/lib/auth.ts (auth configuration)
#   - src/app/api/auth/[...nextauth]/route.ts (API route handler)
#   - src/db/schema/auth.ts (auth schema for Drizzle)
#
# Requires:
#   - PROJECT_ROOT
#   - core/01-database to be completed (Drizzle ORM)
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="core/02-auth"
readonly SCRIPT_NAME="Auth.js Authentication"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify required variables
: "${PROJECT_ROOT:?PROJECT_ROOT not set}"

# Verify database setup is complete (required for Drizzle adapter)
if ! has_script_succeeded "core/01-database"; then
    log_error "Database setup (core/01-database) must complete before auth setup"
    log_error "Run the database phase first"
    exit 1
fi

cd "$PROJECT_ROOT"

# Verify package.json exists
if [[ ! -f "package.json" ]]; then
    log_error "package.json not found. Run core/00-nextjs first."
    exit 1
fi

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing authentication dependencies"

DEPS=("next-auth@beta" "@auth/drizzle-adapter")

pkg_preflight_check "${DEPS[@]}"

pkg_install "${DEPS[@]}" || {
    log_error "Failed to install authentication dependencies"
    exit 1
}

# Verify installation
log_info "Verifying installation..."
pkg_verify "next-auth" || {
    log_error "next-auth verification failed"
    exit 1
}

log_ok "Authentication dependencies installed"

# =============================================================================
# AUTH CONFIGURATION
# =============================================================================

log_step "Creating auth configuration"

mkdir -p src/lib

if [[ ! -f "src/lib/auth.ts" ]]; then
    cat > src/lib/auth.ts <<'EOF'
/**
 * Auth.js Configuration
 * Centralized authentication configuration with Drizzle adapter
 */

import NextAuth from 'next-auth';
import { DrizzleAdapter } from '@auth/drizzle-adapter';
import { db } from '@/db';
import type { NextAuthConfig } from 'next-auth';

// Import providers as needed
// import GitHub from 'next-auth/providers/github';
// import Google from 'next-auth/providers/google';
// import Credentials from 'next-auth/providers/credentials';

/**
 * Auth.js configuration
 * @see https://authjs.dev/getting-started/installation
 */
export const authConfig: NextAuthConfig = {
  // Database adapter for session persistence
  adapter: DrizzleAdapter(db),

  // Authentication providers
  providers: [
    // Add your providers here
    // GitHub({
    //   clientId: process.env.GITHUB_CLIENT_ID!,
    //   clientSecret: process.env.GITHUB_CLIENT_SECRET!,
    // }),
    // Google({
    //   clientId: process.env.GOOGLE_CLIENT_ID!,
    //   clientSecret: process.env.GOOGLE_CLIENT_SECRET!,
    // }),
  ],

  // Session configuration
  session: {
    strategy: 'database', // Use database sessions with Drizzle
    maxAge: 30 * 24 * 60 * 60, // 30 days
    updateAge: 24 * 60 * 60, // Update session every 24 hours
  },

  // Custom pages (optional)
  pages: {
    signIn: '/auth/signin',
    // signOut: '/auth/signout',
    // error: '/auth/error',
    // verifyRequest: '/auth/verify-request',
    // newUser: '/auth/new-user',
  },

  // Callbacks for customizing behavior
  callbacks: {
    // Add user ID to session
    session({ session, user }) {
      if (session.user) {
        session.user.id = user.id;
      }
      return session;
    },

    // Control who can sign in
    // async signIn({ user, account, profile }) {
    //   return true; // Allow all sign-ins
    // },

    // Customize JWT (if using JWT strategy)
    // async jwt({ token, user }) {
    //   if (user) {
    //     token.id = user.id;
    //   }
    //   return token;
    // },
  },

  // Enable debug messages in development
  debug: process.env.NODE_ENV === 'development',

  // Trust host header (required for some deployments)
  trustHost: true,
};

// Export auth handlers and helpers
export const {
  handlers,
  auth,
  signIn,
  signOut,
} = NextAuth(authConfig);

// Type augmentation for session
declare module 'next-auth' {
  interface Session {
    user: {
      id: string;
      name?: string | null;
      email?: string | null;
      image?: string | null;
    };
  }
}
EOF
    log_ok "Created src/lib/auth.ts"
else
    log_skip "src/lib/auth.ts already exists"
fi

# =============================================================================
# API ROUTE HANDLER
# =============================================================================

log_step "Creating API route handler"

mkdir -p "src/app/api/auth/[...nextauth]"

if [[ ! -f "src/app/api/auth/[...nextauth]/route.ts" ]]; then
    cat > "src/app/api/auth/[...nextauth]/route.ts" <<'EOF'
/**
 * Auth.js API Route Handler
 * Handles all /api/auth/* routes
 */

import { handlers } from '@/lib/auth';

export const { GET, POST } = handlers;
EOF
    log_ok "Created src/app/api/auth/[...nextauth]/route.ts"
else
    log_skip "route.ts already exists"
fi

# =============================================================================
# AUTH SCHEMA FOR DRIZZLE
# =============================================================================

log_step "Creating auth schema for Drizzle"

if [[ ! -f "src/db/schema/auth.ts" ]]; then
    cat > src/db/schema/auth.ts <<'EOF'
/**
 * Auth.js Schema for Drizzle ORM
 * Required tables for Auth.js with database sessions
 *
 * @see https://authjs.dev/getting-started/adapters/drizzle
 */

import {
  pgTable,
  text,
  timestamp,
  primaryKey,
  integer,
} from 'drizzle-orm/pg-core';
import type { AdapterAccount } from 'next-auth/adapters';

/**
 * Users table
 * Stores user information from authentication providers
 */
export const users = pgTable('users', {
  id: text('id')
    .primaryKey()
    .$defaultFn(() => crypto.randomUUID()),
  name: text('name'),
  email: text('email').unique(),
  emailVerified: timestamp('email_verified', { mode: 'date' }),
  image: text('image'),
  createdAt: timestamp('created_at', { mode: 'date' }).defaultNow(),
  updatedAt: timestamp('updated_at', { mode: 'date' }).defaultNow(),
});

/**
 * Accounts table
 * Links users to OAuth provider accounts
 */
export const accounts = pgTable(
  'accounts',
  {
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    type: text('type').$type<AdapterAccount['type']>().notNull(),
    provider: text('provider').notNull(),
    providerAccountId: text('provider_account_id').notNull(),
    refresh_token: text('refresh_token'),
    access_token: text('access_token'),
    expires_at: integer('expires_at'),
    token_type: text('token_type'),
    scope: text('scope'),
    id_token: text('id_token'),
    session_state: text('session_state'),
  },
  (account) => ({
    compoundKey: primaryKey({
      columns: [account.provider, account.providerAccountId],
    }),
  })
);

/**
 * Sessions table
 * Stores active user sessions (for database session strategy)
 */
export const sessions = pgTable('sessions', {
  sessionToken: text('session_token').primaryKey(),
  userId: text('user_id')
    .notNull()
    .references(() => users.id, { onDelete: 'cascade' }),
  expires: timestamp('expires', { mode: 'date' }).notNull(),
});

/**
 * Verification tokens table
 * For email verification and magic link authentication
 */
export const verificationTokens = pgTable(
  'verification_tokens',
  {
    identifier: text('identifier').notNull(),
    token: text('token').notNull(),
    expires: timestamp('expires', { mode: 'date' }).notNull(),
  },
  (vt) => ({
    compoundKey: primaryKey({ columns: [vt.identifier, vt.token] }),
  })
);

// Export types for use in application
export type User = typeof users.$inferSelect;
export type NewUser = typeof users.$inferInsert;
export type Account = typeof accounts.$inferSelect;
export type Session = typeof sessions.$inferSelect;
EOF
    log_ok "Created src/db/schema/auth.ts"
else
    log_skip "src/db/schema/auth.ts already exists"
fi

# =============================================================================
# UPDATE SCHEMA INDEX
# =============================================================================

log_step "Updating schema index"

SCHEMA_INDEX="src/db/schema/index.ts"
if [[ -f "$SCHEMA_INDEX" ]]; then
    # Check if auth export already exists
    if ! grep -q "export \* from './auth'" "$SCHEMA_INDEX"; then
        # Add auth export before placeholder or at end
        if grep -q "_placeholder" "$SCHEMA_INDEX"; then
            sed -i.bak "s|export const _placeholder = true;|export * from './auth';\n\n// Placeholder removed - auth schema added|" "$SCHEMA_INDEX"
            rm -f "${SCHEMA_INDEX}.bak"
        else
            echo "export * from './auth';" >> "$SCHEMA_INDEX"
        fi
        log_ok "Added auth export to schema index"
    else
        log_skip "Auth export already in schema index"
    fi
else
    log_warn "Schema index not found at $SCHEMA_INDEX"
fi

# =============================================================================
# ENV TEMPLATE UPDATE
# =============================================================================

log_step "Updating .env.example with auth variables"

ENV_EXAMPLE=".env.example"
if [[ -f "$ENV_EXAMPLE" ]]; then
    # Check if AUTH_SECRET already exists
    if ! grep -q "AUTH_SECRET" "$ENV_EXAMPLE"; then
        cat >> "$ENV_EXAMPLE" <<'EOF'

# =============================================================================
# Authentication (Auth.js)
# =============================================================================
# Generate with: npx auth secret
AUTH_SECRET=your_auth_secret_here

# OAuth Providers (uncomment and configure as needed)
# GitHub
# GITHUB_CLIENT_ID=
# GITHUB_CLIENT_SECRET=

# Google
# GOOGLE_CLIENT_ID=
# GOOGLE_CLIENT_SECRET=

# Auth.js URL (required in production)
# AUTH_URL=https://your-domain.com
EOF
        log_ok "Added auth variables to .env.example"
    else
        log_skip "Auth variables already in .env.example"
    fi
else
    # Create .env.example if it doesn't exist
    cat > "$ENV_EXAMPLE" <<'EOF'
# =============================================================================
# Authentication (Auth.js)
# =============================================================================
# Generate with: npx auth secret
AUTH_SECRET=your_auth_secret_here

# OAuth Providers (uncomment and configure as needed)
# GitHub
# GITHUB_CLIENT_ID=
# GITHUB_CLIENT_SECRET=

# Google
# GOOGLE_CLIENT_ID=
# GOOGLE_CLIENT_SECRET=

# Auth.js URL (required in production)
# AUTH_URL=https://your-domain.com
EOF
    log_ok "Created .env.example with auth variables"
fi

# =============================================================================
# MIDDLEWARE SETUP (OPTIONAL - COMMENTED TEMPLATE)
# =============================================================================

log_step "Creating middleware template"

if [[ ! -f "src/middleware.ts" ]]; then
    cat > src/middleware.ts <<'EOF'
/**
 * Next.js Middleware
 * Handles authentication-based route protection
 *
 * Uncomment and configure the sections below to enable route protection.
 * @see https://authjs.dev/getting-started/session-management/protecting
 */

// import { auth } from '@/lib/auth';
// import { NextResponse } from 'next/server';

// export default auth((req) => {
//   const isLoggedIn = !!req.auth;
//   const isAuthPage = req.nextUrl.pathname.startsWith('/auth');
//   const isApiRoute = req.nextUrl.pathname.startsWith('/api');
//   const isPublicRoute = ['/'].includes(req.nextUrl.pathname);
//
//   // Allow API routes and public routes
//   if (isApiRoute || isPublicRoute) {
//     return NextResponse.next();
//   }
//
//   // Redirect logged-in users away from auth pages
//   if (isAuthPage && isLoggedIn) {
//     return NextResponse.redirect(new URL('/dashboard', req.url));
//   }
//
//   // Redirect unauthenticated users to sign in
//   if (!isLoggedIn && !isAuthPage) {
//     return NextResponse.redirect(new URL('/auth/signin', req.url));
//   }
//
//   return NextResponse.next();
// });

// Middleware matcher configuration
export const config = {
  matcher: [
    // Skip static files and images
    '/((?!_next/static|_next/image|favicon.ico|.*\\.(?:svg|png|jpg|jpeg|gif|webp)$).*)',
  ],
};

// Default export for when auth middleware is disabled
export default function middleware() {
  // No-op middleware - uncomment auth middleware above to enable
}
EOF
    log_ok "Created src/middleware.ts template"
else
    log_skip "src/middleware.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"

log_info ""
log_info "Next steps:"
log_info "  1. Generate AUTH_SECRET: npx auth secret"
log_info "  2. Configure OAuth providers in src/lib/auth.ts"
log_info "  3. Run database migration: pnpm db:push"
log_info "  4. Enable middleware protection (optional)"
log_info ""
