/// <reference types="vitest" />
import '@testing-library/jest-dom/vitest';
import { beforeAll, afterAll } from 'vitest';

// Global test setup
beforeAll(() => {
  // Setup code that runs before all tests
});

afterAll(() => {
  // Cleanup code that runs after all tests
});

// Mock window.matchMedia for tests that use media queries
Object.defineProperty(window, 'matchMedia', {
  writable: true,
  value: (query: string) => ({
    matches: false,
    media: query,
    onchange: null,
    addListener: () => {},
    removeListener: () => {},
    addEventListener: () => {},
    removeEventListener: () => {},
    dispatchEvent: () => false,
  }),
});
