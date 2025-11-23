---
id: google-gemini-nodejs-readme
topic: google-gemini-nodejs
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [javascript, typescript, api-basics]
related_topics: [ai-ml, anthropic-sdk-typescript, openai-codex]
embedding_keywords: [google-gemini, gemini-api, multimodal-ai, generative-ai, vertex-ai, google-ai]
last_reviewed: 2025-11-13
---

# Google Gemini API - Comprehensive Knowledge Base

**API Version:** Gemini 1.5 Pro / Flash (Latest)
**Last Updated:** November 13, 2025
**Primary Models:** gemini-1.5-pro-latest, gemini-1.5-flash-latest

---

## Overview

This knowledge base provides comprehensive documentation for integrating Google's Gemini AI models into production applications. Gemini is Google's most capable multimodal AI model family, supporting text, images, audio, and video inputs with advanced reasoning capabilities.

## Purpose

The Google Gemini API enables developers to build AI-powered applications with:
- **Multimodal Understanding**: Process text, images, audio, and video in a single request
- **Long Context Windows**: Up to 2 million tokens (Gemini 1.5 Pro)
- **Function Calling**: Tool use and API integration
- **Streaming Responses**: Real-time generation
- **Grounding**: Connect to Google Search and custom data sources

This KB ensures type-safe, performant, and production-ready integration patterns.

---

## Contents

### Core Documentation

1. **[Quick Reference](QUICK-REFERENCE.md)** - Fast lookup for common patterns and code snippets
2. **[Index](INDEX.md)** - Complete navigation with learning paths
3. **[Framework Integration Patterns](FRAMEWORK-INTEGRATION-PATTERNS.md)** - Real-world production examples

### Detailed Topics

4. **[01-FUNDAMENTALS.md](01-FUNDAMENTALS.md)** - Core concepts, models, and capabilities
5. **[02-MESSAGES-API.md](02-MESSAGES-API.md)** - Text generation and conversations
6. **[03-MULTIMODAL.md](03-MULTIMODAL.md)** - Images, audio, video processing
7. **[04-STREAMING.md](04-STREAMING.md)** - Real-time response streaming
8. **[05-FUNCTION-CALLING.md](05-FUNCTION-CALLING.md)** - Tool use and API integration
9. **[06-GROUNDING.md](06-GROUNDING.md)** - Google Search integration and data grounding
10. **[07-EMBEDDINGS.md](07-EMBEDDINGS.md)** - Text embeddings for semantic search
11. **[08-SAFETY-CONTENT.md](08-SAFETY-CONTENT.md)** - Content filtering and safety settings
12. **[09-ERROR-HANDLING.md](09-ERROR-HANDLING.md)** - Production-grade error management
13. **[10-PERFORMANCE.md](10-PERFORMANCE.md)** - Token optimization and caching
14. **[11-CONFIG-OPERATIONS.md](11-CONFIG-OPERATIONS.md)** - Deployment, monitoring, quotas

---

## Quick Start

### Installation

```bash
# Google AI SDK (direct API access)
npm install @google/generative-ai

# Or Vertex AI SDK (for Google Cloud)
npm install @google-cloud/vertexai
```

### Basic Setup (Google AI)

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });

const result = await model.generateContent('Explain quantum computing');
const response = await result.response;
const text = response.text();

console.log(text);
```

### Basic Setup (Vertex AI)

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: 'your-project-id',
  location: 'us-central1',
});

const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-pro',
});

const result = await model.generateContent('Explain quantum computing');
const response = await result.response;
console.log(response.text());
```

---

## Key Features

### ✅ Multimodal Input

Process multiple modalities in a single request:

```typescript
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });

const imagePart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('image.jpg')).toString('base64'),
    mimeType: 'image/jpeg',
  },
};

const result = await model.generateContent([
  'What is in this image?',
  imagePart,
]);

console.log(result.response.text());
```

### ✅ Massive Context Window

Gemini 1.5 Pro supports up to 2 million tokens:

```typescript
// Process entire codebases, documents, or video transcripts
const longDocument = fs.readFileSync('large-document.txt', 'utf-8');

const result = await model.generateContent([
  'Summarize this document:',
  longDocument,
]);
```

### ✅ Function Calling

Integrate with APIs and tools:

```typescript
const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather for a location',
    parameters: {
      type: 'object',
      properties: {
        location: { type: 'string', description: 'City and state' },
      },
      required: ['location'],
    },
  },
];

const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: 'What is the weather in Boston?' }] }],
  tools: [{ functionDeclarations: functions }],
});
```

### ✅ Streaming Responses

Real-time generation for better UX:

```typescript
const result = await model.generateContentStream('Write a long story');

for await (const chunk of result.stream) {
  const chunkText = chunk.text();
  process.stdout.write(chunkText);
}

const finalResponse = await result.response;
console.log('\n\nFinal usage:', finalResponse.usageMetadata);
```

---

## Model Comparison

| Model | Context Window | Strengths | Use Cases |
|-------|---------------|-----------|-----------|
| **gemini-1.5-pro-latest** | 2M tokens | Complex reasoning, multimodal | Long documents, video analysis, complex tasks |
| **gemini-1.5-flash-latest** | 1M tokens | Speed, efficiency | High-throughput, simple tasks, real-time |
| **gemini-1.0-pro** | 32K tokens | Stable, proven | Legacy integrations |
| **text-embedding-004** | N/A | Embeddings | Semantic search, RAG |

**Recommendation**: Use Flash for most tasks (faster, cheaper). Use Pro for complex reasoning, long context, or multimodal tasks.

---

## Typical Architecture

### Component Hierarchy

```
Client Application (UI)
 ↓
API Route Handler (Next.js/Express)
 ↓
AI Service Layer (Business Logic)
 ↓
Gemini SDK (AI Integration)
 ↓
Google AI / Vertex AI API
```

### Common Integration Points

| Component | Purpose | Example Location |
|-----------|---------|------------------|
| **Chat Route** | API endpoint for user messages | `app/api/chat/route.ts` |
| **AI Service** | Conversation orchestration | `lib/ai/gemini-service.ts` |
| **Configuration** | System prompts and settings | `lib/ai/config.ts` |
| **Message Store** | Conversation persistence | `lib/db/messages.ts` |
| **File Upload** | Handle images/audio/video | `app/api/upload/route.ts` |

---

## Best Practices at a Glance

### ✅ DO

- **Use environment variables** for API keys (never hardcode)
- **Choose the right model** (Flash for speed, Pro for complexity)
- **Validate inputs** before sending to Gemini
- **Implement retry logic** for transient failures
- **Use streaming** for better UX on long responses
- **Monitor token usage** to stay within budgets
- **Cache embeddings** for repeated queries
- **Type all responses** with TypeScript interfaces
- **Set appropriate safety settings** for your use case

### ❌ DON'T

- **Never expose API keys** in client-side code
- **Don't ignore rate limits** - implement exponential backoff
- **Don't send PII** without user consent and proper handling
- **Don't exceed context windows** (2M for Pro, 1M for Flash)
- **Don't skip error handling** - always catch API errors
- **Don't use Pro when Flash suffices** - it's more expensive
- **Don't forget safety filters** - they're on by default for a reason

---

## Environment Configuration

### Google AI (Direct API)

```bash
# .env.local
GOOGLE_AI_API_KEY=AIzaSy...your-api-key

# Optional: Override defaults
GEMINI_MODEL=gemini-1.5-flash-latest
GEMINI_MAX_OUTPUT_TOKENS=2048
GEMINI_TEMPERATURE=0.7
```

### Vertex AI (Google Cloud)

```bash
# .env.local
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json

# Optional: Override defaults
VERTEX_AI_LOCATION=us-central1
GEMINI_MODEL=gemini-1.5-pro
```

---

## Common Patterns

### 1. Simple Text Generation

```typescript
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
const result = await model.generateContent('Explain ROI in simple terms');
const response = await result.response;
console.log(response.text());
```

### 2. Conversation with History

```typescript
const chat = model.startChat({
  history: [
    { role: 'user', parts: [{ text: 'Hello' }] },
    { role: 'model', parts: [{ text: 'Hi! How can I help?' }] },
  ],
});

const result = await chat.sendMessage('Tell me about AI');
console.log(result.response.text());
```

### 3. System Instructions (Gemini 1.5+)

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-pro-latest',
  systemInstruction: 'You are an expert ROI analyst. Always provide data-driven insights.',
});

const result = await model.generateContent('Calculate ROI for this project');
```

### 4. Image Analysis

```typescript
const imagePart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('chart.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const result = await model.generateContent([
  'Analyze this chart and extract key metrics',
  imagePart,
]);
```

---

## Performance Considerations

### Token Optimization

- **Choose the right model**: Flash is 3-10x cheaper than Pro for similar tasks
- **Use system instructions**: More efficient than including in every message
- **Cache long contexts**: Vertex AI supports caching (coming to Google AI)
- **Limit output tokens**: Set `maxOutputTokens` to prevent runaway costs

### Rate Limits (Google AI - Free Tier)

| Metric | gemini-1.5-pro | gemini-1.5-flash |
|--------|---------------|------------------|
| **Requests/min** | 2 | 15 |
| **Requests/day** | 50 | 1,500 |
| **Tokens/min** | 32,000 | 1,000,000 |

**Production Tier**: Much higher limits (contact Google for pricing)

### Latency Optimization

- **Use Flash for low latency**: 2-5x faster than Pro
- **Enable streaming**: Start rendering before completion
- **Parallel requests**: Process independent tasks concurrently
- **Edge deployment**: Use Vertex AI in regions close to users

---

## Error Handling Quick Reference

```typescript
import { GoogleGenerativeAIError } from '@google/generative-ai';

try {
  const result = await model.generateContent('Hello');
} catch (error) {
  if (error instanceof GoogleGenerativeAIError) {
    console.error(`API Error: ${error.message}`);

    // Check specific error types
    if (error.message.includes('RESOURCE_EXHAUSTED')) {
      // Rate limit exceeded - retry with backoff
    } else if (error.message.includes('INVALID_ARGUMENT')) {
      // Invalid request parameters
    } else if (error.message.includes('PERMISSION_DENIED')) {
      // Authentication/authorization failure
    }
  } else {
    // Network or other error
    console.error('Unexpected error:', error);
  }
}
```

---

## Testing

### Mock Client for Tests

```typescript
// __tests__/mocks/gemini.ts
export const mockGeminiModel = {
  generateContent: vi.fn(),
  generateContentStream: vi.fn(),
  startChat: vi.fn(),
};

export const mockGeminiAI = {
  getGenerativeModel: vi.fn(() => mockGeminiModel),
};
```

### Example Test

```typescript
import { describe, it, expect, vi } from 'vitest';
import { mockGeminiAI, mockGeminiModel } from './__tests__/mocks/gemini';

describe('Gemini AI Service', () => {
  it('should generate content', async () => {
    mockGeminiModel.generateContent.mockResolvedValue({
      response: {
        text: () => 'Hello from Gemini!',
        usageMetadata: { promptTokenCount: 5, candidatesTokenCount: 4 },
      },
    });

    const result = await aiService.chat('Hello');

    expect(result).toBe('Hello from Gemini!');
    expect(mockGeminiModel.generateContent).toHaveBeenCalledWith('Hello');
  });
});
```

---

## Related Documentation

### Official Resources

- **Google AI Docs**: https://ai.google.dev/docs
- **Vertex AI Docs**: https://cloud.google.com/vertex-ai/docs/generative-ai/learn/overview
- **API Reference**: https://ai.google.dev/api/rest
- **Model Garden**: https://ai.google.dev/models

### Related Knowledge Base Topics

- **TypeScript Patterns**: [`docs/kb/typescript/`](../typescript/)
- **Testing Patterns**: [`docs/kb/testing/`](../testing/)
- **API Design**: [`docs/kb/nextjs/`](../nextjs/)
- **Anthropic Claude**: [`docs/kb/anthropic-sdk-typescript/`](../anthropic-sdk-typescript/)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-11-13 | Initial KB creation for Gemini 1.5 API |

---

## AI Pair Programming Notes

### When to Load This KB

Load this KB when:
- Building AI-powered features with Google Gemini
- Integrating multimodal capabilities (text, image, audio, video)
- Implementing function calling / tool use
- Optimizing for long context windows (>100K tokens)
- Debugging Gemini API integration issues

### Recommended Context Bundle

**For basic integration:**
- README.md (this file)
- QUICK-REFERENCE.md
- 01-FUNDAMENTALS.md

**For multimodal features:**
- QUICK-REFERENCE.md
- 03-MULTIMODAL.md
- FRAMEWORK-INTEGRATION-PATTERNS.md

**For production deployment:**
- 09-ERROR-HANDLING.md
- 10-PERFORMANCE.md
- 11-CONFIG-OPERATIONS.md

### What AI Should Avoid

- Don't use deprecated models (gemini-pro, gemini-pro-vision)
- Don't hardcode API keys in code
- Don't exceed context windows without chunking
- Don't ignore safety filter responses
- Don't use Pro when Flash suffices (cost optimization)

---

## Support

**Questions or Issues?**

1. Check the [Quick Reference](QUICK-REFERENCE.md) first
2. Review [Integration Patterns](FRAMEWORK-INTEGRATION-PATTERNS.md)
3. Consult [Official Google AI Docs](https://ai.google.dev/docs)
4. Check error handling patterns in [09-ERROR-HANDLING.md](09-ERROR-HANDLING.md)

---

**API Version:** Gemini 1.5 Pro / Flash (Latest)
**Status:** Production Ready
**Last Updated:** November 13, 2025
