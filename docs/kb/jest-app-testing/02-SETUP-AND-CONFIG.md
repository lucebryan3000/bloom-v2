---
id: jest-app-testing-02-setup-and-config
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

# 02 · Setup & Config

## Toolchain Snapshot (Nov 10, 2025)
- Jest 29.7.0
- `jest-environment-jsdom` 29.7.0
- `@testing-library/react` 16.3.0
- `@testing-library/jest-dom` 6.9.1
- `msw` 2.12.1

## jest.config.cjs Highlights
```js
const nextJest = require('next/jest')
const createJestConfig = nextJest({ dir: './' })

const customJestConfig = {
 setupFilesAfterEnv: ['<rootDir>/jest.setup.js'],
 testEnvironment: 'jest-environment-jsdom',
 moduleNameMapper: { '^@/(.*)$': '<rootDir>/$1' },
 testPathIgnorePatterns: ['<rootDir>/tests/e2e/', '<rootDir>/playwright/'],
 collectCoverageFrom: ['app/**/*.{ts,tsx}', 'lib/**/*.{ts,tsx}', 'components/**/*.{ts,tsx}'],
 coverageThreshold: {
 global: { branches: 70, functions: 70, lines: 80, statements: 80 },
 },
}

module.exports = createJestConfig(customJestConfig)
```

### Why `next/jest`?
- Shares Next.js Babel config + swc settings.
- Loads `.env.test` by default when present.
- Handles CSS modules + image imports.

## Setup File Conventions (`jest.setup.js`)
- Import `@testing-library/jest-dom` first.
- Mock Next.js router + image.
- Provide `global.fetch` fallback.
- Optionally attach `TextEncoder`/`TextDecoder` polyfills.

```ts
import '@testing-library/jest-dom'

jest.mock('next/router', => ({ /*... */ }))

if (!global.fetch) {
 global.fetch = jest.fn
}
```

## Environment Overrides
- Use `/** @jest-environment node */` at file top for server-only specs.
- For experiments, set `process.env.NEXT_RUNTIME = 'nodejs'` or `'edge'` depending on handler under test.

## Running in Watch Mode
- `npm run test:watch -- --runTestsByPath __tests__/components/home/Hero.test.tsx`
- Use `p` filter to narrow by file, `t` to narrow by test name.

## Collecting Coverage Locally
```bash
npm run test:coverage
open coverage/lcov-report/index.html
```
- Add `--collectCoverageFrom` entries when new directories created.

## IDE Tips
- VS Code Jest extension recognizes `next/jest` config automatically.
- Add `"jest.jestCommandLine": "npm test --"` for reproducible runs.

## Troubleshooting Config
| Issue | Fix |
|-------|-----|
| Module not found for `@/` alias | Ensure mapper is defined and TypeScript path alias matches `tsconfig.json`. |
| Tests crash on experimental decorators | Enable `ts-jest` transformer or compile file ahead of time. |
| Memory leak warnings | Run `npx jest --runInBand --detectOpenHandles` to pinpoint handle. |
| ESM module import errors | Add `transformIgnorePatterns` entry or convert module to CJS stub. |
