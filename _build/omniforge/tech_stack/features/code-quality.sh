#!/usr/bin/env bash
# =============================================================================
# tech_stack/features/code-quality.sh - ESLint + Prettier + Husky
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: Features
# Profile: enterprise
#
# Installs (dev):
#   - eslint (linting)
#   - prettier (formatting)
#   - lint-staged (staged file processing)
#   - husky (git hooks)
#   - @typescript-eslint/eslint-plugin (TypeScript rules)
#   - @typescript-eslint/parser (TypeScript parsing)
#
# Creates:
#   - .eslintrc.json
#   - .prettierrc
#   - .lintstagedrc
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="features/code-quality"
readonly SCRIPT_NAME="ESLint + Prettier Code Quality"

# =============================================================================
# PREFLIGHT
# =============================================================================

log_step "${SCRIPT_NAME} - Preflight"

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

# Verify PROJECT_ROOT is set
if [[ -z "${PROJECT_ROOT:-}" ]]; then
    log_error "PROJECT_ROOT not set"
    exit 1
fi

# Verify project directory exists
if [[ ! -d "$PROJECT_ROOT" ]]; then
    log_error "Project directory does not exist: $PROJECT_ROOT"
    exit 1
fi

cd "$PROJECT_ROOT"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing code quality dependencies"

DEV_DEPS=(
    "${PKG_ESLINT}"
    "${PKG_PRETTIER}"
    "${PKG_LINT_STAGED}"
    "${PKG_HUSKY}"
    "${PKG_TYPESCRIPT_ESLINT_PLUGIN}"
    "${PKG_TYPESCRIPT_ESLINT_PARSER}"
)

# Show cache status
pkg_preflight_check "${DEV_DEPS[@]}"

# Install dev dependencies
log_info "Installing code quality tools..."
pkg_install_dev "${DEV_DEPS[@]}" || {
    log_error "Failed to install code quality dependencies"
    exit 1
}

# Verify installation
log_info "Verifying installation..."
pkg_verify_all "${PKG_ESLINT}" "${PKG_PRETTIER}" "${PKG_LINT_STAGED}" "${PKG_HUSKY}" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "Code quality dependencies installed"

# =============================================================================
# ESLINT CONFIGURATION
# =============================================================================

log_step "Creating ESLint configuration"

if [[ ! -f ".eslintrc.json" ]]; then
    cat > .eslintrc.json <<'EOF'
{
  "root": true,
  "env": {
    "browser": true,
    "es2022": true,
    "node": true
  },
  "extends": [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "next/core-web-vitals"
  ],
  "parser": "@typescript-eslint/parser",
  "parserOptions": {
    "ecmaVersion": "latest",
    "sourceType": "module",
    "project": "./tsconfig.json"
  },
  "plugins": ["@typescript-eslint"],
  "rules": {
    "@typescript-eslint/no-unused-vars": [
      "error",
      {
        "argsIgnorePattern": "^_",
        "varsIgnorePattern": "^_"
      }
    ],
    "@typescript-eslint/consistent-type-imports": [
      "error",
      {
        "prefer": "type-imports"
      }
    ],
    "@typescript-eslint/no-misused-promises": [
      "error",
      {
        "checksVoidReturn": {
          "attributes": false
        }
      }
    ],
    "no-console": ["warn", { "allow": ["warn", "error"] }]
  },
  "ignorePatterns": [
    "node_modules/",
    ".next/",
    "out/",
    "coverage/",
    "*.config.js",
    "*.config.mjs"
  ]
}
EOF
    log_ok "Created .eslintrc.json"
else
    log_skip ".eslintrc.json already exists"
fi

# =============================================================================
# PRETTIER CONFIGURATION
# =============================================================================

log_step "Creating Prettier configuration"

if [[ ! -f ".prettierrc" ]]; then
    cat > .prettierrc <<'EOF'
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 80,
  "bracketSpacing": true,
  "arrowParens": "always",
  "endOfLine": "lf",
  "plugins": ["prettier-plugin-tailwindcss"]
}
EOF
    log_ok "Created .prettierrc"
else
    log_skip ".prettierrc already exists"
fi

# Create .prettierignore
if [[ ! -f ".prettierignore" ]]; then
    cat > .prettierignore <<'EOF'
node_modules/
.next/
out/
coverage/
pnpm-lock.yaml
package-lock.json
*.min.js
*.min.css
EOF
    log_ok "Created .prettierignore"
fi

# =============================================================================
# LINT-STAGED CONFIGURATION
# =============================================================================

log_step "Creating lint-staged configuration"

if [[ ! -f ".lintstagedrc" ]]; then
    cat > .lintstagedrc <<'EOF'
{
  "*.{ts,tsx}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{js,jsx,mjs,cjs}": [
    "eslint --fix",
    "prettier --write"
  ],
  "*.{json,md,yml,yaml}": [
    "prettier --write"
  ],
  "*.css": [
    "prettier --write"
  ]
}
EOF
    log_ok "Created .lintstagedrc"
else
    log_skip ".lintstagedrc already exists"
fi

# =============================================================================
# HUSKY SETUP
# =============================================================================

log_step "Setting up Husky git hooks"

# Initialize husky
if [[ ! -d ".husky" ]]; then
    # Initialize husky
    npx husky init 2>/dev/null || {
        log_warn "Husky init failed, trying manual setup"
        mkdir -p .husky
    }

    # Create pre-commit hook
    cat > .husky/pre-commit <<'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

npx lint-staged
EOF
    chmod +x .husky/pre-commit
    log_ok "Created pre-commit hook"

    # Create commit-msg hook for conventional commits (optional)
    cat > .husky/commit-msg <<'EOF'
#!/bin/sh
. "$(dirname "$0")/_/husky.sh"

# Optional: Add commitlint here
# npx --no -- commitlint --edit "$1"
EOF
    chmod +x .husky/commit-msg
    log_ok "Created commit-msg hook"
else
    log_skip "Husky already initialized"
fi

# =============================================================================
# NPM SCRIPTS
# =============================================================================

log_step "Adding code quality scripts to package.json"

# Add scripts if pkg_add_script is available
if command -v pkg_add_script &>/dev/null || type pkg_add_script &>/dev/null; then
    pkg_add_script "lint" "eslint src --ext .ts,.tsx"
    pkg_add_script "lint:fix" "eslint src --ext .ts,.tsx --fix"
    pkg_add_script "format" "prettier --write \"src/**/*.{ts,tsx,json,css}\""
    pkg_add_script "format:check" "prettier --check \"src/**/*.{ts,tsx,json,css}\""
    pkg_add_script "prepare" "husky"
    log_ok "Added code quality scripts"
else
    log_warn "pkg_add_script not available, skipping script additions"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
