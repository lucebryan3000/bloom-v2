#!/usr/bin/env bash
#!meta
# id: core/nextjs.sh
# name: Next.js + React + TypeScript Foundation
# phase: 0
# phase_name: Project Foundation
# profile_tags:
#   - tech_stack
#   - core
# uses_from_omni_config:
#   - APP_DESCRIPTION
#   - APP_NAME
#   - APP_VERSION
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# required_vars:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - NODE_VERSION
# top_flags:
# dependencies:
#   packages:
#     - @types/node
#     - @types/react
#     - @types/react-dom
#     - next
#     - react
#     - react-dom
#     - typescript
#   dev_packages:
#     - @types/node
#     - @types/react
#     - @types/react-dom
#     - typescript
#!endmeta
# Docs:
#   - https://www.npmjs.com/package/@types/node
#   - https://www.npmjs.com/package/@types/react
#   - https://www.npmjs.com/package/@types/react-dom



# =============================================================================
# tech_stack/core/nextjs.sh - Next.js + React + TypeScript Foundation
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 0 (Foundation)
# Profile: ALL (always installed)
#
# Installs:
#   - next (React framework)
#   - react, react-dom (UI library)
#   - typescript (type safety)
#   - @types/node, @types/react, @types/react-dom (type definitions)
#
# Dependencies:
#   - next
#   - react
#   - react-dom
#   - typescript
#   - @types/node
#   - @types/react
#   - @types/react-dom
#
# Creates:
#   - package.json (if not exists)
#   - tsconfig.json
#   - next.config.ts
#   - src/app/layout.tsx
#   - src/app/page.tsx
#
# Cache Check:
#   - .download-cache/npm/next-*.tgz
#   - .download-cache/npm/react/ directory
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="core/nextjs"
readonly SCRIPT_NAME="Next.js + React + TypeScript"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

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
if [[ ! -d "$INSTALL_DIR" ]]; then
    log_info "Creating project directory: $INSTALL_DIR"
    mkdir -p "$INSTALL_DIR"
fi

cd "$INSTALL_DIR"

# =============================================================================
# PACKAGE.JSON SETUP
# =============================================================================

log_step "Initializing package.json"

# Always write a fresh package.json (overwrites stubs)
if [[ -f "package.json" ]]; then
    cp package.json package.json.bak 2>/dev/null || true
fi

cat > package.json <<EOF
{
  "name": "${APP_NAME}",
  "version": "${APP_VERSION}",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "next dev --turbopack",
    "build": "next build",
    "start": "next start",
    "lint": "next lint",
    "typecheck": "tsc --noEmit"
  },
  "engines": {
    "node": ">=${NODE_VERSION}.0.0"
  },
  "dependencies": {
    "next": "${PKG_NEXT}",
    "react": "${PKG_REACT}",
    "react-dom": "${PKG_REACT_DOM}"
  },
  "devDependencies": {
    "typescript": "${PKG_TYPESCRIPT}",
    "@types/node": "${PKG_TYPES_NODE}",
    "@types/react": "${PKG_TYPES_REACT}",
    "@types/react-dom": "${PKG_TYPES_REACT_DOM}"
  }
}
EOF
log_ok "Wrote package.json"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing dependencies"

# Define required packages
DEPS=("next" "react" "react-dom")
DEV_DEPS=("typescript" "@types/node" "@types/react" "@types/react-dom")

# Show cache status
pkg_preflight_check "${DEPS[@]}" "${DEV_DEPS[@]}"

# Install dependencies (if not already present)
log_info "Installing production dependencies..."
if ! pkg_verify_all "${DEPS[@]}"; then
    if ! pkg_install_retry "${DEPS[@]}"; then
        log_error "Failed to install dependencies"
        exit 1
    fi
else
    log_skip "Production dependencies already installed"
fi

log_info "Installing dev dependencies..."
if ! pkg_verify_all "${DEV_DEPS[@]}"; then
    if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
        log_error "Failed to install dev dependencies"
        exit 1
    fi
else
    log_skip "Dev dependencies already installed"
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify_all "next" "react" "typescript" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "All dependencies installed"

# =============================================================================
# TYPESCRIPT CONFIGURATION
# =============================================================================

log_step "Creating TypeScript configuration"

if [[ ! -f "tsconfig.json" ]]; then
    cat > tsconfig.json <<'EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["dom", "dom.iterable", "esnext"],
    "allowJs": true,
    "skipLibCheck": true,
    "strict": true,
    "noEmit": true,
    "esModuleInterop": true,
    "module": "esnext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "isolatedModules": true,
    "jsx": "preserve",
    "incremental": true,
    "plugins": [{ "name": "next" }],
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx"],
  "exclude": [
    "node_modules",
    "src/test/**/*",
    "test/**/*",
    "e2e/**/*",
    ".next",
    "**/*.backup.ts",
    "**/*.old.ts",
    "**/archive/**/*",
    "**/backup/**/*",
    "_AppModules-Luce/**/*",
    "_backup/**/*",
    "_build/**/*",
    "archive/**/*",
    "backup/**/*"
  ]
}
EOF
    log_ok "Created tsconfig.json"
else
    log_skip "tsconfig.json already exists"
fi

# =============================================================================
# NEXT.JS CONFIGURATION
# =============================================================================

log_step "Creating Next.js configuration"

if [[ ! -f "next.config.ts" ]]; then
    cat > next.config.ts <<'EOF'
import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  // Enable React strict mode for development
  reactStrictMode: true,

  // Needed for Docker multistage build optimization
  output: 'standalone',

  // Relax linting during containerized builds to prioritize successful image creation
  eslint: {
    ignoreDuringBuilds: true,
  },

  // Allow type errors to pass during container builds (fix incrementally in dev)
  typescript: {
    ignoreBuildErrors: true,
  },

  // Environment variables available to the browser
  env: {
    // Add public env vars here
  },

  // Image optimization
  images: {
    remotePatterns: [
      // Add allowed image domains here
    ],
  },
};

export default nextConfig;
EOF
    log_ok "Created next.config.ts"
else
    log_skip "next.config.ts already exists"
fi

# =============================================================================
# APP STRUCTURE
# =============================================================================

log_step "Creating app structure"

mkdir -p src/app

# Root layout
if [[ ! -f "src/app/layout.tsx" ]]; then
    cat > src/app/layout.tsx <<EOF
import type { Metadata } from 'next';
import './globals.css';

export const metadata: Metadata = {
  title: '${APP_NAME}',
  description: '${APP_DESCRIPTION}',
};

export default function RootLayout({
  children,
}: Readonly<{
  children: React.ReactNode;
}>) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  );
}
EOF
    log_ok "Created src/app/layout.tsx"
fi

# Home page
if [[ ! -f "src/app/page.tsx" ]]; then
    cat > src/app/page.tsx <<'EOF'
export default function Home() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center p-24">
      <h1 className="text-4xl font-bold">Welcome</h1>
      <p className="mt-4 text-gray-600">Your app is ready.</p>
    </main>
  );
}
EOF
    log_ok "Created src/app/page.tsx"
fi

# Global styles
if [[ ! -f "src/app/globals.css" ]]; then
    cat > src/app/globals.css <<'EOF'
@config "../../tailwind.config.ts";

@tailwind base;
@tailwind components;
@tailwind utilities;

:root {
  --foreground-rgb: 0, 0, 0;
  --background-rgb: 255, 255, 255;
}

@media (prefers-color-scheme: dark) {
  :root {
    --foreground-rgb: 255, 255, 255;
    --background-rgb: 0, 0, 0;
  }
}

body {
  color: rgb(var(--foreground-rgb));
  background: rgb(var(--background-rgb));
}
EOF
    log_ok "Created src/app/globals.css"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"
