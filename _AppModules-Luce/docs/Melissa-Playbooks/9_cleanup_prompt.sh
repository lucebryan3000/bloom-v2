#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

PROMPT_FILE="Claude-Cleanup-Prototype-Playbooks.md"

if [[ -f "${PROMPT_FILE}" ]]; then
  echo "${PROMPT_FILE} already exists, skipping."
  exit 0
fi

cat > "${PROMPT_FILE}" <<'EOF'
# Claude Code Prompt — Cleanup Prototype Playbook System and Dead Prompt Code

You are working in the `lucebryan3000/bloom` repository.

## Objective

Remove or refactor **prototype playbook-related code and schema** that is no longer needed after introducing:

- `MelissaPersona`
- `ChatProtocol`
- `PlaybookSource`
- `PlaybookCompiled`
- `lib/melissa/*` services, compiler, and session context

This is a **surgical cleanup** to reduce confusion and technical debt.

## High-Level Tasks

1. **Identify prototype Playbook tables and models** in `prisma/schema.prisma`:
   - Anything like: `Playbook`, `Run`, `RunStep`, `ToolCall`, `Artifact`, `TxLog` that are not part of the new architecture.
   - Confirm they are not referenced in current, production-worthy code paths (search repo).

2. **Prepare a migration** to:
   - Drop unused tables / relations safely.
   - Or clearly mark them as deprecated if they are still needed temporarily.

3. **Remove old prompt-concatenation logic** that bypasses the new engine:
   - In `api-melissa-chat-route.ts` or related API routes.
   - In `lib-melissa-agent.ts` or equivalent older agent files.
   - In `/app/settings/page.tsx` (or wherever legacy playbook prompts live).

4. **Ensure new architecture is used as the primary path**:
   - Chat route should load:
     - `MelissaPersona` (default or org-specific)
     - `ChatProtocol` (default or org-specific)
     - `PlaybookCompiled` (active for a given slug)
   - Uses:
     - `SessionContext`
     - `IFL engine`
     - `promptBuilder`

## Constraints

- This repo is effectively **single-user, prototype-friendly**, so:
  - You are allowed to perform **destructive cleanups** (no complex backwards compat needed).
  - Git history is the rollback mechanism.

- Do NOT:
  - Touch logging DB (`logs.db`) or log-related tables.
  - Change authentication, branding, or non-Melissa/Bloom functionality.

## Suggested Steps

1. **Schema cleanup**
   - Open `prisma/schema.prisma`.
   - Identify old Playbook-related models and comment them as `// DEPRECATED` temporarily.
   - Run `rg` (ripgrep) or equivalent across the repo to see where they're used.
   - If truly unused, remove them from the schema and create a migration to drop the tables.

2. **API route cleanup**
   - Inspect `api-melissa-chat-route.ts` (or equivalent).
   - Replace old prompt-building code with calls into:
     - `lib/melissa/personaService`
     - `lib/melissa/protocolService`
     - `lib/melissa/playbookService`
     - `lib/melissa/iflEngine`
     - `lib/melissa/promptBuilder`
   - Remove any leftover hard-coded multi-paragraph system prompts in favor of using Persona/Protocol/Playbook data.

3. **Settings cleanup**
   - Remove legacy “Playbooks” settings that are just static prompt blocks.
   - Ensure the Settings UI uses the new tabs / flows created by the other prompt (`Claude-Settings-Playbook-UI.md`).

4. **Validation**
   - Run migrations.
   - Run tests.
   - Manually verify:
     - Default session can be started.
     - A chosen playbook slug leads to:
       - Persona/Protocol/PlaybookCompiled lookup
       - Next question selection via IFL engine
       - Prompt constructed via promptBuilder

## Deliverables

- Updated `prisma/schema.prisma` and migration dropping prototype playbook tables.
- Cleaned-up API route(s) using the new engine.
- Removed or refactored legacy prompt code in Settings and old agent modules.
- All tests green.

EOF

echo "Claude Code cleanup prompt created at ${PROMPT_FILE}"
