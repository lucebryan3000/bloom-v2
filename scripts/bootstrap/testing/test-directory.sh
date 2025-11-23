#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMON_SH="${SCRIPT_DIR%/*}/lib/common.sh"
[[ -f "${COMMON_SH}" ]] || { echo "ERROR: common.sh not found" >&2; exit 1; }
. "${COMMON_SH}"

SCRIPT_KEY="testing/test-directory.sh"

main() {
    parse_common_args "$@"
    [[ "${SHOW_HELP}" == "true" ]] && { echo "Create test directory structure"; exit 0; }

    if [[ "${ENABLE_TEST_INFRA:-true}" != "true" ]]; then
        log_info "SKIP: Test infrastructure disabled via ENABLE_TEST_INFRA"
        mark_script_success "${SCRIPT_KEY}"
        return 0
    fi

    log_info "=== Creating Test Directory Structure ==="
    cd "${PROJECT_ROOT:-.}"

    ensure_dir "src/test"
    ensure_dir "src/test/mocks"
    ensure_dir "src/test/fixtures"
    ensure_dir "e2e"

    local mock_db='import { vi } from "vitest";

export const mockDb = {
  select: vi.fn().mockReturnThis(),
  from: vi.fn().mockReturnThis(),
  where: vi.fn().mockReturnThis(),
  limit: vi.fn().mockReturnThis(),
  orderBy: vi.fn().mockReturnThis(),
  insert: vi.fn().mockReturnThis(),
  values: vi.fn().mockReturnThis(),
  returning: vi.fn().mockResolvedValue([]),
  update: vi.fn().mockReturnThis(),
  set: vi.fn().mockReturnThis(),
  delete: vi.fn().mockReturnThis(),
};

export const mockTransaction = vi.fn((callback) => callback(mockDb));

vi.mock("@/db", () => ({
  db: mockDb,
}));
'
    write_file_if_missing "src/test/mocks/db.ts" "${mock_db}"

    local mock_auth='import { vi } from "vitest";

export const mockSession = {
  user: {
    id: "test-user-id",
    email: "test@example.com",
    name: "Test User",
  },
  expires: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
};

export const mockAuth = vi.fn().mockResolvedValue(mockSession);

vi.mock("@/lib/auth/config", () => ({
  auth: mockAuth,
  signIn: vi.fn(),
  signOut: vi.fn(),
}));
'
    write_file_if_missing "src/test/mocks/auth.ts" "${mock_auth}"

    local fixtures_users='export const testUsers = {
  admin: {
    id: "admin-id",
    email: "admin@example.com",
    name: "Admin User",
    role: "admin",
  },
  member: {
    id: "member-id",
    email: "member@example.com",
    name: "Member User",
    role: "member",
  },
  guest: {
    id: "guest-id",
    email: "guest@example.com",
    name: "Guest User",
    role: "guest",
  },
} as const;

export type TestUser = (typeof testUsers)[keyof typeof testUsers];
'
    write_file_if_missing "src/test/fixtures/users.ts" "${fixtures_users}"

    local mocks_index='export * from "./db";
export * from "./auth";
'
    write_file_if_missing "src/test/mocks/index.ts" "${mocks_index}"

    local fixtures_index='export * from "./users";
'
    write_file_if_missing "src/test/fixtures/index.ts" "${fixtures_index}"

    local example_unit_test='import { describe, it, expect, vi } from "vitest";
import { render, screen } from "@/test/utils";

// Example component for testing
function ExampleButton({ onClick, children }: { onClick: () => void; children: React.ReactNode }) {
  return <button onClick={onClick}>{children}</button>;
}

describe("ExampleButton", () => {
  it("renders children correctly", () => {
    render(<ExampleButton onClick={() => {}}>Click me</ExampleButton>);
    expect(screen.getByText("Click me")).toBeInTheDocument();
  });

  it("calls onClick when clicked", async () => {
    const handleClick = vi.fn();
    render(<ExampleButton onClick={handleClick}>Click me</ExampleButton>);

    const button = screen.getByText("Click me");
    button.click();

    expect(handleClick).toHaveBeenCalledTimes(1);
  });
});
'
    write_file_if_missing "src/test/example.test.tsx" "${example_unit_test}"

    mark_script_success "${SCRIPT_KEY}"
    log_success "Test directory structure created"
}

main "$@"
