---
id: jest-app-testing-06-app-router-actions
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

# 06 · App Router Actions

## Testing Server Actions
- Mark file with `@jest-environment node`.
- Import action (`import { submitGoalAction } from '@/app/(app)/actions'`).
- Mock `prisma`, `cookies`, `headers` before invoking action.

```ts
/** @jest-environment node */
import { cookies } from 'next/headers'
import { submitGoalAction } from '@/app/(goals)/actions'

jest.mock('next/headers', => ({ cookies: jest.fn }))
jest.mock('@/lib/prisma')

describe('submitGoalAction', => {
 it('sets persona cookie', async => {
 const cookieStore = new Map
;(cookies as jest.Mock).mockReturnValue({ get: cookieStore.get.bind(cookieStore), set: cookieStore.set.bind(cookieStore) })

 const result = await submitGoalAction({ persona: 'builder' })

 expect(result.success).toBe(true)
 expect(cookieStore.get('this project-persona')).toBe('builder')
 })
})
```

## Revalidation
- Mock `revalidatePath` or `revalidateTag` by injecting jest.fn implementations.
- Assert they are called with correct strings.

## Caching Considerations
- When action writes to caches, ensure tests reset in-memory caches by clearing modules.
- `jest.resetModules` + re-import action if caching logic uses singletons.

## Edge vs Node
- App Router actions currently run on Node runtime by default.
- For Edge-specific modules, add `process.env.NEXT_RUNTIME = 'edge'` before import to mimic environment.

## Error Handling Tests
- Force Prisma or API mocks to throw and assert fallback path returns { success: false }.
- Capture telemetry logs with `jest.spyOn(logger, 'error')`.

## FormData Helpers
```ts
const buildFormData = (values: Record<string, string>) =>
 Object.entries(values).reduce((fd, [key, value]) => {
 fd.append(key, value)
 return fd
 }, new FormData)
```
Use helper to simulate `<form>` submissions inside tests.

## File Uploads
- Use `new File([Buffer.from('content')], 'sample.csv')` to mimic user uploads.
- Ensure `Blob`/`File` polyfills exist (JSDOM 22+ includes them).

## Authentication Context
- When actions rely on session, mock `getServerSession` from `next-auth` or internal auth module.
- Provide deterministic user IDs.

## Logging Assertions
- Wrap logger with spy to verify audit trails: `jest.spyOn(logger, 'info').mockImplementation( => {})`.

## Race Conditions
- Use fake timers or manual Promise control to test concurrency safeguards.
