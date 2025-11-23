---
id: playwright-readme
topic: playwright
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['javascript', 'testing-basics']
related_topics: ['testing', 'e2e', 'automation']
embedding_keywords: [playwright, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Playwright Testing Knowledge Base

Welcome to the comprehensive Playwright testing guide for the this project. This knowledge base contains everything you need to write, run, and debug end-to-end tests for our Next.js + Prisma + SQLite application.

## 📚 Documentation Structure

### 1. **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** ⚡
**For**: Quick lookups while coding
**Contains**:
- Installation commands
- Running tests (5 second reference)
- Locator strategies
- Common actions & assertions
- Basic test structure
- API mocking
- Debugging commands
- framework-specific tips

👉 **Start here for quick answers!**

---

### 2. **[PLAYWRIGHT-COMPREHENSIVE-GUIDE.md](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md)** 📖
**For**: Deep understanding and learning
**Contains**:
- Quick start guide
- Ubuntu system setup & dependencies
- Core concepts (headless, page objects, fixtures)
- Writing effective tests (locator strategy, web-first assertions)
- Configuration deep dive
- Running tests headless
- Performance & parallelization
- Debugging & troubleshooting
- Best practices (12 key practices)
- Common pitfalls & solutions
- Project structure examples
- CI/CD integration (GitHub Actions, Docker)
- Complete reference documentation

**Length**: ~1000+ lines with code examples
**Best for**: Learning Playwright properly

---

### 3. **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** 🌸
**For**: Project-specific testing patterns
**Contains**:
- Testing workshop sessions (creation, resume)
- Testing AI chat functionality (basic, streaming, errors)
- Testing ROI calculations (NPV, confidence, sensitivity)
- Database test isolation (3 solutions explained)
- Session state management (Zustand)
- API mocking strategies
- Performance testing examples
- Common this project test patterns
- framework-specific troubleshooting

**Length**: ~800 lines with framework-specific examples
**Best for**: Working on this project features

---

## 🚀 Getting Started (5 Minutes)

### First Time Setup

```bash
cd /path/to/project

# Install Playwright and browsers
npm install -D @playwright/test
npx playwright install --with-deps

# Verify installation
npx playwright --version
```

### Run Your First Test

```bash
# Start dev server (if not already running)
npm run dev

# Run tests headless (default)
npm run test:e2e

# Or watch mode with UI
npx playwright test --ui
```

### Generate a Test

```bash
# Auto-records your interactions and generates test code
npx playwright codegen http://localhost:3001
```

---

## 📋 Common Tasks

### "I need to write a test"
1. Read: **[QUICK-REFERENCE.md](./QUICK-REFERENCE.md)** - Basic test structure (2 min)
2. Copy-paste example from **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)** (5 min)
3. Customize for your feature (10 min)

### "Tests are hanging or timing out"
1. Check: **[Common Pitfalls & Solutions](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md#common-pitfalls--solutions)** in comprehensive guide
2. For database issues: See **[Database Test Isolation](./FRAMEWORK-INTEGRATION-PATTERNS.md#database-test-isolation)**
3. For framework-specific: See **[Troubleshooting](./FRAMEWORK-INTEGRATION-PATTERNS.md#troubleshooting-framework-specific-issues)**

### "I need to debug a failing test"
1. Run with debugging: `npx playwright test --debug`
2. Or use UI mode: `npx playwright test --ui`
3. Read: **[Debugging & Troubleshooting](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md#debugging--troubleshooting)**

### "Tests pass locally but fail in CI"
1. Check: **[CI/CD Integration](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md#cicd-integration)**
2. Common issue: Database isolation - see **[Database Test Isolation](./FRAMEWORK-INTEGRATION-PATTERNS.md#database-test-isolation)**
3. Common issue: Memory leaks - see **[Performance Testing](./FRAMEWORK-INTEGRATION-PATTERNS.md#performance-testing)**

### "I need to mock an API"
1. Quick examples: **[QUICK-REFERENCE.md - API Mocking](./QUICK-REFERENCE.md#api-mocking--interception)**
2. Detailed patterns: **[API Mocking Strategies](./FRAMEWORK-INTEGRATION-PATTERNS.md#api-mocking-strategies)**

### "Tests are too slow"
1. See: **[Performance & Parallelization](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md#performance--parallelization)**
2. For this project: **[Performance Testing](./FRAMEWORK-INTEGRATION-PATTERNS.md#performance-testing)**

---

## 🎯 Key Principles

### 1. **Use Semantic Locators**
```typescript
// ✅ Good - Resilient to UI changes
page.getByRole('button', { name: 'Submit' })

// ❌ Bad - Brittle
page.locator('div.form > button:nth-child(2)')
```

### 2. **Use Web-First Assertions**
```typescript
// ✅ Good - Auto-waits up to 5 seconds
await expect(element).toBeVisible

// ❌ Bad - Fails immediately if not ready
const visible = await element.isVisible
```

### 3. **Test User Behavior, Not Implementation**
```typescript
// ✅ Good - Tests what users see
test('should show error when email is invalid', async ({ page }) => {
 await page.getByLabel('Email').fill('invalid');
 await expect(page.getByText('Invalid email')).toBeVisible;
});

// ❌ Bad - Tests implementation details
test('should call validateEmail function', async ({ page }) => {
 // Can't test this - it's internal
});
```

### 4. **Keep Tests Isolated**
- Each test must run independently
- Use `beforeEach` to reset state
- Don't depend on test execution order

### 5. **For Database Tests: Use Single Worker**
```bash
# Database tests need sequential execution
npx playwright test --workers=1
```

---

## 📊 Test Status & Reports

After running tests, view results:

```bash
# HTML report
npx playwright test && npx playwright show-report

# Or directly
open _build/test/reports/playwright-html/index.html

# Video/trace artifacts (on failure)
ls -la _build/test/artifacts/test-results/
```

---

## 🔧 Configuration

The this project configuration is in **`playwright.config.ts`**:

```typescript
export default defineConfig({
 testDir: './e2e/specs', // Where tests live
 workers: 1, // IMPORTANT: 1 for database tests
 fullyParallel: false, // Don't run in parallel
 timeout: 30 * 1000, // 30 seconds per test

 webServer: {
 command: 'npm run dev', // Start dev server
 url: 'http://localhost:3001',
 },

 projects: [
 { name: 'chromium',... },
 { name: 'firefox',... },
 ],
});
```

**Key for this project**:
- ⚠️ `workers: 1` - SQLite can't handle parallel writers
- ⚠️ `fullyParallel: false` - Run tests sequentially

---

## 🚨 Known Issues & Workarounds

### Issue 1: Tests Hang (SQLite Lock Contention)

**Cause**: Multiple test workers writing to same SQLite file
**Workaround**: Set `workers: 1` in config
**Fix**: Use per-worker test databases (see guide)

### Issue 2: Memory Leaks in Long Runs

**Cause**: Next.js HMR not cleaning up webpack chunks
**Workaround**: Set memory limit in npm scripts
**Fix**: Upgrade Next.js + implement memory monitoring

### Issue 3: Tests Fail on Linux/Ubuntu

**Cause**: Missing system dependencies
**Fix**: Run `npx playwright install-deps`

### Issue 4: API Requests Don't Mock

**Cause**: Route pattern doesn't match
**Fix**: Use wildcard patterns: `**/api/sessions/**`

---

## 📖 Learning Path

**Beginner** (30 minutes)
1. Read: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
2. Run: `npx playwright codegen http://localhost:3001`
3. Try: Copy example from QUICK-REFERENCE

**Intermediate** (2 hours)
1. Read: [PLAYWRIGHT-COMPREHENSIVE-GUIDE.md](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md) sections 1-5
2. Write: 3-5 tests for a feature
3. Debug: Use `--debug` mode when tests fail

**Advanced** (full guide)
1. Read: Complete [PLAYWRIGHT-COMPREHENSIVE-GUIDE.md](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md)
2. Read: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
3. Implement: Custom fixtures, page objects, CI/CD

**Expert** (production-grade)
1. Implement: All best practices from guides
2. Setup: GitHub Actions CI/CD with reporting
3. Monitor: Performance, flakiness, coverage
4. Maintain: Update tests with application changes

---

## 🎓 External Resources

- **Official Playwright Docs**: https://playwright.dev/docs/intro
- **Playwright API Reference**: https://playwright.dev/docs/api/class-playwright
- **Best Practices**: https://playwright.dev/docs/best-practices
- **Debugging Guide**: https://playwright.dev/docs/debug
- **CI Integration**: https://playwright.dev/docs/ci

---

## 📞 Getting Help

### Test Not Finding Element?
1. Use `--debug` mode: `npx playwright test --debug`
2. Or UI mode: `npx playwright test --ui`
3. Check locator strategy in [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#locators-element-selection)

### Tests Timing Out?
1. See: [Common Pitfalls](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md#common-pitfalls--solutions)
2. For database: [Database Isolation](./FRAMEWORK-INTEGRATION-PATTERNS.md#database-test-isolation)

### Need Framework-Specific Example?
1. Check: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
2. Copy example and customize

### Performance Issues?
1. See: [Performance Testing](./FRAMEWORK-INTEGRATION-PATTERNS.md#performance-testing)
2. Check: Memory limits and worker count

---

## 📋 Maintenance & Updates

**Last Updated**: November 8, 2025
**Playwright Version**: 1.56.1+
**Next.js Version**: 14.2.33+
**Status**: Production-Ready

### Updates Made
- ✅ Comprehensive guide with 1000+ lines
- ✅ framework-specific patterns and examples
- ✅ Quick reference card for developers
- ✅ Ubuntu/Linux system setup guide
- ✅ Database isolation strategies (3 solutions)
- ✅ Troubleshooting guide

### When to Update
- After Playwright major version upgrade
- After Next.js upgrade
- When adding new patterns or best practices
- When discovering new pitfalls

---

## 📄 Files in This Directory

```
docs/kb/playwright/
├── README.md # This file
├── QUICK-REFERENCE.md # Quick lookup card
├── PLAYWRIGHT-COMPREHENSIVE-GUIDE.md # Full reference (1000+ lines)
└── FRAMEWORK-INTEGRATION-PATTERNS.md # this project patterns
```

---

## 🎯 Next Steps

1. **First time?** → Start with [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
2. **Ready to learn deeply?** → Read [PLAYWRIGHT-COMPREHENSIVE-GUIDE.md](./PLAYWRIGHT-COMPREHENSIVE-GUIDE.md)
3. **Working on this project?** → Reference [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
4. **Hit a problem?** → Check the troubleshooting section in the relevant guide

---

**Happy testing! 🎭**

For questions or improvements to this KB, please refer to the main project documentation.
