#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="auth/authjs-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Auth.js v5"; exit 0; }

    if [[ "${ENABLE_AUTHJS:-true}" != "true" ]]; then
        log_info "SKIP: Auth.js disabled via ENABLE_AUTHJS"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Auth.js v5 ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "next-auth@beta"
    add_dependency "@auth/core"
    add_dependency "@auth/drizzle-adapter"

    ensure_dir "src/lib/auth"

    local auth_config='import NextAuth from "next-auth";
import { DrizzleAdapter } from "@auth/drizzle-adapter";
import { db } from "@/db";
import type { NextAuthConfig } from "next-auth";

export const authConfig: NextAuthConfig = {
  adapter: DrizzleAdapter(db),
  providers: [],
  session: { strategy: "jwt" },
  pages: {
    signIn: "/login",
    error: "/auth/error",
  },
  callbacks: {
    authorized({ auth, request: { nextUrl } }) {
      const isLoggedIn = !!auth?.user;
      const isOnDashboard = nextUrl.pathname.startsWith("/dashboard");
      if (isOnDashboard) {
        if (isLoggedIn) return true;
        return false;
      }
      return true;
    },
    jwt({ token, user }) {
      if (user) {
        token.id = user.id;
      }
      return token;
    },
    session({ session, token }) {
      if (token && session.user) {
        session.user.id = token.id as string;
      }
      return session;
    },
  },
};

export const { handlers, auth, signIn, signOut } = NextAuth(authConfig);
'
    write_file_if_missing "src/lib/auth/config.ts" "${auth_config}"

    local middleware='import { auth } from "@/lib/auth/config";

export default auth((req) => {
  // Add custom middleware logic here
});

export const config = {
  matcher: ["/((?!api|_next/static|_next/image|favicon.ico).*)"],
};
'
    write_file_if_missing "src/middleware.ts" "${middleware}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Auth.js v5 setup complete"
}

main "$@"
