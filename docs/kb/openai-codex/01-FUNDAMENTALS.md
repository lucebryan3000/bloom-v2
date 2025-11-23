# OpenAI API Fundamentals

Comprehensive guide to OpenAI API core concepts and setup.

## Table of Contents
- [Overview](#overview)
- [Setup](#setup)
- [Authentication](#authentication)
- [Models](#models)
- [Core Concepts](#core-concepts)
- [Request/Response Structure](#requestresponse-structure)
- [Best Practices](#best-practices)

---

## Overview

The OpenAI API provides access to advanced AI models for:
- **Chat**: Conversational AI (GPT-4, GPT-3.5-turbo)
- **Completions**: Text generation (legacy, use chat instead)
- **Embeddings**: Text similarity and search
- **Fine-tuning**: Custom model training
- **Images**: Image generation (DALL·E)
- **Audio**: Speech-to-text (Whisper)

This guide focuses on the **Chat API**, the primary interface for modern applications.

---

## Setup

### Installation

```bash
# npm
npm install openai

# pnpm
pnpm add openai

# yarn
yarn add openai
```

### TypeScript Support

The official SDK includes full TypeScript support:

```typescript
import OpenAI from 'openai';
import type {
  ChatCompletion,
  ChatCompletionMessageParam,
  ChatCompletionCreateParams,
} from 'openai/resources/chat';
```

### Basic Client Initialization

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});
```

### Advanced Configuration

```typescript
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  organization: process.env.OPENAI_ORG_ID, // Optional
  maxRetries: 3,
  timeout: 30000, // 30 seconds
  httpAgent: customAgent, // Custom HTTP agent
});
```

---

## Authentication

### API Keys

Get your API key from: https://platform.openai.com/api-keys

**Environment Variables (Recommended)**

```bash
# .env.local
OPENAI_API_KEY=sk-...
OPENAI_ORG_ID=org-...  # Optional, for multi-org accounts
```

**Next.js Configuration**

```typescript
// next.config.js
module.exports = {
  env: {
    OPENAI_API_KEY: process.env.OPENAI_API_KEY,
  },
};
```

### Security Best Practices

✅ **Do**:
- Store keys in environment variables
- Never commit `.env` files to version control
- Use separate keys for dev/staging/prod
- Rotate keys periodically
- Use organization IDs for team access control

❌ **Don't**:
- Hardcode API keys in source code
- Expose keys in client-side code
- Share keys via email or chat
- Use production keys in development

---

## Models

### Current Models (2025)

#### GPT-4 Family

| Model | Context Window | Use Case |
|-------|----------------|----------|
| `gpt-4` | 8,192 tokens | Most capable, complex tasks |
| `gpt-4-turbo` | 128,000 tokens | Long context, faster, cheaper |
| `gpt-4-turbo-preview` | 128,000 tokens | Latest features |
| `gpt-4-vision-preview` | 128,000 tokens | Image understanding |

#### GPT-3.5 Family

| Model | Context Window | Use Case |
|-------|----------------|----------|
| `gpt-3.5-turbo` | 16,385 tokens | Fast, cost-effective |
| `gpt-3.5-turbo-16k` | 16,385 tokens | Extended context |

### Model Selection Guide

```typescript
// Complex reasoning, high accuracy
const model = "gpt-4";

// Fast responses, simple tasks
const model = "gpt-3.5-turbo";

// Long documents (>8K tokens)
const model = "gpt-4-turbo";

// Image understanding
const model = "gpt-4-vision-preview";
```

### Checking Available Models

```typescript
const models = await openai.models.list();

for await (const model of models) {
  console.log(model.id);
}
```

---

## Core Concepts

### 1. Messages

Chat API uses message-based conversations:

```typescript
type Role = 'system' | 'user' | 'assistant' | 'function';

interface Message {
  role: Role;
  content: string;
  name?: string; // For function calls
}
```

**Roles Explained**:

- **system**: Sets behavior/personality (e.g., "You are a helpful assistant")
- **user**: User's input/questions
- **assistant**: Model's responses
- **function**: Function call results

**Example Conversation**:

```typescript
const messages: ChatCompletionMessageParam[] = [
  {
    role: "system",
    content: "You are a helpful coding assistant specializing in TypeScript."
  },
  {
    role: "user",
    content: "How do I type async functions?"
  },
  {
    role: "assistant",
    content: "You can use Promise<T> as the return type..."
  },
  {
    role: "user",
    content: "Can you show an example?"
  },
];
```

### 2. Tokens

Tokens are pieces of text the model processes:
- 1 token ≈ 4 characters in English
- 1 token ≈ ¾ of a word
- Context window = max tokens per request

**Token Counting**:

```typescript
import { encode } from 'gpt-tokenizer';

function countTokens(text: string): number {
  return encode(text).length;
}

const text = "Hello, world!";
console.log(`Tokens: ${countTokens(text)}`); // ~4 tokens
```

### 3. Temperature

Controls randomness (0-2):

```typescript
// Deterministic, focused
temperature: 0

// Balanced
temperature: 0.7

// Creative, random
temperature: 1.5
```

**Guidelines**:
- **0-0.3**: Code generation, factual Q&A
- **0.7-0.9**: Creative writing, brainstorming
- **1.0-2.0**: Highly creative, experimental

### 4. Max Tokens

Limits response length:

```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [...],
  max_tokens: 500, // Limit response to 500 tokens
});
```

**Note**: `max_tokens` is output only. Total usage = prompt + completion tokens.

---

## Request/Response Structure

### Basic Request

```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "Hello!" }
  ],
  temperature: 0.7,
  max_tokens: 500,
  top_p: 1,
  frequency_penalty: 0,
  presence_penalty: 0,
});
```

### Response Structure

```typescript
interface ChatCompletion {
  id: string;
  object: "chat.completion";
  created: number;
  model: string;
  choices: Array<{
    index: number;
    message: {
      role: "assistant";
      content: string;
    };
    finish_reason: "stop" | "length" | "function_call" | "content_filter";
  }>;
  usage: {
    prompt_tokens: number;
    completion_tokens: number;
    total_tokens: number;
  };
}
```

### Accessing the Response

```typescript
const completion = await openai.chat.completions.create({...});

// Get response text
const response = completion.choices[0].message.content;

// Get token usage
const { prompt_tokens, completion_tokens, total_tokens } = completion.usage;

// Check finish reason
const finishReason = completion.choices[0].finish_reason;
if (finishReason === 'length') {
  console.warn('Response was truncated due to max_tokens');
}
```

---

## Best Practices

### 1. System Messages

Use clear, specific system messages:

```typescript
// ✅ Good: Specific and actionable
{
  role: "system",
  content: `You are a TypeScript expert helping developers write type-safe code.
  - Provide complete, working code examples
  - Explain type annotations clearly
  - Follow TypeScript best practices
  - Use modern ES6+ syntax`
}

// ❌ Bad: Vague
{
  role: "system",
  content: "You are helpful."
}
```

### 2. Context Management

Keep conversations focused:

```typescript
// Limit conversation history
const MAX_HISTORY = 10;
const recentMessages = messages.slice(-MAX_HISTORY);

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [systemMessage, ...recentMessages],
});
```

### 3. Error Handling

Always wrap API calls:

```typescript
try {
  const completion = await openai.chat.completions.create({...});
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    console.error('API Error:', error.status, error.message);

    if (error.status === 429) {
      // Handle rate limit
    } else if (error.status >= 500) {
      // Retry on server error
    }
  } else {
    console.error('Unexpected error:', error);
  }
}
```

### 4. Cost Optimization

```typescript
// Use cheaper model for simple tasks
const model = isComplexTask ? "gpt-4" : "gpt-3.5-turbo";

// Limit max_tokens
max_tokens: 500,

// Cache responses
const cacheKey = `completion:${prompt}`;
const cached = cache.get(cacheKey);
if (cached) return cached;
```

### 5. Testing

Mock API calls in tests:

```typescript
// test/mocks/openai.ts
export const mockOpenAI = {
  chat: {
    completions: {
      create: jest.fn().mockResolvedValue({
        choices: [{
          message: { role: 'assistant', content: 'Mocked response' }
        }],
        usage: { total_tokens: 100 }
      }),
    },
  },
};
```

---

## Environment-Specific Configuration

### Development

```typescript
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  maxRetries: 1,
  timeout: 10000, // Fail fast in dev
});
```

### Production

```typescript
const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
  maxRetries: 3,
  timeout: 30000,
  dangerouslyAllowBrowser: false, // Never true in production
});
```

### Testing

```typescript
const openai = new OpenAI({
  apiKey: process.env.OPENAI_TEST_API_KEY || 'test-key',
  baseURL: process.env.OPENAI_MOCK_URL, // Mock server
});
```

---

## Next Steps

- [Chat API Guide](./02-CHAT-API.md) - Complete chat patterns
- [Function Calling](./03-FUNCTION-CALLING.md) - Structured outputs
- [Streaming](./04-STREAMING.md) - Real-time responses
- [Error Handling](./05-ERROR-HANDLING.md) - Robust error management

---

**Last Updated**: 2025-01-13
