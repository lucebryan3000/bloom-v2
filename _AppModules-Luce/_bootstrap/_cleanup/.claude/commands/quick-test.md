# Quick Test Command

Run all quality checks and tests for the Appmelia Bloom project.

## Usage
```
/quick-test
```

## What This Does

Runs the following checks in sequence:

### 1. TypeScript Type Check
```bash
npm run type-check
```
- Validates all TypeScript types
- No implicit any errors
- Strict null checks pass

### 2. ESLint
```bash
npm run lint
```
- Code style consistency
- Potential bugs
- Best practice violations

### 3. Unit Tests
```bash
npm test -- --passWithNoTests
```
- All unit tests pass
- Component tests
- Utility function tests
- ROI calculation tests

### 4. Build Test
```bash
npm run build
```
- Production build succeeds
- No build-time errors
- All routes compile

## Success Criteria

All checks must pass:
- ✅ 0 TypeScript errors
- ✅ 0 ESLint errors
- ✅ All tests passing
- ✅ Build successful

## Output Format

```
🔍 Running Quick Test Suite...

✅ TypeScript Check: Passed
✅ ESLint: Passed (0 errors, 2 warnings)
✅ Unit Tests: Passed (23/23)
✅ Build: Successful

🎉 All checks passed! Ready to commit.
```

## When to Use

Run this command:
- **Before committing** code
- **After completing** a feature
- **Before creating** a pull request
- **When in doubt** about code quality

## Troubleshooting

If any check fails:
1. Read the error output carefully
2. Fix the reported issues
3. Run `/quick-test` again
4. Repeat until all checks pass

## Related Commands

- `/test-melissa` - Test Melissa.ai chat interface specifically
- `/validate-roi` - Test ROI calculations with sample data
- `/check-progress` - See overall project completion status
