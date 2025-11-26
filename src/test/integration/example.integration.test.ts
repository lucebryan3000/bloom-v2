import { describe, it, expect } from 'vitest';

describe('Example Integration Tests', () => {
  it('should demonstrate integration test structure', () => {
    // Integration tests typically test multiple components together
    const input = { value: 10 };
    const processed = { ...input, doubled: input.value * 2 };

    expect(processed.value).toBe(10);
    expect(processed.doubled).toBe(20);
  });
});
