---
id: jest-app-testing-11-ci-observability
topic: jest-app-testing
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [jest-app-testing-basics]
related_topics: ['testing', 'javascript', 'unit-tests']
embedding_keywords: [jest-app-testing]
last_reviewed: 2025-11-13
---

# 11 · CI, Coverage & Observability

## GitHub Actions Flow
1. Install dependencies via `npm ci`.
2. Run `npm run lint` + `npm run test:coverage`.
3. Upload coverage artifact + junit report (coming soon).
4. Gate merge if coverage thresholds violated.

## Coverage Management
- HTML report: `coverage/lcov-report/index.html`.
- Trend logs stored per PR under `_build/test/reports/playwright-history.json` (reuse format).
- Use `--coverageReporters=json-summary` to feed dashboards.

## Alerting Hooks
- Pipeline posts Slack alerts when coverage drops >2% from base branch.
- Use `scripts/dev-monitor-v2.js` to gather stats locally.

## Handling Flakes
- Use `jest.retryTimes(2)` sparingly for external-service-heavy specs.
- Record flakes with reproduction steps in `/logs/jest-flakes.md` (create if missing).

## Logging inside Tests
- Wrap logger: `jest.spyOn(logger, 'info').mockImplementation( => {})`.
- Assert logs for critical paths (auditing, compliance events).

## Metrics Validation
- Use `apm.trackMetric` spies for LLM token usage.
- Example: `expect(apm.trackMetric).toHaveBeenCalledWith('llm.tokens', expect.any(Number))`.

## Test Duration Budgets
| Suite | Target |
|-------|--------|
| Unit (`__tests__`) | < 45s |
| Integration (`tests/`) | < 120s |
| Total pipeline | < 3m |

Track durations with `--runInBand --logHeapUsage` when diagnosing slow suites.

## Reporting Format
- Adopt `jest-junit` to produce XML for GitHub checks (TODO).
- Store reports under `test-results/jest/`.

## Observability TODOs
- Add OpenTelemetry spans around LLM mocks to assert instrumentation.
- Emit structured logs for server actions; test ensures log contains `runId` + `playbookId`.

## When to Upgrade Jest
- Monitor release notes for Node 20 compatibility updates.
- Run `npx jest --runInBand` for smoke tests before bumping major versions.
