---
id: anthropic-sdk-typescript-readme
topic: anthropic-sdk-typescript
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Knowledge Base

**SDK Version:** @anthropic-ai/sdk 0.27.3
**Last Updated:** November 13, 2025
**Claude Model:** claude-sonnet-4-5-20250929

---

## Overview

This knowledge base provides comprehensive documentation for using the Anthropic TypeScript SDK in production applications. It covers installation, configuration, best practices, and integration patterns for building AI-powered features with Claude.

## Purpose

The Anthropic SDK enables developers to integrate Claude AI into their applications. This KB ensures consistent, type-safe, and performant usage of Claude's capabilities with complete TypeScript support.

---

## Contents

### Core Documentation

1. **[Quick Reference](QUICK-REFERENCE.md)** - Fast lookup for common patterns
2. **[Comprehensive Guide](COMPREHENSIVE-GUIDE.md)** - Deep dive technical reference (all topics)
3. **[Integration Patterns](FRAMEWORK-INTEGRATION-PATTERNS.md)** - Real-world production implementation examples
4. **[Installation & Setup](01-INSTALLATION-SETUP.md)** - Getting started
5. **[Messages API](02-MESSAGES-API.md)** - Core conversation patterns
6. **[Streaming Responses](03-STREAMING.md)** - Real-time AI streaming
7. **[Error Handling](04-ERROR-HANDLING.md)** - Production-grade error management
8. **[Prompt Engineering](05-PROMPT-ENGINEERING.md)** - Effective prompt patterns
9. **[Rate Limiting](06-RATE-LIMITING.md)** - Quota management and retries
10. **[Token Management](07-TOKEN-MANAGEMENT.md)** - Cost optimization

### Planned Topics (Coming Soon)

- **Tool Use** - Function calling with Claude
- **Testing** - Unit and integration testing patterns
- **Batch Processing** - Batch API for bulk operations
- **Prompt Caching** - Reduce costs with caching
- **Production Checklist** - Deployment best practices

---

## Quick Start

### Installation

```bash
npm install @anthropic-ai/sdk
```

### Basic Setup

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});

const message = await client.messages.create({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 messages: [{ role: 'user', content: 'Hello, Claude!' }],
});

console.log(message.content);
```

---

## Key Features

### ✅ Type Safety

Full TypeScript support with complete type definitions:

```typescript
import type {
 MessageCreateParams,
 Message,
 ContentBlock,
 TextBlock
} from '@anthropic-ai/sdk/resources';
```

### ✅ Streaming Support

Real-time responses with Server-Sent Events:

```typescript
const stream = await client.messages.create({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 messages: [{ role: 'user', content: 'Write a story' }],
 stream: true,
});

for await (const event of stream) {
 if (event.type === 'content_block_delta') {
 process.stdout.write(event.delta.text);
 }
}
```

### ✅ Token Usage Tracking

Built-in cost monitoring:

```typescript
const message = await client.messages.create({...});

console.log(message.usage);
// { input_tokens: 25, output_tokens: 150 }
```

### ✅ Error Handling

Structured error types for all failure cases:

```typescript
try {
 await client.messages.create({...});
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 console.error(`API Error ${error.status}: ${error.message}`);
 }
}
```

---

## Typical Architecture

### Component Hierarchy

```
Chat Interface (UI)
 ↓
API Route Handler (Next.js/Express)
 ↓
AI Agent (Business Logic)
 ↓
Anthropic SDK (AI Integration)
 ↓
Claude API (Anthropic Cloud)
```

### Common Integration Points

| Component | Purpose | Example Location |
|-----------|---------|------------------|
| **Chat Route** | API endpoint for user messages | `app/api/chat/route.ts` |
| **AI Agent** | Conversation orchestration | `lib/ai/agent.ts` |
| **Configuration** | System prompts and settings | `lib/ai/config.ts` |
| **Message Store** | Conversation persistence | `lib/db/messages.ts` |

---

## Best Practices at a Glance

### ✅ DO

- **Use environment variables** for API keys (never hardcode)
- **Validate inputs** with Zod before sending to Claude
- **Implement retry logic** for transient failures (429, 529)
- **Cache system prompts** to reduce costs
- **Monitor token usage** to stay within budgets
- **Use streaming** for better UX on long responses
- **Type all responses** with TypeScript interfaces

### ❌ DON'T

- **Never expose API keys** in client-side code
- **Don't ignore rate limits** - implement exponential backoff
- **Don't send PII** without user consent and proper handling
- **Don't exceed context windows** (200K tokens for Sonnet 4.5)
- **Don't skip error handling** - always catch API errors
- **Don't use `any` types** - leverage full type safety

---

## Environment Configuration

### Required Environment Variables

```bash
#.env.local
ANTHROPIC_API_KEY=sk-ant-api03-xxxxx

# Optional: Override default settings
ANTHROPIC_MAX_TOKENS=4096
ANTHROPIC_MODEL=claude-sonnet-4-5-20250929
ANTHROPIC_TEMPERATURE=1.0
```

### TypeScript Configuration

```json
// tsconfig.json
{
 "compilerOptions": {
 "strict": true,
 "esModuleInterop": true,
 "moduleResolution": "node"
 }
}
```

---

## Common Patterns

### 1. Simple Message

```typescript
const message = await client.messages.create({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 messages: [{ role: 'user', content: 'What is ROI?' }],
});
```

### 2. Conversation with History

```typescript
const messages = [
 { role: 'user', content: 'Hello' },
 { role: 'assistant', content: 'Hi! How can I help?' },
 { role: 'user', content: 'Tell me about ROI' },
];

const response = await client.messages.create({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 messages,
});
```

### 3. System Prompt

```typescript
const message = await client.messages.create({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 system: 'You are an AI assistant.',
 messages: [{ role: 'user', content: 'Calculate ROI' }],
});
```

### 4. Streaming Response

```typescript
const stream = client.messages.stream({
 model: 'claude-sonnet-4-5-20250929',
 max_tokens: 1024,
 messages: [{ role: 'user', content: 'Write a report' }],
});

stream.on('text', (text) => {
 process.stdout.write(text);
});

const finalMessage = await stream.finalMessage;
```

---

## Performance Considerations

### Token Optimization

- **Prompt Caching**: Cache repeated system prompts (saves 90% on input tokens)
- **Context Management**: Only send relevant conversation history
- **Response Length**: Use `max_tokens` to control output length

### Rate Limits (Standard Tier)

| Metric | Sonnet 4.5 | Haiku 4.5 |
|--------|------------|-----------|
| **Requests/min** | 50 | 50 |
| **Input tokens/min** | 30,000 | 50,000 |
| **Output tokens/min** | 8,000 | 10,000 |

**Note**: Cached tokens don't count toward input token limits!

---

## Error Handling Quick Reference

```typescript
try {
 const message = await client.messages.create({...});
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 switch (error.status) {
 case 400:
 // Invalid request (bad parameters)
 break;
 case 401:
 // Authentication failed
 break;
 case 429:
 // Rate limit exceeded - retry with backoff
 break;
 case 500:
 case 529:
 // Server error - retry
 break;
 default:
 // Unknown error
 }
 }
}
```

---

## Testing

### Mock Client for Tests

```typescript
// __tests__/mocks/anthropic.ts
export const mockAnthropicClient = {
 messages: {
 create: vi.fn,
 stream: vi.fn,
 },
};
```

### Example Test

```typescript
import { describe, it, expect, vi } from 'vitest';
import { mockAnthropicClient } from './__tests__/mocks/anthropic';

describe('AI Agent', => {
 it('should send message to Claude', async => {
 mockAnthropicClient.messages.create.mockResolvedValue({
 content: [{ type: 'text', text: 'Hello!' }],
 usage: { input_tokens: 10, output_tokens: 5 },
 });

 const response = await agent.chat('Hello');

 expect(response).toBe('Hello!');
 expect(mockAnthropicClient.messages.create).toHaveBeenCalledWith({
 model: 'claude-sonnet-4-5-20250929',
 messages: expect.arrayContaining([
 { role: 'user', content: 'Hello' }
 ]),
 });
 });
});
```

---

## Related Documentation

### Official Resources

- **Anthropic SDK Docs**: https://github.com/anthropics/anthropic-sdk-typescript
- **Claude API Docs**: https://docs.claude.com/
- **Prompt Engineering**: https://docs.claude.com/en/docs/build-with-claude/prompt-engineering
- **Rate Limits**: https://docs.claude.com/en/api/rate-limits

### Related Knowledge Base Topics

- **TypeScript Patterns**: [`docs/kb/typescript/`](../typescript/)
- **Testing Patterns**: [`docs/kb/testing/`](../testing/)
- **API Design**: [`docs/kb/nextjs/`](../nextjs/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.1 | 2025-11-13 | Updated SDK version to 0.27.3 (actual version), removed references to non-existent files 08-12 |
| 1.0.0 | 2025-11-11 | Initial KB creation |

---

## Contributing

When adding new patterns or updating documentation:

1. Follow the existing structure (numbered chapters)
2. Include code examples with proper TypeScript types
3. Add integration patterns to `FRAMEWORK-INTEGRATION-PATTERNS.md`
4. Update this README with new sections
5. Cross-reference related documentation

---

## Support

**Questions or Issues?**

1. Check the [Quick Reference](QUICK-REFERENCE.md) first
2. Review [Integration Patterns](FRAMEWORK-INTEGRATION-PATTERNS.md)
3. Consult [Official Anthropic Docs](https://docs.claude.com/)
4. Check your project's architecture documentation

---

**SDK Supported:** @anthropic-ai/sdk 0.27.3
**Claude Model:** claude-sonnet-4-5-20250929
**Status:** Production Ready
