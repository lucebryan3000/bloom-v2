# OpenAI API - Quick Reference

Quick reference for common OpenAI API patterns in TypeScript.

## Table of Contents
- [Setup](#setup)
- [Chat Completions](#chat-completions)
- [Function Calling](#function-calling)
- [Streaming](#streaming)
- [Error Handling](#error-handling)
- [Common Patterns](#common-patterns)

---

## Setup

### Installation
```bash
npm install openai
```

### Basic Client
```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});
```

### Environment Variables
```bash
# .env.local
OPENAI_API_KEY=sk-...
OPENAI_ORG_ID=org-...  # Optional
```

---

## Chat Completions

### Simple Chat
```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "Hello!" }
  ],
});

const response = completion.choices[0].message.content;
```

### Multi-Turn Conversation
```typescript
const messages: OpenAI.Chat.ChatCompletionMessageParam[] = [
  { role: "system", content: "You are a helpful assistant." },
  { role: "user", content: "What's 2+2?" },
  { role: "assistant", content: "4" },
  { role: "user", content: "What about 2+3?" },
];

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages,
});
```

### JSON Mode
```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4-turbo",
  messages: [
    { role: "system", content: "Respond in JSON format." },
    { role: "user", content: "List 3 colors" }
  ],
  response_format: { type: "json_object" },
});

const data = JSON.parse(completion.choices[0].message.content || '{}');
```

### Temperature Control
```typescript
// More random/creative
const creative = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [...],
  temperature: 0.9,  // Range: 0-2
});

// More focused/deterministic
const focused = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [...],
  temperature: 0.2,
});
```

---

## Function Calling

### Define Functions
```typescript
const functions: OpenAI.Chat.ChatCompletionCreateParams.Function[] = [
  {
    name: "get_weather",
    description: "Get the current weather in a location",
    parameters: {
      type: "object",
      properties: {
        location: {
          type: "string",
          description: "City and state, e.g. San Francisco, CA",
        },
        unit: {
          type: "string",
          enum: ["celsius", "fahrenheit"],
        },
      },
      required: ["location"],
    },
  },
];
```

### Call with Functions
```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "user", content: "What's the weather in SF?" }
  ],
  functions,
  function_call: "auto",  // or { name: "get_weather" }
});

const message = completion.choices[0].message;

if (message.function_call) {
  const { name, arguments: args } = message.function_call;
  const parsedArgs = JSON.parse(args);

  // Execute function
  const result = await getWeather(parsedArgs.location);

  // Send result back
  const followUp = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      { role: "user", content: "What's the weather in SF?" },
      message,
      {
        role: "function",
        name,
        content: JSON.stringify(result),
      },
    ],
  });
}
```

### Structured Data Extraction
```typescript
const functions = [{
  name: "extract_person",
  description: "Extract person information",
  parameters: {
    type: "object",
    properties: {
      name: { type: "string" },
      age: { type: "number" },
      occupation: { type: "string" },
    },
    required: ["name"],
  },
}];

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "user", content: "John is a 30 year old engineer" }
  ],
  functions,
  function_call: { name: "extract_person" },
});

const data = JSON.parse(
  completion.choices[0].message.function_call?.arguments || '{}'
);
// { name: "John", age: 30, occupation: "engineer" }
```

---

## Streaming

### Basic Streaming
```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "Tell me a story" }],
  stream: true,
});

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content || '';
  process.stdout.write(content);
}
```

### Streaming in Next.js API Route
```typescript
// app/api/chat/route.ts
import OpenAI from 'openai';
import { OpenAIStream, StreamingTextResponse } from 'ai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function POST(req: Request) {
  const { messages } = await req.json();

  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    stream: true,
    messages,
  });

  const stream = OpenAIStream(response);
  return new StreamingTextResponse(stream);
}
```

### Streaming with Function Calls
```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [...],
  functions,
  stream: true,
});

let functionCall = { name: '', arguments: '' };

for await (const chunk of stream) {
  const delta = chunk.choices[0]?.delta;

  if (delta?.function_call) {
    functionCall.name += delta.function_call.name || '';
    functionCall.arguments += delta.function_call.arguments || '';
  } else if (delta?.content) {
    process.stdout.write(delta.content);
  }
}

if (functionCall.name) {
  const args = JSON.parse(functionCall.arguments);
  // Handle function call
}
```

---

## Error Handling

### Basic Try-Catch
```typescript
try {
  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [...],
  });
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    console.error('OpenAI API Error:', error.status, error.message);
  } else {
    console.error('Unexpected error:', error);
  }
}
```

### Retry with Exponential Backoff
```typescript
async function chatWithRetry(
  params: OpenAI.Chat.ChatCompletionCreateParams,
  maxRetries = 3
) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await openai.chat.completions.create(params);
    } catch (error) {
      if (error instanceof OpenAI.APIError) {
        // Retry on rate limit or server errors
        if (error.status === 429 || error.status >= 500) {
          const delay = Math.pow(2, i) * 1000; // Exponential backoff
          await new Promise(resolve => setTimeout(resolve, delay));
          continue;
        }
      }
      throw error;
    }
  }
  throw new Error('Max retries exceeded');
}
```

### Handle Specific Errors
```typescript
try {
  const completion = await openai.chat.completions.create({...});
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    switch (error.status) {
      case 400:
        console.error('Bad request:', error.message);
        break;
      case 401:
        console.error('Invalid API key');
        break;
      case 429:
        console.error('Rate limit exceeded');
        break;
      case 500:
        console.error('OpenAI server error');
        break;
      default:
        console.error('API error:', error.status, error.message);
    }
  }
}
```

---

## Common Patterns

### Token Counting
```typescript
import { encode } from 'gpt-tokenizer';

function countTokens(text: string): number {
  return encode(text).length;
}

const tokens = countTokens("Hello, world!");
console.log(`Token count: ${tokens}`);
```

### Rate Limit Handling
```typescript
class RateLimiter {
  private queue: Array<() => Promise<any>> = [];
  private processing = false;
  private requestsPerMinute = 60;
  private delay = 60000 / this.requestsPerMinute;

  async add<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push(async () => {
        try {
          const result = await fn();
          resolve(result);
        } catch (error) {
          reject(error);
        }
      });
      this.process();
    });
  }

  private async process() {
    if (this.processing) return;
    this.processing = true;

    while (this.queue.length > 0) {
      const fn = this.queue.shift();
      if (fn) {
        await fn();
        await new Promise(resolve => setTimeout(resolve, this.delay));
      }
    }

    this.processing = false;
  }
}

const limiter = new RateLimiter();
const completion = await limiter.add(() =>
  openai.chat.completions.create({...})
);
```

### Response Caching
```typescript
import { LRUCache } from 'lru-cache';

const cache = new LRUCache<string, string>({
  max: 100,
  ttl: 1000 * 60 * 60, // 1 hour
});

async function getCachedCompletion(
  prompt: string
): Promise<string> {
  const cacheKey = `completion:${prompt}`;
  const cached = cache.get(cacheKey);

  if (cached) return cached;

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [{ role: "user", content: prompt }],
  });

  const response = completion.choices[0].message.content || '';
  cache.set(cacheKey, response);
  return response;
}
```

### Timeout Handling
```typescript
async function chatWithTimeout(
  params: OpenAI.Chat.ChatCompletionCreateParams,
  timeoutMs = 30000
) {
  const timeoutPromise = new Promise((_, reject) => {
    setTimeout(() => reject(new Error('Request timeout')), timeoutMs);
  });

  const completionPromise = openai.chat.completions.create(params);

  return Promise.race([completionPromise, timeoutPromise]);
}
```

### Cost Tracking
```typescript
interface TokenUsage {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  estimatedCost: number;
}

function calculateCost(
  usage: OpenAI.CompletionUsage,
  model: string
): TokenUsage {
  const pricing = {
    'gpt-4': { input: 0.03 / 1000, output: 0.06 / 1000 },
    'gpt-3.5-turbo': { input: 0.0015 / 1000, output: 0.002 / 1000 },
  };

  const price = pricing[model as keyof typeof pricing];
  const cost = (
    usage.prompt_tokens * price.input +
    usage.completion_tokens * price.output
  );

  return {
    promptTokens: usage.prompt_tokens,
    completionTokens: usage.completion_tokens,
    totalTokens: usage.total_tokens,
    estimatedCost: cost,
  };
}

const completion = await openai.chat.completions.create({...});
const cost = calculateCost(completion.usage!, 'gpt-4');
console.log(`Cost: $${cost.estimatedCost.toFixed(4)}`);
```

---

## Related Documentation

- [Fundamentals](./01-FUNDAMENTALS.md) - Detailed API concepts
- [Chat API](./02-CHAT-API.md) - Complete chat patterns
- [Function Calling](./03-FUNCTION-CALLING.md) - Advanced function usage
- [Streaming](./04-STREAMING.md) - Streaming best practices
- [Error Handling](./05-ERROR-HANDLING.md) - Comprehensive error strategies

---

**Last Updated**: 2025-01-13
