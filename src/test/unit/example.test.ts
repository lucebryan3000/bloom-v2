import { describe, it, expect } from 'vitest';

describe('Example Unit Tests', () => {
  it('should pass basic assertion', () => {
    expect(1 + 1).toBe(2);
  });

  it('should handle string operations', () => {
    const greeting = 'Hello, World!';
    expect(greeting).toContain('Hello');
  });
});
