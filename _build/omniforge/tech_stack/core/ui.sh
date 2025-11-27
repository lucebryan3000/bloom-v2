#!/usr/bin/env bash
#!meta
# id: core/ui.sh
# name: UI Framework (shadcn/ui + Tailwind)
# phase: 2
# phase_name: Core Features
# profile_tags:
#   - tech_stack
#   - core
# uses_from_omni_config:
#   - ENABLE_SHADCN
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
#   - GLOBALS_CSS
# top_flags:
# dependencies:
#   packages:
#     - autoprefixer
#     - class-variance-authority
#     - clsx
#     - lucide-react
#     - postcss
#     - tailwindcss
#     - tailwind-merge
#   dev_packages:
#     - autoprefixer
#     - postcss
#     - tailwindcss
#!endmeta


# =============================================================================
# tech_stack/core/ui.sh - UI Framework (shadcn/ui + Tailwind)
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 2 (UI)
# Profile: starter, standard, advanced, enterprise
#
# Installs:
#   - tailwindcss, postcss, autoprefixer (dev)
#   - lucide-react (icons)
#   - class-variance-authority (component variants)
#   - clsx (class merging)
#   - tailwind-merge (tailwind class deduplication)
#
# Creates:
#   - tailwind.config.ts (with shadcn preset)
#   - postcss.config.mjs
#   - src/lib/utils.ts (cn() helper)
#   - components.json (shadcn CLI config)
#
# Cache Check:
#   - .download-cache/npm/lucide-react-0.554.0.tgz
# =============================================================================
#
# Dependencies:
#   - tailwindcss (dev)
#   - postcss (dev)
#   - autoprefixer (dev)
#   - lucide-react
#   - class-variance-authority
#   - clsx
#   - tailwind-merge
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi
source "${SCRIPT_DIR}/../_lib/pkg-install.sh"

readonly SCRIPT_ID="core/ui"
readonly SCRIPT_NAME="UI Framework (shadcn/ui + Tailwind)"

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
    log_error "PROJECT_ROOT does not exist: $INSTALL_DIR"
    exit 1
fi

# Verify package.json exists (dependency on core/nextjs)
if [[ ! -f "${INSTALL_DIR}/package.json" ]]; then
    log_error "package.json not found. Run core/nextjs first."
    exit 1
fi

cd "$INSTALL_DIR"

# =============================================================================
# DEPENDENCY INSTALLATION
# =============================================================================

log_step "Installing Tailwind CSS dependencies"

# Dev dependencies for Tailwind/PostCSS
DEV_DEPS=("${PKG_TAILWINDCSS}" "${PKG_POSTCSS}" "${PKG_AUTOPREFIXER}")

# Production dependencies for shadcn utilities
DEPS=("${PKG_LUCIDE_REACT}" "${PKG_CLASS_VARIANCE_AUTHORITY}" "${PKG_CLSX}" "${PKG_TAILWIND_MERGE}")

# Show cache status
pkg_preflight_check "${DEPS[@]}" "${DEV_DEPS[@]}"

# Check for specific cached version of lucide-react
LUCIDE_CACHE="lucide-react-0.554.0.tgz"
if pkg_cache_exists "$LUCIDE_CACHE"; then
    log_info "Found cached lucide-react: $LUCIDE_CACHE"
fi

# Install dev dependencies
log_info "Installing Tailwind CSS dev dependencies..."
if ! pkg_verify_all "${DEV_DEPS[@]}"; then
    if ! pkg_install_dev_retry "${DEV_DEPS[@]}"; then
        log_error "Failed to install Tailwind dev dependencies"
        exit 1
    fi
else
    log_skip "Tailwind dev deps already installed"
fi

# Install production dependencies
log_info "Installing shadcn utility dependencies..."
if ! pkg_verify_all "${DEPS[@]}"; then
    if ! pkg_install_retry "${DEPS[@]}"; then
        log_error "Failed to install shadcn dependencies"
        exit 1
    fi
else
    log_skip "shadcn dependencies already installed"
fi

# Verify installation
log_info "Verifying installation..."
pkg_verify_all "tailwindcss" "lucide-react" "clsx" "tailwind-merge" || {
    log_error "Package verification failed"
    exit 1
}

log_ok "All UI dependencies installed"

# =============================================================================
# TAILWIND CONFIGURATION
# =============================================================================

log_step "Creating Tailwind CSS configuration"

if [[ ! -f "tailwind.config.ts" ]]; then
    cat > tailwind.config.ts <<'EOF'
import type { Config } from 'tailwindcss';

const config: Config = {
  darkMode: ['class'],
  content: [
    './src/pages/**/*.{js,ts,jsx,tsx,mdx}',
    './src/components/**/*.{js,ts,jsx,tsx,mdx}',
    './src/app/**/*.{js,ts,jsx,tsx,mdx}',
  ],
  theme: {
    container: {
      center: true,
      padding: '2rem',
      screens: {
        '2xl': '1400px',
      },
    },
    extend: {
      colors: {
        border: 'hsl(var(--border))',
        input: 'hsl(var(--input))',
        ring: 'hsl(var(--ring))',
        background: 'hsl(var(--background))',
        foreground: 'hsl(var(--foreground))',
        primary: {
          DEFAULT: 'hsl(var(--primary))',
          foreground: 'hsl(var(--primary-foreground))',
        },
        secondary: {
          DEFAULT: 'hsl(var(--secondary))',
          foreground: 'hsl(var(--secondary-foreground))',
        },
        destructive: {
          DEFAULT: 'hsl(var(--destructive))',
          foreground: 'hsl(var(--destructive-foreground))',
        },
        muted: {
          DEFAULT: 'hsl(var(--muted))',
          foreground: 'hsl(var(--muted-foreground))',
        },
        accent: {
          DEFAULT: 'hsl(var(--accent))',
          foreground: 'hsl(var(--accent-foreground))',
        },
        popover: {
          DEFAULT: 'hsl(var(--popover))',
          foreground: 'hsl(var(--popover-foreground))',
        },
        card: {
          DEFAULT: 'hsl(var(--card))',
          foreground: 'hsl(var(--card-foreground))',
        },
      },
      borderRadius: {
        lg: 'var(--radius)',
        md: 'calc(var(--radius) - 2px)',
        sm: 'calc(var(--radius) - 4px)',
      },
      keyframes: {
        'accordion-down': {
          from: { height: '0' },
          to: { height: 'var(--radix-accordion-content-height)' },
        },
        'accordion-up': {
          from: { height: 'var(--radix-accordion-content-height)' },
          to: { height: '0' },
        },
      },
      animation: {
        'accordion-down': 'accordion-down 0.2s ease-out',
        'accordion-up': 'accordion-up 0.2s ease-out',
      },
    },
  },
  plugins: [],
};

export default config;
EOF
    log_ok "Created tailwind.config.ts"
else
    log_skip "tailwind.config.ts already exists"
fi

# =============================================================================
# POSTCSS CONFIGURATION
# =============================================================================

log_step "Creating PostCSS configuration"

if [[ ! -f "postcss.config.mjs" ]]; then
    cat > postcss.config.mjs <<'EOF'
/** @type {import('postcss-load-config').Config} */
const config = {
  plugins: {
    "@tailwindcss/postcss": {},
    autoprefixer: {},
  },
};

export default config;
EOF
log_ok "Created postcss.config.mjs"
else
    log_skip "postcss.config.mjs already exists"
fi

# =============================================================================
# APP ROUTER SAFETY PAGES
# =============================================================================

log_step "Creating App Router safety pages (error/not-found) and 404 fallback"

# Ensure app directory exists
mkdir -p src/app
mkdir -p pages

if [[ ! -f "src/app/error.tsx" ]]; then
    cat > src/app/error.tsx <<'EOF'
"use client";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export default function GlobalError({ error }: { error: Error }) {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-3xl font-semibold">Something went wrong</h1>
      <p className="text-muted-foreground">{error.message || "Unexpected error"}</p>
    </main>
  );
}
EOF
    log_ok "Created src/app/error.tsx"
else
    log_skip "src/app/error.tsx already exists"
fi

if [[ ! -f "src/app/not-found.tsx" ]]; then
    cat > src/app/not-found.tsx <<'EOF'
"use client";

export const dynamic = "force-dynamic";
export const runtime = "nodejs";

export default function NotFound() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-3xl font-semibold">Page not found</h1>
      <p className="text-muted-foreground">The page you are looking for does not exist.</p>
    </main>
  );
}
EOF
    log_ok "Created src/app/not-found.tsx"
else
    log_skip "src/app/not-found.tsx already exists"
fi

if [[ ! -f "pages/404.tsx" ]]; then
    cat > pages/404.tsx <<'EOF'
export const runtime = 'nodejs';
export const dynamic = 'force-dynamic';

export default function Custom404() {
  return (
    <main className="flex min-h-screen flex-col items-center justify-center gap-4 p-8">
      <h1 className="text-3xl font-semibold">404 - Page Not Found</h1>
      <p className="text-muted-foreground">This page does not exist.</p>
    </main>
  );
}
EOF
    log_ok "Created pages/404.tsx"
else
    log_skip "pages/404.tsx already exists"
fi

if [[ ! -f "pages/_document.tsx" ]]; then
    cat > pages/_document.tsx <<'EOF'
import { Html, Head, Main, NextScript } from "next/document";

export default function Document() {
  return (
    <Html lang="en">
      <Head />
      <body>
        <Main />
        <NextScript />
      </body>
    </Html>
  );
}
EOF
    log_ok "Created pages/_document.tsx"
else
    log_skip "pages/_document.tsx already exists"
fi

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

log_step "Creating utility functions"

mkdir -p src/lib

if [[ ! -f "src/lib/utils.ts" ]]; then
    cat > src/lib/utils.ts <<'EOF'
/**
 * Utility functions for class name management
 * Used by shadcn/ui components
 */

import { type ClassValue, clsx } from 'clsx';
import { twMerge } from 'tailwind-merge';

/**
 * Merge class names with Tailwind CSS conflict resolution
 * Combines clsx for conditional classes with tailwind-merge for deduplication
 *
 * @example
 * cn('px-2 py-1', 'px-4') // => 'py-1 px-4'
 * cn('text-red-500', condition && 'text-blue-500')
 */
export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
EOF
    log_ok "Created src/lib/utils.ts"
else
    log_skip "src/lib/utils.ts already exists"
fi

# =============================================================================
# SHADCN CLI CONFIGURATION
# =============================================================================

log_step "Creating shadcn/ui configuration"

if [[ ! -f "components.json" ]]; then
    cat > components.json <<'EOF'
{
  "$schema": "https://ui.shadcn.com/schema.json",
  "style": "default",
  "rsc": true,
  "tsx": true,
  "tailwind": {
    "config": "tailwind.config.ts",
    "css": "src/app/globals.css",
    "baseColor": "slate",
    "cssVariables": true,
    "prefix": ""
  },
  "aliases": {
    "components": "@/components",
    "utils": "@/lib/utils",
    "ui": "@/components/ui",
    "lib": "@/lib",
    "hooks": "@/hooks"
  }
}
EOF
    log_ok "Created components.json"
else
    log_skip "components.json already exists"
fi

# =============================================================================
# UPDATE GLOBALS.CSS
# =============================================================================

log_step "Updating globals.css with Tailwind directives"

GLOBALS_CSS="src/app/globals.css"

if [[ -f "$GLOBALS_CSS" ]]; then
    # Check if Tailwind directives are already present
    if ! grep -q "@tailwind base" "$GLOBALS_CSS"; then
        log_warn "globals.css exists but missing Tailwind directives, updating..."
        # Backup existing file
        cp "$GLOBALS_CSS" "${GLOBALS_CSS}.bak"
    fi
fi

# Create/overwrite globals.css with full shadcn/ui theme
mkdir -p src/app
cat > "$GLOBALS_CSS" <<'EOF'
@config "../../tailwind.config.ts";

@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96.1%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96.1%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96.1%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}

@layer base {
  * {
    @apply border-border;
  }
  body {
    @apply bg-background text-foreground;
  }
}
EOF
log_ok "Updated src/app/globals.css with shadcn theme"

# =============================================================================
# CREATE COMPONENTS DIRECTORY
# =============================================================================

log_step "Creating components directory structure"

mkdir -p src/components/ui
mkdir -p src/hooks

# Create a placeholder for UI components
if [[ ! -f "src/components/ui/.gitkeep" ]]; then
    touch src/components/ui/.gitkeep
    log_ok "Created src/components/ui directory"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"