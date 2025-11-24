#!/usr/bin/env bash
# =============================================================================
# tech_stack/core/00-nextjs.sh - Next.js + React + TypeScript Foundation
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
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="core/00-nextjs"
readonly SCRIPT_NAME="Next.js + React + TypeScript"

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

if [[ ! -f "package.json" ]]; then
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
  }
}
EOF
    log_ok "Created package.json"
else
    log_skip "package.json already exists"
fi

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing dependencies"

# Define required packages
DEPS=("next" "react" "react-dom")
DEV_DEPS=("typescript" "@types/node" "@types/react" "@types/react-dom")

# Show cache status
pkg_preflight_check "${DEPS[@]}" "${DEV_DEPS[@]}"

# Install dependencies
log_info "Installing production dependencies..."
pkg_install "${DEPS[@]}" || {
    log_error "Failed to install dependencies"
    exit 1
}

log_info "Installing dev dependencies..."
pkg_install_dev "${DEV_DEPS[@]}" || {
    log_error "Failed to install dev dependencies"
    exit 1
}

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
  "include": ["next-env.d.ts", "**/*.ts", "**/*.tsx", ".next/types/**/*.ts"],
  "exclude": ["node_modules"]
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

  // Experimental features
  experimental: {
    // Enable typed routes
    typedRoutes: true,
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
