#!/usr/bin/env bash
# =============================================================================
# File: phases/03-security/15-server-action-template.sh
# Purpose: Provide a canonical template for Server Actions with Zod + rate limiting
# Assumes: Zod schemas and rate limiter exist
# Creates: src/lib/serverActionTemplate.ts with example pattern
# =============================================================================

set -euo pipefail
IFS=$'\n\t'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../lib/common.sh"

# =============================================================================
# METADATA
# =============================================================================
readonly SCRIPT_ID="15"
readonly SCRIPT_NAME="server-action-template"
readonly SCRIPT_DESCRIPTION="Create Server Action template with Zod validation"

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
    $(basename "$0")              # Create template
    $(basename "$0") --dry-run    # Preview content

WHAT THIS SCRIPT DOES:
    1. Creates src/lib/action.ts with action wrapper utility
    2. Provides type-safe Server Action pattern
    3. Includes Zod validation, rate limiting, error handling
    4. Creates example action in src/features/example

EOF
}

# =============================================================================
# MAIN LOGIC
# =============================================================================
main() {
    parse_common_args "$@"
    init_logging "$SCRIPT_NAME"

    log_step "Starting Server Action template creation"

    # Step 1: Check prerequisites
    log_step "Checking prerequisites"
    require_file "package.json" "Initialize project first"
    ensure_dir "src/lib"

    # Step 2: Create action utility
    log_step "Creating src/lib/action.ts"

    local action_util='"use server";

import { z, ZodSchema } from "zod";
import type { RateLimitResult } from "./rateLimiter";
import { rateLimit } from "./rateLimiter";

/**
 * Server Action Result Type
 *
 * All Server Actions return this consistent shape for
 * predictable client-side handling.
 */
export type ActionResult<T> =
  | { success: true; data: T }
  | { success: false; error: ActionError };

/**
 * Action Error Structure
 */
export interface ActionError {
  code: string;
  message: string;
  fieldErrors?: Record<string, string[]>;
  rateLimit?: RateLimitResult;
}

/**
 * Action Configuration
 */
interface ActionConfig<TInput, TOutput> {
  /** Zod schema for input validation */
  schema: ZodSchema<TInput>;

  /** Rate limiter configuration (optional) */
  rateLimit?: {
    /** Requests per interval */
    limit: number;
    /** Interval in milliseconds */
    interval: number;
    /** Namespace for this action */
    namespace: string;
  };

  /** Get user identifier for rate limiting */
  getIdentifier?: () => Promise<string>;

  /** The action handler function */
  handler: (input: TInput) => Promise<TOutput>;
}

/**
 * Create a type-safe Server Action with validation and rate limiting
 *
 * @example
 * ```ts
 * export const createProject = createAction({
 *   schema: CreateProjectSchema,
 *   rateLimit: { limit: 5, interval: 60000, namespace: "create_project" },
 *   handler: async (input) => {
 *     const project = await db.insert(projects).values(input);
 *     return project;
 *   },
 * });
 * ```
 */
export function createAction<TInput, TOutput>(
  config: ActionConfig<TInput, TOutput>
) {
  return async (rawInput: unknown): Promise<ActionResult<TOutput>> => {
    try {
      // Step 1: Validate input with Zod
      const parseResult = config.schema.safeParse(rawInput);

      if (!parseResult.success) {
        return {
          success: false,
          error: {
            code: "VALIDATION_ERROR",
            message: "Invalid input",
            fieldErrors: parseResult.error.flatten().fieldErrors as Record<
              string,
              string[]
            >,
          },
        };
      }

      const input = parseResult.data;

      // Step 2: Check rate limit (if configured)
      if (config.rateLimit) {
        const limiter = rateLimit({
          limit: config.rateLimit.limit,
          interval: config.rateLimit.interval,
          namespace: config.rateLimit.namespace,
        });

        const identifier = config.getIdentifier
          ? await config.getIdentifier()
          : "anonymous";

        const rateLimitResult = await limiter.check(identifier);

        if (!rateLimitResult.success) {
          return {
            success: false,
            error: {
              code: "RATE_LIMITED",
              message: `Too many requests. Please try again in ${Math.ceil(
                rateLimitResult.resetIn / 1000
              )} seconds.`,
              rateLimit: rateLimitResult,
            },
          };
        }
      }

      // Step 3: Execute handler
      const data = await config.handler(input);

      return {
        success: true,
        data,
      };
    } catch (error) {
      // Handle known errors
      if (error instanceof ActionError) {
        return {
          success: false,
          error: {
            code: error.code,
            message: error.message,
          },
        };
      }

      // Log unexpected errors
      console.error("Action error:", error);

      return {
        success: false,
        error: {
          code: "INTERNAL_ERROR",
          message: "An unexpected error occurred. Please try again.",
        },
      };
    }
  };
}

/**
 * Custom error class for action errors
 */
export class ActionError extends Error {
  constructor(
    public code: string,
    message: string
  ) {
    super(message);
    this.name = "ActionError";
  }
}

/**
 * Optimistic locking error
 */
export class ConcurrencyError extends ActionError {
  constructor(message = "This record was modified by another user. Please refresh and try again.") {
    super("CONCURRENCY_ERROR", message);
  }
}

/**
 * Not found error
 */
export class NotFoundError extends ActionError {
  constructor(resource: string) {
    super("NOT_FOUND", `${resource} not found`);
  }
}

/**
 * Authorization error
 */
export class UnauthorizedError extends ActionError {
  constructor(message = "You are not authorized to perform this action") {
    super("UNAUTHORIZED", message);
  }
}
'

    write_file "src/lib/action.ts" "$action_util"

    # Step 3: Create example action
    log_step "Creating example action"

    ensure_dir "src/features/example"

    local example_action='"use server";

import { z } from "zod";
import { createAction, NotFoundError } from "@/lib/action";

/**
 * Example: Greeting action
 *
 * Demonstrates the Server Action pattern with:
 * - Zod validation
 * - Rate limiting
 * - Error handling
 * - Type-safe return
 */

// Input schema
const GreetingSchema = z.object({
  name: z.string().min(1, "Name is required").max(100),
  language: z.enum(["en", "es", "fr"]).default("en"),
});

// Output type
interface GreetingResult {
  message: string;
  timestamp: string;
}

// Action implementation
export const greet = createAction({
  schema: GreetingSchema,

  // Rate limit: 10 greetings per minute
  rateLimit: {
    limit: 10,
    interval: 60 * 1000,
    namespace: "greeting",
  },

  // Handler
  handler: async (input): Promise<GreetingResult> => {
    const greetings = {
      en: `Hello, ${input.name}!`,
      es: `¡Hola, ${input.name}!`,
      fr: `Bonjour, ${input.name}!`,
    };

    return {
      message: greetings[input.language],
      timestamp: new Date().toISOString(),
    };
  },
});

/**
 * Example usage in a component:
 *
 * ```tsx
 * "use client";
 *
 * import { greet } from "@/features/example/actions";
 *
 * export function GreetingForm() {
 *   const [result, setResult] = useState<string>("");
 *
 *   async function handleSubmit(formData: FormData) {
 *     const response = await greet({
 *       name: formData.get("name"),
 *       language: "en",
 *     });
 *
 *     if (response.success) {
 *       setResult(response.data.message);
 *     } else {
 *       setResult(`Error: ${response.error.message}`);
 *     }
 *   }
 *
 *   return (
 *     <form action={handleSubmit}>
 *       <input name="name" placeholder="Your name" />
 *       <button type="submit">Greet</button>
 *       <p>{result}</p>
 *     </form>
 *   );
 * }
 * ```
 */
'

    write_file "src/features/example/actions.ts" "$example_action"

    log_success "Script $SCRIPT_ID completed"
}

main "$@"
