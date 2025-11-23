---
id: anthropic-sdk-typescript-07-token-management
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

# Anthropic SDK TypeScript - Token Management Guide

Cost optimization and token usage strategies for production applications.

---

## Table of Contents

1. [Overview](#overview)
2. [Token Counting Basics](#token-counting-basics)
3. [Estimating Tokens](#estimating-tokens)
4. [Usage Tracking](#usage-tracking)
5. [Prompt Caching](#prompt-caching)
6. [Cache TTL](#cache-ttl)
7. [Cache-Aware Rate Limits](#cache-aware-rate-limits)
8. [System Prompt Caching](#system-prompt-caching)
9. [Context Trimming](#context-trimming)
10. [Cost Calculation](#cost-calculation)
11. [Budget Alerts](#budget-alerts)
12. [Example: Token Tracking](#example-token-tracking)
13. [Optimization Strategies](#optimization-strategies)

---

## Overview

Tokens are the fundamental units of text processing in Claude. Effective token management:

- Reduces API costs
- Stays within rate limits
- Improves response times
- Enables longer conversations

**Key principle**: Monitor token usage, cache aggressively, trim proactively.

---

## Token Counting Basics

### What is a Token?

A token is a unit of text, roughly:

- **1 token ≈ 4 characters**
- **1 token ≈ 0.75 words**
- **100 tokens ≈ 75 words**

### Token Composition

```
"Hello, world!" = 4 tokens

Breakdown:
1. "Hello"
2. ","
3. " world"
4. "!"
```

Punctuation, spaces, and special characters count as tokens.

### Input vs. Output Tokens

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
});

console.log({
 inputTokens: response.usage.input_tokens, // Your prompt
 outputTokens: response.usage.output_tokens, // Claude's response
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
});
```

**Input tokens** = system prompt + conversation history + current message
**Output tokens** = Claude's generated response

---

## Estimating Tokens

### Simple Estimation Function

```typescript
function estimateTokens(text: string): number {
 // Rough estimate: 1 token ≈ 4 characters
 return Math.ceil(text.length / 4);
}

const prompt = "Explain TypeScript in simple terms.";
const estimated = estimateTokens(prompt);
console.log(`Estimated tokens: ${estimated}`); // ~9 tokens
```

### Multi-Message Estimation

```typescript
function estimateConversationTokens(
 messages: Anthropic.MessageParam[],
 systemPrompt?: string
): number {
 let total = 0;

 if (systemPrompt) {
 total += estimateTokens(systemPrompt);
 }

 for (const message of messages) {
 const content =
 typeof message.content === "string" ? message.content: "";
 total += estimateTokens(content);
 total += 4; // Overhead for message structure
 }

 return total;
}

// Usage
const messages = [
 { role: "user" as const, content: "What is React?" },
 {
 role: "assistant" as const,
 content: "React is a JavaScript library...",
 },
 { role: "user" as const, content: "How do I install it?" },
];

const estimated = estimateConversationTokens(
 messages,
 "You are a helpful assistant."
);
console.log(`Estimated input tokens: ${estimated}`);
```

### Accurate Token Counting

For precise counts, use actual API responses:

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

// Compare to estimate
const estimatedInput = estimateConversationTokens(messages);
const accuracy = (estimatedInput / actualTokens.input) * 100;
console.log(`Estimation accuracy: ${accuracy.toFixed(1)}%`);
```

---

## Usage Tracking

### Real-Time Token Tracker

```typescript
interface TokenUsage {
 inputTokens: number;
 outputTokens: number;
 totalTokens: number;
 requestCount: number;
}

class TokenTracker {
 private usage: TokenUsage = {
 inputTokens: 0,
 outputTokens: 0,
 totalTokens: 0,
 requestCount: 0,
 };

 track(response: Anthropic.Message): void {
 this.usage.inputTokens += response.usage.input_tokens;
 this.usage.outputTokens += response.usage.output_tokens;
 this.usage.totalTokens +=
 response.usage.input_tokens + response.usage.output_tokens;
 this.usage.requestCount++;
 }

 getUsage: TokenUsage {
 return {...this.usage };
 }

 getAverageTokensPerRequest: number {
 return this.usage.requestCount > 0
 ? this.usage.totalTokens / this.usage.requestCount
: 0;
 }

 reset: void {
 this.usage = {
 inputTokens: 0,
 outputTokens: 0,
 totalTokens: 0,
 requestCount: 0,
 };
 }
}

// Usage
const tracker = new TokenTracker;

const response = await anthropic.messages.create({
 /*... */
});
tracker.track(response);

console.log("Usage:", tracker.getUsage);
console.log("Avg per request:", tracker.getAverageTokensPerRequest);
```

### Session-Level Tracking

```typescript
interface SessionTokenUsage {
 sessionId: string;
 inputTokens: number;
 outputTokens: number;
 totalTokens: number;
 messageCount: number;
 startTime: Date;
 lastActivity: Date;
}

class SessionTokenTracker {
 private sessions = new Map<string, SessionTokenUsage>;

 track(sessionId: string, response: Anthropic.Message): void {
 const existing = this.sessions.get(sessionId);

 if (existing) {
 existing.inputTokens += response.usage.input_tokens;
 existing.outputTokens += response.usage.output_tokens;
 existing.totalTokens +=
 response.usage.input_tokens + response.usage.output_tokens;
 existing.messageCount++;
 existing.lastActivity = new Date;
 } else {
 this.sessions.set(sessionId, {
 sessionId,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens:
 response.usage.input_tokens + response.usage.output_tokens,
 messageCount: 1,
 startTime: new Date,
 lastActivity: new Date,
 });
 }
 }

 getSessionUsage(sessionId: string): SessionTokenUsage | undefined {
 return this.sessions.get(sessionId);
 }

 getAllSessions: SessionTokenUsage[] {
 return Array.from(this.sessions.values);
 }

 getTotalUsage: TokenUsage {
 let total: TokenUsage = {
 inputTokens: 0,
 outputTokens: 0,
 totalTokens: 0,
 requestCount: 0,
 };

 for (const session of this.sessions.values) {
 total.inputTokens += session.inputTokens;
 total.outputTokens += session.outputTokens;
 total.totalTokens += session.totalTokens;
 total.requestCount += session.messageCount;
 }

 return total;
 }
}

// Usage
const sessionTracker = new SessionTokenTracker;

const response = await anthropic.messages.create({
 /*... */
});
sessionTracker.track("session-123", response);

console.log("Session usage:", sessionTracker.getSessionUsage("session-123"));
console.log("Total usage:", sessionTracker.getTotalUsage);
```

---

## Prompt Caching

### What is Prompt Caching?

Prompt caching reduces token costs by reusing frequently repeated prompt content. Benefits:

- **90% cost reduction** on cached content
- Faster responses (cached content is pre-processed)
- Lower token consumption
- Higher effective rate limits

**Cache TTL**: 5 minutes

### Enabling Prompt Caching

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: [
 {
 type: "text",
 text: "You are a helpful assistant with extensive knowledge...",
 cache_control: { type: "ephemeral" }, // Enable caching
 },
 ],
 messages: messages,
});

// Subsequent requests within 5 minutes reuse cached system prompt
```

### What to Cache

✅ **Good candidates:**

- System prompts (rarely change)
- Long context documents
- Conversation history prefix
- Reference materials

❌ **Poor candidates:**

- User messages (always unique)
- Dynamic content
- Frequently changing data

### Multi-Block Caching

```typescript
const systemPrompt = [
 {
 type: "text" as const,
 text: "You are Melissa, an expert business consultant...",
 cache_control: { type: "ephemeral" as const },
 },
 {
 type: "text" as const,
 text: "Current workshop phase: Discovery\nGoal: Identify pain points...",
 // No cache_control - changes frequently
 },
];

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: messages,
});
```

---

## Cache TTL

### Understanding Cache Lifetime

- **TTL**: 5 minutes from last use
- **Auto-refresh**: Each cache hit extends TTL by 5 minutes
- **Expiration**: Cache is purged after 5 minutes of inactivity

### Cache Refresh Strategy

```typescript
class CacheManager {
 private lastCacheUse = new Date;
 private readonly CACHE_TTL_MS = 5 * 60 * 1000; // 5 minutes

 isCacheValid: boolean {
 const elapsed = Date.now - this.lastCacheUse.getTime;
 return elapsed < this.CACHE_TTL_MS;
 }

 markCacheUsed: void {
 this.lastCacheUse = new Date;
 }

 shouldWarmCache: boolean {
 // Warm cache if it's about to expire
 const elapsed = Date.now - this.lastCacheUse.getTime;
 const threshold = this.CACHE_TTL_MS - 30000; // 30s before expiry
 return elapsed > threshold;
 }
}

// Usage
const cacheManager = new CacheManager;

if (cacheManager.shouldWarmCache) {
 console.log("Warming cache with a dummy request...");
 await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 10,
 system: [
 {
 type: "text",
 text: CACHED_SYSTEM_PROMPT,
 cache_control: { type: "ephemeral" },
 },
 ],
 messages: [{ role: "user", content: "ping" }],
 });
}

cacheManager.markCacheUsed;
```

---

## Cache-Aware Rate Limits

### Rate Limits with Caching

| Metric | Without Cache | With Cache (90% cached) |
| ----------------------- | --------------------- | ----------------------- |
| Input tokens consumed | 10,000 | 1,000 + 9,000 (cached) |
| Billed input tokens | 10,000 @ $3/M | 1,000 @ $3/M + 9,000 @ $0.30/M |
| Total input cost | $0.030 | $0.006 |
| Rate limit impact | Full 10,000 counted | Only 1,000 counted |

### Monitoring Cache Performance

```typescript
interface CacheMetrics {
 totalRequests: number;
 cacheHits: number;
 cacheMisses: number;
 cachedTokens: number;
 uncachedTokens: number;
 tokensSaved: number;
 costSaved: number;
}

class CacheMetricsTracker {
 private metrics: CacheMetrics = {
 totalRequests: 0,
 cacheHits: 0,
 cacheMisses: 0,
 cachedTokens: 0,
 uncachedTokens: 0,
 tokensSaved: 0,
 costSaved: 0,
 };

 track(response: Anthropic.Message, headers: Record<string, string>): void {
 this.metrics.totalRequests++;

 const cacheHit = headers["anthropic-cache-hit"] === "true";
 const cachedTokens = parseInt(headers["anthropic-cache-tokens"] || "0");

 if (cacheHit) {
 this.metrics.cacheHits++;
 this.metrics.cachedTokens += cachedTokens;
 this.metrics.tokensSaved += Math.floor(cachedTokens * 0.9); // 90% savings
 this.metrics.costSaved += (cachedTokens * 0.9 * 3.0) / 1_000_000; // $3/M savings
 } else {
 this.metrics.cacheMisses++;
 }

 this.metrics.uncachedTokens += response.usage.input_tokens - cachedTokens;
 }

 getMetrics: CacheMetrics {
 return {...this.metrics };
 }

 getCacheHitRate: number {
 return this.metrics.totalRequests > 0
 ? (this.metrics.cacheHits / this.metrics.totalRequests) * 100
: 0;
 }
}

// Usage
const cacheMetrics = new CacheMetricsTracker;

const response = await anthropic.messages.create({
 /*... */
});
cacheMetrics.track(response, response.headers);

console.log("Cache hit rate:", cacheMetrics.getCacheHitRate.toFixed(1) + "%");
console.log("Cost saved:", `$${cacheMetrics.getMetrics.costSaved.toFixed(4)}`);
```

---

## System Prompt Caching

### Example: System Prompt Strategy

```typescript
// lib/melissa/config.ts
export const MELISSA_SYSTEM_PROMPT = `
You are Melissa, an expert AI business consultant...
[Long system prompt - 2000+ tokens]
`.trim;

// Create cacheable system prompt
function createCacheableSystemPrompt(
 basePrompt: string,
 dynamicContext?: string
): Array<{ type: "text"; text: string; cache_control?: { type: "ephemeral" } }> {
 const blocks = [
 {
 type: "text" as const,
 text: basePrompt,
 cache_control: { type: "ephemeral" as const }, // Cache static prompt
 },
 ];

 if (dynamicContext) {
 blocks.push({
 type: "text" as const,
 text: dynamicContext, // Don't cache dynamic content
 });
 }

 return blocks;
}

// Usage
const systemPrompt = createCacheableSystemPrompt(
 MELISSA_SYSTEM_PROMPT,
 `Current phase: ${phase}\nSession ID: ${sessionId}`
);

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: messages,
});
```

### Caching Conversation History

```typescript
// Cache older conversation history
function buildCacheableMessages(
 messages: Anthropic.MessageParam[]
): Anthropic.MessageParam[] {
 if (messages.length <= 5) {
 return messages; // Too short to cache
 }

 // Cache all but last 2 messages
 const cacheableCount = messages.length - 2;
 const cacheable = messages.slice(0, cacheableCount);
 const fresh = messages.slice(cacheableCount);

 // Mark last cacheable message for caching
 const lastCacheable = cacheable[cacheable.length - 1];
 if (typeof lastCacheable.content === "string") {
 lastCacheable.content = [
 {
 type: "text",
 text: lastCacheable.content,
 cache_control: { type: "ephemeral" },
 },
 ];
 }

 return [...cacheable,...fresh];
}

// Usage
const cacheableMessages = buildCacheableMessages(conversationHistory);
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: cacheableMessages,
});
```

---

## Context Trimming

### Why Trim Context?

Long conversations approach the 200K token limit. Trimming:

- Keeps conversations within limits
- Reduces costs
- Maintains recent context
- Improves response times

### Simple Trimming Strategy

```typescript
const MAX_HISTORY_TOKENS = 100000; // 100K tokens

function trimMessages(
 messages: Anthropic.MessageParam[],
 maxTokens: number
): Anthropic.MessageParam[] {
 let totalTokens = 0;
 const trimmed: Anthropic.MessageParam[] = [];

 // Keep most recent messages
 for (let i = messages.length - 1; i >= 0; i--) {
 const message = messages[i];
 const tokens = estimateTokens(
 typeof message.content === "string" ? message.content: ""
 );

 if (totalTokens + tokens > maxTokens) {
 break;
 }

 trimmed.unshift(message);
 totalTokens += tokens;
 }

 // Ensure first message is from user
 if (trimmed[0]?.role !== "user") {
 trimmed.shift;
 }

 return trimmed;
}

// Usage
const trimmedMessages = trimMessages(conversationHistory, MAX_HISTORY_TOKENS);
console.log(`Trimmed from ${conversationHistory.length} to ${trimmedMessages.length} messages`);
```

### Smart Trimming with Summaries

```typescript
async function trimWithSummary(
 anthropic: Anthropic,
 messages: Anthropic.MessageParam[],
 maxTokens: number
): Promise<Anthropic.MessageParam[]> {
 const totalTokens = estimateConversationTokens(messages);

 if (totalTokens <= maxTokens) {
 return messages; // No trimming needed
 }

 // Summarize older messages
 const summaryPoint = Math.floor(messages.length / 2);
 const toSummarize = messages.slice(0, summaryPoint);
 const toKeep = messages.slice(summaryPoint);

 const conversationText = toSummarize
.map((m) => `${m.role}: ${m.content}`)
.join("\n\n");

 const summaryResponse = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 300,
 messages: [
 {
 role: "user",
 content: `Summarize this conversation in 2-3 sentences:\n\n${conversationText}`,
 },
 ],
 });

 const summary = summaryResponse.content[0].text;

 // Replace old messages with summary
 return [{ role: "assistant" as const, content: summary },...toKeep];
}
```

---

## Cost Calculation

### Pricing (Jan 2025)

| Token Type | Cost per Million Tokens |
| ---------------- | ----------------------- |
| Input (uncached) | $3.00 |
| Input (cached) | $0.30 (90% discount) |
| Output | $15.00 |

### Cost Calculator

```typescript
interface CostBreakdown {
 inputCost: number;
 cachedCost: number;
 outputCost: number;
 totalCost: number;
}

function calculateCost(usage: {
 input_tokens: number;
 output_tokens: number;
 cached_tokens?: number;
}): CostBreakdown {
 const INPUT_COST = 3.0 / 1_000_000; // $3 per million
 const CACHED_COST = 0.3 / 1_000_000; // $0.30 per million
 const OUTPUT_COST = 15.0 / 1_000_000; // $15 per million

 const uncachedTokens =
 usage.input_tokens - (usage.cached_tokens || 0);
 const cachedTokens = usage.cached_tokens || 0;

 const inputCost = uncachedTokens * INPUT_COST;
 const cachedCost = cachedTokens * CACHED_COST;
 const outputCost = usage.output_tokens * OUTPUT_COST;
 const totalCost = inputCost + cachedCost + outputCost;

 return {
 inputCost,
 cachedCost,
 outputCost,
 totalCost,
 };
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

console.log("Cost breakdown:", {
 input: `$${cost.inputCost.toFixed(6)}`,
 cached: `$${cost.cachedCost.toFixed(6)}`,
 output: `$${cost.outputCost.toFixed(6)}`,
 total: `$${cost.totalCost.toFixed(6)}`,
});
```

### Session Cost Tracking

```typescript
interface SessionCost {
 sessionId: string;
 inputCost: number;
 cachedCost: number;
 outputCost: number;
 totalCost: number;
 messageCount: number;
}

class SessionCostTracker {
 private sessions = new Map<string, SessionCost>;

 track(
 sessionId: string,
 usage: {
 input_tokens: number;
 output_tokens: number;
 cached_tokens?: number;
 }
 ): void {
 const cost = calculateCost(usage);
 const existing = this.sessions.get(sessionId);

 if (existing) {
 existing.inputCost += cost.inputCost;
 existing.cachedCost += cost.cachedCost;
 existing.outputCost += cost.outputCost;
 existing.totalCost += cost.totalCost;
 existing.messageCount++;
 } else {
 this.sessions.set(sessionId, {
 sessionId,
 inputCost: cost.inputCost,
 cachedCost: cost.cachedCost,
 outputCost: cost.outputCost,
 totalCost: cost.totalCost,
 messageCount: 1,
 });
 }
 }

 getSessionCost(sessionId: string): SessionCost | undefined {
 return this.sessions.get(sessionId);
 }

 getTotalCost: number {
 let total = 0;
 for (const session of this.sessions.values) {
 total += session.totalCost;
 }
 return total;
 }

 getAverageCostPerMessage(sessionId: string): number {
 const session = this.sessions.get(sessionId);
 return session && session.messageCount > 0
 ? session.totalCost / session.messageCount
: 0;
 }
}

// Usage
const costTracker = new SessionCostTracker;

const response = await anthropic.messages.create({
 /*... */
});
costTracker.track("session-123", response.usage);

console.log("Session cost:", costTracker.getSessionCost("session-123"));
console.log("Avg per message:", `$${costTracker.getAverageCostPerMessage("session-123").toFixed(6)}`);
```

---

## Budget Alerts

### Budget Thresholds

```typescript
interface BudgetAlerts {
 dailyBudget: number;
 warningThreshold: number; // Percentage
 criticalThreshold: number; // Percentage
 onWarning: (spent: number, limit: number) => void;
 onCritical: (spent: number, limit: number) => void;
 onExceeded: (spent: number, limit: number) => void;
}

class BudgetAlertSystem {
 private dailySpend = 0;
 private lastReset = new Date;
 private alerts: BudgetAlerts;

 constructor(alerts: BudgetAlerts) {
 this.alerts = alerts;
 }

 track(cost: number): void {
 this.resetIfNewDay;
 this.dailySpend += cost;

 const percentUsed = (this.dailySpend / this.alerts.dailyBudget) * 100;

 if (this.dailySpend >= this.alerts.dailyBudget) {
 this.alerts.onExceeded(this.dailySpend, this.alerts.dailyBudget);
 throw new Error(`Daily budget of $${this.alerts.dailyBudget} exceeded`);
 } else if (percentUsed >= this.alerts.criticalThreshold) {
 this.alerts.onCritical(this.dailySpend, this.alerts.dailyBudget);
 } else if (percentUsed >= this.alerts.warningThreshold) {
 this.alerts.onWarning(this.dailySpend, this.alerts.dailyBudget);
 }
 }

 private resetIfNewDay: void {
 const now = new Date;
 if (now.getDate !== this.lastReset.getDate) {
 this.dailySpend = 0;
 this.lastReset = now;
 }
 }

 getRemainingBudget: number {
 this.resetIfNewDay;
 return Math.max(0, this.alerts.dailyBudget - this.dailySpend);
 }

 getPercentUsed: number {
 this.resetIfNewDay;
 return (this.dailySpend / this.alerts.dailyBudget) * 100;
 }
}

// Usage
const budgetAlert = new BudgetAlertSystem({
 dailyBudget: 50, // $50/day
 warningThreshold: 70, // Warn at 70%
 criticalThreshold: 90, // Critical at 90%
 onWarning: (spent, limit) => {
 console.warn(`⚠️ Budget warning: $${spent.toFixed(2)} of $${limit} used`);
 },
 onCritical: (spent, limit) => {
 console.error(`🚨 Critical: $${spent.toFixed(2)} of $${limit} used`);
 // sendAlert('Critical budget threshold', spent);
 },
 onExceeded: (spent, limit) => {
 console.error(`❌ Budget exceeded: $${spent.toFixed(2)} > $${limit}`);
 // sendAlert('Budget exceeded', spent);
 },
});

const response = await anthropic.messages.create({
 /*... */
});
const cost = calculateCost(response.usage);
budgetAlert.track(cost.totalCost);

console.log("Remaining budget:", `$${budgetAlert.getRemainingBudget.toFixed(2)}`);
console.log("Percent used:", `${budgetAlert.getPercentUsed.toFixed(1)}%`);
```

---

## Example: Token Tracking

### Database-Backed Implementation

```typescript
// After each API call
logger.info("AI message processed", "melissa", {
 sessionId,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
 phase: conversationPhase,
 model: response.model,
});

// Store in database
await prisma.tokenUsage.create({
 data: {
 sessionId,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 model: response.model,
 timestamp: new Date,
 },
});
```

### Analytics Query

```typescript
// Get token usage for date range
async function getTokenAnalytics(startDate: Date, endDate: Date) {
 const usage = await prisma.tokenUsage.aggregate({
 where: {
 timestamp: { gte: startDate, lte: endDate },
 },
 _sum: {
 inputTokens: true,
 outputTokens: true,
 },
 _avg: {
 inputTokens: true,
 outputTokens: true,
 },
 _count: { id: true },
 });

 const totalCost = calculateCost({
 input_tokens: usage._sum.inputTokens || 0,
 output_tokens: usage._sum.outputTokens || 0,
 });

 return {
 totalRequests: usage._count.id,
 totalInputTokens: usage._sum.inputTokens || 0,
 totalOutputTokens: usage._sum.outputTokens || 0,
 avgInputTokens: usage._avg.inputTokens || 0,
 avgOutputTokens: usage._avg.outputTokens || 0,
 totalCost: totalCost.totalCost,
 };
}
```

---

## Optimization Strategies

### 1. Cache System Prompts

```typescript
// ✅ Good: Cache static system prompt
system: [
 {
 type: "text",
 text: LONG_SYSTEM_PROMPT,
 cache_control: { type: "ephemeral" },
 },
];
```

### 2. Trim Conversation History

```typescript
// Keep only recent messages
const trimmed = trimMessages(conversationHistory, 50000);
```

### 3. Use Concise Prompts

```typescript
// ❌ Bad: Verbose
"Please provide a very detailed and comprehensive explanation..."

// ✅ Good: Concise
"Explain in 2-3 sentences."
```

### 4. Adjust max_tokens

```typescript
// Don't request more tokens than needed
max_tokens: 200, // For short responses
max_tokens: 1000, // For medium responses
max_tokens: 4000, // For long responses
```

### 5. Batch Requests

```typescript
// Combine multiple prompts into one request
const content = `
Answer these 3 questions:
1. What is TypeScript?
2. What is React?
3. What is Next.js?
`;
```

### 6. Monitor and Alert

```typescript
// Set up monitoring
const tracker = new TokenTracker;
const budgetAlert = new BudgetAlertSystem({
 /*... */
});
const cacheMetrics = new CacheMetricsTracker;
```

---

## Best Practices

1. **Always cache system prompts**: 90% cost savings
2. **Trim conversation history**: Stay under 100K tokens
3. **Track usage**: Monitor tokens and costs
4. **Set budgets**: Implement spending limits
5. **Use concise prompts**: Every word counts
6. **Adjust max_tokens**: Match expected response length
7. **Monitor cache performance**: Ensure >70% hit rate
8. **Alert on anomalies**: Detect cost spikes early

---

## See Also

- [06-RATE-LIMITING.md](./06-RATE-LIMITING.md) - Rate limit management
- [05-PROMPT-ENGINEERING.md](./05-PROMPT-ENGINEERING.md) - Effective prompting
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [Official Token Management Docs](https://docs.anthropic.com/claude/docs/models-overview#model-comparison)
