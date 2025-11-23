# OpenAI API Knowledge Base

> **Note**: OpenAI Codex has been deprecated. This KB covers modern OpenAI API usage with GPT-4, GPT-3.5-turbo, and other current models.

## Overview

Comprehensive guide to integrating OpenAI's API into TypeScript/Node.js applications, with focus on:
- Chat Completions (GPT-4, GPT-3.5-turbo)
- Function calling and structured outputs
- Streaming responses
- Error handling and rate limiting
- Security and best practices

## Quick Links

- [Quick Reference](./QUICK-REFERENCE.md) - Common patterns and code snippets
- [Fundamentals](./01-FUNDAMENTALS.md) - API basics and setup
- [Chat API](./02-CHAT-API.md) - Chat completions endpoint
- [Function Calling](./03-FUNCTION-CALLING.md) - Structured outputs and tools
- [Streaming](./04-STREAMING.md) - Real-time response handling
- [Error Handling](./05-ERROR-HANDLING.md) - Robust error management
- [Rate Limiting](./06-RATE-LIMITING.md) - Token management and quotas
- [Security](./07-SECURITY.md) - API key safety and data privacy
- [Testing](./08-TESTING.md) - Unit and integration testing strategies
- [Framework Integration](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Next.js patterns

## Installation

```bash
npm install openai
# or
pnpm add openai
# or
yarn add openai
```

## Basic Example

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "Hello!" }
  ],
});

console.log(completion.choices[0].message.content);
```

## Current Models (as of 2025)

### GPT-4 Family
- **gpt-4** - Most capable model, best for complex tasks
- **gpt-4-turbo** - Faster, cheaper, 128K context
- **gpt-4-vision** - Supports image inputs

### GPT-3.5 Family
- **gpt-3.5-turbo** - Fast, cost-effective for simple tasks
- **gpt-3.5-turbo-16k** - Extended context window

### Specialized Models
- **text-embedding-ada-002** - Text embeddings
- **whisper-1** - Audio transcription
- **dall-e-3** - Image generation

## Key Features

### 1. Function Calling
```typescript
const functions = [{
  name: "get_weather",
  description: "Get current weather",
  parameters: {
    type: "object",
    properties: {
      location: { type: "string" },
    },
    required: ["location"],
  },
}];

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "What's the weather in SF?" }],
  functions,
  function_call: "auto",
});
```

### 2. Streaming
```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "Tell me a story" }],
  stream: true,
});

for await (const chunk of stream) {
  process.stdout.write(chunk.choices[0]?.delta?.content || '');
}
```

### 3. JSON Mode
```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4-turbo",
  messages: [
    { role: "system", content: "You are a helpful assistant. Respond in JSON." },
    { role: "user", content: "List 3 colors" }
  ],
  response_format: { type: "json_object" },
});
```

## Common Use Cases

### 1. Chat Interface
See: [02-CHAT-API.md](./02-CHAT-API.md#chat-interface-pattern)

### 2. Content Generation
See: [02-CHAT-API.md](./02-CHAT-API.md#content-generation)

### 3. Data Extraction
See: [03-FUNCTION-CALLING.md](./03-FUNCTION-CALLING.md#structured-data-extraction)

### 4. Code Generation
See: [02-CHAT-API.md](./02-CHAT-API.md#code-generation)

## Best Practices

### ✅ Do
- Store API keys in environment variables
- Implement exponential backoff for retries
- Use streaming for long responses
- Cache responses when appropriate
- Monitor token usage and costs
- Validate all inputs and outputs
- Use function calling for structured outputs

### ❌ Don't
- Hardcode API keys in source code
- Ignore rate limit errors
- Send sensitive data without encryption
- Skip input validation
- Rely solely on model outputs without verification

## Project Integration

This project (your application) uses OpenAI API for:
- **AI Agent Example**: Chat interface with GPT-4
- **Content Generation**: ROI report summaries
- **Data Extraction**: Structured business intelligence

### Example: Melissa Chat Endpoint

```typescript
// app/api/chat/route.ts
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function POST(request: Request) {
  const { messages } = await request.json();

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages,
    temperature: 0.7,
  });

  return Response.json(completion.choices[0].message);
}
```

## Rate Limits & Costs

### Current Limits (2025)
- **Tier 1** (Free): 3 RPM, 200 RPD
- **Tier 2** ($5+ spent): 60 RPM, 1M TPM
- **Tier 3** ($50+ spent): 3500 RPM, 10M TPM

### Pricing (approximate)
- **GPT-4**: $0.03/1K input tokens, $0.06/1K output tokens
- **GPT-3.5-turbo**: $0.0015/1K input tokens, $0.002/1K output tokens

See: [06-RATE-LIMITING.md](./06-RATE-LIMITING.md)

## Troubleshooting

### Common Errors

**401 Unauthorized**
```typescript
// Check API key is set
if (!process.env.OPENAI_API_KEY) {
  throw new Error('OPENAI_API_KEY not set');
}
```

**429 Rate Limit**
```typescript
// Implement exponential backoff
await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, retryCount)));
```

**500 Server Error**
```typescript
// Retry with exponential backoff
// Log error details for debugging
```

See: [05-ERROR-HANDLING.md](./05-ERROR-HANDLING.md)

## Migration from Codex

If you're migrating from the deprecated Codex models:

```typescript
// ❌ Old (Codex - deprecated)
const completion = await openai.createCompletion({
  model: "code-davinci-002",
  prompt: "def factorial(n):",
  max_tokens: 100,
});

// ✅ New (GPT-4)
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "system", content: "You are a coding assistant." },
    { role: "user", content: "Write a Python factorial function" }
  ],
});
```

## Resources

### Official Documentation
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)
- [OpenAI Cookbook](https://github.com/openai/openai-cookbook)
- [Best Practices Guide](https://platform.openai.com/docs/guides/production-best-practices)

### Community
- [OpenAI Community Forum](https://community.openai.com/)
- [OpenAI Discord](https://discord.gg/openai)

### Tools
- [OpenAI Playground](https://platform.openai.com/playground)
- [Tokenizer](https://platform.openai.com/tokenizer)

## Related Documentation

- [Anthropic SDK](../anthropic-sdk-typescript/) - Alternative AI provider
- [Vercel AI SDK](../vercel-ai/) - Multi-provider AI framework
- [Next.js API Routes](../nextjs/05-API-ROUTES.md) - API integration patterns

---

**Last Updated**: 2025-01-13
**Maintained By**: your application Documentation Team
**Status**: ✅ Active (replaces deprecated Codex docs)
