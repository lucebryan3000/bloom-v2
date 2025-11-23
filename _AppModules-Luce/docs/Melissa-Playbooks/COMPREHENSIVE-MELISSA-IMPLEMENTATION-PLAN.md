# Comprehensive Melissa Playbooks Implementation Plan

**Version:** 1.0 UNIFIED
**Last Updated:** November 15, 2025
**Status:** Ready to Execute
**Single Source of Truth:** This document replaces all previous fragmented documentation

---

## Executive Summary

This is the **DEFINITIVE IMPLEMENTATION PLAN** for the Melissa Playbooks system, consolidating all 10 shell script phases (1-10) plus the install sequence into one comprehensive roadmap.

The implementation is delivered via shell scripts in this directory:
- `install.sh` (runs phases 1-6)
- `1_schema_and_migrate.sh` through `10_seed_melissa_data.sh` (additional phases)

**Total Implementation Time:** ~8-12 hours (depends on testing depth)

---

## What Gets Implemented

### Phase 1: Database Schema & Migration (1_schema_and_migrate.sh)
- Adds 4 Prisma models: `MelissaPersona`, `ChatProtocol`, `PlaybookSource`, `PlaybookCompiled`
- Runs `npx prisma migrate dev`
- Seeds default Melissa persona, protocol, and example playbook
- **Outcome:** Database ready with Melissa entities

### Phase 2: Service Layer (2_config_services.sh)
- Creates `lib/melissa/personaService.ts` (Persona CRUD)
- Creates `lib/melissa/protocolService.ts` (Protocol CRUD)
- Creates `lib/melissa/playbookService.ts` (Playbook CRUD)
- **Outcome:** TypeScript service classes for data access

### Phase 3: Markdown Specification (3_markdown_spec.sh)
- Creates `docs/playbooks/PLAYBOOK_SPEC_V1.md`
- Defines playbook JSON structure and validation rules
- **Outcome:** Developer documentation

### Phase 4: Compile Pipeline (4_compile_pipeline.sh)
- Creates `lib/melissa/playbookCompiler.ts`
- Implements playbook source → compiled format conversion
- **Outcome:** Playbook compilation engine

### Phase 5: Settings UI Prompt (5_settings_prompt.sh)
- Creates `Claude-Settings-Playbook-UI.md`
- UI/UX guidance for playbook management interface
- **Outcome:** Implementation spec for frontend

### Phase 6: Session Context (6_session_context.sh)
- Creates `lib/melissa/sessionContext.ts`
- Session management and playbook state handling
- **Outcome:** Session integration layer

### Phase 7: IFL & Prompt Builder (7_ifl_and_prompt_builder.sh)
- Creates/updates Intelligent Facilitation Loop components
- Creates prompt generation utilities
- **Outcome:** Core Melissa facilitation engine

### Phase 8: Test Suite (8_tests_prompt.sh)
- Creates test files for all Melissa components
- Generates test specifications
- **Outcome:** Full test coverage

### Phase 9: Cleanup & Validation (9_cleanup_prompt.sh)
- Removes prototype/temporary playbooks
- Validates schema integrity
- **Outcome:** Clean production state

### Phase 10: Seed Melissa Data (10_seed_melissa_data.sh)
- Seeds additional test playbooks
- Creates example data for development
- **Outcome:** Ready-to-use development database

---

## Step-by-Step Execution

### Prerequisites
```bash
cd /home/luce/apps/bloom

# Verify you have:
node --version        # Should be 20.x+
npm list @prisma/client  # Should be 6.19.0+

# Ensure no uncommitted changes
git status
```

### Execute Installation (Phases 1-6)
```bash
# From bloom repo root:
./_build-prompts/Melissa-Playbooks/install.sh
```

This runs automatically:
1. 1_schema_and_migrate.sh
2. 2_config_services.sh
3. 3_markdown_spec.sh
4. 4_compile_pipeline.sh
5. 5_settings_prompt.sh
6. 6_session_context.sh

**Expected Output:**
```
✓ 1_schema_and_migrate.sh completed
✓ 2_config_services.sh completed
✓ 3_markdown_spec.sh completed
✓ 4_compile_pipeline.sh completed
✓ 5_settings_prompt.sh completed
✓ 6_session_context.sh completed
```

### Execute Additional Phases (7-10)

After `install.sh` completes successfully:

```bash
# Phase 7: IFL & Prompt Builder
./_build-prompts/Melissa-Playbooks/7_ifl_and_prompt_builder.sh

# Phase 8: Tests
./_build-prompts/Melissa-Playbooks/8_tests_prompt.sh

# Phase 9: Cleanup
./_build-prompts/Melissa-Playbooks/9_cleanup_prompt.sh

# Phase 10: Seed Data
./_build-prompts/Melissa-Playbooks/10_seed_melissa_data.sh
```

---

## Verification & Testing

After each phase, run:

```bash
# Type check
npx tsc --noEmit

# Build
npm run build

# Tests (if created by Phase 8)
npm test

# Dev server
npm run dev
```

---

## What This Gives You

✅ **Database Models**
- MelissaPersona (who Melissa is)
- ChatProtocol (how Melissa behaves)
- PlaybookSource (playbook markdown)
- PlaybookCompiled (playbook execution format)

✅ **Service Layer**
- Type-safe CRUD operations
- Database abstraction

✅ **Compilation Engine**
- Converts markdown playbooks to executable format
- Validation and error handling

✅ **Session Integration**
- Playbook state management
- Session context tracking

✅ **IFL Engine**
- Intelligent Facilitation Loop
- Melissa's question/response logic

✅ **Test Suite**
- Full component coverage
- Integration tests

---

## Troubleshooting

### If install.sh fails:

1. **Prisma errors:**
   ```bash
   npx prisma generate
   npx prisma migrate dev
   ```

2. **Schema already exists:**
   - Script checks for existing models and skips if found
   - Safe to run multiple times (idempotent)

3. **Permission errors:**
   ```bash
   chmod +x _build-prompts/Melissa-Playbooks/*.sh
   ```

---

## Key Files Created

| Phase | Files | Purpose |
|-------|-------|---------|
| 1 | `prisma/seed-melissa-playbooks.cjs` | Database seeding |
| 2 | `lib/melissa/personaService.ts`, `protocolService.ts`, `playbookService.ts` | Data access layer |
| 3 | `docs/playbooks/PLAYBOOK_SPEC_V1.md` | Specification |
| 4 | `lib/melissa/playbookCompiler.ts` | Compilation engine |
| 5 | `Claude-Settings-Playbook-UI.md` | UI specification |
| 6 | `lib/melissa/sessionContext.ts` | Session management |
| 7 | `lib/melissa/iflEngine.ts`, `promptBuilder.ts` | Facilitation logic |
| 8 | `tests/melissa/*.test.ts` | Test suite |
| 10 | Additional playbook seeds | Example data |

---

## Success Criteria

✅ All 10 phases execute without errors
✅ Database schema matches Prisma models
✅ Services created and typed correctly
✅ Build passes: `npm run build`
✅ Type check passes: `npx tsc --noEmit`
✅ Dev server starts: `npm run dev`
✅ Tests pass (Phase 8): `npm test`

---

## Git Workflow

```bash
# Create feature branch
git checkout -b feature/melissa-implementation

# After install.sh completes
git add .
git commit -m "feat: implement Melissa Playbooks phases 1-6"

# After phases 7-10
git add .
git commit -m "feat: complete Melissa implementation phases 7-10"

# Push and create PR
git push origin feature/melissa-implementation
```

---

## Next Steps After Implementation

1. **Wire UI Components**
   - Use `Claude-Settings-Playbook-UI.md` specifications
   - Implement playbook management interface

2. **Test Playbooks**
   - Use seeded example playbooks
   - Create custom playbooks via API

3. **Integrate with Sessions**
   - Connect playbook execution to Session model
   - Save playbook state during execution

4. **Deploy**
   - Run full test suite
   - Build for production
   - Deploy to Docker

---

## Important Notes

- All scripts are **idempotent** (safe to run multiple times)
- Models/files created are checked before creation
- Existing files are skipped, not overwritten
- Database migrations are non-destructive
- Full git history preserved

---

**Document:** COMPREHENSIVE-MELISSA-IMPLEMENTATION-PLAN.md
**Purpose:** Single authoritative implementation guide
**Authority:** Replaces all fragmented documentation
**Status:** Ready to execute
