---
description: Load Backend TypeScript Architect agent for TypeScript/API/database work
---

# TypeScript Backend Architect

Invoke the backend-typescript-architect agent for TypeScript backend development tasks.

## Usage
```
/agent-typescript-architect <your task description>
```

**Shorthand:** Use `/ts` for quick access (same agent)

## What This Does

Launches the **backend-typescript-architect** agent with deep expertise in:

### Core Competencies
- **TypeScript Mastery**: Advanced patterns, strict mode, type safety
- **Next.js 16+**: App Router, async params, server actions
- **Runtimes**: Bun optimization, Node.js best practices
- **API Design**: RESTful endpoints, GraphQL implementation
- **Database**: Prisma ORM, SQLite/PostgreSQL optimization
- **Security**: OWASP guidelines, auth/authorization patterns
- **Testing**: E2E with Playwright, backend API testing, test isolation
- **Architecture**: Microservices, distributed systems, clean architecture

### When to Use

Use `/agent-typescript-architect` (or `/ts`) for backend-focused tasks like:
- Designing or refactoring API endpoints
- Database schema design and migrations
- TypeScript type system improvements
- Performance optimization for backend services
- Security audits and fixes
- Test strategy and implementation
- Build configuration and CI/CD integration

### Agent Profile

**Personality**: Sharp, no-nonsense senior backend engineer
**Code Style**: Self-documenting with strategic comments explaining "why"
**Principles**: SOLID, clean architecture, type safety first
**Focus**: Production-ready, maintainable, well-documented code

## Examples

```bash
# API endpoint design
/agent-typescript-architect Design a new API endpoint for exporting session data to PDF

# Database optimization
/agent-typescript-architect Optimize the Prisma schema for better query performance

# TypeScript fixes
/agent-typescript-architect Fix all TypeScript strict mode errors in the API routes

# Security audit
/agent-typescript-architect Review authentication flow for OWASP compliance

# Testing strategy
/agent-typescript-architect Create E2E tests for the ROI calculation API
```

## Output

The agent will:
1. **Create a TodoWrite list** to track all work items
2. Analyze your requirements and identify edge cases
3. Design the solution using best practices
4. Implement clean, type-safe TypeScript code
5. Add comprehensive error handling
6. Include tests where appropriate
7. **Run `npm run build`** before marking work complete
8. Document the implementation

## Related Commands

- `/quick-test` - Run all quality checks before committing
- `/validate-roi` - Test ROI calculations
- `/test-melissa` - Test Melissa.ai chat interface

## Agent Configuration

- **Dry Run**: Enabled by default (previews changes)
- **Timeout**: 300 seconds
- **Restrictions**: Cannot push directly to main branch
- **Auto-loaded**: This agent is always in context (not on-demand)

## Key Features

### TodoWrite Workflow
The agent uses TodoWrite to track all work items and provide transparency:
- Creates todo list at start of task
- Marks tasks as in_progress/completed throughout
- Updates list if scope changes
- Ensures build validation is never forgotten

### Knowledge Base Access
The agent has deep knowledge of:
- **Playwright Testing**: `docs/kb/playwright/` (2,695 lines)
- **TypeScript Patterns**: `docs/kb/typescript/` (810+ lines)
- **Next.js 16 Patterns**: Async params, route handlers
- **Database Isolation**: Per-worker test databases
- **CI/CD Integration**: GitHub Actions, build validation

### Critical TypeScript Patterns
The agent enforces:
- Next.js 16+ async params pattern (Promise-based)
- Comprehensive API error handling
- TypeScript strict mode compliance
- Test helper factories for maintainability
- Build validation before task completion

---

**Note**: This command invokes the specialized backend-typescript-architect agent from `.claude/agents/backend-typescript-architect.md`

**Shorthand**: Use `/ts` for quicker access to the same agent
