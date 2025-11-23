---
id: jest-app-testing-09-mocking-external-services
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

# 09 · External Services & AI

## Vercel AI SDK (`ai` package)
```ts
jest.mock('ai', => ({
 generateText: jest.fn,
}))

import { generateText } from 'ai'
```
- Mock before importing code using the SDK.
- Set resolved values per test case.

```ts
;(generateText as jest.Mock).mockResolvedValue({
 text: JSON.stringify({ question: 'Test?', options: [] }),
 usage: { promptTokens: 400, completionTokens: 120 },
})
```

## Slack / Webhooks
- Use `msw` to intercept POST requests.
- Assert request body inside handler to confirm payload structure.

## Email Providers
- Mock `@/lib/email` modules; assert functions invoked with sanitized content.

## Cost Tracking
- Ensure tests assert telemetry writes when AI calls succeed/fail.
- Example: `expect(logger.info).toHaveBeenCalledWith(expect.objectContaining({ tokens: 600 }))`.

## Prompt Snapshots
- Store under `tests/prompts/__snapshots__`.
- Compare only stable sections (system prompt, guardrails) to avoid brittle completions.

## Error Injection
- Force `generateText` to throw to validate fallback flows (LLM offline, rate limited).
- Provide descriptive error messages so actions can surface user-friendly status.

## Rate Limits
- Mock `429` responses and ensure retry logic engages with exponential backoff.

## Secrets & Config
- Avoid reading real env vars; inject via `process.env.<KEY>` inside test scope.
- Use `afterEach( => delete process.env.<KEY>)` cleanup.

## Telemetry Validation
- Spy on `apm.trackMetric` or `metrics.send` to guarantee usage is recorded.

## JSON Guards
- When AI returns JSON inside triple backticks, strip them before parsing; tests should confirm guard handles formatting variations.
