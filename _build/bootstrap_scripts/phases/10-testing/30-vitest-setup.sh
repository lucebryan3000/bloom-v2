#!/usr/bin/env bash
# =============================================================================
# File: phases/10-testing/30-vitest-setup.sh
# Purpose: Install and configure Vitest for unit/integration tests
# Creates: vitest.config.ts, test scripts
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

readonly SCRIPT_ID="30"
readonly SCRIPT_NAME="vitest-setup"
readonly SCRIPT_DESCRIPTION="Install and configure Vitest"

usage() { cat <<EOF
Usage: $(basename "$0") [OPTIONS]
$SCRIPT_DESCRIPTION
EOF
}

main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Installing Vitest"
    require_pnpm
    add_dependency "vitest" "true"
    add_dependency "@vitejs/plugin-react" "true"
    add_dependency "@testing-library/react" "true"
    add_dependency "@testing-library/jest-dom" "true"
    add_dependency "jsdom" "true"

    log_step "Creating vitest.config.ts"

    local vitest_config='import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./tests/setup.ts"],
    include: ["tests/**/*.{test,spec}.{js,ts,tsx}"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      exclude: ["node_modules", "tests"],
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
'

    write_file "vitest.config.ts" "$vitest_config"

    log_step "Creating test setup file"
    ensure_dir "tests"

    local setup='import "@testing-library/jest-dom";

// Mock Next.js router
vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    prefetch: vi.fn(),
  }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));
'

    write_file "tests/setup.ts" "$setup"

    log_step "Adding test scripts"
    add_npm_script "test" "vitest"
    add_npm_script "test:run" "vitest run"
    add_npm_script "test:coverage" "vitest run --coverage"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
