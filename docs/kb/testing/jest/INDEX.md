---
id: jest-index
topic: jest
file_role: index
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [testing, typescript, react]
embedding_keywords: [jest, testing, index, navigation, table-of-contents]
last_reviewed: 2025-11-14
---

# Jest KB - Table of Contents

## Quick Navigation

### Getting Started
- [README](./README.md) - Overview and usage guide
- [QUICK-REFERENCE](./QUICK-REFERENCE.md) - Cheat sheet for quick lookups
- [01-FUNDAMENTALS](./01-FUNDAMENTALS.md) - Core concepts and mental models

### Core Concepts
- [02-MATCHERS-ASSERTIONS](./02-MATCHERS-ASSERTIONS.md) - Matchers and assertions
- [03-MOCKING-SPIES](./03-MOCKING-SPIES.md) - Mocking, spies, and test doubles

### Practical Use Cases
- [04-ASYNC-TESTING](./04-ASYNC-TESTING.md) - Testing asynchronous code
- [05-REACT-TESTING](./05-REACT-TESTING.md) - React component testing
- [06-API-TESTING](./06-API-TESTING.md) - API route and backend testing
- [07-DATABASE-TESTING](./07-DATABASE-TESTING.md) - Database and Prisma testing

### Advanced Topics
- [08-SNAPSHOT-TESTING](./08-SNAPSHOT-TESTING.md) - Snapshot testing
- [09-PERFORMANCE-OPTIMIZATION](./09-PERFORMANCE-OPTIMIZATION.md) - Test performance
- [10-ADVANCED-PATTERNS](./10-ADVANCED-PATTERNS.md) - Advanced patterns

### Configuration & Operations
- [11-CONFIG-OPERATIONS](./11-CONFIG-OPERATIONS.md) - Configuration, CI/CD, tooling
- [FRAMEWORK-INTEGRATION-PATTERNS](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Framework integrations

## Topic Graph

```
01-FUNDAMENTALS (start here)
    ├── 02-MATCHERS-ASSERTIONS
    ├── 03-MOCKING-SPIES
    └── 04-ASYNC-TESTING
        ├── 05-REACT-TESTING
        ├── 06-API-TESTING
        └── 07-DATABASE-TESTING
            ├── 08-SNAPSHOT-TESTING
            ├── 09-PERFORMANCE-OPTIMIZATION
            └── 10-ADVANCED-PATTERNS
                └── 11-CONFIG-OPERATIONS
```

## By Difficulty Level

### Beginner
- 01-FUNDAMENTALS
- 02-MATCHERS-ASSERTIONS
- QUICK-REFERENCE

### Intermediate
- 03-MOCKING-SPIES
- 04-ASYNC-TESTING
- 05-REACT-TESTING
- 06-API-TESTING

### Advanced
- 07-DATABASE-TESTING
- 08-SNAPSHOT-TESTING
- 09-PERFORMANCE-OPTIMIZATION
- 10-ADVANCED-PATTERNS
- 11-CONFIG-OPERATIONS

## By Use Case

### "I need to test a React component"
→ 05-REACT-TESTING, FRAMEWORK-INTEGRATION-PATTERNS

### "I need to mock an API call"
→ 03-MOCKING-SPIES, 06-API-TESTING

### "My tests are slow"
→ 09-PERFORMANCE-OPTIMIZATION, 11-CONFIG-OPERATIONS

### "I need to test database operations"
→ 07-DATABASE-TESTING, FRAMEWORK-INTEGRATION-PATTERNS

### "I'm new to Jest"
→ QUICK-REFERENCE, 01-FUNDAMENTALS, 02-MATCHERS-ASSERTIONS

## AI Pair Programming Notes

When working with AI assistants:
- Load **QUICK-REFERENCE.md** first for syntax awareness
- Add **01-FUNDAMENTALS.md** for conceptual understanding
- Include specific use-case files (04-07) based on the task
- Reference **FRAMEWORK-INTEGRATION-PATTERNS.md** for Next.js/React/Prisma specifics

## Last Updated

2025-11-14
