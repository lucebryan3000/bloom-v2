#!/usr/bin/env bash
# =============================================================================
# File: phases/04-auth/16-authjs-v5-setup.sh
# Purpose: Install and configure Auth.js v5 for Next.js App Router
# Assumes: Next.js project exists
# Creates: Auth configuration and API route
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="16"
readonly SCRIPT_NAME="authjs-v5-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Auth.js v5 for App Router"

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
    $(basename "$0")              # Set up Auth.js
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Installs next-auth (Auth.js v5)
    2. Creates auth configuration (src/auth.ts)
    3. Creates API route handler
    4. Sets up credentials provider for MVP

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Auth.js v5 setup"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_pnpm
    require_file "package.json" "Initialize project first"

    # Step 2: Install dependencies
    log_step "Installing Auth.js"

    add_dependency "next-auth@beta"
    add_dependency "bcryptjs"
    add_dependency "@types/bcryptjs" "true"

    # Step 3: Create auth configuration
    log_step "Creating src/auth.ts"

    ensure_dir "src"

    local auth_config='import NextAuth from "next-auth";
import Credentials from "next-auth/providers/credentials";
import { z } from "zod";
import bcrypt from "bcryptjs";
import { db } from "@/db";
import { users } from "@/db/schema";
import { eq } from "drizzle-orm";

/**
 * Auth.js v5 Configuration
 *
 * Configured for credentials-based authentication.
 * Ready for future OAuth providers (Google, Azure AD, etc.)
 *
 * @see https://authjs.dev/getting-started/installation
 */

// Login credentials schema
const LoginSchema = z.object({
  email: z.string().email(),
  password: z.string().min(8),
});

export const {
  handlers: { GET, POST },
  auth,
  signIn,
  signOut,
} = NextAuth({
  pages: {
    signIn: "/login",
    error: "/login",
  },

  callbacks: {
    /**
     * JWT callback - add user data to token
     */
    async jwt({ token, user }) {
      if (user) {
        token.id = user.id;
        token.role = user.role;
      }
      return token;
    },

    /**
     * Session callback - expose user data to client
     */
    async session({ session, token }) {
      if (token && session.user) {
        session.user.id = token.id as string;
        session.user.role = token.role as string;
      }
      return session;
    },

    /**
     * Authorized callback - protect routes
     */
    async authorized({ auth, request }) {
      const isLoggedIn = !!auth?.user;
      const isOnDashboard = request.nextUrl.pathname.startsWith("/workspace");
      const isOnSettings = request.nextUrl.pathname.startsWith("/settings");
      const isOnReports = request.nextUrl.pathname.startsWith("/reports");

      // Protected routes
      if (isOnDashboard || isOnSettings || isOnReports) {
        if (isLoggedIn) return true;
        return false; // Redirect to login
      }

      return true;
    },
  },

  providers: [
    Credentials({
      name: "credentials",
      credentials: {
        email: { label: "Email", type: "email" },
        password: { label: "Password", type: "password" },
      },

      async authorize(credentials) {
        // Validate credentials
        const parsed = LoginSchema.safeParse(credentials);
        if (!parsed.success) {
          return null;
        }

        const { email, password } = parsed.data;

        // Find user
        const [user] = await db
          .select()
          .from(users)
          .where(eq(users.email, email.toLowerCase()))
          .limit(1);

        if (!user || !user.passwordHash) {
          return null;
        }

        // Verify password
        const isValid = await bcrypt.compare(password, user.passwordHash);
        if (!isValid) {
          return null;
        }

        return {
          id: user.id,
          email: user.email,
          name: user.name,
          role: user.role,
          image: user.image,
        };
      },
    }),

    // TODO: Add OAuth providers as needed
    // Google({
    //   clientId: process.env.GOOGLE_CLIENT_ID,
    //   clientSecret: process.env.GOOGLE_CLIENT_SECRET,
    // }),
  ],

  session: {
    strategy: "jwt",
    maxAge: 30 * 24 * 60 * 60, // 30 days
  },

  trustHost: true,
});

/**
 * Extended types for Auth.js
 */
declare module "next-auth" {
  interface User {
    role?: string;
  }

  interface Session {
    user: {
      id: string;
      role: string;
      email: string;
      name?: string | null;
      image?: string | null;
    };
  }
}

declare module "next-auth/jwt" {
  interface JWT {
    id?: string;
    role?: string;
  }
}
'

    write_file "src/auth.ts" "$auth_config"

    # Step 4: Create API route
    log_step "Creating API route handler"

    ensure_dir "src/app/api/auth/[...nextauth]"

    local api_route='import { handlers } from "@/auth";

export const { GET, POST } = handlers;
'

    write_file "src/app/api/auth/[...nextauth]/route.ts" "$api_route"

    # Step 5: Create middleware
    log_step "Creating middleware.ts"

    local middleware='import { auth } from "@/auth";

export default auth;

export const config = {
  /**
   * Match all routes except:
   * - api/auth (auth endpoints)
   * - _next (Next.js internals)
   * - static files (images, etc.)
   */
  matcher: [
    "/((?!api/auth|_next/static|_next/image|favicon.ico|.*\\.png$).*)",
  ],
};
'

    write_file "src/middleware.ts" "$middleware"

    # Step 6: Create auth helpers
    log_step "Creating auth helper functions"

    local auth_helpers='import { auth } from "@/auth";
import { redirect } from "next/navigation";
import { cache } from "react";

/**
 * Get the current user session (cached)
 *
 * Use this in Server Components and Server Actions.
 */
export const getCurrentUser = cache(async () => {
  const session = await auth();
  return session?.user ?? null;
});

/**
 * Require authentication
 *
 * Redirects to login if not authenticated.
 * Use at the top of protected pages/layouts.
 */
export async function requireAuth() {
  const user = await getCurrentUser();

  if (!user) {
    redirect("/login");
  }

  return user;
}

/**
 * Require specific role
 *
 * Redirects to home if user lacks required role.
 */
export async function requireRole(role: "admin" | "editor" | "viewer") {
  const user = await requireAuth();

  const roleHierarchy = { admin: 3, editor: 2, viewer: 1 };
  const userLevel = roleHierarchy[user.role as keyof typeof roleHierarchy] ?? 0;
  const requiredLevel = roleHierarchy[role];

  if (userLevel < requiredLevel) {
    redirect("/");
  }

  return user;
}

/**
 * Check if user is authenticated (no redirect)
 */
export async function isAuthenticated(): Promise<boolean> {
  const user = await getCurrentUser();
  return !!user;
}
'

    write_file "src/lib/auth.ts" "$auth_helpers"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
