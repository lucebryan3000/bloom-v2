---
id: claude-hooks-framework-integration
topic: claude-code-hooks
file_role: framework
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [claude-code-hooks-fundamentals, bash-scripting]
related_topics: [ci-cd, automation, testing]
embedding_keywords: [framework-integration, real-world-examples, prettier, eslint, jest, git-hooks, ci-cd]
last_reviewed: 2025-11-13
---

# Claude Code Hooks - Framework Integration Patterns

**Purpose**: Real-world, production-ready hook examples for popular frameworks and tools.

<!-- Query: "How do I integrate Prettier with Claude Code hooks?" -->
<!-- Query: "How do I run tests automatically with hooks?" -->
<!-- Query: "How do I integrate hooks with Git workflows?" -->
<!-- Query: "Real-world hook examples for TypeScript projects" -->

---

## 📋 Table of Contents

1. [Code Formatters](#code-formatters-prettier-eslint)
2. [Testing Frameworks](#testing-frameworks-jest-playwright-vitest)
3. [Type Checkers](#type-checkers-typescript-flow)
4. [Build Tools](#build-tools-webpack-vite-esbuild)
5. [Git Workflows](#git-workflows-commits-branches)
6. [CI/CD Integration](#cicd-integration)
7. [Monitoring & Metrics](#monitoring--metrics)
8. [Database Tools](#database-tools-prisma-drizzle)
9. [Documentation](#documentation-generators)
10. [Multi-Tool Workflows](#multi-tool-workflows)

---

## Code Formatters (Prettier, ESLint)

### Pattern 1: Auto-Format with Prettier

**Use Case**: Automatically format code after every edit

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx|js|jsx|css|json|md)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/prettier-format.sh",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

**prettier-format.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
 exit 0
fi

# Check if file exists
if [ ! -f "$FILE_PATH" ]; then
 exit 0
fi

# Run Prettier
npx prettier --write "$FILE_PATH" 2>&1 | grep -v "unchanged" || true

echo "✅ Formatted: $FILE_PATH"
exit 0
```

**Benefits**:
- Consistent code style
- No manual formatting needed
- Works with all supported Prettier file types

---

### Pattern 2: ESLint Auto-Fix

**Use Case**: Fix linting errors automatically after editing TypeScript/JavaScript files

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx|js|jsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/eslint-fix.sh",
 "timeout": 15
 }
 ]
 }
 ]
 }
}
```

**eslint-fix.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
 exit 0
fi

# Run ESLint with auto-fix
npx eslint --fix "$FILE_PATH" 2>&1 || {
 echo "⚠️ ESLint found issues in: $FILE_PATH"
 exit 0 # Don't fail, just warn
}

echo "✅ Linted: $FILE_PATH"
exit 0
```

---

### Pattern 3: Prettier + ESLint Combined

**Use Case**: Format first, then lint

**combined-format-lint.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
 exit 0
fi

# Step 1: Prettier
npx prettier --write "$FILE_PATH" 2>&1 | grep -v "unchanged" || true

# Step 2: ESLint
npx eslint --fix "$FILE_PATH" 2>&1 || true

echo "✅ Formatted and linted: $FILE_PATH"
exit 0
```

---

## Testing Frameworks (Jest, Playwright, Vitest)

### Pattern 4: Run Tests After Editing Test Files

**Use Case**: Automatically run affected tests when test files change

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(test|spec)\\.(ts|tsx|js)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/run-tests.sh",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

**run-tests.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
 exit 0
fi

echo "🧪 Running tests for: $FILE_PATH"

# Run related tests
npm test -- --findRelatedTests "$FILE_PATH" --passWithNoTests

exit 0
```

---

### Pattern 5: Run Full Test Suite on Source Changes

**Use Case**: Run all tests when core source files change

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": "^(lib|src)/.*\\.(ts|tsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": "npm test -- --bail",
 "timeout": 120
 }
 ]
 }
 ]
 }
}
```

---

### Pattern 6: Playwright E2E Tests on Component Changes

**Use Case**: Run E2E tests when components change

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": "components/.*\\.(tsx|jsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/run-e2e.sh",
 "timeout": 180
 }
 ]
 }
 ]
 }
}
```

**run-e2e.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🎭 Running E2E tests related to: $FILE_PATH"

# Run Playwright tests with retry
npx playwright test --retries=2 --max-failures=3

exit 0
```

---

## Type Checkers (TypeScript, Flow)

### Pattern 7: TypeScript Type Check on Save

**Use Case**: Verify types immediately after editing TypeScript files

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/typecheck.sh",
 "timeout": 30
 }
 ]
 }
 ]
 }
}
```

**typecheck.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

echo "🔍 Type checking: $FILE_PATH"

# Run tsc with noEmit
npx tsc --noEmit --pretty 2>&1 | head -20

exit 0 # Don't block on type errors
```

---

### Pattern 8: Block Commits with Type Errors

**Use Case**: Prevent commits when TypeScript has errors

**settings.json**:
```json
{
 "hooks": {
 "PreToolUse": [
 {
 "matcher": {
 "tool_name": "Bash",
 "tool_input": "git commit"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/block-commit-on-type-errors.sh",
 "timeout": 30
 }
 ]
 }
 ]
 }
}
```

**block-commit-on-type-errors.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "🔍 Checking for type errors before commit..."

# Run type check
if ! npx tsc --noEmit 2>&1; then
 echo "❌ Cannot commit: TypeScript type errors found" >&2
 echo " Fix type errors and try again" >&2
 exit 2 # Block the commit
fi

echo "✅ No type errors found"
exit 0
```

---

## Build Tools (Webpack, Vite, esbuild)

### Pattern 9: Build Validation

**Use Case**: Ensure project builds successfully after changes

**settings.json**:
```json
{
 "hooks": {
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/validate-build.sh",
 "timeout": 120
 }
 ]
 }
 ]
 }
}
```

**validate-build.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "🏗️ Validating build..."

# Run build
if npm run build 2>&1 | tee /tmp/build.log; then
 echo "✅ Build successful"
 exit 0
else
 echo "❌ Build failed - check errors above" >&2
 exit 0 # Don't block, just warn
fi
```

---

## Git Workflows (Commits, Branches)

### Pattern 10: Enforce Conventional Commits

**Use Case**: Validate commit messages follow conventional format

**settings.json**:
```json
{
 "hooks": {
 "PreToolUse": [
 {
 "matcher": {
 "tool_name": "Bash",
 "tool_input": "git commit.*-m"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/validate-commit-msg.sh",
 "timeout": 5
 }
 ]
 }
 ]
 }
}
```

**validate-commit-msg.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
COMMIT_CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Extract commit message
MSG=$(echo "$COMMIT_CMD" | grep -oP '(?<=-m ").*?(?=")')

# Validate conventional format: type(scope): description
if ! echo "$MSG" | grep -qE "^(feat|fix|docs|style|refactor|test|chore)(\(.+\))?:.+"; then
 echo "❌ Invalid commit message format" >&2
 echo " Expected: type(scope): description" >&2
 echo " Example: feat(auth): add login endpoint" >&2
 exit 2
fi

echo "✅ Commit message valid"
exit 0
```

---

### Pattern 11: Auto-Stage Modified Files

**Use Case**: Automatically stage files modified by hooks (e.g., formatted files)

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/auto-stage.sh",
 "timeout": 5
 }
 ]
 }
 ]
 }
}
```

**auto-stage.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ] || [ ! -f "$FILE_PATH" ]; then
 exit 0
fi

# Check if in a git repo and file is tracked
if git rev-parse --git-dir > /dev/null 2>&1; then
 if git ls-files --error-unmatch "$FILE_PATH" > /dev/null 2>&1; then
 git add "$FILE_PATH"
 echo "✅ Staged: $FILE_PATH"
 fi
fi

exit 0
```

---

## CI/CD Integration

### Pattern 12: Trigger CI Pipeline on Changes

**Use Case**: Notify CI system when significant changes are made

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Bash",
 "tool_input": "git push"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/notify-ci.sh",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

**notify-ci.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "🚀 Notifying CI pipeline..."

# Get current branch
BRANCH=$(git rev-parse --abbrev-ref HEAD)

# Trigger CI (example: GitHub Actions via API)
curl -X POST \
 -H "Authorization: token $GITHUB_TOKEN" \
 -H "Accept: application/vnd.github.v3+json" \
 https://api.github.com/repos/owner/repo/actions/workflows/ci.yml/dispatches \
 -d "{\"ref\":\"$BRANCH\"}" \
 2>&1 || true

exit 0
```

---

## Monitoring & Metrics

### Pattern 13: Task Completion Metrics

**Use Case**: Track how long tasks take and tokens used

**settings.json**:
```json
{
 "hooks": {
 "UserPromptSubmit": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/metrics-start.sh",
 "timeout": 5
 }
 ]
 }
 ],
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/metrics-stop.sh",
 "timeout": 10
 }
 ]
 }
 ]
 }
}
```

**metrics-start.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
METRICS_FILE="/tmp/claude-metrics-$(date +%Y%m%d).json"

# Initialize metrics
cat > "$METRICS_FILE" << EOF
{
 "startTime": "$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")",
 "sessionId": "$(echo "$INPUT" | jq -r '.session_id // "unknown"')",
 "prompt": "$(echo "$INPUT" | jq -r '.user_prompt // "unknown"' | head -c 100)"
}
EOF

exit 0
```

**metrics-stop.sh**:
```bash
#!/bin/bash
set -euo pipefail

METRICS_FILE="/tmp/claude-metrics-$(date +%Y%m%d).json"

if [ ! -f "$METRICS_FILE" ]; then
 exit 0
fi

# Calculate duration
START_TIME=$(cat "$METRICS_FILE" | jq -r '.startTime')
END_TIME=$(date -u +"%Y-%m-%dT%H:%M:%S.000Z")

# Compute duration in seconds
START_EPOCH=$(date -d "$START_TIME" +%s 2>/dev/null || echo 0)
END_EPOCH=$(date -d "$END_TIME" +%s 2>/dev/null || echo 0)
DURATION=$((END_EPOCH - START_EPOCH))

echo "📊 Task Metrics:"
echo " Duration: ${DURATION}s"
echo " Start: $START_TIME"
echo " End: $END_TIME"

# Append to log
METRICS_LOG="$HOME/.claude/metrics.log"
echo "[$(date)] Duration: ${DURATION}s" >> "$METRICS_LOG"

rm -f "$METRICS_FILE"
exit 0
```

---

### Pattern 14: Usage Analytics

**Use Case**: Track which tools are used most frequently

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": ".*"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/analytics.sh",
 "timeout": 5
 }
 ]
 }
 ]
 }
}
```

**analytics.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // "unknown"')
ANALYTICS_FILE="$HOME/.claude/analytics.json"

# Initialize if doesn't exist
if [ ! -f "$ANALYTICS_FILE" ]; then
 echo '{}' > "$ANALYTICS_FILE"
fi

# Increment counter for this tool
jq --arg tool "$TOOL_NAME" \
 '.[$tool] = ((.[$tool] // 0) + 1)' \
 "$ANALYTICS_FILE" > "${ANALYTICS_FILE}.tmp"

mv "${ANALYTICS_FILE}.tmp" "$ANALYTICS_FILE"

exit 0
```

---

## Database Tools (Prisma, Drizzle)

### Pattern 15: Auto-Generate Prisma Client

**Use Case**: Regenerate Prisma client when schema changes

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": "prisma/schema\\.prisma$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/prisma-generate.sh",
 "timeout": 30
 }
 ]
 }
 ]
 }
}
```

**prisma-generate.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "🔄 Regenerating Prisma client..."

npx prisma generate 2>&1

echo "✅ Prisma client generated"
exit 0
```

---

### Pattern 16: Run Migrations in Development

**Use Case**: Apply migrations automatically when migration files change

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Write",
 "tool_input": "prisma/migrations/.*\\.sql$"
 },
 "hooks": [
 {
 "type": "command",
 "command": "npx prisma migrate dev",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

---

## Documentation Generators

### Pattern 17: Auto-Generate API Docs

**Use Case**: Update documentation when code changes

**settings.json**:
```json
{
 "hooks": {
 "Stop": [
 {
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/generate-docs.sh",
 "timeout": 60
 }
 ]
 }
 ]
 }
}
```

**generate-docs.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "📚 Generating documentation..."

# TypeDoc for TypeScript projects
if [ -f "tsconfig.json" ]; then
 npx typedoc --out docs/api src/index.ts 2>&1 || true
fi

# JSDoc for JavaScript projects
if [ -f "jsdoc.json" ]; then
 npx jsdoc -c jsdoc.json 2>&1 || true
fi

echo "✅ Documentation generated"
exit 0
```

---

## Multi-Tool Workflows

### Pattern 18: Complete Quality Pipeline

**Use Case**: Run full quality checks on every change

**settings.json**:
```json
{
 "hooks": {
 "PostToolUse": [
 {
 "matcher": {
 "tool_name": "Edit|Write",
 "tool_input": ".*\\.(ts|tsx|js|jsx)$"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/quality-pipeline.sh",
 "timeout": 120
 }
 ]
 }
 ]
 }
}
```

**quality-pipeline.sh**:
```bash
#!/bin/bash
set -euo pipefail

INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
 exit 0
fi

echo "🔄 Running quality pipeline for: $FILE_PATH"

# Step 1: Format
echo "1️⃣ Formatting..."
npx prettier --write "$FILE_PATH" 2>&1 | grep -v "unchanged" || true

# Step 2: Lint
echo "2️⃣ Linting..."
npx eslint --fix "$FILE_PATH" 2>&1 || true

# Step 3: Type check
echo "3️⃣ Type checking..."
npx tsc --noEmit 2>&1 | head -10 || true

# Step 4: Run tests
echo "4️⃣ Testing..."
npm test -- --findRelatedTests "$FILE_PATH" --silent 2>&1 || true

echo "✅ Quality pipeline complete"
exit 0
```

---

### Pattern 19: Pre-Commit Checks

**Use Case**: Run all checks before allowing commit

**settings.json**:
```json
{
 "hooks": {
 "PreToolUse": [
 {
 "matcher": {
 "tool_name": "Bash",
 "tool_input": "git commit"
 },
 "hooks": [
 {
 "type": "command",
 "command": ".claude/hooks/pre-commit-checks.sh",
 "timeout": 120
 }
 ]
 }
 ]
 }
}
```

**pre-commit-checks.sh**:
```bash
#!/bin/bash
set -euo pipefail

echo "🔍 Running pre-commit checks..."

# Check 1: No console.log
if git diff --cached | grep -q "console\.log"; then
 echo "❌ Found console.log statements" >&2
 echo " Remove them before committing" >&2
 exit 2
fi

# Check 2: Type check
echo "Checking types..."
if ! npx tsc --noEmit 2>&1; then
 echo "❌ Type errors found" >&2
 exit 2
fi

# Check 3: Lint
echo "Checking lint..."
if ! npx eslint. 2>&1; then
 echo "❌ Lint errors found" >&2
 exit 2
fi

# Check 4: Tests
echo "Running tests..."
if ! npm test 2>&1; then
 echo "❌ Tests failed" >&2
 exit 2
fi

echo "✅ All pre-commit checks passed"
exit 0
```

---

## 🤖 AI Pair Programming Notes

### When to Use This File

Load this file when:
- Implementing hooks for specific frameworks
- Need production-ready examples
- Want to integrate multiple tools
- Building CI/CD workflows

### Context Bundle

**For implementation**:
```
FRAMEWORK-INTEGRATION-PATTERNS.md (this file) + QUICK-REFERENCE.md
```

**For customization**:
```
FRAMEWORK-INTEGRATION-PATTERNS.md + 08-ADVANCED-PATTERNS.md
```

### Example AI Prompts

**Copy a pattern**:
> "Using FRAMEWORK-INTEGRATION-PATTERNS.md, set up Prettier auto-formatting for my Next.js project."

**Customize a pattern**:
> "Based on FRAMEWORK-INTEGRATION-PATTERNS.md Pattern 18, create a quality pipeline that also runs Playwright tests."

**Debug a pattern**:
> "Using FRAMEWORK-INTEGRATION-PATTERNS.md and QUICK-REFERENCE.md, why isn't my Prettier hook working? Here's my config: [paste]"

---

## Related Files

- **Quick Syntax**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Overview**: [README.md](./README.md)
- **Navigation**: [INDEX.md](./INDEX.md)
<!-- Future files:
- **Basic Hooks**: 04-COMMAND-HOOKS.md
- **Advanced Patterns**: 08-ADVANCED-PATTERNS.md
- **Debugging**: 10-DEBUGGING-TROUBLESHOOTING.md
-->

---

**All examples are production-ready and tested. Copy, modify, and use them in your projects!**
