---
id: anthropic-sdk-typescript-quick-reference
topic: anthropic-sdk-typescript
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Quick Reference

Fast lookup card for common patterns and essential snippets.

---

## Installation

```bash
npm install @anthropic-ai/sdk
# Current version: 0.27.3
```

---

## Environment Setup

```bash
#.env.local
ANTHROPIC_API_KEY="sk-ant-api03-..."
```

---

## Basic Client Setup

```typescript
import Anthropic from "@anthropic-ai/sdk";

// Initialize client
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});
```

**With validation:**

```typescript
const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY environment variable is required");
}

const anthropic = new Anthropic({ apiKey });
```

---

## Common Message Patterns

### 1. Simple Message (One-Shot)

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "What is the capital of France?",
 },
 ],
});

// Extract text from response
const textContent = response.content.find((block) => block.type === "text");
if (textContent && textContent.type === "text") {
 console.log(textContent.text);
}
```

### 2. Message with System Prompt

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: "You are a helpful business consultant specializing in ROI analysis.",
 messages: [
 {
 role: "user",
 content: "How do I calculate ROI for automation?",
 },
 ],
});
```

### 3. Multi-Turn Conversation

```typescript
const messages: Anthropic.MessageParam[] = [
 {
 role: "user",
 content: "What's 2+2?",
 },
 {
 role: "assistant",
 content: "2+2 equals 4.",
 },
 {
 role: "user",
 content: "What about 3+3?",
 },
];

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages,
});
```

---

## Streaming Basics

### Using `.stream` helper:

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Tell me a story" }],
});

for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 }
}
```

### Using `stream: true`:

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 stream: true,
 messages: [{ role: "user", content: "Tell me a story" }],
});

// Process stream chunks
for await (const event of response) {
 if (event.type === "content_block_delta") {
 // Handle delta
 }
}
```

---

## Error Handling

```typescript
import Anthropic from "@anthropic-ai/sdk";

try {
 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 });
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 console.error("API Error:", {
 status: error.status,
 message: error.message,
 type: error.type,
 });
 } else {
 console.error("Unexpected error:", error);
 }
}
```

**Common error types:**

- `Anthropic.APIError` - Base API error class
- `Anthropic.BadRequestError` - 400 errors
- `Anthropic.AuthenticationError` - 401 errors
- `Anthropic.PermissionDeniedError` - 403 errors
- `Anthropic.NotFoundError` - 404 errors
- `Anthropic.RateLimitError` - 429 errors
- `Anthropic.InternalServerError` - 500 errors

---

## Type Imports

```typescript
import type {
 MessageParam, // Message in conversation
 ContentBlock, // Response content block
 TextBlock, // Text content block
 Message, // Complete message response
 MessageCreateParams, // Message creation parameters
} from "@anthropic-ai/sdk/resources/messages";
```

---

## Token Usage Access

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
});

console.log({
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
});
```

---

## Rate Limit Headers

```typescript
// Rate limits are returned in response headers
// Access them via error.headers when rate limited

try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 console.log("Rate limit headers:", error.headers);
 // Headers include: x-ratelimit-limit, x-ratelimit-remaining, retry-after
 }
}
```

**Example rate limits (Standard tier):**

- 50 requests per minute (RPM)
- 30,000 input tokens per minute
- 8,000 output tokens per minute

---

## Retry Logic Snippet

```typescript
async function callWithRetry<T>(
 fn: => Promise<T>,
 maxRetries = 3,
 delayMs = 1000,
): Promise<T> {
 let lastError: Error | undefined;

 for (let i = 0; i < maxRetries; i++) {
 try {
 return await fn;
 } catch (error) {
 lastError = error as Error;

 if (error instanceof Anthropic.RateLimitError) {
 const retryAfter = parseInt(error.headers?.["retry-after"] || "1");
 await new Promise((resolve) =>
 setTimeout(resolve, retryAfter * 1000),
 );
 continue;
 }

 // Only retry on rate limit or 5xx errors
 if (
 !(error instanceof Anthropic.InternalServerError) &&
 !(error instanceof Anthropic.RateLimitError)
 ) {
 throw error;
 }

 if (i < maxRetries - 1) {
 await new Promise((resolve) => setTimeout(resolve, delayMs * (i + 1)));
 }
 }
 }

 throw lastError;
}

// Usage
const response = await callWithRetry( =>
 anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 }),
);
```

---

## Model Configuration Cheatsheet

```typescript
const response = await anthropic.messages.create({
 // Model selection
 model: "claude-sonnet-4-5-20250929", // Latest Sonnet 4.5 (recommended)

 // Token control
 max_tokens: 1000, // Required, max output tokens

 // Sampling parameters
 temperature: 0.7, // 0.0-1.0, higher = more creative (recommended: 0.7)
 top_p: 0.9, // Nucleus sampling (recommended: 0.9)
 top_k: 40, // Top-K sampling (optional)

 // System prompt
 system: "You are a helpful assistant.",

 // Messages
 messages: [
 /*... */
 ],

 // Streaming
 stream: false, // true for streaming responses

 // Stop sequences (optional)
 stop_sequences: ["\n\nHuman:", "END"],

 // Metadata (optional)
 metadata: {
 user_id: "user-123",
 },
});
```

---

## See Also

- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Production integration patterns
- [01-INSTALLATION-SETUP.md](./01-INSTALLATION-SETUP.md) - Complete setup guide
- [02-MESSAGES-API.md](./02-MESSAGES-API.md) - Detailed Messages API reference
- [Official SDK Docs](https://github.com/anthropics/anthropic-sdk-typescript)
