# Tests

This directory contains all test files for the project.

## Structure

```
__tests__/
├── unit/           # Unit tests for individual functions/components
├── integration/    # Integration tests for combined functionality
├── fixtures/       # Test data and fixtures
├── mocks/          # Mock implementations and stubs
└── setup.ts        # Global test setup
```

## Running Tests

```bash
# Run all tests
pnpm test

# Run tests in watch mode
pnpm test:watch

# Run tests with coverage
pnpm test:coverage

# Run specific test file
pnpm test path/to/test.spec.ts
```

## Naming Conventions

- Unit tests: `*.test.ts` or `*.spec.ts`
- Integration tests: `*.integration.test.ts`
- Test fixtures: `*.fixture.ts`
