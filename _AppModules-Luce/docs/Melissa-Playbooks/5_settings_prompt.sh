#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${ROOT_DIR}"

PROMPT_FILE="Claude-Settings-Playbook-UI.md"

if [[ -f "${PROMPT_FILE}" ]]; then
  echo "${PROMPT_FILE} already exists, skipping."
  exit 0
fi

cat > "${PROMPT_FILE}" <<'EOF'
# Claude Code Prompt — Wire Settings UI for Persona / Protocol / Playbooks

You are working in the `lucebryan3000/bloom` repository.

## Objective

Implement basic Settings UI panels so that:

1. **Persona Tab**
   - Lists available `MelissaPersona` records.
   - Shows which one is default.
   - For now, fields can be read-only (name, slug, baseTone, etc.) or minimally editable.

2. **Protocol / Rules Tab**
   - Lists available `ChatProtocol` records.
   - Shows which one is default.
   - Displays key engine fields (phases, maxQuestions, maxFollowups, driftSoftLimit, driftHardLimit, complianceMode, strictPhases).
   - Editing can be read-only or minimal for v1 (even just viewing is OK).

3. **Playbooks Tab**
   - Lists `PlaybookSource` rows (name, slug, category, status, version).
   - Clicking a row opens a basic Markdown editor bound to `PlaybookSource.markdown`.
   - Provides a "Compile" button that calls a backend API to run `compilePlaybookSource(sourceId, { activate: true })`.
   - After compilation, marks the new `PlaybookCompiled` as active.

## Constraints

- Do NOT redesign the entire Settings layout; add to existing Settings framework.
- Use existing design system / components where possible.
- Keep the implementation minimal but functional:
  - One route / page section per tab
  - Lightweight tables & forms
  - No advanced UX states yet

## Backend expectations

You can assume the following helpers exist (or create small wrappers for them):

- `lib/melissa/personaService.ts`
  - `getDefaultPersona()`
  - `getPersonaBySlug(slug)`

- `lib/melissa/protocolService.ts`
  - `getDefaultProtocol()`
  - `getProtocolBySlug(slug)`

- `lib/melissa/playbookService.ts`
  - `getPlaybookSourceBySlug(slug)`
  - `getActiveCompiledBySlug(slug)`

- `lib/melissa/playbookCompiler.ts`
  - `compilePlaybookSource(sourceId: string, options?: { activate?: boolean })`

If any helper is missing, implement a thin wrapper around Prisma that matches the intended behavior.

## Deliverables

1. New/updated React components under `app/settings` or wherever Settings is implemented that:
   - Add a tab for Persona
   - Add a tab for Protocol / Rules
   - Add a tab for Playbooks

2. API route(s) that:
   - Read `PlaybookSource` and update its `markdown`/`status`
   - Trigger compilation via `compilePlaybookSource`

3. Basic error handling and loading states.

## Testing / Verification

- Ensure:
  - Persona tab renders at least the default Melissa persona.
  - Protocol tab renders the default `bloom_ifl_v1`.
  - Playbooks tab lists `bottleneck_throughput_v1` and can:
    - Load and edit its Markdown.
    - Compile and activate a compiled version.
- Do not add or modify database schema in this step.

EOF

echo "Claude Code Settings UI prompt created at ${PROMPT_FILE}"
