#!/usr/bin/env bash
# =============================================================================
# omni.settings.sh
# Advanced/system settings and derived values for OmniForge.
# These settings were moved here from bootstrap.conf as part of the cutover.
# =============================================================================

# -----------------------------------------------------------------------------
# SECTION 2: ADVANCED SETTINGS
# -----------------------------------------------------------------------------
# Occasionally changed settings for development workflow

: "${PREFLIGHT_REMEDIATE:=true}"
: "${PREFLIGHT_SKIP_MISSING:=false}"
: "${PREFLIGHT_DOWNLOAD_PACKAGES:=true}"

: "${AUTO_INSTALL_PNPM:=true}"
: "${AUTO_INSTALL_NODE:=true}"
: "${AUTO_INSTALL_DOCKER:=true}"
: "${AUTO_INSTALL_PSQL:=true}"

: "${LOG_LEVEL:=status}"          # Options: quiet, status, verbose
: "${LOG_FORMAT:=plain}"          # Options: plain, json
: "${LOG_ROTATE_DAYS:=30}"
: "${LOG_CLEANUP_DAYS:=90}"

: "${DOCKER_REQUIRED:=true}"
: "${ENABLE_DOCKER:=true}"
: "${DOCKER_EXEC_MODE:=container}"              # Options: host, container
: "${DOCKER_COMPOSE_FILE:=docker-compose.yml}"
: "${APP_SERVICE_NAME:=app}"
: "${APP_ENV_FILE:=.env}"
: "${ENABLE_REDIS:=false}"
: "${DOCKER_REGISTRY:=ghcr.io}"
: "${DOCKER_BUILDKIT:=1}"

: "${GIT_SAFETY:=true}"
: "${ALLOW_DIRTY:=false}"
: "${NON_INTERACTIVE:=false}"
: "${MAX_CMD_SECONDS:=960}"
: "${BOOTSTRAP_RESUME_MODE:=skip}"              # Options: skip, force

: "${BACKUP_LOCATION:=./backups}"
: "${ENABLE_AUTO_BACKUP:=true}"
: "${DRY_RUN_DIR:=./dry-run}"

# -----------------------------------------------------------------------------
# SECTION 3: SYSTEM CONFIGURATION
# -----------------------------------------------------------------------------
# Rarely changed - framework versions, paths, package definitions

: "${NODE_VERSION:=20.18.1}"
: "${PNPM_VERSION:=9.15.0}"
: "${REQUIRED_NODE_VERSION:=20}"
: "${NEXT_VERSION:=15}"
: "${POSTGRES_VERSION:=16}"
: "${PGVECTOR_IMAGE:=pgvector/pgvector:pg16}"

: "${PROJECT_ROOT:=.}"
: "${OMNIFORGE_DIR:=${SCRIPTS_DIR:-_build/omniforge}}"
: "${TOOLS_DIR:=${PROJECT_ROOT}/.tools}"
: "${LOG_DIR:=${OMNIFORGE_DIR}/logs}"

: "${INSTALL_DIR_TEST:=./test/install-1}"
: "${INSTALL_DIR_PROD:=./app}"

: "${SRC_DIR:=src}"
: "${SRC_APP_DIR:=${SRC_DIR}/app}"
: "${SRC_COMPONENTS_DIR:=${SRC_DIR}/components}"
: "${SRC_LIB_DIR:=${SRC_DIR}/lib}"
: "${SRC_DB_DIR:=${SRC_DIR}/db}"
: "${SRC_STYLES_DIR:=${SRC_DIR}/styles}"
: "${SRC_HOOKS_DIR:=${SRC_DIR}/hooks}"
: "${SRC_TYPES_DIR:=${SRC_DIR}/types}"
: "${SRC_STORES_DIR:=${SRC_DIR}/stores}"
: "${SRC_TEST_DIR:=${SRC_DIR}/test}"
: "${PUBLIC_DIR:=public}"
: "${TEST_DIR:=__tests__}"
: "${E2E_DIR:=e2e}"

if [[ -z "${PROJECT_DIRECTORIES+x}" ]]; then
PROJECT_DIRECTORIES="$(cat <<'EOF'
${SRC_APP_DIR}
${SRC_COMPONENTS_DIR}
${SRC_LIB_DIR}
${SRC_DB_DIR}
${SRC_STYLES_DIR}
${SRC_HOOKS_DIR}
${SRC_TYPES_DIR}
${PUBLIC_DIR}
EOF
)"
fi

: "${DEV_PORT:=3000}"
: "${DEV_SERVER_URL:=http://localhost:${DEV_PORT}}"

: "${NODE_LOCAL_DIR:=${TOOLS_DIR}/node}"
: "${NODE_LOCAL_BIN:=${NODE_LOCAL_DIR}/bin/node}"
: "${NPM_LOCAL_BIN:=${NODE_LOCAL_DIR}/bin/npm}"
: "${NPX_LOCAL_BIN:=${NODE_LOCAL_DIR}/bin/npx}"
: "${PNPM_LOCAL_DIR:=${TOOLS_DIR}/pnpm}"
: "${PNPM_LOCAL_BIN:=${PNPM_LOCAL_DIR}/bin/pnpm}"
: "${TOOLS_ACTIVATE_SCRIPT:=${PROJECT_ROOT}/.toolsrc}"

: "${NODE_DOWNLOAD_BASE:=https://nodejs.org/dist}"
: "${NODE_PLATFORM:=linux}"
: "${NODE_ARCH:=x64}"

: "${OMNIFORGE_EXAMPLE_FILES_DIR:=${OMNIFORGE_DIR}/example-files}"
: "${TEMPLATE_TOOLSRC:=${OMNIFORGE_EXAMPLE_FILES_DIR}/.toolsrc.example}"

: "${OMNI_VERSION:=3.0.0}"
: "${OMNI_TAGLINE:=Infinite Architectures. Instant Foundation.}"
: "${OMNI_LOGO:=block}"

: "${ENV_ANTHROPIC_API_KEY:=ANTHROPIC_API_KEY}"
: "${ENV_AUTH_SECRET:=AUTH_SECRET}"
: "${ENV_DATABASE_URL:=DATABASE_URL}"

# Package definitions (Core Framework)
: "${PKG_NEXT:=next@15}"
: "${PKG_REACT:=react@19}"
: "${PKG_REACT_DOM:=react-dom@19}"
: "${PKG_TYPESCRIPT:=typescript@5}"
: "${PKG_TYPES_NODE:=@types/node@20}"
: "${PKG_TYPES_REACT:=@types/react@19}"
: "${PKG_TYPES_REACT_DOM:=@types/react-dom@19}"

# Package definitions (Database & ORM)
: "${PKG_DRIZZLE_ORM:=drizzle-orm}"
: "${PKG_DRIZZLE_KIT:=drizzle-kit}"
: "${PKG_POSTGRES_JS:=postgres}"
: "${PKG_TSX:=tsx}"

# Package definitions (AI & Auth)
: "${PKG_VERCEL_AI:=ai}"
: "${PKG_AI_SDK_OPENAI:=@ai-sdk/openai}"
: "${PKG_AI_SDK_ANTHROPIC:=@ai-sdk/anthropic}"
: "${PKG_NEXT_AUTH:=next-auth@beta}"
: "${PKG_AUTH_DRIZZLE_ADAPTER:=@auth/drizzle-adapter}"
: "${PKG_BCRYPTJS:=bcryptjs}"
: "${PKG_TYPES_BCRYPTJS:=@types/bcryptjs}"

# Package definitions (State & UI)
: "${PKG_ZUSTAND:=zustand}"
: "${PKG_IMMER:=immer}"
: "${PKG_CLSX:=clsx}"
: "${PKG_TAILWIND_MERGE:=tailwind-merge}"
: "${PKG_CLASS_VARIANCE_AUTHORITY:=class-variance-authority}"
: "${PKG_LUCIDE_REACT:=lucide-react}"
: "${PKG_REACT_TO_PRINT:=react-to-print}"

# Package definitions (Tailwind & PostCSS)
: "${PKG_TAILWINDCSS:=tailwindcss}"
: "${PKG_POSTCSS:=postcss}"
: "${PKG_AUTOPREFIXER:=autoprefixer}"

# Package definitions (Jobs & Observability)
: "${PKG_PG_BOSS:=pg-boss}"
: "${PKG_PINO:=pino}"
: "${PKG_PINO_PRETTY:=pino-pretty}"

# Package definitions (Validation & Env)
: "${PKG_ZOD:=zod}"
: "${PKG_T3_ENV:=@t3-oss/env-nextjs}"

# Package definitions (Export System)
: "${PKG_JSPDF:=jspdf}"
: "${PKG_HTML2CANVAS:=html2canvas}"
: "${PKG_EXCELJS:=exceljs}"
: "${PKG_TYPES_EXCELJS:=@types/exceljs}"

# Package definitions (Markdown & Narrative)
: "${PKG_MARKDOWN_IT:=markdown-it}"
: "${PKG_REMARK:=remark}"
: "${PKG_REMARK_HTML:=remark-html}"

# Package definitions (Testing)
: "${PKG_VITEST:=vitest}"
: "${PKG_VITEJS_PLUGIN_REACT:=@vitejs/plugin-react}"
: "${PKG_TESTING_LIBRARY_REACT:=@testing-library/react}"
: "${PKG_TESTING_LIBRARY_JEST_DOM:=@testing-library/jest-dom}"
: "${PKG_JSDOM:=jsdom}"
: "${PKG_PLAYWRIGHT:=@playwright/test}"

# Package definitions (Code Quality)
: "${PKG_ESLINT:=eslint}"
: "${PKG_ESLINT_CONFIG_PRETTIER:=eslint-config-prettier}"
: "${PKG_ESLINT_PLUGIN_JSX_A11Y:=eslint-plugin-jsx-a11y}"
: "${PKG_TYPESCRIPT_ESLINT_PLUGIN:=@typescript-eslint/eslint-plugin}"
: "${PKG_TYPESCRIPT_ESLINT_PARSER:=@typescript-eslint/parser}"
: "${PKG_PRETTIER:=prettier}"
: "${PKG_PRETTIER_PLUGIN_TAILWIND:=prettier-plugin-tailwindcss}"
: "${PKG_HUSKY:=husky}"
: "${PKG_LINT_STAGED:=lint-staged}"

# Package profiles
: "${AUTH_PACKAGE_PROFILE:=core}"
: "${AI_PACKAGE_PROFILE:=core}"
: "${UI_PACKAGE_PROFILE:=core}"
: "${TEST_PACKAGE_PROFILE:=full}"
: "${CODE_QUALITY_PACKAGE_PROFILE:=full}"

# -----------------------------------------------------------------------------
# SECTION 6: DERIVED VALUES
# -----------------------------------------------------------------------------

# Resolve PROJECT_ROOT if relative
if [[ "${PROJECT_ROOT}" == "." ]]; then
  PROJECT_ROOT="$(cd "${SCRIPTS_DIR:-$(cd -- \"$(dirname \"${BASH_SOURCE[0]}\")/..\" && pwd)}/../.." && pwd)"
fi

# Dynamically computed installation directory
if [[ -z "${INSTALL_DIR+x}" ]]; then
  if [[ "${INSTALL_TARGET:-test}" == "prod" ]]; then
    INSTALL_DIR="${INSTALL_DIR_PROD}"
  else
    INSTALL_DIR="${INSTALL_DIR_TEST}"
  fi
fi

: "${OMNIFORGE_SETUP_MARKER:=${PROJECT_ROOT}/.omniforge_setup_complete}"
: "${BOOTSTRAP_STATE_FILE:=${PROJECT_ROOT}/.bootstrap_state}"
: "${GIT_REMOTE_URL:=${GIT_REMOTE_URL:-}}"
