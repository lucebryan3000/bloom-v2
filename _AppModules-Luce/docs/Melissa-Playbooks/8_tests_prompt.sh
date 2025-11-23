#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

PROMPT_FILE="Claude-Tests-IFL-and-Compiler.md"

if [[ -f "${PROMPT_FILE}" ]]; then
  echo "${PROMPT_FILE} already exists, skipping."
  exit 0
fi

cat > "${PROMPT_FILE}" <<'EOF'
# Claude Code Prompt — Add Tests for IFL Engine, Prompt Builder, and Compiler

You are working in the `lucebryan3000/bloom` repository.

## Objective

Add a **basic but meaningful test suite** for the new Melissa/Bloom playbook architecture:

1. `lib/melissa/promptBuilder.ts`
2. `lib/melissa/iflEngine.ts`
3. `lib/melissa/playbookCompiler.ts` (stub implementation)

The goal is not exhaustive coverage yet, but a **solid safety net** so future refactors and LLM-assisted changes don't silently break core behavior.

## Assumptions

- The project already uses a testing framework (likely Jest or similar). Inspect `package.json` and existing `__tests__` folders and conform to the existing pattern.
- Prisma is configured for tests already with test databases as described in the architecture notes.
- You do NOT need to spin up an actual SQLite instance for every unit test if it's easier to:
  - Use plain objects for DTOs
  - Or lightly mock Prisma imports where appropriate

## Requirements

### 1. Tests for `promptBuilder.ts`

Create tests that:

- Verify `buildPrompt`:
  - Includes persona name/slug
  - Includes playbook name/slug/category
  - Includes the current phase and question text
  - Clearly instructs the LLM to ask only one question and wait for a response

Edge cases to cover:

- `ctx.currentPhase` is null (ensure it degrades gracefully)
- Question has no `type` or `options`

### 2. Tests for `iflEngine.ts`

Create tests for:

- `extractQuestions(playbook)`
  - Given a `PlaybookCompiled` mock with `questions` as an array, ensure proper mapping to `CompiledQuestion[]`.
  - Handles empty or malformed `questions` gracefully.

- `getNextQuestion(ctx, playbook)`
  - When `ctx.answers` is empty, returns the first question.
  - When some questions are answered, returns the next unanswered one.
  - When all questions are answered, returns `null`.

- `applyAnswer(ctx, questionId, answer)`
  - Returns a new `SessionContext` with the answer recorded.
  - Increments `totalQuestionsAsked`.

### 3. Tests for `playbookCompiler.ts`

Even with the stub, create tests that:

- Call `parseMarkdownToPlaybookDTO(source)` with a minimal `PlaybookSource` mock and assert:
  - DTO includes name, slug, category, version.
  - DTO has a `phaseMap` with all 5 phases defined (even if empty).
  - `compileInfo` contains at least a `notes` field and `sourceId`.

- Call `compilePlaybookSource(sourceId)` using an in-memory Prisma test DB or a simple mock and assert:
  - A `PlaybookCompiled` row is created.
  - `sourceId`, `slug`, `category` match.
  - `isActive` toggles correctly when `options.activate` is true.
  - `status` is `compiled_ok` by default.

## Implementation Notes

- Reuse any existing test utilities (e.g., test DB setup).
- Place tests under an appropriate directory (`__tests__/lib/melissa` or similar).
- Keep tests **fast and focused** — avoid full end-to-end runs for now.

## Deliverables

1. New test files exercising:
   - `promptBuilder.buildPrompt`
   - `iflEngine.extractQuestions`, `getNextQuestion`, `applyAnswer`
   - `playbookCompiler.parseMarkdownToPlaybookDTO`, `compilePlaybookSource`

2. `npm test` / `yarn test` passes.

3. A brief summary in a comment or dev log noting what was covered and any TODOs for deeper tests later.

EOF

echo "Claude Code tests prompt created at ${PROMPT_FILE}"
