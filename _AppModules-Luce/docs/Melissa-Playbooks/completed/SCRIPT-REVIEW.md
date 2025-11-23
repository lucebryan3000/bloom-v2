# Shell Script Review - Melissa Playbooks Installation Scripts

**Date**: 2025-11-14
**Reviewer**: Claude Code
**Status**: ✅ **ALL SCRIPTS PASS - SAFE TO EXECUTE**

---

## Executive Summary

Reviewed **11 shell scripts** for the Melissa Playbooks refactor installation. All scripts pass syntax validation, have proper permissions, and follow best practices. **Ready for execution.**

### Quick Stats

- **Total Scripts**: 11
- **Syntax Errors**: 0
- **Security Issues**: 0
- **Permission Issues**: 0
- **Best Practice Violations**: 0

---

## Scripts Reviewed

### Phase 1 Installation Scripts

1. ✅ `install.sh` - Orchestrator for Phase 1
2. ✅ `1_schema_and_migrate.sh` - Prisma schema updates
3. ✅ `2_config_services.sh` - Service file creation
4. ✅ `3_markdown_spec.sh` - Markdown spec documentation
5. ✅ `4_compile_pipeline.sh` - Compiler stub creation
6. ✅ `5_settings_prompt.sh` - Settings UI prompt generation
7. ✅ `6_session_context.sh` - SessionContext type creation

### Phase 2 Installation Scripts

8. ✅ `install_phase2.sh` - Orchestrator for Phase 2
9. ✅ `7_ifl_and_prompt_builder.sh` - IFL engine & prompt builder stubs
10. ✅ `8_tests_prompt.sh` - Test prompt generation
11. ✅ `9_cleanup_prompt.sh` - Cleanup prompt generation

---

## Detailed Review

### 1. `install.sh` ✅

**Purpose**: Orchestrates Phase 1 installation (scripts 1-6)

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Shebang: `#!/usr/bin/env bash`
- ✅ Error handling: `set -euo pipefail` (fail on errors, undefined vars, pipe failures)
- ✅ Path resolution: Uses `BASH_SOURCE[0]` for reliable path detection
- ✅ Validates repo root location (2 directories up)
- ✅ Pre-execution checks: Verifies scripts exist and are executable before running
- ✅ Clear progress output with visual separators

**Potential Issues**: **NONE**

**Notes**:
- Assumes script is run from `_build-prompts/Melissa-Playbooks/`
- Scripts must be executable (currently are)
- Uses relative paths correctly

---

### 2. `1_schema_and_migrate.sh` ✅

**Purpose**: Updates Prisma schema with 4 new models, runs migration, and seeds database

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Error handling: `set -euo pipefail`
- ✅ Schema validation: Checks if `prisma/schema.prisma` exists
- ✅ Idempotent operations: Checks if models already exist before appending
- ✅ Safe heredocs: Uses `<<'EOF'` (non-interpolating) for schema definitions
- ✅ Migration naming: `add_melissa_playbook_architecture`
- ✅ Generates Prisma client after migration
- ✅ Creates dedicated seed script: `prisma/seed-melissa-playbooks.cjs`

**Schema Models Added**:
1. `MelissaPersona` - Melissa's personality configuration
2. `ChatProtocol` - Behavioral rules and engine settings
3. `PlaybookSource` - Human-authored Markdown playbooks
4. `PlaybookCompiled` - Runtime-ready JSON playbooks

**Seed Data**:
- Default persona: `melissa_v2` (Investigative Synthesist)
- Default protocol: `bloom_ifl_v1` (One Question Engine)
- Example playbook: `bottleneck_throughput_v1`

**Potential Issues**: **NONE**

**Notes**:
- Skips `prisma format` to avoid download errors in sandboxed environments (good decision)
- Seed script is CommonJS (`.cjs`) for Node compatibility
- Uses `upsert` for idempotency in seeding

---

### 3. `2_config_services.sh` ✅

**Purpose**: Creates TypeScript service files for persona, protocol, and playbook management

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates `lib/melissa/` directory
- ✅ Checks if files exist before overwriting
- ✅ Proper TypeScript typing with Prisma imports

**Files Created**:
1. `personaService.ts` - Load personas by slug or default
2. `protocolService.ts` - Load protocols by slug or default
3. `playbookService.ts` - Load playbook sources and compiled versions

**Service Functions**:
- Organization-scoped lookups (multi-tenant ready)
- Default fallback logic
- Proper Prisma typing

**Potential Issues**: **NONE**

---

### 4. `3_markdown_spec.sh` ✅

**Purpose**: Creates Markdown playbook specification documentation

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates `docs/playbooks/` directory
- ✅ Checks if spec already exists
- ✅ Comprehensive spec with examples

**Spec Contents**:
- Frontmatter block (slug, category, objective, protocol, persona)
- Phases definition
- Questions format (YAML-like)
- Optional rules, scoring, and report spec

**Potential Issues**: **NONE**

**Notes**:
- This is documentation only, no code generation
- Provides clear authoring guidelines for playbook creators

---

### 5. `4_compile_pipeline.sh` ✅

**Purpose**: Creates playbook compiler stub (Markdown → JSON)

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxr-xr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates `lib/melissa/playbookCompiler.ts`
- ✅ Defines `CompiledPlaybookDTO` interface
- ✅ Stub implementation with TODO comments
- ✅ Database integration via Prisma

**Functions Created**:
1. `parseMarkdownToPlaybookDTO()` - Parse Markdown (STUB)
2. `compilePlaybookSource()` - Compile and persist to DB

**Potential Issues**: **NONE**

**Notes**:
- Stub returns minimal valid DTO with all phases
- Actual parsing logic marked with TODO for later implementation
- Includes activation logic (deactivates old versions when activating new)

---

### 6. `5_settings_prompt.sh` ✅

**Purpose**: Generates Claude Code prompt for building Settings UI

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxr-xr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates prompt in same directory
- ✅ Checks if prompt already exists
- ✅ Well-structured prompt with clear objectives

**Prompt Requests**:
1. Persona tab (view/edit persona settings)
2. Protocol/Rules tab (view/edit engine settings)
3. Playbooks tab (Markdown editor + compile button)

**Potential Issues**: **NONE**

**Notes**:
- This creates a prompt file, not executable code
- Designed for human/Claude consumption

---

### 7. `6_session_context.sh` ✅

**Purpose**: Creates SessionContext TypeScript type definition

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates `lib/melissa/sessionContext.ts`
- ✅ Defines in-memory session state structure
- ✅ Helper functions for building and updating context

**Types Defined**:
- `Assumption` - User/system assumptions with confidence scores
- `SessionContext` - Complete session state
- `buildInitialSessionContext()` - Factory function
- `recordAnswer()` - Answer recording helper

**Potential Issues**: **NONE**

**Notes**:
- In-memory representation (persistence handled separately)
- Includes answer storage, scores, and assumptions tracking
- Tracks question count and followup count

---

### 8. `install_phase2.sh` ✅

**Purpose**: Orchestrates Phase 2 installation (scripts 7-9)

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Same structure as `install.sh`
- ✅ Error handling: `set -euo pipefail`
- ✅ Pre-execution validation

**Scripts Orchestrated**:
1. `7_ifl_and_prompt_builder.sh`
2. `8_tests_prompt.sh`
3. `9_cleanup_prompt.sh`

**Potential Issues**: **NONE**

---

### 9. `7_ifl_and_prompt_builder.sh` ✅

**Purpose**: Creates IFL engine and prompt builder stubs

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxrwxr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates two TypeScript files
- ✅ Checks for existing files before overwriting

**Files Created**:
1. `lib/melissa/promptBuilder.ts`
   - `buildPrompt()` - Generates LLM prompts from persona/protocol/playbook
   - Includes persona, playbook context, and current question

2. `lib/melissa/iflEngine.ts`
   - `extractQuestions()` - Parse questions from compiled playbook
   - `getNextQuestion()` - Determine next unanswered question
   - `applyAnswer()` - Record answer and update context

**Potential Issues**: **NONE**

**Notes**:
- Both are stubs with TODO comments for full implementation
- Provide working baseline for testing

---

### 10. `8_tests_prompt.sh` ✅

**Purpose**: Generates Claude Code prompt for writing tests

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxr-xr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates comprehensive test prompt
- ✅ Checks if prompt already exists

**Test Coverage Requested**:
1. `promptBuilder.ts` - Prompt generation logic
2. `iflEngine.ts` - Question sequencing and answer application
3. `playbookCompiler.ts` - Markdown parsing (even stub version)

**Potential Issues**: **NONE**

**Notes**:
- Emphasizes "safety net" testing vs. exhaustive coverage
- Allows mocking Prisma for unit tests

---

### 11. `9_cleanup_prompt.sh` ✅

**Purpose**: Generates Claude Code prompt for cleaning up prototype code

**Syntax Check**: ✅ PASS
**Permissions**: `-rwxr-xr-x` (executable)
**Best Practices**: ✅ All followed

**Key Features**:
- ✅ Creates cleanup prompt
- ✅ Checks if prompt already exists

**Cleanup Tasks Defined**:
1. Identify and remove prototype Playbook tables
2. Prepare migration to drop unused tables
3. Remove old prompt-concatenation logic
4. Ensure new architecture is primary code path

**Potential Issues**: **NONE**

**Notes**:
- Emphasizes surgical cleanup (not destructive)
- Provides rollback mechanism via Git
- Excludes logging DB and non-Melissa functionality

---

## Security Analysis

### ✅ All Scripts Follow Security Best Practices

1. **Error Handling**: All scripts use `set -euo pipefail`
   - `-e`: Exit on error
   - `-u`: Exit on undefined variable
   - `-o pipefail`: Fail if any command in pipe fails

2. **Safe Heredocs**: Uses `<<'EOF'` (non-interpolating) for code blocks
   - Prevents shell variable expansion in generated code
   - Protects against injection

3. **Path Safety**:
   - Uses `BASH_SOURCE[0]` for reliable script location
   - Uses `cd` with error checking
   - Validates paths before operations

4. **Idempotency**:
   - Checks if files/models exist before creating
   - Uses `upsert` in seed scripts
   - Safe to run multiple times

5. **No Hardcoded Credentials**: No secrets or API keys in scripts

6. **No External Downloads**: Scripts generate code, don't fetch from internet

7. **Prisma Operations**: All database operations through Prisma (safe, typed)

---

## Execution Order & Dependencies

### Phase 1 (run `./install.sh`)

```
install.sh
 ├─> 1_schema_and_migrate.sh     (schema → migration → seed)
 ├─> 2_config_services.sh        (services)
 ├─> 3_markdown_spec.sh          (docs)
 ├─> 4_compile_pipeline.sh       (compiler)
 ├─> 5_settings_prompt.sh        (prompt file)
 └─> 6_session_context.sh        (types)
```

**Dependencies**:
- Must run from `_build-prompts/Melissa-Playbooks/` directory
- Requires Prisma installed (`npx prisma` available)
- Requires Node.js for seed script

### Phase 2 (run `./install_phase2.sh`)

```
install_phase2.sh
 ├─> 7_ifl_and_prompt_builder.sh (engine stubs)
 ├─> 8_tests_prompt.sh           (test prompt)
 └─> 9_cleanup_prompt.sh         (cleanup prompt)
```

**Dependencies**:
- Phase 1 must be completed first
- No database operations in Phase 2

---

## Potential Runtime Issues

### ⚠️ Minor Considerations (NOT Blockers)

1. **Working Directory Assumption**
   - **Scripts assume** you run them from `_build-prompts/Melissa-Playbooks/`
   - **Mitigation**: Both installers compute `ROOT_DIR` dynamically
   - **Status**: ✅ Handled correctly

2. **Prisma Availability**
   - **Scripts require** `npx prisma` to be available
   - **Mitigation**: Check before running: `npx prisma --version`
   - **Status**: ✅ Likely available (project already uses Prisma)

3. **Node.js Requirement**
   - **Seed script** requires Node.js to run `.cjs` file
   - **Mitigation**: Check before running: `node --version`
   - **Status**: ✅ Likely available (Next.js project)

4. **Existing Schema Conflicts**
   - **If models already exist**, scripts skip appending
   - **Mitigation**: Scripts check with `grep` before appending
   - **Status**: ✅ Idempotent design

5. **Prisma Format Skipped**
   - **Script skips** `npx prisma format` to avoid download errors
   - **Impact**: Schema might not be auto-formatted
   - **Status**: ✅ Cosmetic only, not a problem

---

## Pre-Execution Checklist

Before running `./install.sh`:

- [ ] ✅ **Verify you're in the correct directory**:
  ```bash
  pwd
  # Should be: /home/luce/apps/bloom/_build-prompts/Melissa-Playbooks
  ```

- [ ] ✅ **Check Node.js is available**:
  ```bash
  node --version
  # Should return: v20.x.x or higher
  ```

- [ ] ✅ **Check Prisma is available**:
  ```bash
  npx prisma --version
  # Should return: 5.22.0 or similar
  ```

- [ ] ✅ **Backup database** (optional but recommended):
  ```bash
  cp ../../prisma/bloom.db ../../prisma/bloom.db.backup-$(date +%Y%m%d-%H%M%S)
  ```

- [ ] ✅ **Commit current work**:
  ```bash
  cd ../..
  git add .
  git commit -m "Checkpoint before Melissa Playbooks refactor"
  cd _build-prompts/Melissa-Playbooks
  ```

---

## Execution Plan

### Step 1: Run Phase 1

```bash
cd /home/luce/apps/bloom/_build-prompts/Melissa-Playbooks
./install.sh
```

**Expected Output**:
```
==> Bloom repo root: /home/luce/apps/bloom

────────────────────────────────────────
 Running 1_schema_and_migrate.sh
────────────────────────────────────────
==> Updating Prisma schema...
>> Appending model MelissaPersona...
>> Appending model ChatProtocol...
>> Appending model PlaybookSource...
>> Appending model PlaybookCompiled...
==> Running npx prisma migrate dev...
✓ 1_schema_and_migrate.sh completed

────────────────────────────────────────
 Running 2_config_services.sh
────────────────────────────────────────
Created lib/melissa/personaService.ts
Created lib/melissa/protocolService.ts
Created lib/melissa/playbookService.ts
✓ 2_config_services.sh completed

────────────────────────────────────────
 Running 3_markdown_spec.sh
────────────────────────────────────────
Markdown Playbook spec created at docs/playbooks/PLAYBOOK_SPEC_V1.md
✓ 3_markdown_spec.sh completed

────────────────────────────────────────
 Running 4_compile_pipeline.sh
────────────────────────────────────────
Compile pipeline stub created at lib/melissa/playbookCompiler.ts
✓ 4_compile_pipeline.sh completed

────────────────────────────────────────
 Running 5_settings_prompt.sh
────────────────────────────────────────
Claude Code Settings UI prompt created at Claude-Settings-Playbook-UI.md
✓ 5_settings_prompt.sh completed

────────────────────────────────────────
 Running 6_session_context.sh
────────────────────────────────────────
SessionContext type created at lib/melissa/sessionContext.ts
✓ 6_session_context.sh completed

All steps completed. Review git diff, run tests, and wire remaining pieces as needed.
```

### Step 2: Review Changes

```bash
cd /home/luce/apps/bloom
git status
git diff prisma/schema.prisma
git diff lib/melissa/
```

### Step 3: Test Schema

```bash
npx prisma studio
# Verify new tables exist:
# - MelissaPersona
# - ChatProtocol
# - PlaybookSource
# - PlaybookCompiled
```

### Step 4: Run Phase 2

```bash
cd _build-prompts/Melissa-Playbooks
./install_phase2.sh
```

### Step 5: Review Generated Prompts

```bash
cat Claude-Settings-Playbook-UI.md
cat Claude-Tests-IFL-and-Compiler.md
cat Claude-Cleanup-Prototype-Playbooks.md
```

---

## Post-Execution Verification

After running both phases, verify:

1. **Database Schema** ✅
   ```bash
   npx prisma studio
   # Check for: MelissaPersona, ChatProtocol, PlaybookSource, PlaybookCompiled
   ```

2. **Seed Data** ✅
   ```sql
   -- In Prisma Studio, verify:
   -- MelissaPersona: melissa_v2 (isDefault = true)
   -- ChatProtocol: bloom_ifl_v1 (isDefault = true)
   -- PlaybookSource: bottleneck_throughput_v1
   ```

3. **Service Files** ✅
   ```bash
   ls -l lib/melissa/
   # Should show:
   # - personaService.ts
   # - protocolService.ts
   # - playbookService.ts
   # - playbookCompiler.ts
   # - sessionContext.ts
   # - promptBuilder.ts
   # - iflEngine.ts
   ```

4. **Documentation** ✅
   ```bash
   ls -l docs/playbooks/
   # Should show: PLAYBOOK_SPEC_V1.md
   ```

5. **TypeScript Compilation** ✅
   ```bash
   npx tsc --noEmit
   # Should complete without errors
   ```

---

## Rollback Plan

If anything goes wrong:

```bash
# 1. Rollback Git changes
git reset --hard HEAD

# 2. Restore database backup
cp prisma/bloom.db.backup-YYYYMMDD-HHMMSS prisma/bloom.db

# 3. Regenerate Prisma client
npx prisma generate

# 4. Restart dev server
npm run dev:kill
npm run dev
```

---

## Conclusion

### ✅ **ALL SCRIPTS ARE SAFE TO EXECUTE**

**No syntax errors, no security issues, no permission problems.**

All scripts follow bash best practices:
- Proper error handling (`set -euo pipefail`)
- Safe heredocs (non-interpolating)
- Idempotent operations
- Clear documentation
- Proper path resolution

**Recommendation**: Execute Phase 1 first, review results, then execute Phase 2.

**Risk Level**: **LOW** - Scripts are well-written, idempotent, and safe.

---

## Next Steps

1. ✅ Run pre-execution checklist
2. ✅ Execute `./install.sh` from `_build-prompts/Melissa-Playbooks/`
3. ✅ Review git diff and verify database changes
4. ✅ Execute `./install_phase2.sh`
5. ✅ Use generated Claude prompts to complete implementation
6. ✅ Run tests
7. ✅ Update documentation

---

**Reviewed By**: Claude Code
**Review Date**: 2025-11-14
**Status**: ✅ APPROVED FOR EXECUTION
