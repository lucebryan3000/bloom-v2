# /build-backlog - Build Backlog Manager

**Purpose**: Read and display the build backlog with context to get started on tasks. Shows file references, dependencies, and decisions needed—just enough info to begin work, not a full design document.

**Version**: 1.6
**Last Updated**: November 16, 2025
**Backlog Location**: [`.claude/commands/build-backlog/build-backlog.md`](.claude/commands/build-backlog/build-backlog.md)

---

## Quick Start

```bash
/build-backlog              # Display full categorized backlog
/build-backlog help         # Show all available commands (this list)
/build-backlog add task1, task2, task3   # Add tasks to backlog (comma-separated)
/build-backlog update CATEGORY X/Y       # Fast update completion status (e.g., "Cookie XSS Security" "3/3")
/build-backlog organize     # Reorganize tasks by domain (completed sections at bottom)
/build-backlog verify       # Check if any tasks have already been implemented
/build-backlog status       # Show completion summary and per-category breakdown
/build-backlog search api   # Search backlog for keyword
/build-backlog deps         # Show task dependencies and blockers
/build-backlog notes        # Show decisions needed and implementation notes
/build-backlog start task   # Get context to begin working on a task
```

---

## 🎯 Key Features

- **Quick Task Addition**: Add tasks via comma-separated list with `add` mode
- **Fast Updates**: Instant completion status updates with `update` mode (no Edit tool lag)
- **Smart Organization**: Groups tasks by technical domain and dependencies, not just categories
- **Focus on Active Work**: Completed sections automatically moved to bottom (organize mode)
- **File Status Tracking**: Shows which files exist (✓), need creation (✗), or need decisions (?)
- **Dependency Mapping**: Visualizes what blocks what and what can start now
- **Decision Tracking**: Highlights critical decisions needed before building
- **Quick Context**: Jump to any task with `start` mode to get just enough info to begin
- **Search & Filter**: Find related tasks across the entire backlog
- **Modification Modes**: Only `add` and `update` modes modify the backlog—all others are safe

---

## What This Command Does

### 1. **Read & Parse**
- Reads `.claude/commands/build-backlog/build-backlog.md` from project root
- Shows when backlog was last updated
- Parses all task categories and individual tasks

### 2. **Show File References** (organize, start, default modes)
- Links to files you need to create
- Links to files you need to modify
- Marks file status: exists (`✓`), needs creation (`✗`), decision needed (`?`)
- **Note**: File status checking only in `organize` and `start` modes

### 3. **Show Dependencies** (deps mode)
- What each task needs before it can start
- What each task blocks when done
- Which tasks have no blockers (can start now)

### 4. **Show Notes & Decisions** (notes mode)
- Implementation decisions needed
- Important technical notes
- Questions that need answers before building

### 5. **Count Checkboxes** (status mode)
- Fast checkbox counting: `[x]` vs `[ ]`
- Shows overall summary plus per-category breakdown
- No filesystem checks - just markdown parsing
- For actual implementation verification, use `verify` mode

### 6. **Verify Implementation** (verify mode)
- Scans actual codebase for implemented features
- Checks if files exist that should be created
- Finds partially implemented work
- Slower than status - runs file searches

### 7. **Add Tasks** (add mode)
- Parse comma-separated task list
- Intelligently categorize based on keywords
- Format with proper markdown structure
- Ask for category if ambiguous
- Append to appropriate section in backlog

### 8. **Fast Update** (update mode)
- Instant completion status updates using shell script (no Edit tool lag)
- Updates both section status and summary table in one operation
- Auto-calculates percentage from X/Y format
- Creates backup before modification
- Example: `/build-backlog update "Cookie XSS Security" "3/3"` → instant update

### 9. **Safe Modifications**
- Only `add` and `update` modes modify `.claude/commands/build-backlog/build-backlog.md`
- Both modes create `.bak` backup before changes
- All other modes are non-destructive
- Safe to run anytime

---

## Display Modes

### Default View (Full Backlog)
Shows all categories with tasks and file references:

```
=== BUILD BACKLOG ===
Backlog Updated: Nov 15, 2025 at 2:30 PM

✅ PHASE 3 FEATURES (9/9 COMPLETE)
  [x] Add SettingsAuditLog and LogFilterPreference models
      Files: prisma/schema.prisma:L1055-L1108
             app/api/settings/audit-logs/route.ts

  [x] Create database migration for Phase 3 models
      Files: prisma/migrations/20251115213244_add_phase3_audit_and_filter_models/

🔄 CONTINUE SESSION FEATURE (0/5 NOT STARTED)
  [ ] Implement session resume functionality
      Files: app/api/sessions/[id]/route.ts (modify)
             app/api/sessions/[id]/resume/route.ts (create)

  [ ] Add session state restoration
      Files: lib/melissa/agent.ts (modify)
             prisma/schema.prisma (add contextSnapshot field)

🧪 TEST CONSOLIDATION PROJECT (0/9 NOT STARTED)
  [ ] Audit all test files in project
      Files: tests/e2e/** (find all)
             tests/unit/** (find all)

📊 BUSINESS EVENTS AUDIT TRAIL (0/12 NOT STARTED)
  [ ] Review and decide which events require audit logging
      Decision: Which events from checklist? (session, ROI, report, etc)
```

### Search Mode
Filter tasks by keyword:

```
/build-backlog search session

Results for "session" (3 matches):

🔄 CONTINUE SESSION FEATURE
  [ ] Implement session resume functionality
  [ ] Add session state restoration
  [ ] Create UI for "Resume Session" option
```

### Status Mode
Overall summary plus per-category breakdown (pure checkbox counting - no filesystem checks):

**When status mode is requested:**
Claude will output the backlog status in a code block (triple backticks, no language identifier) to preserve formatting.

```
/build-backlog status

=== BACKLOG STATUS ===
Last Updated: 2025-11-15 19:37:51

SUMMARY: 25/44 tasks complete (56%)

────────────────────────────────────────────────────────────────

✅ Phase 3 Features..................... 9/9 (100%) COMPLETE
✅ Test Infrastructure Fixes............ 6/6 (100%) COMPLETE
✅ Test Consolidation Project........... 10/10 (100%) COMPLETE
🔄 Continue Session Feature............. 0/5 (0%) NOT STARTED
📊 Business Events Audit Trail.......... 0/14 (0%) NOT STARTED
⚠️  Remaining Unit Test Failures........ 0/5 (0%) DEFERRED

────────────────────────────────────────────────────────────────

NEXT PRIORITIES

🎯 Continue Session Feature (0/5 - 0%)
   Status: Ready to start
   Blockers: Design decisions needed (session timeout, snapshot strategy)
   Impact: Blocks workshop resume functionality

⚠️  Business Events Audit Trail (0/14 - 0%)
   Status: BLOCKED
   Blocker: Scope decision needed (which events to log)
   Impact: Analytics and audit compliance

────────────────────────────────────────────────────────────────

Quick Commands:
  /build-backlog verify     # Check what's actually implemented
  /build-backlog organize   # Group by technical domain
  /build-backlog notes      # See all decisions needed
  /build-backlog deps       # See what blocks what
```

### Dependencies Mode
Task dependencies and blockers:

```
/build-backlog deps

TASK DEPENDENCIES

Continue Session
  ├─ Requires: Session model with contextSnapshot field
  ├─ Depends on: Session state persistence design
  ├─ Blocks: Workshop resume functionality
  └─ Status: Not started

Test Consolidation
  ├─ Requires: Identify all test file locations
  ├─ Depends on: None (can start independently)
  ├─ Blocks: CI/CD pipeline validation
  └─ Status: Not started

Business Events
  ├─ Requires: Decision on event logging scope
  ├─ Depends on: BusinessEventLog schema design
  ├─ Blocks: Analytics and audit compliance
  └─ Status: Blocked (awaiting scope decision)
```

### Notes Mode
Implementation notes and decisions needed:

```
/build-backlog notes

DECISIONS NEEDED

Business Events Audit Trail:
  ✓ Which events to log? (session, ROI, report, login, branding, melissa, file, task, cleanup)
  ? New model or extend SettingsAuditLog?
  ? Session timeout duration? (30/60/90 days?)
  ? Snapshot vs rebuild for conversation history?

Continue Session:
  ? What triggers "session expired"?
  ? How long are sessions resumable?

Test Consolidation:
  ? Include test artifacts in /scripts/testing/results/?
  ? Update jest.config.js and playwright.config.ts paths?

IMPLEMENTATION NOTES

Continue Session:
  • Melissa context reconstruction should be idempotent
  • Consider performance impact of snapshot vs rebuild
  • Need comprehensive E2E test coverage

Business Events:
  • Many integration points across application
  • Consider batching events for performance
  • Plan for future analytics dashboard

Test Consolidation:
  • /settings page calls test utilities (identify which)
  • Task Scheduler calls test files (identify which)
  • Update build configuration after moving files
```

### Start Mode
Quick context to begin working on a task:

```
/build-backlog start continue-session

GETTING STARTED: Continue Session Feature
Backlog Updated: Nov 15, 2025

TASK GROUP: Continue Session (0/5 tasks)
Priority: High (blocks workshop testing)

FILES TO KNOW:
  ✓ app/api/sessions/[id]/route.ts - Session endpoints
  ✓ lib/melissa/agent.ts - Conversation context
  ✓ prisma/schema.prisma - Session model (L45-60)
  ✗ app/api/sessions/[id]/resume/route.ts - Create this
  ✗ components/workshop/SessionResume.tsx - Create this

RELATED TESTS:
  • tests/e2e/session.spec.ts - Existing session tests
  • tests/unit/sessionStore.test.ts - Store tests

FIRST STEPS:
  1. Review Session model in prisma/schema.prisma
  2. Check existing session GET/POST endpoints
  3. Plan state restoration approach (snapshot vs rebuild)
  4. Create /api/sessions/[id]/resume endpoint
  5. Implement UI component

BLOCKERS/DECISIONS:
  • Session timeout duration not yet decided
  • Snapshot vs rebuild strategy needed

RELATED TASKS:
  • [ ] Add validation for expired sessions
  • [ ] Test session resumption flow
  • [ ] Create UI for "Resume Session" option
```

### Update Mode
Fast status updates without Edit tool lag:

```
/build-backlog update "Cookie XSS Security" "3/3"

🚀 FAST UPDATE MODE (using shell script)

Updating 'Cookie XSS Security' to 3/3 complete | **100%** ✅...
✅ Updated Cookie XSS Security in backlog
Backup saved to .claude/commands/build-backlog/build-backlog.md.bak

Changes made:
  1. Section status: **Status**: 3/3 tasks complete (100%)
  2. Table row: | Cookie XSS Security | 3/3 complete | **100%** ✅ | RESOLVED |

Time: <1 second (no Edit tool overhead)
```

**Examples:**
```bash
# Mark security issue as resolved
/build-backlog update "Cookie XSS Security" "3/3"

# Update business events progress
/build-backlog update "Business Events" "5/14"

# Mark test failures as improved
/build-backlog update "Unit Test Failures" "195/202"
```

**How it works:**
- Uses fast shell script (`scripts/backlog-update.sh`)
- No Edit tool = no context loading lag
- Auto-calculates percentage from X/Y
- Updates both status line and summary table
- Creates `.bak` backup automatically
- Returns in <1 second

### Add Mode
Add tasks to the backlog via comma-separated list:

```
/build-backlog add Fix session timeout issue, Create metrics dashboard widget, Update branding to support custom fonts

ADDING TASKS TO BACKLOG

Parsing 3 tasks...

1. "Fix session timeout issue"
   → Detected keywords: session, timeout
   → Category: 🔄 Continue Session Feature
   → Added as: [ ] Fix session timeout issue

2. "Create metrics dashboard widget"
   → Detected keywords: dashboard, widget
   → Category: 📊 New category needed
   → Prompt: Which category should this go in?
     A) Create new "Dashboard Widgets" category
     B) Add to "Business Events Audit Trail"
     C) Specify custom category name

3. "Update branding to support custom fonts"
   → Detected keywords: branding, fonts
   → Category: ✅ Settings & Persistence (marked complete - reopen?)
   → Prompt: This category is marked complete. Should we:
     A) Reopen this category
     B) Create new "Branding Enhancements" category

────────────────────────────────────────────────────────────────

SUMMARY

✅ 1 task added automatically
⚠️ 2 tasks need category selection

Updated: .claude/commands/build-backlog/build-backlog.md
```

**Smart Categorization Keywords:**
- **Session**: session, resume, timeout, state, pause
- **Testing**: test, spec, fixture, playwright, jest, e2e, unit
- **Events/Audit**: event, audit, log, trail, tracking, analytics
- **Settings**: settings, config, preference, branding, theme
- **API**: api, endpoint, route, rest, graphql
- **UI/Components**: component, widget, dashboard, page, form, button
- **Database**: database, schema, migration, prisma, model

**Usage Tips:**
- Tasks are added as unchecked `[ ]` by default
- File references and notes can be added manually after
- Use natural language - Claude will parse and categorize
- If category is ambiguous, you'll be prompted to choose
- Tasks are appended to the end of the matching category

### Help Mode
List all available commands:

```
/build-backlog help

AVAILABLE COMMANDS

/build-backlog              Display full categorized backlog
/build-backlog help         Show all available commands (this list)
/build-backlog add TASKS    Add comma-separated tasks to backlog
/build-backlog update CAT X/Y  Fast update completion status (instant, no lag)
/build-backlog organize     Group tasks by technical domain & dependencies
/build-backlog verify       Check if any tasks have already been implemented
/build-backlog status       Show summary + per-category breakdown
/build-backlog search KEY   Search backlog for keyword
/build-backlog deps         Show task dependencies and blockers
/build-backlog notes        Show decisions needed and implementation notes
/build-backlog start TASK   Get quick start context for a specific task

EXAMPLES

/build-backlog add Fix bug, Create feature, Update docs
/build-backlog update "Cookie XSS Security" "3/3"   # Instant status update
/build-backlog search session          # Find all session-related tasks
/build-backlog start continue-session  # Get started on session resume feature
/build-backlog verify                  # Check for already-implemented tasks
/build-backlog deps                    # See what blocks what
/build-backlog status                  # Quick completion check

🔗 Full backlog: .claude/commands/build-backlog/build-backlog.md
```

### Verify Mode
Check if any backlog tasks have already been implemented:

```
/build-backlog verify

BACKLOG VERIFICATION REPORT
Backlog Updated: Nov 15, 2025

🔍 CHECKING FOR ALREADY-IMPLEMENTED TASKS...

Session Lifecycle & Persistence
  ✅ Session resume API endpoint
     Status: Already exists at app/api/sessions/[id]/resume/route.ts
     Action: Mark task complete

  ⚠️  Session state restoration context
     Status: Partially implemented in lib/melissa/agent.ts
     Action: Review implementation and mark as complete or adjust task scope

Test Infrastructure & Organization
  🔴 No implemented tasks detected

Business Events & Audit Trail
  ✅ Business event logging infrastructure
     Status: Exists at lib/events/businessEventLogger.ts
     Files affected: 3 references across codebase
     Action: Review scope and mark as complete if full

  🟡 Partial: Session event logging
     Status: Implemented in app/api/sessions/route.ts only
     Action: Check if all integration points are complete

Settings & Configuration
  ✅ All 9 tasks verified as complete ✓

---

SUMMARY

Total Tasks: 35
Already Implemented: 3
Partially Implemented: 2
Not Started: 30

RECOMMENDATIONS

1. Review 3 verified implemented tasks
2. Clarify scope of 2 partially-implemented tasks
3. Update backlog accordingly

Run: /build-backlog start <task-name> for detailed context
```

### Organize Mode
Intelligently group tasks by actual relationships and domains:

**Note**: Completed sections are automatically moved to the bottom to focus on active work.

**EFFICIENCY RULES FOR ORGANIZE MODE:**
1. **Simple edits = simple actions**: If just marking checkboxes or moving sections, do NOT add extra content
2. **No overthinking**: Cut/paste/edit checkbox status only - don't write new documentation
3. **File checks only when needed**: Only verify file existence if output requires status markers
4. **Minimal reads**: Read each file ONCE, not multiple times
5. **Trust the content**: Don't re-investigate what's already documented

```
/build-backlog organize

=== REORGANIZED BACKLOG ===
Backlog Updated: Nov 15, 2025
Organized by: Technical Domain & Dependencies
Sort Order: Active domains first, completed domains last

🚧 ACTIVE DOMAINS
────────────────────────────────────────────────────────────────

🔷 DOMAIN: SESSION LIFECYCLE & PERSISTENCE (1/5 tasks - 20% complete)
Description: Resume sessions, restore state, manage expiration

In Progress: 1/5
  [x] Implement session resume functionality
  [ ] Add session state restoration (context, progress, conversation history)
  [ ] Create UI for "Resume Session" option on workshop page
  [ ] Add validation for expired sessions
  [ ] Test session resumption flow

Related (from Business Events): 0/3
  [ ] Session creation/completion/resume flows (event logging)
  [ ] Determine session timeout duration (decision needed)
  [ ] Design session lifecycle audit schema

Cross-File Impact:
  ✓ app/api/sessions/[id]/route.ts
  ✓ app/api/sessions/[id]/resume/route.ts (created)
  ✓ lib/melissa/agent.ts
  ✓ prisma/schema.prisma
  ✗ components/workshop/SessionResume.tsx

Dependencies:
  ├─ Requires: Session model with contextSnapshot field
  ├─ Depends on: Session state persistence design decision
  └─ Blocks: Workshop resume functionality


🔷 DOMAIN: TEST INFRASTRUCTURE & ORGANIZATION (0/9 tasks - 0% complete)
Description: Consolidate testing, unify artifacts, update references

Not Started: 0/9
  [ ] Audit all test files in project (Playwright + Jest locations)
  [ ] Create /scripts/testing/ directory structure
  [ ] Move Playwright tests to /scripts/testing/e2e/
  [ ] Move Jest tests to /scripts/testing/unit/
  [ ] Move test fixtures to /scripts/testing/fixtures/
  [ ] Update /settings page references to new test paths
  [ ] Update Task Scheduler references to new test paths
  [ ] Update build configuration paths
  [ ] Create test artifacts directory at /scripts/testing/results/

Cross-File Impact:
  ~ jest.config.js
  ~ playwright.config.ts
  ~ tests/e2e/** (move to /scripts/testing/e2e/)
  ~ tests/unit/** (move to /scripts/testing/unit/)
  ~ app/pages/settings.tsx (update references)
  ~ app/pages/task-scheduler.tsx (update references)

Dependencies:
  ├─ Requires: Identify all test file locations
  ├─ Depends on: None (can start independently)
  ├─ Blocks: CI/CD pipeline validation
  └─ Blocks: Accurate test reporting


🔷 DOMAIN: EVENT LOGGING & AUDIT TRAIL (0/12 tasks - 0% complete)
Description: Track business events, audit changes, enable analytics

⚠️  BLOCKED: Requires scope decision

Not Started: 0/1 (Scope Definition)
  [ ] Review and decide which events require audit logging

Not Started: 0/3 (Schema & Infrastructure)
  [ ] Assess impact on SettingsAuditLog schema (may need new BusinessEventLog model)
  [ ] Design audit schema for: session lifecycle, ROI calculations, report generation, task execution
  [ ] Create API endpoints for business event logging

Not Started: 0/7 (Integration Points)
  [ ] ROI calculation pipeline (event logging)
  [ ] Report generation and export (event logging)
  [ ] Task scheduler execution (event logging)
  [ ] Authentication/login events (event logging)
  [ ] Branding updates (event logging)
  [ ] Melissa settings changes (event logging)
  [ ] File uploads (event logging)

Not Started: 0/1 (Analytics)
  [ ] Create business events dashboard or analytics view

Cross-File Impact:
  ? prisma/schema.prisma (new BusinessEventLog or extend SettingsAuditLog)
  ✗ app/api/events/business-events/route.ts (create)
  ~ lib/roi/calculator.ts (add event logging)
  ~ lib/export/reports.ts (add event logging)
  ~ lib/scheduler/tasks.ts (add event logging)
  ~ app/api/auth/** (add event logging)
  ~ app/api/settings/branding/route.ts (add event logging)
  ~ app/api/melissa/** (add event logging)
  ~ app/api/files/upload/route.ts (add event logging)

Blockers/Decisions:
  ? Which events to log? (session, ROI, report, login, branding, melissa, file, task, cleanup)
  ? New model or extend SettingsAuditLog?
  ? How long to retain events?
  ? Batch events for performance?

Dependencies:
  ├─ Requires: Decision on event logging scope
  ├─ Depends on: BusinessEventLog schema design
  ├─ Blocks: Analytics and audit compliance
  └─ Status: Blocked (awaiting scope decision)


✅ COMPLETED DOMAINS
────────────────────────────────────────────────────────────────

🔷 DOMAIN: SETTINGS & PERSISTENCE (9/9 tasks - 100% COMPLETE ✅)
Description: Phase 3 audit logging, filter preferences, cross-tab sync

Completed Tasks:
  [x] Add SettingsAuditLog and LogFilterPreference models
  [x] Create database migration for Phase 3 models
  [x] Implement cross-tab synchronization
  [x] Create API endpoints for audit logging
  [x] Create API endpoints for log filter persistence
  [x] Implement useCustomEventListener hook
  [x] Create Phase 3 validation script (4/4 tests passing)
  [x] Move Claude-generated docs to _build/claude-docs/
  [x] Create /claude-docs-cleanup slash command playbook

Files Modified:
  ✓ prisma/schema.prisma
  ✓ app/api/settings/audit-logs/route.ts
  ✓ app/api/settings/log-filter-preferences/route.ts
  ✓ lib/hooks/useCustomEventListener.ts

Status: All tasks completed in previous phase


🔷 DOMAIN: TEST INFRASTRUCTURE FIXES (6/6 tasks - 100% COMPLETE ✅)
Description: Fix Jest fetch polyfill, localStorage mocking, async handling

Completed Tasks:
  [x] Fix Jest fetch polyfill for Node 18+ compatibility
  [x] Create enhanced localStorage mock factory
  [x] Refactor dashboardLayoutStore.test.ts
  [x] Fix async/await handling in tests
  [x] Reduce unit test failures from 20 → 17
  [x] Achievement: dashboardLayoutStore PASS (5 tests fixed)

Status: All infrastructure issues resolved (Nov 15, 2025)
```

---

## File Status Symbols

- `✓` - File exists
- `✗` - File needs to be created
- `?` - Decision needed before file creation
- `~` - File exists but needs updates

---

## Usage Examples

```bash
# Remember what commands exist
/build-backlog help

# Add tasks quickly (comma-separated)
/build-backlog add Fix session timeout, Create dashboard widget, Update docs

# Update completion status FAST (no Edit tool lag)
/build-backlog update "Cookie XSS Security" "3/3"
/build-backlog update "Business Events" "5/14"

# Check if we've already implemented some tasks (do this first!)
/build-backlog verify

# See tasks grouped by technical domain
/build-backlog organize

# Get quick start context for a task
/build-backlog start continue-session

# Check what blocks what
/build-backlog deps

# See what decisions are needed before building
/build-backlog notes

# Quick view of completion
/build-backlog status

# Find tasks related to something
/build-backlog search session
```

## Pro Tips

1. **Need to add tasks quickly?** → `/build-backlog add task1, task2, task3`
2. **Need to update completion status?** → `/build-backlog update "Category" "X/Y"` (instant, no lag!)
3. **First time reviewing backlog?** → `/build-backlog verify` to see what's already implemented
4. **Quick progress check?** → `/build-backlog status` (fast summary + breakdown)
5. **Forgot what commands exist?** → `/build-backlog help`
6. **Want to start work?** → `/build-backlog organize` then `/build-backlog start [task-name]`
7. **Need to unblock something?** → `/build-backlog notes` to see decisions needed
8. **Looking for related tasks?** → `/build-backlog search [keyword]`

### Fast vs Slow Commands

**Instant** (shell script):
- `update` - Status updates (<1 second, no Edit tool lag)

**Fast** (markdown parsing only):
- `status` - Summary + per-category breakdown
- `search` - Keyword filtering
- `notes` - Show decisions
- `deps` - Show dependencies
- `add` - Parse tasks and append to backlog

**Slower** (filesystem checks):
- `verify` - Scan codebase for implemented features
- `organize` - Check file existence for status markers
- `start` - Check which files exist vs need creation

---

## Notes

- **Mostly read-only**: Only `add` mode modifies the backlog file
- **Smart categorization**: `add` mode auto-categorizes based on keywords
- **File checking**: Marks which files exist, which need creation
- **Enough context**: Just enough info to get started, not a full FRD
- **Safe**: All modes except `add` are non-destructive
- **Simple**: Focus on starting tasks, not detailed planning

---

## Related Commands

- `/claude-docs-cleanup` - Organize documentation
- `npm test` - Run all tests
- `npx prisma studio` - View database
