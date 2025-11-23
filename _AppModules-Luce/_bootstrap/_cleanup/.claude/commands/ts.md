# TypeScript Backend Architect

Invoke the backend-typescript-architect agent for TypeScript backend development tasks.

## Usage
```
/ts <your task description>
```

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

Use `/ts` for backend-focused tasks like:
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
/ts Design a new API endpoint for exporting session data to PDF

# Database optimization
/ts Optimize the Prisma schema for better query performance

# TypeScript fixes
/ts Fix all TypeScript strict mode errors in the API routes

# Security audit
/ts Review authentication flow for OWASP compliance

# Testing strategy
/ts Create E2E tests for the ROI calculation API
```

## Output

The agent will:
1. Analyze your requirements
2. Design the solution using best practices
3. Implement clean, type-safe TypeScript code
4. Add comprehensive error handling
5. Include tests where appropriate
6. Document the implementation

## Related Commands

- `/quick-test` - Run all quality checks before committing
- `/validate-roi` - Test ROI calculations
- `/test-melissa` - Test Melissa.ai chat interface

## Agent Configuration

- **Dry Run**: Enabled by default (previews changes)
- **Timeout**: 300 seconds
- **Restrictions**: Cannot push directly to main branch

---

**Note**: This command invokes the specialized backend-typescript-architect agent from `.claude/agents/backend-typescript-architect.md`
