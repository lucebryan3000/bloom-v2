---
id: playwright-index
topic: playwright
file_role: index
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [testing, e2e-testing, browser-automation]
embedding_keywords: [playwright, testing, index, navigation, table-of-contents]
last_reviewed: 2025-11-14
---

# Playwright KB - Table of Contents

## Quick Navigation

### Getting Started
- [README](./README.md) - Overview and usage guide
- [QUICK-REFERENCE](./QUICK-REFERENCE.md) - Cheat sheet for quick lookups
- [01-FUNDAMENTALS](./01-FUNDAMENTALS.md) - Core concepts and mental models

### Core Concepts
- [02-SELECTORS-LOCATORS](./02-SELECTORS-LOCATORS.md) - Finding elements
- [03-INTERACTIONS-ASSERTIONS](./03-INTERACTIONS-ASSERTIONS.md) - Interactions and assertions

### Practical Use Cases
- [04-PAGE-NAVIGATION](./04-PAGE-NAVIGATION.md) - Page navigation and routing
- [05-API-TESTING](./05-API-TESTING.md) - API testing and network mocking
- [06-AUTHENTICATION-STATE](./06-AUTHENTICATION-STATE.md) - Authentication testing
- [07-DATABASE-FIXTURES](./07-DATABASE-FIXTURES.md) - Database and fixtures

### Advanced Topics
- [08-PARALLEL-ISOLATION](./08-PARALLEL-ISOLATION.md) - Parallel execution
- [09-DEBUGGING-TROUBLESHOOTING](./09-DEBUGGING-TROUBLESHOOTING.md) - Debugging
- [10-ADVANCED-PATTERNS](./10-ADVANCED-PATTERNS.md) - Advanced patterns

### Configuration & Operations
- [11-CONFIG-OPERATIONS](./11-CONFIG-OPERATIONS.md) - Configuration, CI/CD
- [FRAMEWORK-INTEGRATION-PATTERNS](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework integrations

## Topic Graph

```
01-FUNDAMENTALS (start here)
    ├── 02-SELECTORS-LOCATORS
    └── 03-INTERACTIONS-ASSERTIONS
        ├── 04-PAGE-NAVIGATION
        ├── 05-API-TESTING
        └── 06-AUTHENTICATION-STATE
            └── 07-DATABASE-FIXTURES
                ├── 08-PARALLEL-ISOLATION
                ├── 09-DEBUGGING-TROUBLESHOOTING
                └── 10-ADVANCED-PATTERNS
                    └── 11-CONFIG-OPERATIONS
```

## By Difficulty Level

### Beginner
- 01-FUNDAMENTALS
- 02-SELECTORS-LOCATORS
- 03-INTERACTIONS-ASSERTIONS
- QUICK-REFERENCE

### Intermediate
- 04-PAGE-NAVIGATION
- 05-API-TESTING
- 06-AUTHENTICATION-STATE
- 07-DATABASE-FIXTURES

### Advanced
- 08-PARALLEL-ISOLATION
- 09-DEBUGGING-TROUBLESHOOTING
- 10-ADVANCED-PATTERNS
- 11-CONFIG-OPERATIONS

## By Use Case

### "I need to test a user flow"
→ 03-INTERACTIONS-ASSERTIONS, 04-PAGE-NAVIGATION

### "I need to test authenticated pages"
→ 06-AUTHENTICATION-STATE, FRAMEWORK-INTEGRATION-PATTERNS

### "My tests are flaky"
→ 09-DEBUGGING-TROUBLESHOOTING, 08-PARALLEL-ISOLATION

### "I need to set up test data"
→ 07-DATABASE-FIXTURES, FRAMEWORK-INTEGRATION-PATTERNS

### "I'm new to Playwright"
→ QUICK-REFERENCE, 01-FUNDAMENTALS, 02-SELECTORS-LOCATORS

## AI Pair Programming Notes

When working with AI assistants:
- Load **QUICK-REFERENCE.md** first for syntax awareness
- Add **01-FUNDAMENTALS.md** for conceptual understanding
- Include specific use-case files (04-07) based on the task
- Reference **FRAMEWORK-INTEGRATION-PATTERNS.md** for Next.js/Prisma specifics

## Last Updated

2025-11-14
