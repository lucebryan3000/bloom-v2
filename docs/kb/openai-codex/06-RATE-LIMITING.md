# Rate Limiting & Token Management

Guide to managing OpenAI API rate limits and token usage.

## Rate Limits (2025)

### By Tier

| Tier | Spend | RPM (GPT-4) | TPM (GPT-4) | RPM (GPT-3.5) | TPM (GPT-3.5) |
|------|-------|-------------|-------------|---------------|---------------|
| Free | $0 | 3 | 40,000 | 3 | 40,000 |
| Tier 1 | $5+ | 500 | 600,000 | 3,500 | 1,000,000 |
| Tier 2 | $50+ | 5,000 | 5,000,000 | 10,000 | 10,000,000 |
| Tier 3 | $100+ | 10,000 | 10,000,000 | 10,000 | 10,000,000 |

## Token Counting

```typescript
import { encode } from 'gpt-tokenizer';

function countTokens(text: string): number {
  return encode(text).length;
}

function estimateRequestTokens(
  messages: ChatCompletionMessageParam[]
): number {
  let tokens = 3; // Base overhead
  for (const message of messages) {
    tokens += 4; // Message overhead
    tokens += countTokens(message.content);
  }
  return tokens;
}
```

## Rate Limiter Implementation

```typescript
class RateLimiter {
  private queue: Array<{
    fn: () => Promise<any>;
    resolve: (value: any) => void;
    reject: (error: any) => void;
  }> = [];
  private processing = false;
  private requestsPerMinute: number;
  private tokensPerMinute: number;
  private delay: number;

  constructor(rpm: number, tpm: number) {
    this.requestsPerMinute = rpm;
    this.tokensPerMinute = tpm;
    this.delay = 60000 / rpm;
  }

  async add<T>(fn: () => Promise<T>): Promise<T> {
    return new Promise((resolve, reject) => {
      this.queue.push({ fn, resolve, reject });
      this.process();
    });
  }

  private async process() {
    if (this.processing || this.queue.length === 0) return;
    this.processing = true;

    while (this.queue.length > 0) {
      const item = this.queue.shift()!;
      try {
        const result = await item.fn();
        item.resolve(result);
      } catch (error) {
        item.reject(error);
      }
      await new Promise(r => setTimeout(r, this.delay));
    }

    this.processing = false;
  }
}

// Usage
const limiter = new RateLimiter(500, 600000); // Tier 1 GPT-4

const completion = await limiter.add(() =>
  openai.chat.completions.create({...})
);
```

## Cost Tracking

```typescript
interface CostTracker {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  estimatedCost: number;
}

const PRICING = {
  'gpt-4': { input: 0.03 / 1000, output: 0.06 / 1000 },
  'gpt-4-turbo': { input: 0.01 / 1000, output: 0.03 / 1000 },
  'gpt-3.5-turbo': { input: 0.0015 / 1000, output: 0.002 / 1000 },
};

function trackCost(
  usage: OpenAI.CompletionUsage,
  model: string
): CostTracker {
  const price = PRICING[model as keyof typeof PRICING];
  if (!price) throw new Error(`Unknown model: ${model}`);

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
```

## Budget Management

```typescript
class BudgetManager {
  private dailySpend = 0;
  private dailyLimit: number;
  private lastReset = Date.now();

  constructor(dailyLimitUSD: number) {
    this.dailyLimit = dailyLimitUSD;
  }

  async checkAndDeduct(estimatedCost: number): Promise<boolean> {
    this.resetIfNewDay();

    if (this.dailySpend + estimatedCost > this.dailyLimit) {
      return false; // Budget exceeded
    }

    this.dailySpend += estimatedCost;
    return true;
  }

  private resetIfNewDay() {
    const now = Date.now();
    const dayInMs = 24 * 60 * 60 * 1000;
    if (now - this.lastReset > dayInMs) {
      this.dailySpend = 0;
      this.lastReset = now;
    }
  }
}
```

---

**Last Updated**: 2025-01-13
