#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="foundation/init-nextjs.sh"

usage() {
    cat <<EOF
Initialize Next.js ${NEXT_VERSION} App Router project with pnpm.
Creates package.json, src/app, .gitignore, .env.example, .env.local

Uses: PKG_NEXT, PKG_REACT, PKG_REACT_DOM, APP_NAME
EOF
}

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { usage; exit 0; }

    log_info "=== Initializing Next.js Project ==="

    cd "${PROJECT_ROOT:-.}"

    if [[ -f "package.json" && -d "src/app" ]]; then
        log_info "SKIP: Next.js project already initialized"
    else
        run_cmd "pnpm create next-app@latest . --typescript --tailwind --eslint --app --src-dir --import-alias '@/*' --use-pnpm --no-git"
    fi

    # Ensure .gitignore
    local gitignore_content="node_modules
.pnpm-store
.next
out
build
dist
coverage
.nyc_output
.DS_Store
*.pem
*.log
.env
.env.local
.env.*.local
.vercel
*.tsbuildinfo
next-env.d.ts
.idea
.vscode
logs/
test-results/
playwright-report/
"
    write_file_if_missing ".gitignore" "${gitignore_content}"

    # Ensure .env.example
    local env_example="# ${APP_NAME} Environment Variables
${ENV_DATABASE_URL}=postgresql://${DB_USER}:${DB_PASSWORD}@localhost:${DB_PORT}/${DB_NAME}
${ENV_AUTH_SECRET}=generate_a_secure_random_string_here
${ENV_ANTHROPIC_API_KEY}=sk-ant-your-key-here
NEXT_PUBLIC_APP_URL=http://localhost:3000
NODE_ENV=development
"
    write_file_if_missing ".env.example" "${env_example}"

    # Ensure .env.local
    if [[ ! -f ".env.local" ]]; then
        if [[ "${DRY_RUN:-false}" != "true" ]]; then
            cp .env.example .env.local 2>/dev/null || echo "${env_example}" > .env.local
            log_info "Created: .env.local"
        fi
    fi

    mark_script_success "${SCRIPT_KEY}"
    log_success "Next.js initialization complete"
}

main "$@"
