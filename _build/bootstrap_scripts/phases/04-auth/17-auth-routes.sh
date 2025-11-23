#!/usr/bin/env bash
# =============================================================================
# File: phases/04-auth/17-auth-routes.sh
# Purpose: Generate /app/(auth) routes for login/logout
# Assumes: Auth.js configured
# Creates: src/app/(auth)/login/page.tsx and related files
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="17"
readonly SCRIPT_NAME="auth-routes"
readonly SCRIPT_DESCRIPTION="Generate authentication routes and pages"

# =============================================================================
# USAGE
# =============================================================================
usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

$SCRIPT_DESCRIPTION

OPTIONS:
    -h, --help      Show this help message and exit
    -n, --dry-run   Show what would be done without making changes
    -v, --verbose   Enable verbose output

EXAMPLES:
    $(basename "$0")              # Create auth routes
    $(basename "$0") --dry-run    # Preview changes

WHAT THIS SCRIPT DOES:
    1. Creates (auth) route group with layout
    2. Creates login page with credentials form
    3. Creates logout action
    4. Adds basic styling for auth pages

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting auth routes creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"

    # Step 2: Create auth layout
    log_step "Creating auth layout"

    ensure_dir "src/app/(auth)"

    local auth_layout='import type { Metadata } from "next";

export const metadata: Metadata = {
  title: "Authentication - Bloom2",
  description: "Sign in to Bloom2",
};

/**
 * Auth Layout
 *
 * Minimal layout for authentication pages.
 * No navigation, centered content.
 */
export default function AuthLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-50 dark:bg-gray-900 px-4 py-12">
      <div className="w-full max-w-md">
        {/* Logo */}
        <div className="text-center mb-8">
          <h1 className="text-3xl font-bold text-gray-900 dark:text-white">
            Bloom2
          </h1>
          <p className="mt-2 text-sm text-gray-600 dark:text-gray-400">
            ROI Workshop Platform
          </p>
        </div>

        {/* Auth Card */}
        <div className="bg-white dark:bg-gray-800 shadow-lg rounded-lg p-8">
          {children}
        </div>
      </div>
    </div>
  );
}
'

    write_file "src/app/(auth)/layout.tsx" "$auth_layout"

    # Step 3: Create login page
    log_step "Creating login page"

    ensure_dir "src/app/(auth)/login"

    local login_page='import { Metadata } from "next";
import { LoginForm } from "./login-form";

export const metadata: Metadata = {
  title: "Sign In - Bloom2",
};

/**
 * Login Page
 *
 * Server Component wrapper for the login form.
 */
export default function LoginPage({
  searchParams,
}: {
  searchParams: { error?: string; callbackUrl?: string };
}) {
  return (
    <>
      <h2 className="text-2xl font-semibold text-center text-gray-900 dark:text-white mb-6">
        Sign in to your account
      </h2>

      {searchParams.error && (
        <div className="mb-4 p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-md text-sm">
          {searchParams.error === "CredentialsSignin"
            ? "Invalid email or password"
            : "An error occurred. Please try again."}
        </div>
      )}

      <LoginForm callbackUrl={searchParams.callbackUrl} />
    </>
  );
}
'

    write_file "src/app/(auth)/login/page.tsx" "$login_page"

    # Step 4: Create login form component
    log_step "Creating login form component"

    local login_form='"use client";

import { useState } from "react";
import { signIn } from "next-auth/react";
import { useRouter } from "next/navigation";

interface LoginFormProps {
  callbackUrl?: string;
}

/**
 * Login Form Component
 *
 * Client component for handling credentials login.
 */
export function LoginForm({ callbackUrl = "/workspace" }: LoginFormProps) {
  const router = useRouter();
  const [isLoading, setIsLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  async function handleSubmit(e: React.FormEvent<HTMLFormElement>) {
    e.preventDefault();
    setIsLoading(true);
    setError(null);

    const formData = new FormData(e.currentTarget);

    try {
      const result = await signIn("credentials", {
        email: formData.get("email") as string,
        password: formData.get("password") as string,
        redirect: false,
      });

      if (result?.error) {
        setError("Invalid email or password");
        setIsLoading(false);
        return;
      }

      router.push(callbackUrl);
      router.refresh();
    } catch {
      setError("An unexpected error occurred");
      setIsLoading(false);
    }
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-6">
      {error && (
        <div className="p-4 bg-red-50 dark:bg-red-900/20 text-red-600 dark:text-red-400 rounded-md text-sm">
          {error}
        </div>
      )}

      <div>
        <label
          htmlFor="email"
          className="block text-sm font-medium text-gray-700 dark:text-gray-300"
        >
          Email address
        </label>
        <input
          id="email"
          name="email"
          type="email"
          autoComplete="email"
          required
          disabled={isLoading}
          className="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:text-white disabled:opacity-50"
          placeholder="you@example.com"
        />
      </div>

      <div>
        <label
          htmlFor="password"
          className="block text-sm font-medium text-gray-700 dark:text-gray-300"
        >
          Password
        </label>
        <input
          id="password"
          name="password"
          type="password"
          autoComplete="current-password"
          required
          disabled={isLoading}
          minLength={8}
          className="mt-1 block w-full rounded-md border border-gray-300 dark:border-gray-600 px-3 py-2 shadow-sm focus:border-blue-500 focus:outline-none focus:ring-1 focus:ring-blue-500 dark:bg-gray-700 dark:text-white disabled:opacity-50"
          placeholder="••••••••"
        />
      </div>

      <div className="flex items-center justify-between">
        <div className="flex items-center">
          <input
            id="remember"
            name="remember"
            type="checkbox"
            className="h-4 w-4 rounded border-gray-300 text-blue-600 focus:ring-blue-500"
          />
          <label
            htmlFor="remember"
            className="ml-2 block text-sm text-gray-700 dark:text-gray-300"
          >
            Remember me
          </label>
        </div>

        <a
          href="#"
          className="text-sm font-medium text-blue-600 hover:text-blue-500 dark:text-blue-400"
        >
          Forgot password?
        </a>
      </div>

      <button
        type="submit"
        disabled={isLoading}
        className="w-full flex justify-center py-2 px-4 border border-transparent rounded-md shadow-sm text-sm font-medium text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
      >
        {isLoading ? (
          <>
            <svg
              className="animate-spin -ml-1 mr-2 h-4 w-4 text-white"
              fill="none"
              viewBox="0 0 24 24"
            >
              <circle
                className="opacity-25"
                cx="12"
                cy="12"
                r="10"
                stroke="currentColor"
                strokeWidth="4"
              />
              <path
                className="opacity-75"
                fill="currentColor"
                d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"
              />
            </svg>
            Signing in...
          </>
        ) : (
          "Sign in"
        )}
      </button>
    </form>
  );
}
'

    write_file "src/app/(auth)/login/login-form.tsx" "$login_form"

    # Step 5: Create logout action
    log_step "Creating logout action"

    local logout_action='"use server";

import { signOut } from "@/auth";

/**
 * Logout Server Action
 *
 * Signs out the user and redirects to home.
 */
export async function logout() {
  await signOut({ redirectTo: "/" });
}
'

    write_file "src/app/(auth)/logout/actions.ts" "$logout_action"

    ensure_dir "src/app/(auth)/logout"

    local logout_page='import { redirect } from "next/navigation";
import { logout } from "./actions";

/**
 * Logout Page
 *
 * Immediately triggers logout and redirects.
 * Can also be used as an action from a button.
 */
export default async function LogoutPage() {
  await logout();
  redirect("/");
}
'

    write_file "src/app/(auth)/logout/page.tsx" "$logout_page"

    # Step 6: Create user button component
    log_step "Creating user button component"

    ensure_dir "src/components/auth"

    local user_button='"use client";

import { signOut, useSession } from "next-auth/react";
import Link from "next/link";
import { useState } from "react";

/**
 * User Button Component
 *
 * Displays current user with dropdown menu for account actions.
 */
export function UserButton() {
  const { data: session, status } = useSession();
  const [isOpen, setIsOpen] = useState(false);

  if (status === "loading") {
    return (
      <div className="h-8 w-8 rounded-full bg-gray-200 dark:bg-gray-700 animate-pulse" />
    );
  }

  if (!session?.user) {
    return (
      <Link
        href="/login"
        className="text-sm font-medium text-gray-700 dark:text-gray-300 hover:text-gray-900 dark:hover:text-white"
      >
        Sign in
      </Link>
    );
  }

  const initials = session.user.name
    ?.split(" ")
    .map((n) => n[0])
    .join("")
    .toUpperCase()
    .slice(0, 2) || session.user.email?.[0].toUpperCase() || "?";

  return (
    <div className="relative">
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="flex items-center gap-2 rounded-full focus:outline-none focus:ring-2 focus:ring-blue-500"
      >
        {session.user.image ? (
          <img
            src={session.user.image}
            alt={session.user.name || "User"}
            className="h-8 w-8 rounded-full"
          />
        ) : (
          <div className="h-8 w-8 rounded-full bg-blue-600 flex items-center justify-center text-white text-sm font-medium">
            {initials}
          </div>
        )}
      </button>

      {isOpen && (
        <>
          {/* Backdrop */}
          <div
            className="fixed inset-0 z-10"
            onClick={() => setIsOpen(false)}
          />

          {/* Dropdown */}
          <div className="absolute right-0 mt-2 w-48 bg-white dark:bg-gray-800 rounded-md shadow-lg ring-1 ring-black ring-opacity-5 z-20">
            <div className="p-3 border-b border-gray-100 dark:border-gray-700">
              <p className="text-sm font-medium text-gray-900 dark:text-white truncate">
                {session.user.name || "User"}
              </p>
              <p className="text-xs text-gray-500 dark:text-gray-400 truncate">
                {session.user.email}
              </p>
            </div>

            <div className="py-1">
              <Link
                href="/settings"
                className="block px-4 py-2 text-sm text-gray-700 dark:text-gray-300 hover:bg-gray-100 dark:hover:bg-gray-700"
                onClick={() => setIsOpen(false)}
              >
                Settings
              </Link>
              <button
                onClick={() => signOut({ callbackUrl: "/" })}
                className="w-full text-left px-4 py-2 text-sm text-red-600 dark:text-red-400 hover:bg-gray-100 dark:hover:bg-gray-700"
              >
                Sign out
              </button>
            </div>
          </div>
        </>
      )}
    </div>
  );
}
'

    write_file "src/components/auth/user-button.tsx" "$user_button"

    # Step 7: Create session provider
    log_step "Creating session provider"

    local session_provider='"use client";

import { SessionProvider as NextAuthSessionProvider } from "next-auth/react";

/**
 * Session Provider
 *
 * Wraps the app to provide session context to client components.
 * Add this to your root layout.
 */
export function SessionProvider({ children }: { children: React.ReactNode }) {
  return <NextAuthSessionProvider>{children}</NextAuthSessionProvider>;
}
'

    write_file "src/components/auth/session-provider.tsx" "$session_provider"

    # Export from components/auth/index.ts
    local auth_index='export { UserButton } from "./user-button";
export { SessionProvider } from "./session-provider";
'

    write_file "src/components/auth/index.ts" "$auth_index"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
