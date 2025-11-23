---
id: anthropic-sdk-typescript-06-rate-limiting
topic: anthropic-sdk-typescript
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [anthropic-sdk-typescript-basics]
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Rate Limiting Guide

Comprehensive quota management and rate limit handling for production applications.

---

## Table of Contents

1. [Overview](#overview)
2. [Rate Limit Tiers](#rate-limit-tiers)
3. [Token Limits](#token-limits)
4. [Request Limits](#request-limits)
5. [Response Headers](#response-headers)
6. [Monitoring Usage](#monitoring-usage)
7. [Implementing Retry with Backoff](#implementing-retry-with-backoff)
8. [Queue Systems](#queue-systems)
9. [Prompt Caching](#prompt-caching)
10. [Example: Usage Tracking](#example-usage-tracking)
11. [Cost Estimation](#cost-estimation)
12. [Alert Thresholds](#alert-thresholds)

---

## Overview

Rate limiting controls API usage to ensure fair access and prevent abuse. Anthropic enforces limits on:

- **Requests per minute (RPM)**: How many API calls you can make
- **Tokens per minute (TPM)**: How many tokens you can process (input + output)
- **Tokens per day (TPD)**: Daily token quota

**Key principle**: Design your application to gracefully handle rate limits and stay within quotas.

---

## Rate Limit Tiers

### Current Tier Structure (Jan 2025)

| Tier | Requests/Min | Input Tokens/Min | Output Tokens/Min | Cost | Use Case |
| ------------- | ------------ | ---------------- | ----------------- | ------------ | ---------------------- |
| **Free** | 5 | 25,000 | 5,000 | Free | Testing, prototypes |
| **Standard** | 50 | 40,000 | 8,000 | Pay-as-you-go| Small apps |
| **Pro** | 1,000 | 400,000 | 80,000 | $40/month + | Production apps |
| **Scale** | Custom | Custom | Custom | Contact sales| Enterprise |

**Note**: Limits are for Claude Sonnet 4.5. Other models may have different limits.

### Checking Your Tier

```typescript
// Rate limit info is in response headers
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
});

// Access via Anthropic SDK (if available)
// Or check dashboard: https://console.anthropic.com/settings/limits
```

### Upgrading Tiers

1. Visit [console.anthropic.com/settings/plans](https://console.anthropic.com/settings/plans)
2. Select appropriate tier
3. Provide billing information
4. Limits update immediately

---

## Token Limits

### Understanding Token Limits

Tokens are the atomic units of text processing. Limits apply to:

- **Input tokens**: Your prompt + conversation history + system prompt
- **Output tokens**: Claude's response

### Claude Sonnet 4.5 Limits

| Limit Type | Value | Note |
| ----------------------- | ---------------------- | ----------------------------- |
| Context window | 200,000 tokens | Total input capacity |
| Max output tokens | 8,192 tokens | Per response |
| Input TPM (Standard) | 40,000 tokens/min | Across all requests |
| Output TPM (Standard) | 8,000 tokens/min | Across all requests |

### Token Estimation

```typescript
// Rough estimates:
// - 1 token ≈ 4 characters
// - 1 token ≈ 0.75 words
// - 100 tokens ≈ 75 words

function estimateTokens(text: string): number {
 return Math.ceil(text.length / 4);
}

const systemPrompt = "You are a helpful assistant.";
const userMessage = "Explain quantum computing in simple terms.";

const estimatedInput = estimateTokens(systemPrompt + userMessage);
const estimatedOutput = 1000; // max_tokens parameter

console.log(`Estimated usage: ${estimatedInput + estimatedOutput} tokens`);
```

### Accurate Token Counting

For precise counts, use Anthropic's tokenizer (if available) or count actual usage from responses:

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

const actualTokens = {
 input: response.usage.input_tokens,
 output: response.usage.output_tokens,
 total: response.usage.input_tokens + response.usage.output_tokens,
};

console.log("Actual token usage:", actualTokens);
```

---

## Request Limits

### Requests Per Minute (RPM)

Standard tier: **50 RPM**

```typescript
// Calculate your request rate
const requestsPerMinute = 50; // Standard tier
const delayBetweenRequests = 60000 / requestsPerMinute; // 1200ms

async function rateLimitedRequest {
 const response = await anthropic.messages.create({
 /*... */
 });

 // Wait before next request
 await new Promise((resolve) => setTimeout(resolve, delayBetweenRequests));

 return response;
}
```

### Burst vs. Sustained Rate

- **Burst**: Short spike in requests (tolerated briefly)
- **Sustained**: Long-term average rate (must stay under limit)

Anthropic uses a **token bucket** algorithm that allows brief bursts but enforces sustained limits.

---

## Response Headers

### Rate Limit Headers

Every API response includes rate limit headers:

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

// Access headers (TypeScript)
interface RateLimitHeaders {
 "anthropic-ratelimit-requests-limit": string; // e.g., "50"
 "anthropic-ratelimit-requests-remaining": string; // e.g., "45"
 "anthropic-ratelimit-requests-reset": string; // ISO 8601 timestamp

 "anthropic-ratelimit-tokens-limit": string; // e.g., "40000"
 "anthropic-ratelimit-tokens-remaining": string; // e.g., "38500"
 "anthropic-ratelimit-tokens-reset": string; // ISO 8601 timestamp

 "retry-after"?: string; // Seconds to wait (only on 429 errors)
}
```

### Parsing Headers

```typescript
function parseRateLimitHeaders(headers: Record<string, string>) {
 return {
 requests: {
 limit: parseInt(headers["anthropic-ratelimit-requests-limit"] || "0"),
 remaining: parseInt(
 headers["anthropic-ratelimit-requests-remaining"] || "0"
 ),
 reset: new Date(headers["anthropic-ratelimit-requests-reset"] || ""),
 },
 tokens: {
 limit: parseInt(headers["anthropic-ratelimit-tokens-limit"] || "0"),
 remaining: parseInt(
 headers["anthropic-ratelimit-tokens-remaining"] || "0"
 ),
 reset: new Date(headers["anthropic-ratelimit-tokens-reset"] || ""),
 },
 };
}

// Usage
const limits = parseRateLimitHeaders(response.headers);
console.log(`Requests remaining: ${limits.requests.remaining}`);
console.log(`Tokens remaining: ${limits.tokens.remaining}`);
```

### Monitoring Remaining Quota

```typescript
async function requestWithQuotaCheck {
 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 });

 const limits = parseRateLimitHeaders(response.headers);

 // Warn if quota is low
 if (limits.requests.remaining < 5) {
 console.warn(
 `⚠️ Low request quota: ${limits.requests.remaining} remaining`
 );
 }

 if (limits.tokens.remaining < 5000) {
 console.warn(`⚠️ Low token quota: ${limits.tokens.remaining} remaining`);
 }

 return response;
}
```

---

## Monitoring Usage

### Real-Time Usage Tracking

```typescript
class UsageTracker {
 private usage = {
 requests: 0,
 inputTokens: 0,
 outputTokens: 0,
 totalTokens: 0,
 errors: 0,
 rateLimitHits: 0,
 };

 track(response: Anthropic.Message): void {
 this.usage.requests++;
 this.usage.inputTokens += response.usage.input_tokens;
 this.usage.outputTokens += response.usage.output_tokens;
 this.usage.totalTokens +=
 response.usage.input_tokens + response.usage.output_tokens;
 }

 trackError(error: unknown): void {
 this.usage.errors++;
 if (error instanceof Anthropic.RateLimitError) {
 this.usage.rateLimitHits++;
 }
 }

 getUsage {
 return {...this.usage };
 }

 reset: void {
 this.usage = {
 requests: 0,
 inputTokens: 0,
 outputTokens: 0,
 totalTokens: 0,
 errors: 0,
 rateLimitHits: 0,
 };
 }
}

// Usage
const tracker = new UsageTracker;

try {
 const response = await anthropic.messages.create({
 /*... */
 });
 tracker.track(response);
} catch (error) {
 tracker.trackError(error);
}

console.log("Usage stats:", tracker.getUsage);
```

### Logging Usage to Database

```typescript
// Example pattern
async function logUsage(response: Anthropic.Message, sessionId: string) {
 await prisma.usageLog.create({
 data: {
 sessionId,
 model: response.model,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens:
 response.usage.input_tokens + response.usage.output_tokens,
 timestamp: new Date,
 },
 });
}
```

---

## Implementing Retry with Backoff

### Basic Retry for 429 Errors

```typescript
async function retryOn429<T>(
 fn: => Promise<T>,
 maxRetries = 3
): Promise<T> {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 if (
 error instanceof Anthropic.RateLimitError &&
 attempt < maxRetries
 ) {
 // Get retry-after header or use default
 const retryAfter =
 parseInt(error.headers?.["retry-after"] || "60") * 1000;
 console.log(
 `Rate limited. Retrying in ${retryAfter / 1000}s... (attempt ${attempt})`
 );
 await new Promise((resolve) => setTimeout(resolve, retryAfter));
 continue;
 }
 throw error; // Not rate limit or max retries exceeded
 }
 }
 throw new Error("Max retries exceeded");
}

// Usage
const response = await retryOn429( =>
 anthropic.messages.create({
 /*... */
 })
);
```

### Exponential Backoff with Jitter

```typescript
function calculateBackoff(attempt: number, baseDelay = 1000): number {
 const exponential = baseDelay * Math.pow(2, attempt - 1);
 const jitter = Math.random * exponential * 0.1; // 10% jitter
 return exponential + jitter;
}

async function retryWithBackoff<T>(
 fn: => Promise<T>,
 maxRetries = 3
): Promise<T> {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 if (
 error instanceof Anthropic.RateLimitError &&
 attempt < maxRetries
 ) {
 const delay = calculateBackoff(attempt);
 console.log(`Retrying in ${Math.round(delay)}ms...`);
 await new Promise((resolve) => setTimeout(resolve, delay));
 continue;
 }
 throw error;
 }
 }
 throw new Error("Max retries exceeded");
}
```

---

## Queue Systems

### Simple In-Memory Queue

```typescript
class RequestQueue {
 private queue: Array< => Promise<unknown>> = [];
 private processing = false;
 private requestsPerMinute: number;

 constructor(requestsPerMinute: number) {
 this.requestsPerMinute = requestsPerMinute;
 }

 async enqueue<T>(fn: => Promise<T>): Promise<T> {
 return new Promise((resolve, reject) => {
 this.queue.push(async => {
 try {
 const result = await fn;
 resolve(result as T);
 } catch (error) {
 reject(error);
 }
 });

 if (!this.processing) {
 this.processQueue;
 }
 });
 }

 private async processQueue: Promise<void> {
 this.processing = true;
 const delayMs = 60000 / this.requestsPerMinute;

 while (this.queue.length > 0) {
 const fn = this.queue.shift;
 if (fn) {
 await fn;
 await new Promise((resolve) => setTimeout(resolve, delayMs));
 }
 }

 this.processing = false;
 }

 getQueueLength: number {
 return this.queue.length;
 }
}

// Usage
const queue = new RequestQueue(50); // 50 RPM

async function queuedRequest {
 return await queue.enqueue( =>
 anthropic.messages.create({
 /*... */
 })
 );
}
```

### Priority Queue

```typescript
interface QueuedRequest<T> {
 fn: => Promise<T>;
 priority: number;
 resolve: (value: T) => void;
 reject: (error: unknown) => void;
}

class PriorityQueue {
 private queue: Array<QueuedRequest<unknown>> = [];
 private processing = false;
 private requestsPerMinute: number;

 constructor(requestsPerMinute: number) {
 this.requestsPerMinute = requestsPerMinute;
 }

 async enqueue<T>(fn: => Promise<T>, priority = 0): Promise<T> {
 return new Promise((resolve, reject) => {
 this.queue.push({ fn, priority, resolve, reject });

 // Sort by priority (higher first)
 this.queue.sort((a, b) => b.priority - a.priority);

 if (!this.processing) {
 this.processQueue;
 }
 });
 }

 private async processQueue: Promise<void> {
 this.processing = true;
 const delayMs = 60000 / this.requestsPerMinute;

 while (this.queue.length > 0) {
 const request = this.queue.shift;
 if (request) {
 try {
 const result = await request.fn;
 request.resolve(result);
 } catch (error) {
 request.reject(error);
 }
 await new Promise((resolve) => setTimeout(resolve, delayMs));
 }
 }

 this.processing = false;
 }
}

// Usage
const priorityQueue = new PriorityQueue(50);

// High priority request (user-facing)
await priorityQueue.enqueue( => anthropic.messages.create({
 /*... */
}), 10);

// Low priority request (background job)
await priorityQueue.enqueue( => anthropic.messages.create({
 /*... */
}), 1);
```

---

## Prompt Caching

### What is Prompt Caching?

Prompt caching reduces token usage by caching frequently reused prompt content (like system prompts). This:

- Reduces input token consumption by up to **90%**
- Lowers costs
- Stays within rate limits longer
- **Cache TTL**: 5 minutes

### How to Use Prompt Caching

```typescript
// Mark cacheable content with cache_control
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: [
 {
 type: "text",
 text: MELISSA_SYSTEM_PROMPT, // Long system prompt
 cache_control: { type: "ephemeral" }, // Cache this content
 },
 ],
 messages: messages,
});

// Subsequent requests within 5 minutes reuse cached system prompt
// Only tokens in `messages` are counted as new input tokens
```

### Cache-Aware Rate Limits

With caching:

- **Input tokens** = Uncached tokens only (90% reduction)
- **Output tokens** = Same as before
- **Cache reads** count as separate quota (much higher limits)

### Example: Caching Strategy

```typescript
// Cache system prompt (rarely changes)
const systemPrompt = [
 {
 type: "text" as const,
 text: MELISSA_SYSTEM_PROMPT,
 cache_control: { type: "ephemeral" as const },
 },
];

// Cache conversation context (changes per message)
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: messages, // Not cached (changes frequently)
});
```

### Monitoring Cache Performance

```typescript
const response = await anthropic.messages.create({
 /*... */
});

// Check cache usage in headers
const cacheHit =
 response.headers?.["anthropic-cache-hit"] === "true" || false;
const cachedTokens = parseInt(
 response.headers?.["anthropic-cache-tokens"] || "0"
);

console.log({
 cacheHit,
 cachedTokens,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
});
```

---

## Example: Usage Tracking

### Database-Backed Pattern

```typescript
// After each API call
logger.info("AI message processed", "melissa", {
 sessionId,
 model: response.model,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
 phase: conversationPhase,
});

// Store in database for analytics
await prisma.usageMetric.create({
 data: {
 sessionId,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 model: response.model,
 timestamp: new Date,
 },
});
```

### Usage Dashboard

```typescript
// Get usage stats for date range
async function getUsageStats(startDate: Date, endDate: Date) {
 const usage = await prisma.usageMetric.aggregate({
 where: {
 timestamp: {
 gte: startDate,
 lte: endDate,
 },
 },
 _sum: {
 inputTokens: true,
 outputTokens: true,
 },
 _count: {
 id: true,
 },
 });

 return {
 totalRequests: usage._count.id,
 totalInputTokens: usage._sum.inputTokens || 0,
 totalOutputTokens: usage._sum.outputTokens || 0,
 totalTokens:
 (usage._sum.inputTokens || 0) + (usage._sum.outputTokens || 0),
 };
}
```

---

## Cost Estimation

### Claude Sonnet 4.5 Pricing (Jan 2025)

- **Input**: $3.00 per million tokens
- **Output**: $15.00 per million tokens
- **Cached input**: $0.30 per million tokens (90% discount)

### Cost Calculator

```typescript
function calculateCost(usage: {
 input_tokens: number;
 output_tokens: number;
 cached_tokens?: number;
}): number {
 const INPUT_COST_PER_MILLION = 3.0;
 const OUTPUT_COST_PER_MILLION = 15.0;
 const CACHED_COST_PER_MILLION = 0.3;

 const inputCost =
 ((usage.input_tokens - (usage.cached_tokens || 0)) / 1_000_000) *
 INPUT_COST_PER_MILLION;
 const cachedCost =
 ((usage.cached_tokens || 0) / 1_000_000) * CACHED_COST_PER_MILLION;
 const outputCost = (usage.output_tokens / 1_000_000) * OUTPUT_COST_PER_MILLION;

 return inputCost + cachedCost + outputCost;
}

// Usage
const response = await anthropic.messages.create({
 /*... */
});

const cost = calculateCost({
 input_tokens: response.usage.input_tokens,
 output_tokens: response.usage.output_tokens,
 cached_tokens: 0, // From headers if available
});

console.log(`Cost: $${cost.toFixed(6)}`);
```

### Daily Budget Tracking

```typescript
class BudgetTracker {
 private dailyBudget: number;
 private currentSpend = 0;
 private lastReset = new Date;

 constructor(dailyBudgetUSD: number) {
 this.dailyBudget = dailyBudgetUSD;
 }

 trackRequest(usage: {
 input_tokens: number;
 output_tokens: number;
 }): void {
 this.resetIfNewDay;
 const cost = calculateCost(usage);
 this.currentSpend += cost;

 if (this.currentSpend >= this.dailyBudget) {
 throw new Error(
 `Daily budget of $${this.dailyBudget} exceeded. Current spend: $${this.currentSpend.toFixed(2)}`
 );
 }
 }

 private resetIfNewDay: void {
 const now = new Date;
 if (now.getDate !== this.lastReset.getDate) {
 this.currentSpend = 0;
 this.lastReset = now;
 }
 }

 getRemainingBudget: number {
 this.resetIfNewDay;
 return Math.max(0, this.dailyBudget - this.currentSpend);
 }
}

// Usage
const budgetTracker = new BudgetTracker(50); // $50/day

try {
 const response = await anthropic.messages.create({
 /*... */
 });
 budgetTracker.trackRequest(response.usage);
} catch (error) {
 console.error("Budget exceeded:", error.message);
}
```

---

## Alert Thresholds

### Setting Up Alerts

```typescript
interface AlertThresholds {
 requestsRemainingWarning: number;
 tokensRemainingWarning: number;
 costPerRequestWarning: number;
 rateLimitHitsThreshold: number;
}

const thresholds: AlertThresholds = {
 requestsRemainingWarning: 5, // Warn when <5 requests left
 tokensRemainingWarning: 5000, // Warn when <5000 tokens left
 costPerRequestWarning: 0.5, // Warn if request costs >$0.50
 rateLimitHitsThreshold: 3, // Alert after 3 rate limit hits
};

function checkAlerts(
 limits: ReturnType<typeof parseRateLimitHeaders>,
 cost: number,
 rateLimitHits: number
): void {
 if (limits.requests.remaining < thresholds.requestsRemainingWarning) {
 console.warn(
 `⚠️ Low request quota: ${limits.requests.remaining} remaining`
 );
 // sendAlert('Low request quota', limits.requests.remaining);
 }

 if (limits.tokens.remaining < thresholds.tokensRemainingWarning) {
 console.warn(
 `⚠️ Low token quota: ${limits.tokens.remaining} remaining`
 );
 }

 if (cost > thresholds.costPerRequestWarning) {
 console.warn(`⚠️ High cost request: $${cost.toFixed(4)}`);
 }

 if (rateLimitHits >= thresholds.rateLimitHitsThreshold) {
 console.error(`🚨 Rate limit threshold exceeded: ${rateLimitHits} hits`);
 // sendAlert('Rate limit threshold exceeded', rateLimitHits);
 }
}
```

---

## Best Practices

1. **Monitor rate limit headers**: Check remaining quota after each request
2. **Implement retry logic**: Handle 429 errors with exponential backoff
3. **Use prompt caching**: Cache system prompts for 90% token savings
4. **Track usage**: Log token consumption and costs
5. **Set budgets**: Implement daily/monthly spending limits
6. **Queue requests**: Use queues to stay within rate limits
7. **Alert on anomalies**: Notify when quota is low or costs spike
8. **Batch when possible**: Combine multiple prompts into one request

---

## See Also

- [04-ERROR-HANDLING.md](./04-ERROR-HANDLING.md) - Error handling patterns
- [07-TOKEN-MANAGEMENT.md](./07-TOKEN-MANAGEMENT.md) - Token optimization
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [Official Rate Limits Documentation](https://docs.anthropic.com/claude/reference/rate-limits)
