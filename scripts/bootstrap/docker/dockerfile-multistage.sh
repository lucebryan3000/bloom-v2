#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="docker/dockerfile-multistage.sh"

usage() { cat <<EOF
Generate multi-stage Dockerfile for Node ${NODE_VERSION} + pnpm.
EOF
}

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { usage; exit 0; }

    log_info "=== Creating Dockerfile ==="
    cd "${PROJECT_ROOT:-.}"

    local dockerfile="# ${APP_NAME} Multi-Stage Dockerfile
FROM node:${NODE_VERSION}-alpine AS deps
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
COPY package.json pnpm-lock.yaml* ./
RUN --mount=type=cache,id=pnpm,target=/root/.local/share/pnpm/store pnpm install --frozen-lockfile

FROM node:${NODE_VERSION}-alpine AS builder
RUN corepack enable && corepack prepare pnpm@latest --activate
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
ENV NEXT_TELEMETRY_DISABLED=1 NODE_ENV=production
RUN pnpm build

FROM node:${NODE_VERSION}-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production NEXT_TELEMETRY_DISABLED=1
RUN addgroup --system --gid 1001 nodejs && adduser --system --uid 1001 nextjs
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static ./.next/static
RUN chown -R nextjs:nodejs /app
USER nextjs
EXPOSE 3000
ENV HOSTNAME=\"0.0.0.0\" PORT=3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 CMD wget --no-verbose --tries=1 --spider http://localhost:3000/api/health || exit 1
CMD [\"node\", \"server.js\"]
"

    write_file_if_missing "Dockerfile" "${dockerfile}"
    mark_script_success "${SCRIPT_KEY}"
    log_success "Dockerfile created"
}

main "$@"
