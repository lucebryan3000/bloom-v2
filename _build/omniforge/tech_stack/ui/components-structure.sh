#!/usr/bin/env bash
#!meta
# id: ui/components-structure.sh
# name: components structure
# phase: 3
# phase_name: User Interface
# profile_tags:
#   - tech_stack
#   - ui
# uses_from_omni_config:
#   - ENABLE_SHADCN
# uses_from_omni_settings:
#   - PROJECT_ROOT
#   - INSTALL_DIR
# top_flags:
# dependencies:
#   packages:
#     - lucide-react
#     - clsx
#     - tailwind-merge
#     - class-variance-authority
#     - react-to-print
#   dev_packages:
#     - tailwindcss
#     - postcss
#     - autoprefixer
#!endmeta

# =============================================================================
# tech_stack/ui/components-structure.sh - Component Directory Structure
# =============================================================================
# Part of OmniForge - Infinite Architectures. Instant Foundation.
#
# Phase: 3 (User Interface)
# Purpose: Creates organized component directory structure with barrel exports
# =============================================================================
#
# Dependencies:
#   - none
#

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/../../lib/common.sh"
if command -v parse_stack_flags >/dev/null 2>&1; then
    parse_stack_flags "$@"
fi

readonly SCRIPT_ID="ui/components-structure"
readonly SCRIPT_NAME="Component Directory Structure"

if [[ "${DRY_RUN:-false}" == "true" ]]; then
    log_skip "DRY_RUN: skipping ${SCRIPT_NAME}"
    exit 0
fi

# Check if already completed
if has_script_succeeded "${SCRIPT_ID}"; then
    log_skip "${SCRIPT_NAME} (already completed)"
    exit 0
fi

log_step "${SCRIPT_NAME}"

: "${PROJECT_ROOT:?PROJECT_ROOT not set}"
cd "$INSTALL_DIR"

# =============================================================================
# CREATE DIRECTORY STRUCTURE
# =============================================================================

log_step "Creating component directories"

# Create all component directories
mkdir -p src/components/ui
mkdir -p src/components/common
mkdir -p src/components/forms
mkdir -p src/components/layout

log_ok "Created component directories"

# =============================================================================
# CREATE BARREL EXPORTS (index.ts files)
# =============================================================================

log_step "Creating barrel export files"

# src/components/ui/index.ts - shadcn components
if [[ ! -f "src/components/ui/index.ts" ]]; then
    cat > src/components/ui/index.ts <<'EOF'
/**
 * UI Components (shadcn/ui)
 *
 * This directory contains shadcn/ui components.
 * Add components using: pnpm dlx shadcn@latest add <component>
 *
 * @example
 * import { Button, Card, Input } from '@/components/ui';
 */

// Export shadcn components as they are added
// Example: export { Button } from './button';
// Example: export { Card, CardHeader, CardContent } from './card';

// Placeholder export to keep this a valid module until components are added.
export {};
EOF
    log_ok "Created src/components/ui/index.ts"
else
    log_skip "src/components/ui/index.ts already exists"
fi

# src/components/common/index.ts - shared components
if [[ ! -f "src/components/common/index.ts" ]]; then
    cat > src/components/common/index.ts <<'EOF'
/**
 * Common/Shared Components
 *
 * Reusable components used across multiple features.
 * Examples: Logo, Avatar, Badge, Spinner, EmptyState
 *
 * @example
 * import { Logo, Spinner, EmptyState } from '@/components/common';
 */

// Export common components as they are created
// Example: export { Logo } from './Logo';
// Example: export { Spinner } from './Spinner';
// Example: export { EmptyState } from './EmptyState';

// Placeholder export to keep this a valid module until components are added.
export {};
EOF
    log_ok "Created src/components/common/index.ts"
else
    log_skip "src/components/common/index.ts already exists"
fi

# src/components/forms/index.ts - form components
if [[ ! -f "src/components/forms/index.ts" ]]; then
    cat > src/components/forms/index.ts <<'EOF'
/**
 * Form Components
 *
 * Form-specific components including form fields, validation displays,
 * and form wrappers. Typically used with react-hook-form and zod.
 *
 * @example
 * import { FormField, FormError, SubmitButton } from '@/components/forms';
 */

// Export form components as they are created
// Example: export { FormField } from './FormField';
// Example: export { FormError } from './FormError';
// Example: export { SubmitButton } from './SubmitButton';

// Placeholder export to keep this a valid module until components are added.
export {};
EOF
    log_ok "Created src/components/forms/index.ts"
else
    log_skip "src/components/forms/index.ts already exists"
fi

# src/components/layout/index.ts - layout components
if [[ ! -f "src/components/layout/index.ts" ]]; then
    cat > src/components/layout/index.ts <<'EOF'
/**
 * Layout Components
 *
 * Structural layout components for page organization.
 * Examples: Header, Footer, Sidebar, Navigation, Container
 *
 * @example
 * import { Header, Sidebar, PageContainer } from '@/components/layout';
 */

// Export layout components as they are created
// Example: export { Header } from './Header';
// Example: export { Sidebar } from './Sidebar';
// Example: export { PageContainer } from './PageContainer';
EOF
    log_ok "Created src/components/layout/index.ts"
else
    log_skip "src/components/layout/index.ts already exists"
fi

# src/components/index.ts - root barrel export
if [[ ! -f "src/components/index.ts" ]]; then
    cat > src/components/index.ts <<'EOF'
/**
 * Components Root Export
 *
 * Re-exports all component categories for convenient imports.
 * Prefer importing from specific directories for tree-shaking.
 *
 * @example
 * // Preferred: import from specific directory
 * import { Button } from '@/components/ui';
 *
 * // Alternative: import from root (may affect tree-shaking)
 * import { Button } from '@/components';
 */

export * from './ui';
export * from './common';
export * from './forms';
export * from './layout';
EOF
    log_ok "Created src/components/index.ts"
else
    log_skip "src/components/index.ts already exists"
fi

# =============================================================================
# MARK SUCCESS
# =============================================================================

mark_script_success "${SCRIPT_ID}"
log_ok "${SCRIPT_NAME} complete"