---
id: playwright-readme
topic: playwright
file_role: overview
profile: full
difficulty_level: beginner-to-advanced
kb_version: 3.1
prerequisites: [javascript-basics, typescript-basics, web-basics]
related_topics: [testing, e2e-testing, browser-automation]
embedding_keywords: [playwright, e2e-testing, browser-testing, end-to-end, automation]
last_reviewed: 2025-11-14
---

# Playwright Testing Framework Knowledge Base

## Overview

This knowledge base provides comprehensive guidance for using Playwright, the modern end-to-end testing framework for web applications. Playwright is used in the Appmelia Bloom project for E2E and integration testing.

## File Map

### Core Files
1. **README.md** (this file) – Overview, file map, usage guidance
2. **INDEX.md** – Table of contents, topic graph, quick navigation
3. **QUICK-REFERENCE.md** – Cheat-sheet style reference for humans + AI

### Numbered Core Files
4. **01-FUNDAMENTALS.md** – Core Playwright concepts, browser automation, mental models
5. **02-SELECTORS-LOCATORS.md** – Selectors, locators, element finding strategies
6. **03-INTERACTIONS-ASSERTIONS.md** – User interactions, assertions, expectations
7. **04-PAGE-NAVIGATION.md** – Page navigation, routing, multi-page scenarios
8. **05-API-TESTING.md** – API testing, network interception, mocking
9. **06-AUTHENTICATION-STATE.md** – Auth testing, session management, cookies
10. **07-DATABASE-FIXTURES.md** – Database setup, test fixtures, data management
11. **08-PARALLEL-ISOLATION.md** – Parallel execution, test isolation, workers
12. **09-DEBUGGING-TROUBLESHOOTING.md** – Debugging tools, trace viewer, troubleshooting
13. **10-ADVANCED-PATTERNS.md** – Advanced patterns, page objects, best practices
14. **11-CONFIG-OPERATIONS.md** – Configuration, CI/CD, reporting
15. **FRAMEWORK-INTEGRATION-PATTERNS.md** – Next.js, React, Prisma integrations

## Target Profile

- **Profile**: Full (~10,000 lines)
- **Audience**: Developers working on the Appmelia Bloom project
- **Difficulty**: Beginner to Advanced

## Using This KB

### For Humans
- Start with **QUICK-REFERENCE.md** for syntax and common patterns
- Read **01-FUNDAMENTALS.md** for core concepts
- Jump to specific use-case files (04-07) for practical examples

### For AI Pair Programmers

#### Bundle 1: Learning/Basic E2E Testing
Load these files together:
- `QUICK-REFERENCE.md`
- `01-FUNDAMENTALS.md`
- `02-SELECTORS-LOCATORS.md`

#### Bundle 2: Full Page Testing
Load these files together:
- `QUICK-REFERENCE.md`
- `03-INTERACTIONS-ASSERTIONS.md`
- `04-PAGE-NAVIGATION.md`

#### Bundle 3: Complex Scenarios
Load these files together:
- `QUICK-REFERENCE.md`
- `05-API-TESTING.md`
- `06-AUTHENTICATION-STATE.md`
- `07-DATABASE-FIXTURES.md`

#### Bundle 4: Debug/Configuration
Load these files together:
- `09-DEBUGGING-TROUBLESHOOTING.md`
- `11-CONFIG-OPERATIONS.md`
- `FRAMEWORK-INTEGRATION-PATTERNS.md`

## Example Prompt Patterns

1. **E2E Test Writing**:
   ```
   Load docs/kb/testing/playwright/QUICK-REFERENCE.md and docs/kb/testing/playwright/03-INTERACTIONS-ASSERTIONS.md.
   Given this context, write E2E tests for this user flow.
   ```

2. **Authentication Testing**:
   ```
   Using the golden path from docs/kb/testing/playwright/06-AUTHENTICATION-STATE.md,
   help me test authenticated user scenarios.
   ```

3. **Configuration Help**:
   ```
   Load docs/kb/testing/playwright/11-CONFIG-OPERATIONS.md.
   How should I configure Playwright for Next.js 16 with per-worker databases?
   ```

## Quality Standards

This KB follows the v3.1 playbook quality rubric:
- **Example Clarity**: Clear, layered examples with explicit labels
- **Explanation Depth**: Deep explanations with trade-offs
- **Navigation Ease**: Excellent INDEX, stable IDs, cross-references
- **Framework Integration**: Thoughtful patterns for Next.js, Prisma
- **Best Practice Coverage**: Strong guidance on patterns and anti-patterns
- **RAG Retrievability**: Tight, single-concept chunks with stable IDs

Target Score: 24/30 minimum

## Last Updated

2025-11-14
