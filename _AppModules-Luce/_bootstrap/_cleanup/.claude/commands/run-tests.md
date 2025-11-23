# /run-tests - Interactive Test Runner

**Purpose**: Simplified test runner with 5 focused options for different testing scenarios.

**Version**: 2.0
**Last Updated**: November 15, 2025

---

## Quick Start

```bash
/run-tests              # Interactive menu (5 options)
/run-tests quick        # Quick validation (smoke tests only)
/run-tests backend      # Backend tests (unit + domain + integration)
/run-tests frontend     # Frontend tests (E2E workflows + UI)
/run-tests full         # Complete test suite
/run-tests help         # Show this help
```

---

## How It Works

When you run `/run-tests`, Claude will:

1. **Analyze your test structure** in `/tests/` directory
2. **Present test categories** with file counts and descriptions
3. **Ask which tests to run** with numbered options
4. **Execute the selected tests** using appropriate npm scripts
5. **Show results** and offer to run more tests

---

## Test Groups (Consolidated)

### 1. Quick Validation (~1-2 minutes)
**Purpose**: Fast critical path check before commits
**What runs**: Smoke tests only (6 Playwright tests)
**Coverage**: Health checks, homepage, chat, core functionality
**Command**: `npm run test:e2e:smoke`
**When to use**: Before every commit, rapid feedback

### 2. Backend Tests (~2-3 minutes)
**Purpose**: Verify all backend logic and APIs
**What runs**: All Jest tests (22 files)
- Unit tests (11 files): Utils, components, stores, cache
- Domain tests (5 files): ROI calculator, confidence, sensitivity, LLM
- Integration tests (6 files): API endpoints, system integration
**Command**: `npm test`
**When to use**: Backend code changes, API modifications, ROI logic changes

### 3. Frontend Tests (~3-5 minutes)
**Purpose**: Validate user-facing features and workflows
**What runs**: E2E workflow + settings + accessibility tests (13 files)
- Workflows (6 files): Sessions, exports, library, pause/resume, Melissa
- Integration (3 files): Full system, API sessions, test infrastructure
- Settings (1 file): Melissa config UI
- Accessibility (2 files): WCAG compliance
- Smoke (1 file): Chat workflow only
**Command**: `npm run test:e2e:workflows && playwright test tests/e2e/integration tests/e2e/settings tests/e2e/accessibility`
**When to use**: UI changes, workflow modifications, component updates

### 4. Full Test Suite (~5-8 minutes)
**Purpose**: Comprehensive validation before deployment
**What runs**: Everything (41 files)
- All Jest tests (unit + domain + integration)
- All Playwright tests (smoke + workflows + integration + settings + accessibility)
**Command**: `npm test && npm run test:e2e`
**When to use**: Pre-deployment, major features, release preparation

### 5. Custom Pattern
**Purpose**: Target specific tests by file or pattern
**What runs**: User-specified tests
**Examples**:
- Single file: `tests/domain/roi/calculator.test.ts`
- Pattern: `--testPathPattern=melissa`
- Directory: `tests/e2e/workflows/`
**When to use**: Debugging, focused testing, investigating failures

---

## Interactive Prompts

### Main Menu (Simplified)

**When `/run-tests` is invoked, Claude will present this formatted menu:**

```
🧪 BLOOM TEST RUNNER
41 test files total | 5 focused options

SELECT TEST GROUP:

  1. ⚡ Quick Validation       (~1-2 min)  - Smoke tests before commits
  2. 🔧 Backend Tests          (~2-3 min)  - Jest: unit + domain + integration
  3. 🎨 Frontend Tests         (~3-5 min)  - E2E: workflows + UI + accessibility
  4. 🚀 Full Test Suite        (~5-8 min)  - Everything before deployment
  5. 🎯 Custom Pattern         (varies)    - Specify test path or pattern

Enter number (1-5): _
```

### After Selection
```
Running: 🔧 Backend Tests (22 Jest files)
Command: npm test

Estimated time: ~2-3 minutes
Press Ctrl+C to cancel...
```

### After Execution
```
=== TEST RESULTS ===
✅ Backend Tests: 185/202 passing (91.5%)
⏱️  Duration: 2m 14s

What next?
1. Run more tests
2. View test coverage (npm run test:coverage)
3. Exit

Enter number (1-3):
```

---

## Custom Test Patterns

When selecting option 5 (Custom), you can specify:

**File patterns:**
```
tests/unit/utils/*.test.ts
tests/e2e/smoke/chat.spec.ts
tests/domain/roi/calculator.test.ts
```

**Jest patterns:**
```
--testPathPattern=melissa
--testPathPattern=session
--testNamePattern="should calculate NPV"
```

**Playwright patterns:**
```
tests/e2e/workflows/session-workflow.spec.ts
tests/e2e/smoke/
```

---

## Underlying NPM Scripts

The 5 test groups map to these npm scripts:

```bash
# Option 1: Quick Validation
npm run test:e2e:smoke

# Option 2: Backend Tests
npm test

# Option 3: Frontend Tests
npm run test:e2e:workflows && \
  playwright test tests/e2e/integration tests/e2e/settings tests/e2e/accessibility

# Option 4: Full Test Suite
npm test && npm run test:e2e

# Option 5: Custom Pattern
jest <pattern>           # For Jest tests
playwright test <path>   # For E2E tests
```

**Individual npm scripts (for manual use):**
```bash
npm run test:unit           # Unit tests only (11 files)
npm run test:domain         # Domain tests only (5 files)
npm run test:integration    # Integration tests only (6 files)
npm run test:watch          # Watch mode
npm run test:coverage       # With coverage report
npm run test:cleanup        # Kill zombie processes
```

---

## Smart Features

### Pre-flight Checks
Before running E2E tests, Claude will:
- Check if dev server is running
- Offer to start server if needed
- Run `npm run dev:clean` to kill existing servers

### Test Recommendations
Based on recent changes, Claude may suggest:
- "Run smoke tests first (fastest critical path check)"
- "ROI calculator changed - run domain tests"
- "API routes modified - run integration tests"

### Failure Handling
If tests fail, Claude will:
- Show failure summary
- Offer to re-run failed tests only
- Suggest relevant debugging commands

---

## Usage Instructions for Claude

**When `/run-tests` is invoked:**

1. Present the simplified 5-option menu (already defined in this command)
2. Wait for user's selection (they will type a number 1-5)
3. Execute the corresponding command using Bash tool
4. Show results and offer next actions

**Option mapping:**
- Option 1: `npm run test:e2e:smoke`
- Option 2: `npm test`
- Option 3: `npm run test:e2e:workflows && playwright test tests/e2e/integration tests/e2e/settings tests/e2e/accessibility`
- Option 4: `npm test && npm run test:e2e`
- Option 5: Custom (ask for pattern)

**For custom patterns (option 5):**
- Ask: "Enter test path or pattern:"
- Detect type: `.test.ts` → Jest, `.spec.ts` → Playwright
- Execute: `jest <pattern>` or `playwright test <pattern>`

**For E2E tests (options 1, 3, 4):**
- Check if dev server is running: `lsof -i :3001`
- If not running, ask: "Dev server not detected. Start it? (y/n)"
- If yes: run `npm run dev:clean && npm run dev` in background
- Then execute E2E tests

**After execution:**
- Parse test results
- Show pass/fail summary with duration
- Ask: "What next? (1) Run more tests (2) Coverage (3) Exit"

---

## Example Session

```
User: /run-tests

Claude:
🧪 BLOOM TEST RUNNER
41 test files total | 5 focused options

SELECT TEST GROUP:

  1. ⚡ Quick Validation       (~1-2 min)  - Smoke tests before commits
  2. 🔧 Backend Tests          (~2-3 min)  - Jest: unit + domain + integration
  3. 🎨 Frontend Tests         (~3-5 min)  - E2E: workflows + UI + accessibility
  4. 🚀 Full Test Suite        (~5-8 min)  - Everything before deployment
  5. 🎯 Custom Pattern         (varies)    - Specify test path or pattern

Enter number (1-5):

User: 1

Claude:
Running: ⚡ Quick Validation (6 Playwright smoke tests)
Command: npm run test:e2e:smoke

Estimated time: ~1-2 minutes
Checking dev server... ✓ Running on port 3001

Executing tests...
[runs: npm run test:e2e:smoke]

=== TEST RESULTS ===
✅ Quick Validation: 6/6 passing (100%)
⏱️  Duration: 1m 32s

What next?
1. Run more tests
2. View test coverage
3. Exit

Enter number (1-3):

User: 3

Claude: ✅ Test session complete!
```

---

## Notes

- All test files are in `/tests/` directory (Next.js standard structure)
- Jest tests: `.test.ts` or `.test.tsx` files
- Playwright tests: `.spec.ts` files in `/tests/e2e/`
- Test results stored in `/tests/reports/`
- Coverage reports in `/tests/reports/coverage/`

---

## Related Commands

- `/build-backlog` - View testing tasks in backlog
- `npm run test:cleanup` - Kill zombie test processes
- `npm run dev:clean` - Clean dev servers before E2E tests
