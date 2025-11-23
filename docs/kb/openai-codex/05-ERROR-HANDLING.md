# Error Handling Guide

Robust error handling strategies for OpenAI API.

## Error Types

```typescript
try {
  const completion = await openai.chat.completions.create({...});
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    // API errors
    console.error('Status:', error.status);
    console.error('Message:', error.message);
    console.error('Code:', error.code);
  } else if (error instanceof OpenAI.APIConnectionError) {
    // Network errors
    console.error('Connection failed');
  } else if (error instanceof OpenAI.RateLimitError) {
    // Rate limit exceeded
    console.error('Rate limit hit');
  } else {
    // Other errors
    console.error('Unexpected error:', error);
  }
}
```

## Exponential Backoff

```typescript
async function chatWithRetry(
  params: OpenAI.Chat.ChatCompletionCreateParams,
  maxRetries = 3
): Promise<OpenAI.Chat.ChatCompletion> {
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await openai.chat.completions.create(params);
    } catch (error) {
      if (error instanceof OpenAI.APIError) {
        // Retry on rate limit or server errors
        if (error.status === 429 || error.status >= 500) {
          const delay = Math.min(1000 * Math.pow(2, i), 10000);
          console.log(`Retrying in ${delay}ms...`);
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

## Circuit Breaker Pattern

```typescript
class CircuitBreaker {
  private failures = 0;
  private lastFailTime = 0;
  private readonly threshold = 5;
  private readonly timeout = 60000; // 1 minute

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.isOpen()) {
      throw new Error('Circuit breaker is open');
    }

    try {
      const result = await fn();
      this.onSuccess();
      return result;
    } catch (error) {
      this.onFailure();
      throw error;
    }
  }

  private isOpen(): boolean {
    if (this.failures >= this.threshold) {
      const now = Date.now();
      if (now - this.lastFailTime < this.timeout) {
        return true;
      }
      this.reset();
    }
    return false;
  }

  private onSuccess() {
    this.failures = 0;
  }

  private onFailure() {
    this.failures++;
    this.lastFailTime = Date.now();
  }

  private reset() {
    this.failures = 0;
    this.lastFailTime = 0;
  }
}

const breaker = new CircuitBreaker();

const completion = await breaker.execute(() =>
  openai.chat.completions.create({...})
);
```

## Timeout Handling

```typescript
async function chatWithTimeout(
  params: OpenAI.Chat.ChatCompletionCreateParams,
  timeoutMs = 30000
) {
  const timeout = new Promise((_, reject) =>
    setTimeout(() => reject(new Error('Request timeout')), timeoutMs)
  );

  const request = openai.chat.completions.create(params);

  return Promise.race([request, timeout]);
}
```

## Graceful Degradation

```typescript
async function reliableChat(prompt: string): Promise<string> {
  try {
    // Try GPT-4 first
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [{ role: "user", content: prompt }],
    });
    return completion.choices[0].message.content || '';
  } catch (error) {
    console.warn('GPT-4 failed, falling back to GPT-3.5');

    try {
      // Fall back to GPT-3.5
      const completion = await openai.chat.completions.create({
        model: "gpt-3.5-turbo",
        messages: [{ role: "user", content: prompt }],
      });
      return completion.choices[0].message.content || '';
    } catch (fallbackError) {
      // Return cached response or error message
      return getCachedResponse(prompt) || 'Service temporarily unavailable';
    }
  }
}
```

## Validation

```typescript
import { z } from 'zod';

const ChatRequestSchema = z.object({
  model: z.enum(['gpt-4', 'gpt-3.5-turbo']),
  messages: z.array(z.object({
    role: z.enum(['system', 'user', 'assistant']),
    content: z.string().min(1).max(10000),
  })).min(1),
  temperature: z.number().min(0).max(2).optional(),
  max_tokens: z.number().min(1).max(4000).optional(),
});

async function validatedChat(params: unknown) {
  const validated = ChatRequestSchema.parse(params);
  return openai.chat.completions.create(validated);
}
```

## Logging

```typescript
async function loggedChat(
  params: OpenAI.Chat.ChatCompletionCreateParams
) {
  const startTime = Date.now();

  try {
    const completion = await openai.chat.completions.create(params);

    console.log({
      type: 'openai_success',
      model: params.model,
      tokens: completion.usage?.total_tokens,
      duration: Date.now() - startTime,
    });

    return completion;
  } catch (error) {
    console.error({
      type: 'openai_error',
      model: params.model,
      error: error instanceof Error ? error.message : 'Unknown',
      duration: Date.now() - startTime,
    });

    throw error;
  }
}
```

---

**Last Updated**: 2025-01-13
