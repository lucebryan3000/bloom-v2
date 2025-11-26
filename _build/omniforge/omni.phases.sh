#!/usr/bin/env bash
# =============================================================================
# omni.phases.sh
# Canonical phase metadata for OmniForge.
# PHASE_METADATA_*, PHASE_CONFIG_*, PHASE_PACKAGES_*, and BOOTSTRAP_PHASE_*
# were moved here from bootstrap.conf.
# =============================================================================

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 0: Project Foundation
# ─────────────────────────────────────────────────────────────────────────────
# Initialize Next.js, TypeScript, project structure
# Dependencies: git, node, pnpm
# Timeout: 5 minutes
# Packages: Core framework (Next.js 15, React 19, TypeScript 5, type definitions)

PHASE_METADATA_0="number:0|name:Project Foundation|description:Initialize Next.js, TypeScript, project structure"

PHASE_CONFIG_00_FOUNDATION="enabled:true|timeout:300|exec:sequential|docker_required:true|prereq:strict|deps:git:https://git-scm.com,node:https://nodejs.org,pnpm:https://pnpm.io"

PHASE_PACKAGES_00_FOUNDATION="
PKG_NEXT
PKG_REACT
PKG_REACT_DOM
PKG_TYPESCRIPT
PKG_TYPES_NODE
PKG_TYPES_REACT
PKG_TYPES_REACT_DOM
"

BOOTSTRAP_PHASE_00_FOUNDATION="
_combined_scripts/install-package-package-json.sh
_combined_scripts/install-package-next.sh
_combined_scripts/install-package-typescript.sh
foundation/init-nextjs.sh
foundation/init-typescript.sh
foundation/init-package-engines.sh
foundation/init-directory-structure.sh
"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 1: Infrastructure & Database
# ─────────────────────────────────────────────────────────────────────────────
# Docker, PostgreSQL, Drizzle ORM, environment setup (longest phase)
# Dependencies: docker, psql
# Timeout: 20 minutes
# Packages: Drizzle ORM, PostgreSQL client, Zod validation, environment setup

PHASE_METADATA_1="number:1|name:Infrastructure & Database|description:Docker, PostgreSQL, Drizzle, environment setup (takes longest)"

PHASE_CONFIG_01_INFRASTRUCTURE="enabled:true|timeout:1200|exec:sequential|docker_required:true|prereq:strict|deps:docker:https://docker.com,psql:https://postgresql.org"

PHASE_PACKAGES_01_INFRASTRUCTURE="
PKG_DRIZZLE_ORM
PKG_DRIZZLE_KIT|enabled:false
PKG_POSTGRES_JS
PKG_TSX|enabled:false
PKG_ZOD
"

BOOTSTRAP_PHASE_01_INFRASTRUCTURE="
_combined_scripts/install-system-prereqs.sh
_combined_scripts/install-package-drizzle.sh
docker/dockerfile-multistage.sh
docker/docker-compose-pg.sh
docker/docker-pnpm-cache.sh
db/drizzle-setup.sh
db/drizzle-schema-base.sh
db/drizzle-migrations.sh
db/db-client-index.sh
env/env-validation.sh
env/zod-schemas-base.sh
env/rate-limiter.sh
env/server-action-template.sh
"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 2: Core Features
# ─────────────────────────────────────────────────────────────────────────────
# Authentication, AI/LLM integration, state management, background jobs, logging
# Dependencies: openssl (builtin)
# Timeout: 15 minutes
# Packages: Auth.js, Vercel AI SDK, Zustand, pg-boss, Pino logger

PHASE_METADATA_2="number:2|name:Core Features|description:Authentication, AI, state management, background jobs, logging"

PHASE_CONFIG_02_CORE="enabled:true|timeout:900|exec:sequential|docker_required:true|prereq:warn|deps:openssl:builtin"

PHASE_PACKAGES_02_CORE="
PKG_NEXT_AUTH
PKG_BCRYPTJS
PKG_TYPES_BCRYPTJS
PKG_VERCEL_AI
PKG_AI_SDK_ANTHROPIC|enabled:false
PKG_ZUSTAND
PKG_IMMER|enabled:false
PKG_PG_BOSS
PKG_PINO
PKG_PINO_PRETTY|enabled:false
"

BOOTSTRAP_PHASE_02_CORE="
_combined_scripts/install-package-ai.sh
_combined_scripts/install-package-zustand.sh
_combined_scripts/install-package-pgboss.sh
_combined_scripts/install-package-pino.sh
_combined_scripts/install-package-auth.sh
auth/authjs-setup.sh
auth/auth-routes.sh
ai/vercel-ai-setup.sh
ai/prompts-structure.sh
ai/chat-feature-scaffold.sh
state/zustand-setup.sh
state/session-state-lib.sh
jobs/pgboss-setup.sh
jobs/job-worker-template.sh
observability/pino-logger.sh
observability/pino-pretty-dev.sh
"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 3: User Interface
# ─────────────────────────────────────────────────────────────────────────────
# shadcn/ui components, printing support, component organization
# Dependencies: none (buildtime only)
# Timeout: 10 minutes
# Packages: shadcn/ui helpers (clsx, tailwind-merge), react-to-print

PHASE_METADATA_3="number:3|name:User Interface|description:shadcn/ui components, printing, component organization"

PHASE_CONFIG_03_UI="enabled:true|timeout:600|exec:sequential|docker_required:true|prereq:warn|deps:"

PHASE_PACKAGES_03_UI="
PKG_CLSX|enabled:false
PKG_TAILWIND_MERGE|enabled:false
PKG_REACT_TO_PRINT|enabled:false
"

BOOTSTRAP_PHASE_03_UI="
_combined_scripts/install-package-tailwind.sh
_combined_scripts/install-package-react-to-print.sh
ui/shadcn-init.sh
ui/react-to-print.sh
ui/components-structure.sh
"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 4: Extensions & Quality
# ─────────────────────────────────────────────────────────────────────────────
# Intelligence features, exports (PDF/Excel/Markdown), testing, code quality
# Dependencies: none
# Timeout: 30 minutes (optional packages, can skip some)
# Packages: Markdown/export libs, testing frameworks, linting/formatting tools

PHASE_METADATA_4="number:4|name:Extensions & Quality|description:Intelligence, exports, testing, code quality (pick what you need)"

PHASE_CONFIG_04_EXTENSIONS="enabled:true|timeout:1800|exec:sequential|docker_required:true|prereq:warn|deps:"

PHASE_PACKAGES_04_EXTENSIONS="
PKG_MARKDOWN_IT|enabled:false
PKG_REMARK|enabled:false
PKG_REMARK_HTML|enabled:false
PKG_JSPDF|enabled:false
PKG_HTML2CANVAS|enabled:false
PKG_EXCELJS|enabled:false
PKG_TYPES_EXCELJS|enabled:false
PKG_VITEST|enabled:false
PKG_VITEJS_PLUGIN_REACT|enabled:false
PKG_TESTING_LIBRARY_REACT|enabled:false
PKG_TESTING_LIBRARY_JEST_DOM|enabled:false
PKG_JSDOM|enabled:false
PKG_PLAYWRIGHT|enabled:false
PKG_ESLINT|enabled:false
PKG_ESLINT_CONFIG_PRETTIER|enabled:false
PKG_ESLINT_PLUGIN_JSX_A11Y|enabled:false
PKG_PRETTIER|enabled:false
PKG_HUSKY|enabled:false
PKG_LINT_STAGED|enabled:false
"

BOOTSTRAP_PHASE_04_EXTENSIONS="
_combined_scripts/install-package-export.sh
_combined_scripts/install-package-testing.sh
_combined_scripts/install-package-quality.sh
intelligence/melissa-prompts.sh
intelligence/roi-engine.sh
intelligence/confidence-engine.sh
intelligence/hitl-review-queue.sh
export/export-system.sh
export/pdf-export.sh
export/excel-export.sh
export/markdown-export.sh
export/json-export.sh
monitoring/health-endpoints.sh
monitoring/settings-ui.sh
monitoring/feature-flags.sh
testing/vitest-setup.sh
testing/playwright-setup.sh
testing/test-directory.sh
quality/eslint-prettier.sh
quality/husky-lintstaged.sh
quality/ts-strict-mode.sh
quality/verify-build.sh
"

# ─────────────────────────────────────────────────────────────────────────────
# PHASE 5: User-Defined (Custom)
# ─────────────────────────────────────────────────────────────────────────────
# Reserved for user customizations - add your own scripts here without modifying
# core phases. Just add scripts to BOOTSTRAP_PHASE_05_USER_DEFINED and packages
# to PHASE_PACKAGES_05_USER_DEFINED
# Dependencies: none
# Timeout: 10 minutes (adjust as needed)
# Packages: (user-defined)

PHASE_METADATA_5="number:5|name:User-Defined|description:Add your own scripts here without modifying core bootstrap phases"

PHASE_CONFIG_05_USER_DEFINED="enabled:false|timeout:600|exec:sequential|prereq:warn|deps:"

PHASE_PACKAGES_05_USER_DEFINED="
"

BOOTSTRAP_PHASE_05_USER_DEFINED="
"

# ─────────────────────────────────────────────────────────────────────────────
# Legacy Default Steps (kept for backward compatibility)
# ─────────────────────────────────────────────────────────────────────────────
# This is the full ordered list combining all phases 0-5
# Old code may reference BOOTSTRAP_STEPS_DEFAULT - it's now auto-generated from phases

BOOTSTRAP_STEPS_DEFAULT="
_combined_scripts/install-package-package-json.sh
_combined_scripts/install-package-next.sh
_combined_scripts/install-package-typescript.sh
foundation/init-nextjs.sh
foundation/init-typescript.sh
foundation/init-package-engines.sh
foundation/init-directory-structure.sh
docker/dockerfile-multistage.sh
docker/docker-compose-pg.sh
docker/docker-pnpm-cache.sh
db/drizzle-setup.sh
db/drizzle-schema-base.sh
db/drizzle-migrations.sh
db/db-client-index.sh
env/env-validation.sh
env/zod-schemas-base.sh
env/rate-limiter.sh
env/server-action-template.sh
auth/authjs-setup.sh
auth/auth-routes.sh
ai/vercel-ai-setup.sh
ai/prompts-structure.sh
ai/chat-feature-scaffold.sh
state/zustand-setup.sh
state/session-state-lib.sh
jobs/pgboss-setup.sh
jobs/job-worker-template.sh
observability/pino-logger.sh
observability/pino-pretty-dev.sh
intelligence/melissa-prompts.sh
intelligence/roi-engine.sh
intelligence/confidence-engine.sh
intelligence/hitl-review-queue.sh
ui/shadcn-init.sh
ui/react-to-print.sh
ui/components-structure.sh
export/export-system.sh
export/pdf-export.sh
export/excel-export.sh
export/markdown-export.sh
export/json-export.sh
monitoring/health-endpoints.sh
monitoring/settings-ui.sh
monitoring/feature-flags.sh
testing/vitest-setup.sh
testing/playwright-setup.sh
testing/test-directory.sh
quality/eslint-prettier.sh
quality/husky-lintstaged.sh
quality/ts-strict-mode.sh
quality/verify-build.sh
"
