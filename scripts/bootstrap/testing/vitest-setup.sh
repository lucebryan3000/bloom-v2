#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="testing/vitest-setup.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Setup Vitest"; exit 0; }

    if [[ "${ENABLE_TEST_INFRA:-true}" != "true" ]]; then
        log_info "SKIP: Test infrastructure disabled via ENABLE_TEST_INFRA"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Setting up Vitest ==="
    cd "${PROJECT_ROOT:-.}"

    add_dependency "vitest" "true"
    add_dependency "@vitejs/plugin-react" "true"
    add_dependency "@testing-library/react" "true"
    add_dependency "@testing-library/jest-dom" "true"
    add_dependency "jsdom" "true"

    local vitest_config='import { defineConfig } from "vitest/config";
import react from "@vitejs/plugin-react";
import path from "path";

export default defineConfig({
  plugins: [react()],
  test: {
    environment: "jsdom",
    globals: true,
    setupFiles: ["./src/test/setup.ts"],
    include: ["src/**/*.{test,spec}.{ts,tsx}"],
    exclude: ["node_modules", ".next", "e2e"],
    coverage: {
      provider: "v8",
      reporter: ["text", "json", "html"],
      exclude: [
        "node_modules",
        "src/test",
        "**/*.d.ts",
        "**/*.config.*",
        "**/types/*",
      ],
    },
  },
  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
'
    write_file_if_missing "vitest.config.ts" "${vitest_config}"

    ensure_dir "src/test"

    local setup_file='import "@testing-library/jest-dom";

// Mock Next.js router
vi.mock("next/navigation", () => ({
  useRouter: () => ({
    push: vi.fn(),
    replace: vi.fn(),
    prefetch: vi.fn(),
    back: vi.fn(),
  }),
  usePathname: () => "/",
  useSearchParams: () => new URLSearchParams(),
}));

// Mock environment variables for tests
process.env.NODE_ENV = "test";

// Clean up after each test
afterEach(() => {
  vi.clearAllMocks();
});
'
    write_file_if_missing "src/test/setup.ts" "${setup_file}"

    local test_utils='import { render, type RenderOptions } from "@testing-library/react";
import { type ReactElement } from "react";

interface WrapperProps {
  children: React.ReactNode;
}

function AllProviders({ children }: WrapperProps) {
  return <>{children}</>;
}

const customRender = (
  ui: ReactElement,
  options?: Omit<RenderOptions, "wrapper">
) => render(ui, { wrapper: AllProviders, ...options });

export * from "@testing-library/react";
export { customRender as render };
'
    write_file_if_missing "src/test/utils.tsx" "${test_utils}"

    add_npm_script "test" "vitest"
    add_npm_script "test:run" "vitest run"
    add_npm_script "test:coverage" "vitest run --coverage"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Vitest setup complete"
}

main "$@"
