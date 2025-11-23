#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="auth/auth-routes.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create Auth.js API routes"; exit 0; }

    if [[ "${ENABLE_AUTHJS:-true}" != "true" ]]; then
        log_info "SKIP: Auth.js disabled via ENABLE_AUTHJS"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Creating Auth Routes ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/app/api/auth/[...nextauth]"

    local route='import { handlers } from "@/lib/auth/config";

export const { GET, POST } = handlers;
'
    write_file_if_missing "src/app/api/auth/[...nextauth]/route.ts" "${route}"

    ensure_dir "src/app/(auth)/login"

    local login_page='import { signIn } from "@/lib/auth/config";

export default function LoginPage() {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="w-full max-w-md space-y-8 p-8">
        <h1 className="text-2xl font-bold text-center">Sign In</h1>
        <form
          action={async () => {
            "use server";
            await signIn();
          }}
        >
          <button
            type="submit"
            className="w-full rounded-lg bg-primary px-4 py-2 text-white hover:bg-primary/90"
          >
            Sign In
          </button>
        </form>
      </div>
    </div>
  );
}
'
    write_file_if_missing "src/app/(auth)/login/page.tsx" "${login_page}"

    ensure_dir "src/app/(auth)/auth/error"

    local error_page='export default function AuthErrorPage({
  searchParams,
}: {
  searchParams: { error?: string };
}) {
  return (
    <div className="flex min-h-screen items-center justify-center">
      <div className="text-center">
        <h1 className="text-2xl font-bold text-red-600">Authentication Error</h1>
        <p className="mt-2 text-gray-600">
          {searchParams.error || "An error occurred during authentication"}
        </p>
        <a href="/login" className="mt-4 inline-block text-primary hover:underline">
          Back to login
        </a>
      </div>
    </div>
  );
}
'
    write_file_if_missing "src/app/(auth)/auth/error/page.tsx" "${error_page}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Auth routes created"
}

main "$@"
