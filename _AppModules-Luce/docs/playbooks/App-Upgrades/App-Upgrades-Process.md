# App Upgrades Process Playbook
**Version:** 1.1
**Last Updated:** 2025-11-15
**Purpose:** Interactive dependency upgrade workflow with systematic risk assessment

> **📝 Note:** This playbook references helper scripts in `scripts/` directory. Some scripts are placeholders and need to be created. See [PLAYBOOK-AUDIT-ISSUES.md](PLAYBOOK-AUDIT-ISSUES.md) for implementation status.

---

## Table of Contents

1. [Overview](#overview)
2. [Pre-Upgrade Checklist](#pre-upgrade-checklist)
3. [Phase 1: Discovery & Analysis](#phase-1-discovery--analysis)
4. [Phase 2: Risk Assessment](#phase-2-risk-assessment)
5. [Phase 3: Upgrade Execution](#phase-3-upgrade-execution)
6. [Phase 4: Validation & Testing](#phase-4-validation--testing)
7. [Phase 5: Documentation & Cleanup](#phase-5-documentation--cleanup)
8. [Appendix: Templates](#appendix-templates)

---

## Overview

This playbook guides you through a systematic, risk-based approach to upgrading dependencies in the Bloom application.

### Key Principles

1. **Investigate first, upgrade second** - Never blindly upgrade
2. **Risk-based prioritization** - Patch → Minor → Major
3. **Backward compatibility is critical** - Especially for auth and database
4. **Test before commit** - Build, type-check, and validate
5. **Document everything** - Create upgrade reports for future reference

### Expected Outcomes

- ✅ All dependencies scanned and categorized
- ✅ Risk assessment for each potential upgrade
- ✅ Safe upgrades executed with validation
- ✅ Comprehensive documentation of changes
- ✅ Working application with no regressions

---

## Pre-Upgrade Checklist

**Before starting any upgrade work, verify:**

- [ ] Clean git working directory (`git status` shows no uncommitted changes)
- [ ] Latest code from main branch (`git pull origin main`)
- [ ] No failing tests (`npm test` passes)
- [ ] Application builds successfully (`npm run build`)
- [ ] Type checks pass (`npx tsc --noEmit`)
- [ ] Node/npm versions documented (for rollback)

**Document baseline state:**

```bash
# Create baseline directory and save current versions
mkdir -p _build
node --version > _build/upgrade-baseline-node.txt
npm --version >> _build/upgrade-baseline-node.txt
cp package.json _build/upgrade-baseline-package.json
cp package-lock.json _build/upgrade-baseline-package-lock.json
echo "✅ Baseline saved to _build/"
```

---

## Phase 1: Discovery & Analysis

### Activity 1.1: Scan Current Environment

**Commands:**

```bash
# 1. Check Node version vs latest LTS
node --version
# Compare to: https://nodejs.org/en/about/previous-releases

# 2. Check npm outdated packages
npm outdated > _build/npm-outdated-$(date +%Y%m%d).txt

# 3. Check Dependabot PRs
gh pr list --label dependencies --json number,title,url,state

# 4. Scan top 50 packages for major updates
npm list --depth=0 --json | jq -r '.dependencies | keys[]' | head -50 > _build/top-50-packages.txt
```

**Checklist:**

- [ ] Node version documented (local vs CI vs latest LTS)
- [ ] `npm outdated` output saved
- [ ] Dependabot PRs listed
- [ ] Top 50 packages identified

**Output:** Create `_build/claude-docs/PACKAGE-VERSION-ANALYSIS.md`

---

### Activity 1.2: Categorize Updates by Risk

**Risk Categories:**

| Level | Type | Examples | Priority |
|-------|------|----------|----------|
| **LOW** | Patch (x.y.Z) | 5.90.8 → 5.90.9 | P1 (Do first) |
| **MEDIUM** | Minor (x.Y.0) | 5.85.0 → 5.90.0 | P2 (Review changelog) |
| **HIGH** | Major (X.0.0) | 2.4.3 → 3.0.0 | P3 (Investigate deeply) |
| **CRITICAL** | Auth/DB/Core | bcrypt, prisma, next-auth | P4 (Extra caution) |

**Checklist:**

- [ ] All packages categorized by risk level
- [ ] Critical packages flagged (auth, database, framework)
- [ ] Breaking changes identified from changelogs
- [ ] Node version compatibility checked

**Template:**

```markdown
## Package: bcryptjs

**Current:** 2.4.3
**Latest:** 3.0.3
**Risk Level:** HIGH (Major upgrade for auth library)

**Breaking Changes:**
- Hash version: 2a → 2b (backward compatible)
- ES modules by default
- Built-in TypeScript types

**Compatibility:**
- ✅ Existing hashes still verify
- ✅ API unchanged
- ⚠️ Remove @types/bcryptjs after upgrade

**Decision:** SAFE TO UPGRADE
```

---

## Phase 2: Risk Assessment

### Activity 2.1: Investigate Critical Packages

**For each HIGH/CRITICAL risk package:**

#### **Step 1: Find Usage**

```bash
# Find all imports
grep -r "import.*PACKAGE" --include="*.ts" --include="*.tsx"

# Find all usage patterns
grep -r "PACKAGE\." --include="*.ts" --include="*.tsx" -n
```

#### **Step 2: Review Breaking Changes**

```bash
# Check npm changelog
npm view PACKAGE@LATEST_VERSION --json | jq -r '.version, .homepage'

# Research GitHub releases
# Open browser to: https://github.com/OWNER/REPO/releases
```

#### **Step 3: Assess Impact**

**Questions to answer:**

- [ ] What does this package do in our application?
- [ ] How many files use it?
- [ ] What functions/APIs do we use?
- [ ] Are there breaking changes that affect our usage?
- [ ] Can existing data (hashes, DB records, etc.) still be processed?
- [ ] Do we need migration code?

**Checklist:**

- [ ] All usage locations documented
- [ ] Breaking changes reviewed
- [ ] Backward compatibility assessed
- [ ] Migration needs identified
- [ ] Decision documented (upgrade/defer/reject)

---

### Activity 2.2: Create Investigation Report

**For each package, create a decision document:**

**Template:** `_build/claude-docs/PR-{NUMBER}-{PACKAGE}-DECISION.md`

```markdown
# PR #{NUMBER}: {PACKAGE} Upgrade Decision

## Summary
**Package:** {package-name}
**Current:** {current-version}
**Proposed:** {new-version}
**Risk Level:** {LOW|MEDIUM|HIGH|CRITICAL}

## Breaking Changes
1. {Breaking change 1}
2. {Breaking change 2}

## Usage Analysis
**Locations:**
- `{file1}:{line}` - {what it does}
- `{file2}:{line}` - {what it does}

**APIs Used:**
- `{api1}()` - {purpose}
- `{api2}()` - {purpose}

## Compatibility Assessment
- ✅/❌ API compatibility
- ✅/❌ Backward compatibility (data/hashes/DB)
- ✅/❌ TypeScript compatibility
- ✅/❌ Node version compatibility

## Migration Required
- [ ] Code changes needed
- [ ] Database migration needed
- [ ] Config updates needed
- [ ] Type definition changes needed

## Decision
**Status:** APPROVE | DEFER | REJECT
**Reason:** {explanation}

## Next Steps
- [ ] {Action 1}
- [ ] {Action 2}
```

**Checklist:**

- [ ] Decision document created for each HIGH/CRITICAL package
- [ ] All questions answered with evidence
- [ ] Clear decision made (approve/defer/reject)
- [ ] User consulted for ambiguous decisions

---

## Phase 3: Upgrade Execution

### Activity 3.1: Prioritize Upgrades

**Execution order:**

1. **Quick Wins** - Patch updates (LOW risk)
2. **Minor Updates** - After changelog review (MEDIUM risk)
3. **Major Updates** - One at a time (HIGH risk)
4. **Framework Updates** - Last, after everything else (Next.js, React, etc.)

**Checklist:**

- [ ] Upgrades sorted by priority
- [ ] Dependencies grouped (upgrade related packages together)
- [ ] User approves the upgrade plan

---

### Activity 3.2: Execute Upgrades in Batches

**For each batch of upgrades:**

#### **Batch Template:**

```markdown
## Batch: {Batch Name}
**Date:** {date}
**Packages:**
- {package1}: {old} → {new}
- {package2}: {old} → {new}

**Risk Level:** {LOW|MEDIUM|HIGH}
**Expected Duration:** {time estimate}
```

#### **Execution Steps:**

```bash
# 1. Create upgrade branch (optional, for large changes)
git checkout -b upgrade/{batch-name}

# 2. Update package.json
npm install PACKAGE@VERSION --save
# or
npm install PACKAGE@VERSION --save-dev

# 3. Handle related packages (example: Jest family)
npm install jest@30.2.0 @types/jest@30.0.0 @jest/globals@30.2.0 jest-environment-jsdom@30.2.0

# 4. Regenerate lockfile if needed
rm package-lock.json node_modules -rf
npm install

# 5. Verify integrity
npm ci
```

**Checklist:**

- [ ] `package.json` updated
- [ ] `package-lock.json` synchronized
- [ ] `npm ci` completes successfully
- [ ] No unexpected package additions/removals (review `npm install` output)

---

### Activity 3.3: Handle Breaking Changes

**Common scenarios:**

#### **Scenario 1: Remove conflicting type definitions**

```bash
# Example: bcryptjs v3 has built-in types
npm uninstall @types/PACKAGE
```

#### **Scenario 2: Migrate deprecated APIs**

```typescript
// Example: web-vitals v4 → v5
// BEFORE:
import { onFID } from "web-vitals";
onFID((metric) => collect(metric));

// AFTER:
import { onINP } from "web-vitals";
onINP((metric) => collect(metric));
```

#### **Scenario 3: Update configuration**

```typescript
// Example: Next.js 14 → 16 async params
// BEFORE:
export async function GET(req, { params }) {
  const { id } = params;
}

// AFTER:
export async function GET(req, { params }) {
  const { id } = await params;
}
```

**Checklist:**

- [ ] All breaking changes handled
- [ ] Deprecated APIs migrated
- [ ] Config files updated
- [ ] Code changes documented

---

## Phase 4: Validation & Testing

### Activity 4.1: Build Validation

**Run in this order:**

```bash
# 1. Type check (catches most issues)
npx tsc --noEmit

# 2. Linting
npm run lint

# 3. Production build
npm run build
```

**Success Criteria:**

- [ ] ✅ Type check: 0 errors
- [ ] ✅ Lint: 0 errors (warnings acceptable if pre-existing)
- [ ] ✅ Build: Completes successfully
- [ ] ✅ Build time: Within 10% of baseline
- [ ] ✅ Bundle size: Within 10% of baseline

**If errors occur:**

1. **TypeScript errors:**
   - Unused variables: Remove or prefix with `_`
   - Type conflicts: Check for duplicate type definitions
   - API changes: Review package changelog

2. **Build errors:**
   - Module resolution: Check import paths
   - Missing dependencies: `npm install` again
   - Config issues: Review next.config.js, tsconfig.json

---

### Activity 4.2: Automated Testing

**Run test suites:**

```bash
# 1. Unit tests
npm run test:unit

# 2. Integration tests
npm run test:integration

# 3. E2E tests (if applicable)
npm run test:e2e

# 4. Coverage check
npm run test:coverage
```

**Success Criteria:**

- [ ] ✅ All tests pass (or same failures as baseline)
- [ ] ✅ No new test failures introduced
- [ ] ✅ Code coverage maintained (within 2% of baseline)

**Document pre-existing failures:**

```markdown
## Pre-Existing Test Failures (Not caused by upgrades)

1. **Test:** Health check API returns empty object
   - **File:** tests/integration/api-health.spec.ts
   - **Status:** Known issue, tracked in #{issue-number}

2. **Test:** Session creation sessionId undefined
   - **File:** tests/integration/api-sessions.spec.ts
   - **Status:** Deferred, outside upgrade scope
```

---

### Activity 4.3: Package-Specific Testing

**For critical packages, run focused tests:**

#### **Authentication (bcrypt, next-auth):**

```bash
# Test password hashing (single-line for copy/paste compatibility)
node -e "const bcrypt = require('bcryptjs'); const password = 'test123'; const hash = bcrypt.hashSync(password, 10); console.log('Hash created:', hash.substring(0, 10) + '...'); const valid = bcrypt.compareSync(password, hash); console.log('Verification:', valid ? 'PASS ✅' : 'FAIL ❌');"

# Or use the helper script (recommended):
# node scripts/test-bcrypt.js

# Test login flow manually:
# 1. Start dev server: npm run dev
# 2. Register new user
# 3. Login with new user
# 4. Login with existing user (tests backward compat)
```

**Checklist:**

- [ ] Password hashing works
- [ ] Password verification works
- [ ] Existing user login works (backward compat)
- [ ] New user registration works

#### **Database (Prisma):**

```bash
# Generate Prisma client
npx prisma generate

# Test migrations
npx prisma migrate status

# Test database connection (single-line for copy/paste compatibility)
node -e "const { PrismaClient } = require('@prisma/client'); const prisma = new PrismaClient(); prisma.organization.count().then(count => { console.log('Organizations:', count); process.exit(0); }).catch(err => { console.error('DB Error:', err); process.exit(1); });"

# Or use the helper script (recommended):
# node scripts/test-prisma.js
```

**Checklist:**

- [ ] Prisma client generates
- [ ] Database connects
- [ ] Queries execute
- [ ] Migrations status clean

#### **API Framework (Next.js, React):**

```bash
# Start dev server and check for errors
npm run dev

# Check for:
# 1. Server starts without errors
# 2. Routes load correctly
# 3. No console errors in terminal
# 4. Hot reload works
# 5. API endpoints respond
```

**Checklist:**

- [ ] Dev server starts
- [ ] Pages render
- [ ] API routes respond
- [ ] No runtime errors in console

---

### Activity 4.4: Security Audit

```bash
# Run npm audit
npm audit

# Generate audit report
npm audit --json > _build/npm-audit-$(date +%Y%m%d).json
```

**Success Criteria:**

- [ ] ✅ No NEW critical/high vulnerabilities introduced
- [ ] ✅ Existing vulnerabilities documented (if acceptable)
- [ ] ✅ Audit report saved for comparison

**Vulnerability Assessment:**

| Severity | Action |
|----------|--------|
| **Critical** | MUST fix immediately or rollback |
| **High** | Investigate mitigation or plan fix |
| **Moderate** | Document, plan fix in next sprint |
| **Low** | Document, acceptable if no fix available |

---

## Phase 5: Documentation & Cleanup

### Activity 5.1: Create Upgrade Report

**Template:** `_build/claude-docs/DEPENDENCY-UPGRADES-{DATE}.md`

```markdown
# Dependency Upgrades - {Date}
**Status:** ✅ Complete | 🚧 In Progress | ❌ Rolled Back

## Summary

Successfully upgraded {N} packages:
- {N} patch updates
- {N} minor updates
- {N} major updates

## Packages Upgraded

### 1. {Package Name}: {old} → {new}
**Type:** Patch | Minor | Major
**Risk:** Low | Medium | High
**Breaking Changes:**
- {Change 1}
- {Change 2}

**Migration:**
- {Action 1}
- {Action 2}

**Validation:**
- ✅ Type check passed
- ✅ Build successful
- ✅ Tests passing

---

## Validation Results

### Build Performance
- **Build time:** {X}s (baseline: {Y}s)
- **Routes generated:** {N}
- **Bundle size:** {X}KB

### Type Safety
- **Errors:** 0
- **Warnings:** {N}

### Testing
- **Unit tests:** ✅ {X}/{Y} passed
- **Integration tests:** ✅ {X}/{Y} passed
- **E2E tests:** ⏳ Deferred

### Security Audit
- **Critical:** 0
- **High:** 0
- **Moderate:** {N}
- **Low:** {N}

## Breaking Changes Summary

| Package | Change | Migration | Status |
|---------|--------|-----------|--------|
| {pkg1} | {change1} | {action1} | ✅ |
| {pkg2} | {change2} | {action2} | ✅ |

## Git History

**Commits:**
```
{commit1} {message1}
{commit2} {message2}
```

**PRs Merged:**
- #{N}: {title}

## Pre-Existing Issues (Not Related to Upgrades)

1. {Issue 1}
2. {Issue 2}

## Next Steps

### Immediate
- [ ] {Action 1}
- [ ] {Action 2}

### Future
- [ ] {Deferred upgrade 1}
- [ ] {Deferred upgrade 2}

---

**Completed by:** {Your name}
**Date:** {Date}
**Session:** {Session description}
```

**Checklist:**

- [ ] Upgrade report created
- [ ] All packages documented
- [ ] Validation results included
- [ ] Next steps identified

---

### Activity 5.2: Commit & Push Changes

**Commit strategy:**

#### **Option A: Single atomic commit** (for small batches)

```bash
git add package.json package-lock.json
git add {modified-files}
git commit -m "feat: upgrade {N} dependencies

- {package1}: {old} → {new}
- {package2}: {old} → {new}
- {package3}: {old} → {new}

Breaking changes handled:
- {change1}
- {change2}

Validation:
- Type check: PASS
- Build: PASS
- Tests: PASS

See: _build/claude-docs/DEPENDENCY-UPGRADES-{DATE}.md"
```

#### **Option B: Multiple commits** (for large batches)

```bash
# Commit 1: Package updates
git add package.json package-lock.json
git commit -m "feat: upgrade core dependencies"

# Commit 2: Breaking change migrations
git add {migration-files}
git commit -m "feat(auth): migrate bcrypt from FID to INP"

# Commit 3: Cleanup
git add {cleanup-files}
git commit -m "fix: clean up TypeScript warnings and regenerate lockfile"

# Commit 4: Documentation
git add _build/claude-docs/
git commit -m "docs: add dependency upgrade completion summary"
```

**Checklist:**

- [ ] All changes committed
- [ ] Commit messages follow conventional commits
- [ ] Documentation committed
- [ ] Pushed to origin

---

### Activity 5.3: Post-Upgrade Monitoring

**After deployment, monitor for:**

```bash
# 1. Check application logs for new errors
npm run logs:tail

# 2. Filter for errors
npm run logs:errors

# 3. Monitor specific functionality
# - User registration
# - User login
# - API endpoints
# - Database queries
```

**Monitoring checklist (24-48 hours post-deployment):**

- [ ] No new error spikes in logs
- [ ] Authentication working (login/register)
- [ ] API response times stable
- [ ] Database queries performing well
- [ ] No user-reported issues

---

## Appendix: Templates

### Template: Package Investigation Checklist

**Package:** ___________________
**Current Version:** ___________________
**Target Version:** ___________________

**Investigation:**

- [ ] Usage locations found (grep search)
- [ ] APIs used documented
- [ ] Changelog reviewed
- [ ] Breaking changes identified
- [ ] Backward compatibility assessed
- [ ] Migration needs identified

**Decision:**

- [ ] APPROVE - Safe to upgrade
- [ ] DEFER - Needs more investigation
- [ ] REJECT - Too risky or not needed

**Notes:**
___________________________________________
___________________________________________

---

### Template: Validation Checklist

**Upgrade:** ___________________

**Pre-Validation:**

- [ ] Clean git status
- [ ] Baseline documented

**Code Validation:**

- [ ] `npx tsc --noEmit` - 0 errors
- [ ] `npm run lint` - 0 errors
- [ ] `npm run build` - Success
- [ ] Build time: _____s (baseline: _____s)

**Testing:**

- [ ] Unit tests: _____/_____  passed
- [ ] Integration tests: _____/_____ passed
- [ ] E2E tests: _____/_____ passed
- [ ] Coverage: _____%  (baseline: ____%)

**Security:**

- [ ] `npm audit` - No new critical/high
- [ ] Audit report saved

**Package-Specific:**

- [ ] {Specific test 1}
- [ ] {Specific test 2}

**Sign-off:**

- [ ] All checks passed
- [ ] Ready to commit

---

### Template: Rollback Plan

**If validation fails, rollback procedure:**

```bash
# Option 1: Git reset (if not pushed)
git reset --hard HEAD~1

# Option 2: Restore baseline (if pushed)
cp _build/upgrade-baseline-package.json package.json
cp _build/upgrade-baseline-package-lock.json package-lock.json
rm -rf node_modules
npm ci

# Option 3: Revert commit (if pushed and public)
git revert {commit-hash}
git push origin main
```

**Rollback checklist:**

- [ ] Codebase restored
- [ ] Dependencies reinstalled
- [ ] Build validated
- [ ] Tests pass
- [ ] Document why rollback was needed

---

### Template: Decision Matrix

Use this to decide upgrade priority:

| Factor | Score (1-5) | Weight | Weighted |
|--------|-------------|--------|----------|
| Security vulnerability fix | ___ | 5 | ___ |
| Bug fixes included | ___ | 4 | ___ |
| New features needed | ___ | 3 | ___ |
| Performance improvements | ___ | 3 | ___ |
| Breaking changes (inverse) | ___ | 4 | ___ |
| Migration effort (inverse) | ___ | 3 | ___ |
| **TOTAL** | | | **___** |

**Decision:**
- **Score > 60:** High priority (do first)
- **Score 40-60:** Medium priority (do after high)
- **Score < 40:** Low priority (defer or skip)

---

## Common Patterns & Solutions

### Pattern 1: TypeScript Unused Variable Errors

**Error:** `'variable' is declared but its value is never read`

**Solutions:**

```typescript
// Solution 1: Remove if truly unused
// const unused = value; // DELETE THIS

// Solution 2: Prefix with underscore if intentionally unused
const _type = value; // Indicates intentional

// Solution 3: Consume without storing
await response.json(); // Instead of: const data = await response.json()

// Solution 4: Comment out if might be used later
// type RestoreRequest = z.infer<typeof Schema>; // Currently unused
```

---

### Pattern 2: Package Lock Sync Issues

**Error:** `Missing: package@version from lock file`

**Solution:**

```bash
# Full regeneration
rm package-lock.json node_modules -rf
npm install
npm ci # Verify integrity
```

---

### Pattern 3: Type Definition Conflicts

**Error:** `Duplicate identifier` or type conflicts

**Solution:**

```bash
# Check for conflicting @types packages
npm list | grep @types

# Remove conflicting types when package has built-in types
npm uninstall @types/PACKAGE

# Example:
npm uninstall @types/bcryptjs # bcryptjs v3 has built-in types
```

---

### Pattern 4: Breaking API Changes

**Example:** web-vitals onFID → onINP

**Process:**

1. **Find all usage:**
   ```bash
   grep -r "onFID" --include="*.ts" --include="*.tsx"
   ```

2. **Review replacement API:**
   - Read migration guide
   - Check types/parameters
   - Verify behavior equivalence

3. **Update code:**
   ```typescript
   // Old:
   import { onFID } from "web-vitals";
   onFID((metric) => track(metric));

   // New:
   import { onINP } from "web-vitals";
   onINP((metric) => track(metric));
   ```

4. **Test:**
   - Type check passes
   - Build succeeds
   - Functionality verified

---

## FAQ

### Q: Should I update everything at once?

**A:** No. Use risk-based batching:
- Batch 1: Patch updates (low risk)
- Batch 2: Minor updates (medium risk)
- Batch 3: Major updates, one at a time (high risk)

---

### Q: What if CI uses different Node version than local?

**A:** Document both, but prioritize CI environment:
- CI version determines production compatibility
- Local version is developer preference
- Type definitions should match CI version

Example:
- CI: Node 20 → Use `@types/node@20.x`
- Local: Node 22 → Personal setup, not a blocker

---

### Q: Can I skip testing if it's just a patch update?

**A:** Never skip build validation. Testing depends on risk:
- **Always:** Type check + build
- **Patch updates:** Basic smoke test
- **Minor/major:** Full test suite

---

### Q: What if existing tests are failing?

**A:** Document pre-existing failures separately:

```markdown
## Pre-Existing Test Failures (Not caused by upgrades)
1. Test X - Known issue, tracked in #123
2. Test Y - Deferred, outside scope

## New Failures (Caused by upgrade)
*None* ✅
```

---

### Q: How do I know if backward compatibility is maintained?

**A:** For critical packages (auth, database):

1. **Read changelog:** Look for "BREAKING" or "backward compatible"
2. **Test with existing data:**
   - Auth: Login with existing user
   - Database: Query existing records
3. **Check package tests:** Often include compat tests
4. **Ask in investigation:** "Can existing {hashes/records/etc} still be processed?"

---

### Q: When should I defer an upgrade?

**A:** Defer if:
- Breaking changes require major refactoring
- Migration path is unclear
- Testing infrastructure is inadequate
- Time constraints don't allow proper validation
- Package is deprecated (consider alternative)

**Always explain why in the decision document.**

---

### Q: What's the difference between `npm install` and `npm ci`?

**A:**

- `npm install`: Updates `package-lock.json` if needed
- `npm ci`: Installs exactly what's in `package-lock.json` (fails if out of sync)

**Use:**
- `npm install PACKAGE@VERSION`: To upgrade
- `npm ci`: To validate lockfile integrity

---

## Lessons Learned (From 2025-11-15 Session)

### 1. Always check if packages are already up-to-date

**What happened:** Spent time planning Prisma + React Query upgrades, but they were already on latest versions.

**Lesson:** Run `npm outdated` and check dist-tags BEFORE creating upgrade plans.

```bash
# Quick check
npm view PACKAGE dist-tags
```

---

### 2. Investigate usage before making decisions

**What happened:** Initially thought web-vitals was "not used" because no direct imports found. Deeper search found it was actively used in performance monitoring hook.

**Lesson:** Use comprehensive grep patterns:

```bash
# Not just direct imports
grep -r "import.*PACKAGE"

# Also check usage
grep -r "PACKAGE\." -n

# Check type imports
grep -r "from ['\"]PACKAGE['\"]"
```

---

### 3. Backward compatibility is key for auth/database

**What happened:** bcrypt v3 changes hash format from 2a → 2b, but maintains backward compatibility for verification.

**Lesson:** For critical packages, explicitly verify:
- "Can existing data be processed with new version?"
- "Do existing users need migration?"
- "Is there a rollback path?"

---

### 4. TypeScript errors block builds

**What happened:** Production build failed with unused variable errors after upgrades.

**Lesson:** Run `npx tsc --noEmit` BEFORE committing. Catches 90% of issues IDE misses.

---

### 5. Document pre-existing issues separately

**What happened:** Test failures existed before upgrades but could be confused with new issues.

**Lesson:** Always document:
```markdown
## Pre-Existing Issues (Not caused by upgrades)
1. Health check returns empty object
2. Session creation sessionId undefined

**Status:** Deferred, outside scope
```

---

### 6. Type definitions can conflict

**What happened:** Packages now ship built-in TypeScript types, conflicting with separate `@types/*` packages.

**Lesson:** When upgrading to v3+, check if `@types/PACKAGE` should be removed.

---

### 7. Git merge conflicts are expected

**What happened:** Merging Dependabot PR after local changes caused package.json conflicts.

**Lesson:** Commit local changes first, then pull/merge. Git's ort strategy usually auto-resolves package updates cleanly.

---

## Success Metrics

Track these metrics for each upgrade session:

| Metric | Target | Actual |
|--------|--------|--------|
| Packages upgraded | ___ | ___ |
| Breaking changes handled | ___ | ___ |
| Build time change | < 10% | ___% |
| Test failures introduced | 0 | ___ |
| Security vulnerabilities fixed | ___ | ___ |
| Time to completion | ___ | ___ hours |

---

## Revision History

| Version | Date | Changes | Author |
|---------|------|---------|--------|
| 1.1 | 2025-11-15 | Fixed blocking issues: baseline directory creation, multi-line Node.js commands | Claude |
| 1.0 | 2025-11-15 | Initial playbook creation based on Nov 15 upgrade session | Claude |

---

**End of Playbook**

*For questions or improvements, create an issue or update this playbook directly.*
