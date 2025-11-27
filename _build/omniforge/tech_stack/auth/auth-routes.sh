#!/usr/bin/env bash
#!meta
# id: auth/auth-routes.sh
# name: auth routes
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - auth
# uses_from_omni_config:
#   - ENABLE_AUTHJS
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - AUTH_API_DIR
#   - SIGNIN_DIR
#   - SIGNOUT_DIR
# top_flags:
# dependencies:
#   packages: []
#   dev_packages: []
#!endmeta

# =============================================================================
# tech_stack/auth/auth-routes.sh - Auth Routes Setup
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2
# Purpose: Creates auth API routes and signin/signout pages for Auth.js
# =============================================================================
#
# Dependencies:
#   - depends on core/auth (next-auth handlers)
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="auth/auth-routes"
readonly SCRIPT_NAME="Auth Routes Setup"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# Create auth API route directory
AUTH_API_DIR="src/app/api/auth/[...nextauth]"
mkdir -p "${AUTH_API_DIR}"

# Create route.ts for Auth.js API handler
cat > "${AUTH_API_DIR}/route.ts" << 'EOF'
import { handlers } from "@/lib/auth";

export const { GET, POST } = handlers;
EOF

log_ok "Created auth API route handler"

# Create signin page directory
SIGNIN_DIR="src/app/(auth)/signin"
mkdir -p "${SIGNIN_DIR}"

# Create signin page
cat > "${SIGNIN_DIR}/page.tsx" << 'EOF'
import { signIn } from "@/lib/auth";

export default function SignInPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 rounded-lg border p-8 shadow-sm">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Sign In</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Choose your preferred sign-in method
          </p>
        </div>
        <form
          action={async () => {
            "use server";
            await signIn();
          }}
        >
          <button
            type="submit"
            className="w-full rounded-md bg-primary px-4 py-2 text-primary-foreground hover:bg-primary/90"
          >
            Sign In
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

log_ok "Created signin page"

# Create signout page directory
SIGNOUT_DIR="src/app/(auth)/signout"
mkdir -p "${SIGNOUT_DIR}"

# Create signout page
cat > "${SIGNOUT_DIR}/page.tsx" << 'EOF'
import { signOut } from "@/lib/auth";

export default function SignOutPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 rounded-lg border p-8 shadow-sm">
        <div className="text-center">
          <h1 className="text-2xl font-bold">Sign Out</h1>
          <p className="mt-2 text-sm text-muted-foreground">
            Are you sure you want to sign out?
          </p>
        </div>
        <form
          action={async () => {
            "use server";
            await signOut({ redirectTo: "/" });
          }}
        >
          <button
            type="submit"
            className="w-full rounded-md bg-destructive px-4 py-2 text-destructive-foreground hover:bg-destructive/90"
          >
            Sign Out
          </button>
        </form>
      </div>
    </div>
  );
}
EOF

log_ok "Created signout page"

# Create auth layout for auth pages
cat > "src/app/(auth)/layout.tsx" << 'EOF'
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen bg-background">
      {children}
    </div>
  );
}
EOF

log_ok "Created auth layout"

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"