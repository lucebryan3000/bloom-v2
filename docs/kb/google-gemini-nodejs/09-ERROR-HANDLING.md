---
id: google-gemini-nodejs-09-error-handling
topic: google-gemini-nodejs
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [google-gemini-fundamentals, google-gemini-messages-api]
related_topics: [google-gemini, error-handling, resilience, retry-logic]
embedding_keywords: [google-gemini, error-handling, retry-logic, rate-limits, resilience]
last_reviewed: 2025-11-13
---

# Gemini Error Handling

**Purpose**: Implement production-grade error handling, retry logic, and resilience patterns.

---

## 1. Error Types

```typescript
import { GoogleGenerativeAIError } from '@google/generative-ai';

try {
  const result = await model.generateContent(prompt);
} catch (error) {
  if (error instanceof GoogleGenerativeAIError) {
    console.error('Gemini API Error:', error.message);

    if (error.message.includes('API_KEY_INVALID')) {
      // Invalid API key
    } else if (error.message.includes('RESOURCE_EXHAUSTED')) {
      // Rate limit exceeded
    } else if (error.message.includes('PERMISSION_DENIED')) {
      // Permission denied
    } else if (error.message.includes('INVALID_ARGUMENT')) {
      // Invalid request parameters
    } else if (error.message.includes('INTERNAL')) {
      // Internal server error
    } else if (error.message.includes('UNAVAILABLE')) {
      // Service unavailable
    }
  }
}
```

---

## 2. Retry Logic with Exponential Backoff

```typescript
async function generateWithRetry(
  model: any,
  prompt: string,
  maxRetries = 3
): Promise<string> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const result = await model.generateContent(prompt);
      return result.response.text();
    } catch (error) {
      lastError = error as Error;

      if (error instanceof GoogleGenerativeAIError) {
        // Only retry on retryable errors
        if (
          error.message.includes('RESOURCE_EXHAUSTED') ||
          error.message.includes('INTERNAL') ||
          error.message.includes('UNAVAILABLE') ||
          error.message.includes('DEADLINE_EXCEEDED')
        ) {
          const delay = Math.min(1000 * Math.pow(2, attempt), 10000);
          console.log(`Retry attempt ${attempt + 1} after ${delay}ms`);
          await sleep(delay);
          continue;
        }
      }

      // Non-retryable error, throw immediately
      throw error;
    }
  }

  throw new Error(`Failed after ${maxRetries} retries: ${lastError?.message}`);
}

function sleep(ms: number): Promise<void> {
  return new Promise((resolve) => setTimeout(resolve, ms));
}
```

---

## 3. Rate Limit Handling

```typescript
class RateLimitedClient {
  private requestQueue: Array<() => Promise<any>> = [];
  private processing = false;
  private requestCount = 0;
  private windowStart = Date.now();
  private readonly maxRequestsPerMinute = 50; // Adjust based on tier

  async generate(model: any, prompt: string): Promise<string> {
    return new Promise((resolve, reject) => {
      this.requestQueue.push(async () => {
        try {
          const result = await model.generateContent(prompt);
          resolve(result.response.text());
        } catch (error) {
          reject(error);
        }
      });

      this.processQueue();
    });
  }

  private async processQueue() {
    if (this.processing || this.requestQueue.length === 0) return;

    this.processing = true;

    while (this.requestQueue.length > 0) {
      // Check rate limit
      const now = Date.now();
      const windowElapsed = now - this.windowStart;

      if (windowElapsed > 60000) {
        // Reset window
        this.requestCount = 0;
        this.windowStart = now;
      }

      if (this.requestCount >= this.maxRequestsPerMinute) {
        // Wait until window resets
        const waitTime = 60000 - windowElapsed;
        await sleep(waitTime);
        continue;
      }

      // Process next request
      const request = this.requestQueue.shift();
      if (request) {
        this.requestCount++;
        await request();
      }
    }

    this.processing = false;
  }
}
```

---

## 4. Timeout Handling

```typescript
async function generateWithTimeout(
  model: any,
  prompt: string,
  timeoutMs = 30000
): Promise<string> {
  const timeoutPromise = new Promise<never>((_, reject) => {
    setTimeout(() => reject(new Error('Request timeout')), timeoutMs);
  });

  const generatePromise = model.generateContent(prompt).then((result: any) => result.response.text());

  return Promise.race([generatePromise, timeoutPromise]);
}
```

---

## 5. Circuit Breaker Pattern

```typescript
class CircuitBreaker {
  private failures = 0;
  private readonly failureThreshold = 5;
  private readonly resetTimeout = 60000;
  private state: 'closed' | 'open' | 'half-open' = 'closed';
  private nextAttempt = 0;

  async execute<T>(fn: () => Promise<T>): Promise<T> {
    if (this.state === 'open') {
      if (Date.now() < this.nextAttempt) {
        throw new Error('Circuit breaker is open');
      }
      this.state = 'half-open';
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

  private onSuccess() {
    this.failures = 0;
    this.state = 'closed';
  }

  private onFailure() {
    this.failures++;
    if (this.failures >= this.failureThreshold) {
      this.state = 'open';
      this.nextAttempt = Date.now() + this.resetTimeout;
    }
  }
}

const breaker = new CircuitBreaker();
const result = await breaker.execute(() => model.generateContent(prompt));
```

---

## 6. Fallback Strategies

```typescript
async function generateWithFallback(prompt: string): Promise<string> {
  try {
    // Try primary model (Pro)
    const proModel = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });
    const result = await proModel.generateContent(prompt);
    return result.response.text();
  } catch (error) {
    console.log('Primary model failed, trying fallback...');

    try {
      // Fallback to Flash
      const flashModel = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
      const result = await flashModel.generateContent(prompt);
      return result.response.text();
    } catch (fallbackError) {
      // Final fallback - cached response or error message
      return 'Service temporarily unavailable. Please try again later.';
    }
  }
}
```

---

## 7. Best Practices

### ✅ DO

- Implement exponential backoff for retries
- Set reasonable timeouts
- Use circuit breakers for cascading failures
- Log all errors with context
- Have fallback responses
- Monitor error rates

### ❌ DON'T

- Don't retry non-retryable errors
- Don't retry indefinitely
- Don't ignore rate limits
- Don't expose API errors to users
- Don't fail silently

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Use exponential backoff for rate limits
2. Implement timeouts to prevent hanging
3. Circuit breakers prevent cascading failures
4. Always have fallback strategies
5. Log errors for monitoring

---

**Next**: [10-PERFORMANCE.md](10-PERFORMANCE.md) for optimization.
