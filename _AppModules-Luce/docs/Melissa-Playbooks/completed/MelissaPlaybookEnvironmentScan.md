# Melissa Playbook - Environment Scan Report

## 1. File Discovery Summary

### Installation Scripts
- Location: `_build-prompts/Melissa-Playbooks`
- Files found (12): `install.sh`, `install_phase2.sh`, `1_schema_and_migrate.sh`, `2_config_services.sh`, `3_markdown_spec.sh`, `4_compile_pipeline.sh`, `5_settings_prompt.sh`, `6_session_context.sh`, `7_ifl_and_prompt_builder.sh`, `8_tests_prompt.sh`, `9_cleanup_prompt.sh`, `README.md` (+ review docs such as `MelissaPlaybookClaude-review.md`)
- Scripts currently assume repo root is only one directory up, so running them from `_build-prompts/Melissa-Playbooks` points at `_build-prompts` instead of `/home/luce/apps/bloom`

### Service Layer (`lib/melissa/`)
- Files found (11): `agent.ts`, `config.ts`, `constants.ts`, `context-loader.ts`, `processors/{metricsExtractor.ts,responseProcessor.ts,confidenceEstimator.ts}`, `questionRouter.ts`, `services/configService.ts`, `types.ts`, `types/config.ts`
- Missing entirely: `personaService.ts`, `protocolService.ts`, `playbookService.ts`, `playbookCompiler.ts`, `promptBuilder.ts`, `iflEngine.ts`, `sessionContext.ts`, `playbookRouter.ts`, `contextManager.ts`, `metricsExtractor.ts` (compiled version under `lib/melissa/`—current extractor lives under `processors/` only)

### Type Definitions (`lib/types/`)
- Files found (1): `lib/types/playbook.ts` (91 lines) covering metadata/schema helpers only
- No DTO definitions for `PlaybookSource`, `PlaybookCompiled`, or Session Context

### Prisma Schema Additions
- `prisma/schema.prisma` contains only legacy models (`Organization`, `Playbook`, `MelissaConfig`, etc.) and **no** `MelissaPersona`, `ChatProtocol`, `PlaybookSource`, or `PlaybookCompiled` definitions (`rg` returns no matches)
- `prisma/seed-playbooks.ts` still seeds the legacy `Playbook` table (`prisma/seed-playbooks.ts:1-180`)

---

## 2. Bug Validation

### Bug #1: Path Resolution
- **Status:** CONFIRMED
- **Evidence:** `ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"` in both `Melissa-Playbooks/install.sh:7` and `install_phase2.sh:8` resolves to `_build-prompts`, not repo root
- **Fix needed:** Yes – need to climb two directories or use `$PWD/../..`

### Bug #2: Hard-coded `Organization` relation
- **Status:** NOT REPRODUCED
- **Evidence:** `prisma/schema.prisma:11-80` already defines `model Organization`, so the appended models referencing it would compile in this repo; risk only exists on forks that removed `Organization`
- **Fix needed:** No (but scripts should still guard against missing tables if reused elsewhere)

### Bug #3: Missing `prisma generate`
- **Status:** CONFIRMED
- **Evidence:** `_build-prompts/Melissa-Playbooks/1_schema_and_migrate.sh:201-389` appends models, runs `prisma migrate dev` and `node prisma/seed-melissa-playbooks.cjs`, but never calls `npx prisma generate`
- **Fix needed:** Yes – regenerate the client after schema changes

### Bug #4: No compiled playbooks
- **Status:** CONFIRMED
- **Evidence:** The seed block in `1_schema_and_migrate.sh:299-368` inserts a Markdown `PlaybookSource` but there is no call to `compilePlaybookSource` anywhere (and the compiler file itself doesn’t exist)
- **Fix needed:** Yes – compile and activate at least one `PlaybookCompiled` row right after seeding

### Bug #5: PrismaClient per service
- **Status:** CONFIRMED (in scripts) & COMPONENT MISSING
- **Evidence:** `2_config_services.sh:16-73` writes three service files, each doing `const prisma = new PrismaClient();`; because those files were never generated, the service layer is also missing entirely
- **Fix needed:** Yes – services should import the shared `@/lib/db/client` instance and add org scoping

### Bug #6: Parser returns empty
- **Status:** CONFIRMED (script stub) & FILE MISSING
- **Evidence:** `4_compile_pipeline.sh:25-66` hard-codes `questions: []` and static `phaseMap` in `parseMarkdownToPlaybookDTO`; the script never ran, so neither the stub nor a real parser exists
- **Fix needed:** Yes – implement parser + DTO builder and ensure file is emitted

### Bug #7: Prompt builder ignores context
- **Status:** CONFIRMED (script stub) & FILE MISSING
- **Evidence:** `7_ifl_and_prompt_builder.sh:17-46` builds a flat string with no persona/protocol/session context
- **Fix needed:** Yes – need structured system/user prompts using persona, protocol settings, compiled playbook, prior answers, and context loader data

### Bug #8: IFL engine doesn’t advance
- **Status:** CONFIRMED (script stub) & FILE MISSING
- **Evidence:** `_build-prompts/Melissa-Playbooks/7_ifl_and_prompt_builder.sh:48-95` walks questions sequentially and `applyAnswer` only records the answer; no phase progression, counters, or enforcement of ChatProtocol limits
- **Fix needed:** Yes – implement real IFL state machine and persistence hooks

---

## 3. Implementation Completeness

### Compiler (`lib/melissa/playbookCompiler.ts`)
- **Completion:** 0%
- **Working features:** None – file not generated, no DTO types, no compiler wiring
- **Broken/stub:** Parser, activation pipeline, persistence; compiler script only exists as a dormant shell snippet
- **Code sample:** see §9 (script stub only)

### IFL Engine (`lib/melissa/iflEngine.ts`)
- **Completion:** 0%
- **Working features:** None – file absent
- **Broken/stub:** No `getNextQuestion`, counters, protocol enforcement, or persistence
- **Code sample:** see §9 (script stub only)

### Prompt Builder (`lib/melissa/promptBuilder.ts`)
- **Completion:** 0%
- **Working features:** None – file absent
- **Broken/stub:** No persona/protocol wiring, no session context, no compiled playbook awareness, no conversation memory
- **Code sample:** see §9 (script stub only)

### Playbook Service (`lib/melissa/playbookService.ts`)
- **Completion:** 0%
- **Working features:** None – persona/protocol/playbook services were never created; only `configService.ts` exists (`lib/melissa/services/configService.ts:1-140`)
- **Broken/stub:** No tenant-aware loading, no compiled playbook access, no shared Prisma client

### Session Context Manager (`lib/melissa/sessionContext.ts`)
- **Completion:** 0%
- **Working features:** None – script wasn’t run; API endpoint stores ad-hoc JSON blobs (`app/api/melissa/chat/route.ts:98-195`) and `lib/melissa/agent.ts` manages state in-memory only
- **Broken/stub:** No structured context object, no persistence helpers, no counter tracking outside of `MelissaAgent`

### Metrics Extractor (`lib/melissa/processors/metricsExtractor.ts`)
- **Completion:** ~65%
- **Working features:** Extracts process name, weekly hours, team size, hourly rates, automation %, pain points, risks, industries, org size, and uncertainty flags (`lib/melissa/processors/metricsExtractor.ts:1-190`); covered by `__tests__/lib/melissa/metricsExtractor.test.ts`
- **Broken/stub:** No currency normalization, no ROI mapping, no YAML/question awareness, no connection to compiled playbooks or scoring
- **Code sample:** see §9

---

## 4. Integration Status

### Melissa Chat Integration (`app/api/melissa/chat/route.ts`)
- Imports playbook services: **No** – only `MelissaAgent`, config loader, and Prisma (`app/api/melissa/chat/route.ts:11-120`)
- Uses IFL engine: **No** – conversation handled entirely by `MelissaAgent` heuristics
- Maintains session context: **Partially** – stores raw transcript/metadata blobs but no structured `SessionContext`
- Other notes: endpoint seeds sessions with blank `organizationId` and bypasses persona/protocol selection

### ROI Integration
- Metrics mapped to ROI inputs: **No** – no ROI calculator utilities exist (`rg calculateROI` returns nothing)
- Auto-calculation implemented: **No**
- Report generation wired: **No** – no PDF/Excel/JSON export logic referencing Melissa Playbooks

---

## 5. Missing Components

- [ ] `lib/melissa/playbookRouter.ts` – intent-based playbook selection
- [ ] `lib/melissa/playbookCompiler.ts` – Markdown → compiled JSON
- [ ] `lib/melissa/promptBuilder.ts` – persona/protocol/session aware prompts
- [ ] `lib/melissa/iflEngine.ts` – Intelligent Facilitation Loop
- [ ] `lib/melissa/sessionContext.ts` – shared session state helpers
- [ ] `lib/melissa/playbookService.ts`, `personaService.ts`, `protocolService.ts`
- [ ] `docs/playbooks/PLAYBOOK_SPEC_V1.md`
- [ ] `PlaybookSource` / `PlaybookCompiled` Prisma models & migrations
- [ ] ROI calculation/reporting modules
- [ ] Automated tests for compiler/IFL/prompt builder

---

## 6. Revised Completion Estimate

| Component             | Original Estimate | Actual Completion | Gap |
|-----------------------|------------------|-------------------|-----|
| Installation Scripts  | 20%              | 35%               | Path bug + missing `prisma generate` prevent execution despite files existing |
| Compiler              | 10%              | 0%                | File never generated; parser unimplemented |
| IFL Engine            | 20%              | 0%                | No engine/state machine present |
| Prompt Builder        | 15%              | 0%                | No prompt composer or persona/protocol wiring |
| Service Layer         | 40%              | 15%               | Only config service exists; persona/protocol/playbook services absent |
| **OVERALL**           | 25-30%           | ~10%              | Core models, compiler, prompt builder, and IFL are missing entirely |

---

## 7. Priority Fixes Confirmation

| Bug # | Description                | Blocks MVP | Fix Effort | Priority |
|-------|----------------------------|------------|------------|----------|
| 1     | Path resolution            | Yes        | 0.5 h      | 5 |
| 2     | Organization relation      | No         | 0 h        | 2 |
| 3     | Missing `prisma generate`  | Yes        | 0.5 h      | 5 |
| 4     | No compiled data           | Yes        | 4 h        | 5 |
| 5     | PrismaClient chaos         | Yes (once files exist) | 2 h | 4 |
| 6     | Empty parser               | Yes        | 8 h        | 5 |
| 7     | Prompt builder stub        | Yes        | 6 h        | 5 |
| 8     | No phase progression       | Yes        | 6 h        | 5 |

---

## 8. Actionable Next Steps

### Immediate (This Week)
1. Fix `ROOT_DIR` in `Melissa-Playbooks/install.sh` and `install_phase2.sh`, rerun scripts from repo root, and add `npx prisma generate` after migrations.
2. Verify the new Prisma models in `prisma/schema.prisma`, run `prisma migrate dev`, and seed `MelissaPersona`, `ChatProtocol`, and `PlaybookSource`.
3. Implement the generated persona/protocol/playbook services so they import the shared client (`@/lib/db/client`) and scope by `organizationId`.

### Short-term (Next 2 Weeks)
1. Implement `lib/melissa/playbookCompiler.ts` so `parseMarkdownToPlaybookDTO` parses phases/questions/rules from Markdown, then compile and activate default playbooks.
2. Finish `lib/melissa/sessionContext.ts`, `promptBuilder.ts`, and `iflEngine.ts`, and wire them into `app/api/melissa/chat/route.ts` instead of the monolithic `MelissaAgent`.
3. Backfill Jest coverage for compiler, prompt builder, and IFL using the prompts in `_build-prompts/Melissa-Playbooks/8_tests_prompt.sh`.

### Medium-term (Weeks 3-4)
1. Build ROI calculator/report exporters (PDF/Excel/JSON) fed by compiled metrics.
2. Add playbook versioning + validation (e.g., `PlaybookSource.status`, checksum) and connect to Settings UI.
3. Implement tenant-aware session persistence and logging (e.g., storing `SessionContext` rows, `PlaybookCompiled` usage analytics, ROI outputs).

---

## 9. Code Samples (If Available)

### Example: Compiler Implementation (Current State)
```typescript
// Source: _build-prompts/Melissa-Playbooks/4_compile_pipeline.sh:25-66
export function parseMarkdownToPlaybookDTO(source: PlaybookSource): CompiledPlaybookDTO {
  return {
    name: source.name,
    slug: source.slug,
    category: source.category,
    objective: source.objective,
    version: source.version,
    phaseMap: {
      greet_frame: [],
      discover_probe: [],
      validate_quantify: [],
      synthesize_reflect: [],
      advance_close: [],
    },
    questions: [],
    scoringModel: null,
    reportSpec: null,
    rulesOverrides: null,
    compileInfo: {
      notes: 'parseMarkdownToPlaybookDTO is using a placeholder implementation.',
      sourceId: source.id,
    },
  };
}
```
*File note:* this stub never materialized in `lib/melissa/`; the script is the only place it exists.

### Example: Prompt Builder (Current State)
```typescript
// Source: _build-prompts/Melissa-Playbooks/7_ifl_and_prompt_builder.sh:17-46
export function buildPrompt({ persona, playbook, ctx, question }: { ... }): string {
  const lines: string[] = [];
  lines.push(`You are ${persona.name} (${persona.slug}), an investigative synthesist helping a business user.`);
  lines.push(`Playbook: ${playbook.name} (${playbook.slug}) — category: ${playbook.category}`);
  if (playbook.objective) lines.push(`Playbook objective: ${playbook.objective}`);
  lines.push('');
  lines.push(`Current phase: ${ctx.currentPhase ?? 'unknown'}`);
  lines.push(`Question ID: ${question.id}`);
  lines.push(`Question: ${question.text}`);
  lines.push('');
  lines.push('Ask ONLY this one question, and wait for the user response. Do not answer on their behalf.');
  return lines.join('\n');
}
```
*File note:* also missing from `lib/melissa/`—needs to be generated and replaced with the real persona/protocol-aware prompt composer.

### Example: IFL Engine (Current State)
```typescript
// Source: _build-prompts/Melissa-Playbooks/7_ifl_and_prompt_builder.sh:48-95
export function getNextQuestion(ctx: SessionContext, playbook: PlaybookCompiled): CompiledQuestion | null {
  const questions = extractQuestions(playbook);
  for (const q of questions) {
    if (!(q.id in ctx.answers)) {
      return q;
    }
  }
  return null;
}

export function applyAnswer(ctx: SessionContext, questionId: string, answer: unknown): SessionContext {
  const updated = recordAnswer(ctx, questionId, answer);
  // TODO: Implement phase transitions & followupCount increment logic according to ChatProtocol.
  return updated;
}
```
*File note:* no phase tracking, no limits, and the file hasn’t been created yet.

### Example: Metrics Extractor (Current State)
```typescript
// File: lib/melissa/processors/metricsExtractor.ts:1-90
export class MetricsExtractor {
  async extract(userMessage: string, existingMetrics: ExtractedMetrics, phase: ConversationPhase) {
    const extractedMetrics: Partial<ExtractedMetrics> = {};
    const flags: Partial<ConversationFlags> = {};
    const uncertainties: string[] = [];

    if (phase === "greeting" || phase === "discovery") {
      if (!existingMetrics.processName) {
        const processName = this.extractProcessName(userMessage);
        if (processName) {
          extractedMetrics.processName = processName;
          flags.hasProcessName = true;
        }
      }
      const processDescription = this.extractProcessDescription(userMessage, messageLower);
      if (processDescription) extractedMetrics.processDescription = processDescription;
    }

    const weeklyHours = this.extractNumber(userMessage, ["hours","hour","hrs","hr","h/week","weekly"]);
    if (weeklyHours !== null) {
      extractedMetrics.weeklyHours = weeklyHours;
      flags.hasTimeInvestment = true;
      if (weeklyHours > 168) uncertainties.push("Weekly hours exceeds total hours in a week");
    }
    // ...
  }
}
```

---

## 10. Recommendations

- **Architecture:** Treat persona → protocol → playbook compilation as the source of truth and eliminate the monolithic `MelissaAgent`. Persist `SessionContext` rows tied to compiled playbooks and use IFL to drive the API.
- **Implementation:** Re-run installers after fixing paths, check in generated files, and immediately refactor the stubs (compiler, services, prompt builder, IFL) into production-ready TypeScript.
- **Testing:** Extend the existing Jest harness (see `__tests__/lib/melissa/metricsExtractor.test.ts`) to cover compiler parsing fixtures, prompt assembly snapshots, and IFL progression logic before wiring to the API.
- **Timeline:** Budget ~1 week to fix installers + schema + services, another 1–1.5 weeks for compiler/IFL/prompt builder implementations with tests, then ~2 weeks for ROI reporting, validation, and integration polish before an MVP review.
