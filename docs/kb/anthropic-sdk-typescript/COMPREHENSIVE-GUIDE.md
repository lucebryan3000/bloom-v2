---
id: anthropic-sdk-typescript-comprehensive-guide
topic: anthropic-sdk-typescript
file_role: guide
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, guide, tutorial, comprehensive]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Comprehensive Guide

**Complete Technical Reference for Anthropic Claude Integration**

**SDK Version:** @anthropic-ai/sdk 0.27.3
**Last Updated:** November 13, 2025
**Claude Model:** claude-sonnet-4-5-20250929

---

## Table of Contents

1. [Introduction](#introduction)
2. [Installation & Setup](#installation--setup)
3. [Messages API Deep Dive](#messages-api-deep-dive)
4. [Streaming Responses](#streaming-responses)
5. [Error Handling Strategies](#error-handling-strategies)
6. [Prompt Engineering Techniques](#prompt-engineering-techniques)
7. [Rate Limiting & Quotas](#rate-limiting--quotas)
8. [Token Management & Cost Optimization](#token-management--cost-optimization)
9. [Production Best Practices](#production-best-practices)
10. [Integration Patterns](#integration-patterns)

---

## Introduction

This comprehensive guide consolidates all knowledge from the Anthropic SDK TypeScript documentation into a single deep technical reference. Use this when you need detailed explanations, advanced patterns, or complete coverage of a topic.

### When to Use This Guide

- **Deep Dive Learning**: Understanding SDK internals and advanced features
- **Architecture Decisions**: Choosing between implementation approaches
- **Production Implementation**: Building robust, scalable AI integrations
- **Troubleshooting**: Diagnosing complex issues
- **Performance Optimization**: Fine-tuning for cost and speed

### Quick Navigation

- **Fast Lookup**: Use [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Getting Started**: Start with [README.md](./README.md)
- **Integration Examples**: See [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- **Topic Index**: Browse [INDEX.md](./INDEX.md)

---

## Installation & Setup

### Prerequisites

**Required:**
- Node.js >= 18.0.0
- TypeScript >= 4.5.0
- npm, yarn, or pnpm

**Recommended:**
- Next.js 14+ (for server-side integration)
- Prisma 5+ (for database persistence)

### Installation

```bash
npm install @anthropic-ai/sdk
# Current version: 0.27.3
```

### Environment Configuration

✅ **GOOD: Secure configuration with validation**
```typescript
const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY environment variable is required");
}

const anthropic = new Anthropic({ apiKey });
```

❌ **BAD: Hardcoded credentials**
```typescript
// NEVER do this - security risk!
const anthropic = new Anthropic({
 apiKey: "sk-ant-api03-xxxxx" // ❌ Hardcoded!
});
```

### TypeScript Configuration

✅ **GOOD: Strict mode enabled**
```json
{
 "compilerOptions": {
 "strict": true,
 "noImplicitAny": true,
 "strictNullChecks": true,
 "esModuleInterop": true
 }
}
```

❌ **BAD: Loose type checking**
```json
{
 "compilerOptions": {
 "strict": false // ❌ Loses type safety benefits
 }
}
```

### Client Initialization Patterns

**Pattern 1: Basic (Development)**
```typescript
import Anthropic from "@anthropic-ai/sdk";

const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});
```

**Pattern 2: Validated (Recommended)**
```typescript
function createAnthropicClient: Anthropic {
 const apiKey = process.env.ANTHROPIC_API_KEY;
 if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY not configured");
 }
 return new Anthropic({ apiKey });
}

const anthropic = createAnthropicClient;
```

**Pattern 3: Singleton (Production)**
```typescript
class AnthropicService {
 private static instance: Anthropic | null = null;

 static getInstance: Anthropic {
 if (!this.instance) {
 const apiKey = process.env.ANTHROPIC_API_KEY;
 if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY not configured");
 }
 this.instance = new Anthropic({ apiKey });
 }
 return this.instance;
 }
}

// Usage
const anthropic = AnthropicService.getInstance;
```

### Common Pitfalls

**Pitfall 1: Missing Environment Variables**
```typescript
// ❌ BAD: No validation
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY, // Could be undefined!
});

// ✅ GOOD: Always validate
const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) throw new Error("API key required");
const anthropic = new Anthropic({ apiKey });
```

**Pitfall 2: Incorrect Module Resolution**
```typescript
// ❌ BAD: Wrong import
import { Anthropic } from "@anthropic-ai/sdk"; // ❌ Named import doesn't exist

// ✅ GOOD: Default import
import Anthropic from "@anthropic-ai/sdk";
```

**Pitfall 3: Multiple Client Instances**
```typescript
// ❌ BAD: Creating client on every request
async function handleRequest {
 const anthropic = new Anthropic({ /*... */ }); // ❌ Wasteful!
 //...
}

// ✅ GOOD: Reuse client instance
const anthropic = new Anthropic({ /*... */ });
async function handleRequest {
 // Use existing client
}
```

---

## Messages API Deep Dive

### Message Structure

Every message in a conversation follows this type:

```typescript
interface MessageParam {
 role: "user" | "assistant";
 content: string | ContentBlock[];
}
```

**Rules:**
1. Conversations must start with `user` role
2. Roles must alternate (`user` → `assistant` → `user`)
3. System messages use separate `system` parameter

### Creating Messages

**Basic Message:**
```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "What is TypeScript?",
 },
 ],
});
```

**With System Prompt:**
```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: "You are an expert TypeScript developer.", // System prompt
 messages: [
 {
 role: "user",
 content: "Explain generics",
 },
 ],
});
```

**Multi-Turn Conversation:**
```typescript
const messages: Anthropic.MessageParam[] = [
 { role: "user", content: "Hello" },
 { role: "assistant", content: "Hi! How can I help?" },
 { role: "user", content: "Tell me about ROI" },
];

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages,
});
```

### ✅ Good vs ❌ Bad Patterns

**Message Ordering:**

✅ **GOOD: Proper alternation**
```typescript
const messages = [
 { role: "user", content: "Hello" },
 { role: "assistant", content: "Hi!" },
 { role: "user", content: "How are you?" },
];
```

❌ **BAD: Invalid alternation**
```typescript
const messages = [
 { role: "user", content: "Hello" },
 { role: "user", content: "Are you there?" }, // ❌ Two user messages in a row
];
```

**Content Blocks:**

✅ **GOOD: Type-safe content**
```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{
 role: "user",
 content: "Analyze this image",
 }],
});

// Extract safely
const textBlock = response.content.find(block => block.type === "text");
if (textBlock && textBlock.type === "text") {
 console.log(textBlock.text);
}
```

❌ **BAD: Unsafe extraction**
```typescript
const response = await anthropic.messages.create({...});

// ❌ No type checking!
const text = response.content[0].text; // Could fail if not text block
```

### Model Selection

| Model | Use Case | Cost | Speed |
|-------|----------|------|-------|
| **claude-sonnet-4-5-20250929** | Balanced (recommended) | Medium | Fast |
| **claude-opus-4-20250514** | Complex reasoning | High | Slower |
| **claude-haiku-4-5-20250429** | Simple tasks | Low | Very Fast |

✅ **GOOD: Choose model based on task complexity**
```typescript
// Complex analysis
const analysis = await anthropic.messages.create({
 model: "claude-opus-4-20250514", // Use Opus for complex tasks
 max_tokens: 4000,
 messages: [{ role: "user", content: "Analyze this complex dataset..." }],
});

// Simple classification
const classification = await anthropic.messages.create({
 model: "claude-haiku-4-5-20250429", // Use Haiku for simple tasks
 max_tokens: 100,
 messages: [{ role: "user", content: "Is this positive or negative?" }],
});
```

❌ **BAD: Always using most expensive model**
```typescript
// ❌ Wasting money on simple task
const response = await anthropic.messages.create({
 model: "claude-opus-4-20250514", // Overkill for simple question
 max_tokens: 100,
 messages: [{ role: "user", content: "What's 2+2?" }],
});
```

### Sampling Parameters

**Temperature** (0.0 - 1.0):
- **0.0**: Deterministic, focused
- **0.7**: Balanced (recommended default)
- **1.0**: Creative, varied

✅ **GOOD: Match temperature to use case**
```typescript
// Factual analysis - low temperature
const analysis = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.2, // Low for consistency
 messages: [{ role: "user", content: "Calculate ROI" }],
});

// Creative writing - high temperature
const story = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.9, // High for creativity
 messages: [{ role: "user", content: "Write a story" }],
});
```

❌ **BAD: Wrong temperature for task**
```typescript
// ❌ High temperature for factual task
const analysis = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.9, // ❌ Too creative for facts!
 messages: [{ role: "user", content: "What's the formula for ROI?" }],
});
```

### Token Configuration

✅ **GOOD: Reasonable limits**
```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000, // Reasonable for most responses
 messages: [{ role: "user", content: "Explain ROI" }],
});
```

❌ **BAD: Excessive token limits**
```typescript
// ❌ Unnecessarily high - costs more
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 8000, // ❌ Way too high for simple question
 messages: [{ role: "user", content: "What's ROI?" }],
});
```

### Common Pitfalls

**Pitfall 1: Missing `max_tokens`**
```typescript
// ❌ BAD: max_tokens is required!
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 messages: [{ role: "user", content: "Hello" }],
 // ❌ Missing max_tokens - will error!
});

// ✅ GOOD: Always include max_tokens
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
});
```

**Pitfall 2: Incorrect Role Alternation**
```typescript
// ❌ BAD: Starting with assistant
const messages = [
 { role: "assistant", content: "Hello" }, // ❌ Must start with user!
];

// ✅ GOOD: Start with user
const messages = [
 { role: "user", content: "Hello" },
 { role: "assistant", content: "Hi!" },
];
```

**Pitfall 3: Not Extracting Text Properly**
```typescript
// ❌ BAD: Assuming text block exists
const text = response.content[0].text; // ❌ Unsafe!

// ✅ GOOD: Type-safe extraction
const textBlock = response.content.find(b => b.type === "text");
if (textBlock && textBlock.type === "text") {
 console.log(textBlock.text);
}
```

---

## Streaming Responses

### Why Stream?

**Benefits:**
- ✅ Improved UX - Users see responses incrementally
- ✅ Faster perceived performance
- ✅ Better for long responses
- ✅ Can cancel early if needed

### Streaming Approaches

**Approach 1: `.stream` Helper (Recommended)**
```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Write a story" }],
});

for await (const chunk of stream) {
 if (chunk.type === "content_block_delta" && chunk.delta.type === "text_delta") {
 process.stdout.write(chunk.delta.text);
 }
}

const finalMessage = await stream.finalMessage;
```

**Approach 2: `stream: true` Flag**
```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 stream: true,
 messages: [{ role: "user", content: "Write a story" }],
});

for await (const event of response) {
 if (event.type === "content_block_delta") {
 // Handle delta
 }
}
```

### ✅ Good vs ❌ Bad Patterns

**Stream Event Handling:**

✅ **GOOD: Type-safe event handling**
```typescript
for await (const chunk of stream) {
 if (chunk.type === "content_block_delta") {
 if (chunk.delta.type === "text_delta") {
 process.stdout.write(chunk.delta.text);
 }
 }
}
```

❌ **BAD: Unsafe event access**
```typescript
for await (const chunk of stream) {
 // ❌ No type checking!
 process.stdout.write(chunk.delta.text);
}
```

**Stream Cancellation:**

✅ **GOOD: Proper cancellation**
```typescript
const stream = await anthropic.messages.stream({...});

for await (const chunk of stream) {
 if (shouldCancel) {
 break; // Properly ends stream
 }
 // Process chunk
}
```

❌ **BAD: Not handling cancellation**
```typescript
const stream = await anthropic.messages.stream({...});

// ❌ No way to cancel stream
for await (const chunk of stream) {
 // Just processes everything
}
```

### Next.js Server-Sent Events Pattern

✅ **GOOD: Proper SSE implementation**
```typescript
// app/api/chat/route.ts
export async function POST(request: NextRequest) {
 const encoder = new TextEncoder;
 const stream = new ReadableStream({
 async start(controller) {
 const anthropicStream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 });

 for await (const chunk of anthropicStream) {
 if (chunk.type === "content_block_delta") {
 controller.enqueue(
 encoder.encode(`data: ${JSON.stringify(chunk)}\n\n`)
 );
 }
 }

 controller.close;
 },
 });

 return new Response(stream, {
 headers: {
 "Content-Type": "text/event-stream",
 "Cache-Control": "no-cache",
 "Connection": "keep-alive",
 },
 });
}
```

### Common Pitfalls

**Pitfall 1: Not awaiting `finalMessage`**
```typescript
// ❌ BAD: Missing final message
const stream = await anthropic.messages.stream({...});
for await (const chunk of stream) {
 // Process chunks
}
// ❌ Missing final message with usage stats

// ✅ GOOD: Get final message
const stream = await anthropic.messages.stream({...});
for await (const chunk of stream) {
 // Process chunks
}
const finalMessage = await stream.finalMessage; // ✅ Get usage stats
console.log(finalMessage.usage);
```

**Pitfall 2: Blocking the event loop**
```typescript
// ❌ BAD: Blocking processing
for await (const chunk of stream) {
 await slowDatabaseOperation(chunk); // ❌ Blocks stream!
}

// ✅ GOOD: Batch updates
const buffer: string[] = [];
for await (const chunk of stream) {
 buffer.push(chunk.delta.text);
 if (buffer.length >= 10) {
 await processBatch(buffer); // Process in batches
 buffer.length = 0;
 }
}
```

---

## Error Handling Strategies

### Error Hierarchy

```typescript
Anthropic.APIError (base class)
├── AuthenticationError (401)
├── PermissionDeniedError (403)
├── NotFoundError (404)
├── RateLimitError (429)
├── BadRequestError (400)
├── InternalServerError (500)
└── APIConnectionError (network issues)
```

### ✅ Good vs ❌ Bad Error Handling

**Basic Error Handling:**

✅ **GOOD: Specific error types**
```typescript
try {
 const response = await anthropic.messages.create({...});
} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 // Handle rate limit specifically
 console.log("Rate limited, retry after:", error.headers?.["retry-after"]);
 } else if (error instanceof Anthropic.AuthenticationError) {
 // Handle auth error
 console.error("Invalid API key");
 } else if (error instanceof Anthropic.APIError) {
 // Handle other API errors
 console.error(`API error ${error.status}: ${error.message}`);
 } else {
 // Handle unexpected errors
 console.error("Unexpected error:", error);
 }
}
```

❌ **BAD: Generic error handling**
```typescript
try {
 const response = await anthropic.messages.create({...});
} catch (error) {
 console.error("Error:", error); // ❌ Too generic!
}
```

### Retry Logic with Exponential Backoff

✅ **GOOD: Smart retry logic**
```typescript
async function callWithRetry<T>(
 fn: => Promise<T>,
 maxRetries = 3
): Promise<T> {
 for (let i = 0; i < maxRetries; i++) {
 try {
 return await fn;
 } catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 const retryAfter = parseInt(error.headers?.["retry-after"] || "1");
 await new Promise(resolve => setTimeout(resolve, retryAfter * 1000));
 continue;
 }

 if (error instanceof Anthropic.InternalServerError && i < maxRetries - 1) {
 await new Promise(resolve => setTimeout(resolve, Math.pow(2, i) * 1000));
 continue;
 }

 throw error;
 }
 }
 throw new Error("Max retries exceeded");
}

// Usage
const response = await callWithRetry( =>
 anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 })
);
```

❌ **BAD: No retry logic**
```typescript
// ❌ Fails immediately on transient errors
const response = await anthropic.messages.create({...});
```

### Circuit Breaker Pattern

✅ **GOOD: Circuit breaker for resilience**
```typescript
class CircuitBreaker {
 private failures = 0;
 private lastFailTime = 0;
 private state: "closed" | "open" | "half-open" = "closed";

 async execute<T>(fn: => Promise<T>): Promise<T> {
 if (this.state === "open") {
 if (Date.now - this.lastFailTime > 60000) {
 this.state = "half-open";
 } else {
 throw new Error("Circuit breaker is open");
 }
 }

 try {
 const result = await fn;
 if (this.state === "half-open") {
 this.state = "closed";
 this.failures = 0;
 }
 return result;
 } catch (error) {
 this.failures++;
 this.lastFailTime = Date.now;

 if (this.failures >= 5) {
 this.state = "open";
 }

 throw error;
 }
 }
}

const breaker = new CircuitBreaker;

// Usage
const response = await breaker.execute( =>
 anthropic.messages.create({...})
);
```

### Common Pitfalls

**Pitfall 1: Not handling rate limits**
```typescript
// ❌ BAD: No rate limit handling
try {
 await anthropic.messages.create({...});
} catch (error) {
 console.error("Failed"); // ❌ Doesn't retry on 429
}

// ✅ GOOD: Retry on rate limits
try {
 await anthropic.messages.create({...});
} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 const retryAfter = error.headers?.["retry-after"];
 // Retry after delay
 }
}
```

**Pitfall 2: Ignoring error details**
```typescript
// ❌ BAD: Losing error context
catch (error) {
 throw new Error("API call failed"); // ❌ Lost original error
}

// ✅ GOOD: Preserve error context
catch (error) {
 if (error instanceof Anthropic.APIError) {
 throw new Error(`API error ${error.status}: ${error.message}`, {
 cause: error
 });
 }
}
```

---

## Prompt Engineering Techniques

### System Prompt Design

✅ **GOOD: Clear, structured system prompt**
```typescript
const systemPrompt = `You are Melissa, an expert business consultant specializing in ROI analysis.

Your Role:
- Help users identify automation opportunities
- Extract concrete metrics and data
- Calculate realistic ROI projections
- Provide confidence scores for your analysis

Your Style:
- Ask clarifying questions when data is vague
- Use simple, business-friendly language
- Be direct and actionable
- Admit when you don't have enough information

Constraints:
- Only provide ROI calculations when you have sufficient data
- Always express uncertainty with confidence scores
- Don't make assumptions about metrics - ask instead
- Keep responses under 200 words unless detailed analysis is needed`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: [{ role: "user", content: "I want to automate invoicing" }],
});
```

❌ **BAD: Vague system prompt**
```typescript
const systemPrompt = "You are a helpful assistant."; // ❌ Too generic!

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: [{ role: "user", content: "I want to automate invoicing" }],
});
```

### Few-Shot Examples

✅ **GOOD: Structured examples**
```typescript
const systemPrompt = `You extract business metrics from user descriptions.

Examples:

User: "Our team spends 10 hours per week on manual data entry"
Response: { "task": "manual data entry", "time_hours_per_week": 10, "team_size": "unknown" }

User: "5 employees each spend 2 hours daily on invoicing"
Response: { "task": "invoicing", "time_hours_per_week": 50, "team_size": 5 }

Now extract metrics from the user's input.`;
```

❌ **BAD: Inconsistent examples**
```typescript
const systemPrompt = `Extract metrics.

Example 1: manual entry takes time
Example 2: 5 people do invoicing

Now do it.`; // ❌ Examples don't show format!
```

### XML Tags for Structure

✅ **GOOD: Using XML tags**
```typescript
const prompt = `Analyze this business process:

<process>
${userInput}
</process>

Provide your analysis in this format:

<analysis>
 <summary>Brief overview</summary>
 <metrics>
 <time>Hours per week</time>
 <cost>Annual cost</cost>
 </metrics>
 <confidence>0-1 score</confidence>
</analysis>`;
```

❌ **BAD: Unstructured prompt**
```typescript
const prompt = `Analyze this: ${userInput}.
Give me the time and cost.`; // ❌ No structure!
```

### Common Pitfalls

**Pitfall 1: Overloading system prompt**
```typescript
// ❌ BAD: Too much information
const systemPrompt = `You are an assistant. You should be helpful.
You should be polite. You should provide accurate information.
You should ask clarifying questions. You should be concise.
You should...`; // ❌ Information overload!

// ✅ GOOD: Focused and clear
const systemPrompt = `You are an ROI analyst.
Extract metrics, ask clarifying questions, calculate ROI.`;
```

**Pitfall 2: Not using examples**
```typescript
// ❌ BAD: No examples
const prompt = "Extract the metrics from this text";

// ✅ GOOD: With examples
const prompt = `Extract metrics as JSON.

Example: "10 hours per week" → {"hours": 10, "period": "week"}

Now extract from: "${text}"`;
```

---

## Rate Limiting & Quotas

### Rate Limit Tiers

| Tier | Sonnet 4.5 TPM (Input) | Sonnet 4.5 TPM (Output) | RPM |
|------|------------------------|-------------------------|-----|
| Free | 10,000 | 2,000 | 5 |
| Standard | 30,000 | 8,000 | 50 |
| Pro | 80,000 | 16,000 | 100 |
| Scale | Custom | Custom | Custom |

### Monitoring Rate Limits

✅ **GOOD: Track usage from headers**
```typescript
try {
 const response = await anthropic.messages.create({...});

 // Rate limit info is in headers (when approaching limits)
 console.log("Tokens used:", response.usage);

} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 console.log("Rate limit headers:", error.headers);
 // {
 // 'x-ratelimit-limit': '50',
 // 'x-ratelimit-remaining': '0',
 // 'retry-after': '30'
 // }
 }
}
```

### Request Queue Pattern

✅ **GOOD: Queue for rate limit compliance**
```typescript
class RequestQueue {
 private queue: Array< => Promise<any>> = [];
 private processing = false;
 private requestsThisMinute = 0;
 private lastReset = Date.now;
 private readonly RPM = 50;

 async enqueue<T>(fn: => Promise<T>): Promise<T> {
 return new Promise((resolve, reject) => {
 this.queue.push(async => {
 try {
 const result = await fn;
 resolve(result);
 } catch (error) {
 reject(error);
 }
 });

 if (!this.processing) {
 this.process;
 }
 });
 }

 private async process {
 this.processing = true;

 while (this.queue.length > 0) {
 // Reset counter every minute
 if (Date.now - this.lastReset > 60000) {
 this.requestsThisMinute = 0;
 this.lastReset = Date.now;
 }

 // Wait if at rate limit
 if (this.requestsThisMinute >= this.RPM) {
 const waitTime = 60000 - (Date.now - this.lastReset);
 await new Promise(resolve => setTimeout(resolve, waitTime));
 continue;
 }

 const request = this.queue.shift;
 if (request) {
 this.requestsThisMinute++;
 await request;
 }
 }

 this.processing = false;
 }
}

// Usage
const queue = new RequestQueue;

const response = await queue.enqueue( =>
 anthropic.messages.create({...})
);
```

### Common Pitfalls

**Pitfall 1: Not handling 429 errors**
```typescript
// ❌ BAD: Fails immediately on rate limit
await anthropic.messages.create({...});

// ✅ GOOD: Retry with backoff
await callWithRetry( => anthropic.messages.create({...}));
```

**Pitfall 2: Ignoring cached tokens**
```typescript
// ❌ BAD: Not using prompt caching
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: longSystemPrompt, // Not cached!
 messages: [...]
});

// ✅ GOOD: Cache large system prompts
// (Automatic caching for prompts > 1024 tokens, reused within 5 minutes)
```

---

## Token Management & Cost Optimization

### Token Pricing (Sonnet 4.5)

| Token Type | Cost per Million |
|------------|------------------|
| Input | $3.00 |
| Output | $15.00 |
| Cached Input | $0.30 (90% savings) |

### Estimating Tokens

**Rule of Thumb**: 1 token ≈ 4 characters (English)

✅ **GOOD: Estimate before calling**
```typescript
function estimateTokens(text: string): number {
 return Math.ceil(text.length / 4);
}

const prompt = "Long user input...";
const estimatedTokens = estimateTokens(prompt);

if (estimatedTokens > 100000) {
 throw new Error("Input too long");
}

const response = await anthropic.messages.create({...});
```

### Prompt Caching

**How it works:**
- Prompts > 1024 tokens are automatically cached
- Cache TTL: 5 minutes
- 90% cost savings on cached tokens

✅ **GOOD: Structure for caching**
```typescript
// ✅ GOOD: Large system prompt (will be cached)
const systemPrompt = `You are Melissa, an expert ROI analyst.

${longInstructions} // > 1024 tokens

${examples} // Will be cached
`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt, // Cached if > 1024 tokens
 messages: [{ role: "user", content: "Calculate ROI" }],
});

// Subsequent calls within 5 minutes use cached prompt (90% cheaper)
```

❌ **BAD: Not using caching**
```typescript
// ❌ BAD: Building new prompt each time
const systemPrompt = `Dynamic prompt ${Date.now}`; // Never cached!
```

### Context Trimming

✅ **GOOD: Trim old conversation history**
```typescript
function trimConversation(
 messages: Anthropic.MessageParam[],
 maxTokens: number
): Anthropic.MessageParam[] {
 let totalTokens = 0;
 const trimmedMessages: Anthropic.MessageParam[] = [];

 // Keep most recent messages
 for (let i = messages.length - 1; i >= 0; i--) {
 const msg = messages[i];
 const tokens = estimateTokens(msg.content as string);

 if (totalTokens + tokens > maxTokens) {
 break;
 }

 trimmedMessages.unshift(msg);
 totalTokens += tokens;
 }

 return trimmedMessages;
}

// Usage
const recentMessages = trimConversation(allMessages, 10000);
```

### Cost Tracking

✅ **GOOD: Track costs per session**
```typescript
interface UsageTracker {
 inputTokens: number;
 outputTokens: number;
 cachedTokens: number;
 totalCost: number;
}

function calculateCost(usage: Anthropic.Usage): number {
 const inputCost = (usage.input_tokens / 1_000_000) * 3.0;
 const outputCost = (usage.output_tokens / 1_000_000) * 15.0;
 const cachedCost = ((usage as any).cache_read_input_tokens / 1_000_000) * 0.30;

 return inputCost + outputCost + cachedCost;
}

// Track usage
const response = await anthropic.messages.create({...});
const cost = calculateCost(response.usage);

await prisma.session.update({
 where: { id: sessionId },
 data: {
 totalCost: { increment: cost },
 },
});
```

### Common Pitfalls

**Pitfall 1: Not limiting max_tokens**
```typescript
// ❌ BAD: Unlimited output
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 8000, // ❌ Too high!
 messages: [{ role: "user", content: "Hi" }],
});

// ✅ GOOD: Reasonable limits
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 500, // Appropriate for short answer
 messages: [{ role: "user", content: "Hi" }],
});
```

**Pitfall 2: Not using caching**
```typescript
// ❌ BAD: Dynamic system prompt (never cached)
const systemPrompt = `Current time: ${Date.now}\n${instructions}`;

// ✅ GOOD: Static system prompt (cached)
const systemPrompt = instructions; // Reused across requests
```

---

## Production Best Practices

### 1. Environment Configuration

✅ **GOOD: Validate all env vars**
```typescript
const requiredEnvVars = [
 "ANTHROPIC_API_KEY",
 "DATABASE_URL",
 "NEXTAUTH_SECRET",
] as const;

function validateEnvironment {
 const missing = requiredEnvVars.filter(key => !process.env[key]);
 if (missing.length > 0) {
 throw new Error(`Missing env vars: ${missing.join(", ")}`);
 }
}

// Run on startup
validateEnvironment;
```

### 2. Logging & Monitoring

✅ **GOOD: Structured logging**
```typescript
import { logger } from "@/lib/logger";

try {
 const response = await anthropic.messages.create({...});

 logger.info("AI request successful", "anthropic", {
 model: "claude-sonnet-4-5-20250929",
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 latencyMs: Date.now - startTime,
 });
} catch (error) {
 logger.error("AI request failed", "anthropic", {
 error: error instanceof Error ? error.message: String(error),
 stack: error instanceof Error ? error.stack: undefined,
 });
}
```

### 3. Input Validation

✅ **GOOD: Validate with Zod**
```typescript
import { z } from "zod";

const ChatRequestSchema = z.object({
 sessionId: z.string.min(1),
 message: z.string.min(1).max(10000),
});

export async function POST(request: NextRequest) {
 const body = await request.json;
 const { sessionId, message } = ChatRequestSchema.parse(body);
 // Validated input
}
```

### 4. Error Boundaries

✅ **GOOD: User-friendly error messages**
```typescript
try {
 const response = await anthropic.messages.create({...});
} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 return NextResponse.json(
 { error: "AI service is busy. Please try again in a moment." },
 { status: 429 }
 );
 }

 if (error instanceof Anthropic.AuthenticationError) {
 return NextResponse.json(
 { error: "AI service configuration error. Please contact support." },
 { status: 503 }
 );
 }

 return NextResponse.json(
 { error: "Unexpected error. Please try again." },
 { status: 500 }
 );
}
```

### 5. Testing

✅ **GOOD: Mock for tests**
```typescript
jest.mock("@anthropic-ai/sdk", => ({
 __esModule: true,
 default: jest.fn.mockImplementation( => ({
 messages: {
 create: jest.fn.mockResolvedValue({
 content: [{ type: "text", text: "Test response" }],
 usage: { input_tokens: 10, output_tokens: 5 },
 }),
 },
 })),
}));
```

---

## Integration Patterns

For detailed integration patterns and real-world examples, see **[FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)**.

### Key Patterns

1. **Melissa Agent Class**: Encapsulates conversation state and Claude integration
2. **Database Persistence**: Saves conversation to Prisma after each exchange
3. **Multi-Turn Context**: Builds rich context from stored transcript
4. **Phase Tracking**: Manages 6-phase conversation flow
5. **Metrics Extraction**: Pulls business metrics from conversation
6. **Type-Safe API Routes**: Uses Zod validation in Next.js routes
7. **Error Handling**: 3-tier error strategy (config, database, AI)

### Example: Melissa Agent Integration

```typescript
// See FRAMEWORK-INTEGRATION-PATTERNS.md for full implementation
const agent = await MelissaAgent.create({
 sessionId: "session-123",
});

const response = await agent.processMessage("I want to automate invoicing");
// Returns: { message, phase, progress, confidence }
```

---

## Conclusion

This comprehensive guide covers all aspects of using the Anthropic TypeScript SDK in production. For:

- **Quick Reference**: See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)
- **Getting Started**: See [README.md](./README.md)
- **Integration Examples**: See [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
- **Topic Index**: See [INDEX.md](./INDEX.md)

---

**Last Updated**: November 13, 2025
**Version**: 1.0.0
**Status**: Production Ready ✅
