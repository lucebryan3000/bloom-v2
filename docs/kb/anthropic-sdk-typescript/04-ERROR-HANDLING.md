---
id: anthropic-sdk-typescript-04-error-handling
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

# Anthropic SDK TypeScript - Error Handling Guide

Production-ready error management for robust Claude integrations.

---

## Table of Contents

1. [Overview](#overview)
2. [Error Hierarchy](#error-hierarchy)
3. [HTTP Status Codes](#http-status-codes)
4. [Retry Strategies](#retry-strategies)
5. [Rate Limit Handling](#rate-limit-handling)
6. [Timeout Handling](#timeout-handling)
7. [Network Errors](#network-errors)
8. [Validation Errors](#validation-errors)
9. [Authentication Errors](#authentication-errors)
10. [Server Errors](#server-errors)
11. [Circuit Breaker Pattern](#circuit-breaker-pattern)
12. [Logging and Monitoring](#logging-and-monitoring)
13. [User-Friendly Messages](#user-friendly-messages)
14. [Production Error Patterns](#production-error-patterns)

---

## Overview

The Anthropic SDK provides a structured error hierarchy for handling failures. Proper error handling ensures:

- Graceful degradation
- User-friendly error messages
- Automatic retries for transient failures
- Detailed logging for debugging
- Rate limit compliance

**Key principle**: Catch specific error types first, fall back to generic handlers.

---

## Error Hierarchy

### Error Class Structure

```typescript
APIError (base class)
├── BadRequestError (400)
├── AuthenticationError (401)
├── PermissionDeniedError (403)
├── NotFoundError (404)
├── RateLimitError (429)
├── InternalServerError (500+)
├── APIConnectionError (network failures)
└── APIConnectionTimeoutError (timeouts)
```

### Importing Error Classes

```typescript
import Anthropic from "@anthropic-ai/sdk";

// All error classes are properties of the Anthropic namespace
Anthropic.APIError;
Anthropic.BadRequestError;
Anthropic.AuthenticationError;
Anthropic.RateLimitError;
Anthropic.InternalServerError;
Anthropic.APIConnectionError;
Anthropic.APIConnectionTimeoutError;
```

### Type Guards

```typescript
function isAnthropicError(error: unknown): error is Anthropic.APIError {
 return error instanceof Anthropic.APIError;
}

function isRateLimitError(error: unknown): error is Anthropic.RateLimitError {
 return error instanceof Anthropic.RateLimitError;
}
```

---

## HTTP Status Codes

### Complete Status Code Reference

| Status | Error Class | Meaning | Action |
| ------ | ---------------------------- | ------------------------------------- | ------------------------------- |
| 400 | `BadRequestError` | Invalid request parameters | Fix request, don't retry |
| 401 | `AuthenticationError` | Invalid or missing API key | Check API key, don't retry |
| 403 | `PermissionDeniedError` | API key lacks permissions | Check account, don't retry |
| 404 | `NotFoundError` | Resource not found | Check endpoint, don't retry |
| 429 | `RateLimitError` | Rate limit exceeded | Wait and retry |
| 500 | `InternalServerError` | Anthropic server error | Retry with backoff |
| 529 | `InternalServerError` | Service overloaded | Retry with longer backoff |
| N/A | `APIConnectionError` | Network failure | Retry with backoff |
| N/A | `APIConnectionTimeoutError` | Request timed out | Retry with increased timeout |

### Accessing Status Codes

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 console.log("Status code:", error.status); // 400, 401, etc.
 console.log("Error message:", error.message);
 console.log("Request ID:", error.headers?.["x-request-id"]);
 }
}
```

---

## Retry Strategies

### Basic Retry with Exponential Backoff

```typescript
async function withRetry<T>(
 fn: => Promise<T>,
 maxRetries = 3,
 baseDelay = 1000
): Promise<T> {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 const isLastAttempt = attempt === maxRetries;

 if (error instanceof Anthropic.RateLimitError && !isLastAttempt) {
 // Get retry-after header or use exponential backoff
 const retryAfter =
 parseInt(error.headers?.["retry-after"] || "0") * 1000;
 const delay = retryAfter || baseDelay * Math.pow(2, attempt - 1);

 console.log(`Rate limited. Retrying in ${delay}ms...`);
 await new Promise((resolve) => setTimeout(resolve, delay));
 continue;
 }

 if (error instanceof Anthropic.InternalServerError && !isLastAttempt) {
 const delay = baseDelay * Math.pow(2, attempt - 1);
 console.log(`Server error. Retrying in ${delay}ms...`);
 await new Promise((resolve) => setTimeout(resolve, delay));
 continue;
 }

 // Don't retry for client errors (400, 401, 403, 404)
 throw error;
 }
 }

 throw new Error("Max retries exceeded");
}

// Usage
const response = await withRetry( =>
 anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 })
);
```

### Retry with Jitter

Adds randomness to prevent thundering herd problem.

```typescript
function calculateBackoff(attempt: number, baseDelay = 1000): number {
 const exponentialDelay = baseDelay * Math.pow(2, attempt - 1);
 const jitter = Math.random * exponentialDelay * 0.1; // 10% jitter
 return exponentialDelay + jitter;
}

async function withRetryJitter<T>(
 fn: => Promise<T>,
 maxRetries = 3
): Promise<T> {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 if (
 (error instanceof Anthropic.RateLimitError ||
 error instanceof Anthropic.InternalServerError) &&
 attempt < maxRetries
 ) {
 const delay = calculateBackoff(attempt);
 console.log(`Retrying in ${Math.round(delay)}ms (attempt ${attempt})`);
 await new Promise((resolve) => setTimeout(resolve, delay));
 continue;
 }
 throw error;
 }
 }
 throw new Error("Max retries exceeded");
}
```

### Conditional Retry Logic

```typescript
function shouldRetry(error: unknown, attempt: number, maxRetries: number): boolean {
 if (attempt >= maxRetries) return false;

 // Always retry rate limits
 if (error instanceof Anthropic.RateLimitError) return true;

 // Retry 500/529 errors
 if (error instanceof Anthropic.InternalServerError) return true;

 // Retry network failures
 if (error instanceof Anthropic.APIConnectionError) return true;

 // Retry timeouts
 if (error instanceof Anthropic.APIConnectionTimeoutError) return true;

 // Don't retry client errors (400, 401, 403, 404)
 return false;
}

async function smartRetry<T>(
 fn: => Promise<T>,
 maxRetries = 3
): Promise<T> {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 if (shouldRetry(error, attempt, maxRetries)) {
 const delay = calculateBackoff(attempt);
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

## Rate Limit Handling

### Understanding Rate Limits

**Anthropic Rate Limits (as of Jan 2025):**

| Tier | Requests/min | Tokens/min (input) | Tokens/min (output) |
| --------- | ------------ | ------------------ | ------------------- |
| Free | 5 | 25,000 | 5,000 |
| Standard | 50 | 40,000 | 8,000 |
| Pro | 1,000 | 400,000 | 80,000 |
| Scale | Custom | Custom | Custom |

### Rate Limit Headers

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });

 // Check rate limit headers
 console.log({
 requestsLimit: response.headers?.["anthropic-ratelimit-requests-limit"],
 requestsRemaining: response.headers?.["anthropic-ratelimit-requests-remaining"],
 requestsReset: response.headers?.["anthropic-ratelimit-requests-reset"],
 tokensLimit: response.headers?.["anthropic-ratelimit-tokens-limit"],
 tokensRemaining: response.headers?.["anthropic-ratelimit-tokens-remaining"],
 tokensReset: response.headers?.["anthropic-ratelimit-tokens-reset"],
 });
} catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 console.log("Rate limit headers:", error.headers);
 }
}
```

### Handling 429 Errors

```typescript
async function handleRateLimit<T>(fn: => Promise<T>): Promise<T> {
 try {
 return await fn;
 } catch (error) {
 if (error instanceof Anthropic.RateLimitError) {
 // Option 1: Use retry-after header
 const retryAfter = parseInt(error.headers?.["retry-after"] || "60");
 console.log(`Rate limited. Waiting ${retryAfter}s before retry...`);
 await new Promise((resolve) => setTimeout(resolve, retryAfter * 1000));

 // Retry once
 return await fn;
 }
 throw error;
 }
}
```

### Token-Based Rate Limiting

```typescript
class TokenBucket {
 private tokens: number;
 private readonly maxTokens: number;
 private readonly refillRate: number;
 private lastRefill: number;

 constructor(maxTokens: number, refillRate: number) {
 this.tokens = maxTokens;
 this.maxTokens = maxTokens;
 this.refillRate = refillRate;
 this.lastRefill = Date.now;
 }

 async consume(tokens: number): Promise<void> {
 this.refill;

 if (this.tokens < tokens) {
 const waitTime = ((tokens - this.tokens) / this.refillRate) * 1000;
 await new Promise((resolve) => setTimeout(resolve, waitTime));
 this.refill;
 }

 this.tokens -= tokens;
 }

 private refill: void {
 const now = Date.now;
 const elapsed = (now - this.lastRefill) / 1000;
 const tokensToAdd = elapsed * this.refillRate;

 this.tokens = Math.min(this.maxTokens, this.tokens + tokensToAdd);
 this.lastRefill = now;
 }
}

// Usage
const bucket = new TokenBucket(50, 50 / 60); // 50 RPM

async function rateLimitedRequest {
 await bucket.consume(1); // Wait if necessary

 const response = await anthropic.messages.create({
 /*... */
 });
 return response;
}
```

---

## Timeout Handling

### Setting Timeouts

```typescript
// Global timeout
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 timeout: 30000, // 30 seconds
});

// Per-request timeout
const response = await anthropic.messages.create(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 },
 {
 timeout: 15000, // 15 seconds for this request
 }
);
```

### Handling Timeout Errors

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.APIConnectionTimeoutError) {
 console.error("Request timed out:", error.message);

 // Option 1: Retry with longer timeout
 const retryResponse = await anthropic.messages.create(
 {
 /*... */
 },
 { timeout: 60000 } // Double the timeout
 );

 // Option 2: Fallback behavior
 return { content: [{ type: "text", text: "Request timed out. Please try again." }] };
 }
 throw error;
}
```

### Timeout with AbortController

```typescript
const controller = new AbortController;
const timeoutId = setTimeout( => controller.abort, 30000);

try {
 const response = await anthropic.messages.create(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 },
 {
 signal: controller.signal,
 }
 );
 clearTimeout(timeoutId);
 return response;
} catch (error) {
 clearTimeout(timeoutId);
 if (error.name === "AbortError") {
 console.error("Request aborted due to timeout");
 }
 throw error;
}
```

---

## Network Errors

### Handling Connection Failures

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.APIConnectionError) {
 console.error("Network error:", error.message);

 // Check network connectivity
 if (!navigator.onLine) {
 throw new Error("No internet connection");
 }

 // Retry with backoff
 const delay = 2000;
 console.log(`Retrying in ${delay}ms...`);
 await new Promise((resolve) => setTimeout(resolve, delay));

 return await anthropic.messages.create({
 /*... */
 });
 }
 throw error;
}
```

### Network Resilience Pattern

```typescript
async function resilientRequest<T>(
 fn: => Promise<T>,
 options = { maxRetries: 3, baseDelay: 1000 }
): Promise<T> {
 for (let attempt = 1; attempt <= options.maxRetries; attempt++) {
 try {
 return await fn;
 } catch (error) {
 const isNetworkError =
 error instanceof Anthropic.APIConnectionError ||
 error instanceof Anthropic.APIConnectionTimeoutError;

 if (isNetworkError && attempt < options.maxRetries) {
 const delay = options.baseDelay * Math.pow(2, attempt - 1);
 console.log(`Network error. Retrying in ${delay}ms... (${attempt}/${options.maxRetries})`);
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

## Validation Errors

### Handling 400 Errors

```typescript
try {
 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 });
} catch (error) {
 if (error instanceof Anthropic.BadRequestError) {
 console.error("Invalid request:", error.message);

 // Parse error details
 const errorBody = JSON.parse(error.message || "{}");
 console.error("Error type:", errorBody.type);
 console.error("Error details:", errorBody.error);

 // Common 400 errors:
 // - Missing required parameter (max_tokens)
 // - Invalid model name
 // - Messages not alternating user/assistant
 // - Empty messages array
 // - Invalid content format

 throw new Error("Invalid request parameters. Please check your input.");
 }
 throw error;
}
```

### Pre-Request Validation

```typescript
function validateMessageRequest(
 params: Anthropic.MessageCreateParams
): void {
 if (!params.model) {
 throw new Error("Model is required");
 }

 if (!params.max_tokens || params.max_tokens < 1) {
 throw new Error("max_tokens must be >= 1");
 }

 if (!params.messages || params.messages.length === 0) {
 throw new Error("At least one message is required");
 }

 if (params.messages[0].role !== "user") {
 throw new Error("First message must have role 'user'");
 }

 // Check role alternation
 for (let i = 1; i < params.messages.length; i++) {
 const prev = params.messages[i - 1].role;
 const curr = params.messages[i].role;
 if (prev === curr) {
 throw new Error(`Messages must alternate roles (found ${curr} after ${prev} at index ${i})`);
 }
 }
}

// Usage
try {
 validateMessageRequest(params);
 const response = await anthropic.messages.create(params);
} catch (error) {
 console.error("Validation failed:", error.message);
}
```

---

## Authentication Errors

### Handling 401 Errors

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.AuthenticationError) {
 console.error("Authentication failed:", error.message);

 // Common causes:
 // - Missing API key
 // - Invalid API key
 // - Expired API key (rare)

 // Check environment variable
 if (!process.env.ANTHROPIC_API_KEY) {
 throw new Error("ANTHROPIC_API_KEY environment variable is not set");
 }

 // Verify API key format
 const apiKey = process.env.ANTHROPIC_API_KEY;
 if (!apiKey.startsWith("sk-ant-api03-")) {
 throw new Error("Invalid API key format. Must start with 'sk-ant-api03-'");
 }

 throw new Error("Invalid API key. Please check your credentials.");
 }
 throw error;
}
```

### API Key Validation

```typescript
function validateAPIKey(apiKey: string | undefined): void {
 if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY is required");
 }

 if (typeof apiKey !== "string") {
 throw new Error("ANTHROPIC_API_KEY must be a string");
 }

 if (!apiKey.startsWith("sk-ant-api03-")) {
 throw new Error("Invalid API key format");
 }

 if (apiKey.length < 50) {
 throw new Error("API key appears to be incomplete");
 }
}

// Use at startup
validateAPIKey(process.env.ANTHROPIC_API_KEY);
```

---

## Server Errors

### Handling 500/529 Errors

```typescript
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.InternalServerError) {
 const status = error.status;

 if (status === 529) {
 // Service overloaded - wait longer before retry
 console.error("Anthropic service overloaded. Waiting 30s before retry...");
 await new Promise((resolve) => setTimeout(resolve, 30000));
 } else {
 // Generic 500 error - shorter retry
 console.error("Anthropic server error. Retrying in 5s...");
 await new Promise((resolve) => setTimeout(resolve, 5000));
 }

 // Retry once
 return await anthropic.messages.create({
 /*... */
 });
 }
 throw error;
}
```

---

## Circuit Breaker Pattern

Prevents cascading failures by stopping requests after repeated failures.

```typescript
class CircuitBreaker {
 private failureCount = 0;
 private lastFailureTime: number | null = null;
 private state: "closed" | "open" | "half-open" = "closed";

 constructor(
 private readonly failureThreshold = 5,
 private readonly resetTimeout = 60000 // 1 minute
 ) {}

 async execute<T>(fn: => Promise<T>): Promise<T> {
 if (this.state === "open") {
 if (
 this.lastFailureTime &&
 Date.now - this.lastFailureTime > this.resetTimeout
 ) {
 console.log("Circuit breaker: Attempting reset (half-open)");
 this.state = "half-open";
 } else {
 throw new Error("Circuit breaker is open. Service unavailable.");
 }
 }

 try {
 const result = await fn;

 // Success - reset circuit
 if (this.state === "half-open") {
 console.log("Circuit breaker: Reset successful (closed)");
 }
 this.failureCount = 0;
 this.state = "closed";
 return result;
 } catch (error) {
 this.failureCount++;
 this.lastFailureTime = Date.now;

 if (this.failureCount >= this.failureThreshold) {
 console.error(`Circuit breaker: Opened after ${this.failureCount} failures`);
 this.state = "open";
 }

 throw error;
 }
 }

 getState: string {
 return this.state;
 }

 reset: void {
 this.failureCount = 0;
 this.state = "closed";
 this.lastFailureTime = null;
 }
}

// Usage
const breaker = new CircuitBreaker(5, 60000);

async function protectedRequest {
 return await breaker.execute( =>
 anthropic.messages.create({
 /*... */
 })
 );
}
```

---

## Logging and Monitoring

### Structured Error Logging

```typescript
interface ErrorLog {
 timestamp: string;
 errorType: string;
 statusCode?: number;
 message: string;
 requestId?: string;
 context?: Record<string, unknown>;
}

function logError(error: unknown, context?: Record<string, unknown>): void {
 const log: ErrorLog = {
 timestamp: new Date.toISOString,
 errorType: error?.constructor?.name || "UnknownError",
 message: error instanceof Error ? error.message: String(error),
 context,
 };

 if (error instanceof Anthropic.APIError) {
 log.statusCode = error.status;
 log.requestId = error.headers?.["x-request-id"];
 }

 console.error(JSON.stringify(log));

 // Send to monitoring service
 // sendToMonitoring(log);
}

// Usage
try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 logError(error, {
 model: "claude-sonnet-4-5-20250929",
 sessionId: "session-123",
 });
 throw error;
}
```

### Error Metrics

```typescript
class ErrorMetrics {
 private metrics = {
 total: 0,
 byType: new Map<string, number>,
 byStatus: new Map<number, number>,
 };

 record(error: unknown): void {
 this.metrics.total++;

 const errorType = error?.constructor?.name || "UnknownError";
 this.metrics.byType.set(errorType, (this.metrics.byType.get(errorType) || 0) + 1);

 if (error instanceof Anthropic.APIError && error.status) {
 this.metrics.byStatus.set(
 error.status,
 (this.metrics.byStatus.get(error.status) || 0) + 1
 );
 }
 }

 getMetrics {
 return {
 total: this.metrics.total,
 byType: Object.fromEntries(this.metrics.byType),
 byStatus: Object.fromEntries(this.metrics.byStatus),
 };
 }

 reset: void {
 this.metrics = {
 total: 0,
 byType: new Map,
 byStatus: new Map,
 };
 }
}

// Usage
const errorMetrics = new ErrorMetrics;

try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 errorMetrics.record(error);
 throw error;
}

// View metrics
console.log(errorMetrics.getMetrics);
```

---

## User-Friendly Messages

### Error to User Message Mapping

```typescript
function getUserFriendlyError(error: unknown): string {
 if (error instanceof Anthropic.AuthenticationError) {
 return "Unable to authenticate with AI service. Please contact support.";
 }

 if (error instanceof Anthropic.RateLimitError) {
 return "Too many requests. Please wait a moment and try again.";
 }

 if (error instanceof Anthropic.BadRequestError) {
 return "Invalid input. Please check your message and try again.";
 }

 if (error instanceof Anthropic.InternalServerError) {
 return "AI service is temporarily unavailable. Please try again in a few moments.";
 }

 if (error instanceof Anthropic.APIConnectionError) {
 return "Network error. Please check your connection and try again.";
 }

 if (error instanceof Anthropic.APIConnectionTimeoutError) {
 return "Request timed out. Please try again.";
 }

 return "An unexpected error occurred. Please try again or contact support.";
}

// Usage in API route
export async function POST(request: NextRequest) {
 try {
 const response = await anthropic.messages.create({
 /*... */
 });
 return NextResponse.json({ response });
 } catch (error) {
 const userMessage = getUserFriendlyError(error);
 return NextResponse.json({ error: userMessage }, { status: 500 });
 }
}
```

---

## Production Error Patterns

### Example: Custom Error Handler

```typescript
// lib/melissa/errorHandler.ts
export class MelissaErrorHandler {
 static handle(error: unknown, context: { sessionId: string }): never {
 // Log error
 console.error("Melissa error:", {
 error: error instanceof Error ? error.message: String(error),
 sessionId: context.sessionId,
 timestamp: new Date.toISOString,
 });

 // Specific handling
 if (error instanceof Anthropic.RateLimitError) {
 throw new Error("AI service rate limit reached. Please try again in a moment.");
 }

 if (error instanceof Anthropic.AuthenticationError) {
 throw new Error("AI service authentication failed. Please contact support.");
 }

 if (error instanceof Anthropic.BadRequestError) {
 throw new Error("Invalid request to AI service. Please check your input.");
 }

 // Generic fallback
 throw new Error("Failed to generate AI response. Please try again.");
 }
}
```

### Example: API Route Error Handling

```typescript
// app/api/melissa/chat/route.ts
export async function POST(request: NextRequest) {
 try {
 const { message, sessionId } = await request.json;

 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: message }],
 });

 return NextResponse.json({ response });
 } catch (error) {
 console.error("Chat API error:", error);

 if (error instanceof Anthropic.APIError) {
 return NextResponse.json(
 { error: getUserFriendlyError(error) },
 { status: error.status || 500 }
 );
 }

 return NextResponse.json(
 { error: "An unexpected error occurred" },
 { status: 500 }
 );
 }
}
```

---

## Best Practices

### 1. Catch Specific Errors First

```typescript
try {
 await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 // Specific errors first
 if (error instanceof Anthropic.RateLimitError) {
 // Handle rate limit
 } else if (error instanceof Anthropic.AuthenticationError) {
 // Handle auth error
 } else if (error instanceof Anthropic.APIError) {
 // Generic API error
 } else {
 // Non-API error
 }
}
```

### 2. Always Log Errors

Include context for debugging:

```typescript
console.error("Error context:", {
 error: error.message,
 sessionId,
 userId,
 timestamp: new Date.toISOString,
});
```

### 3. Return User-Friendly Messages

Never expose internal error details to users.

### 4. Implement Retries for Transient Failures

Use exponential backoff with jitter.

### 5. Monitor Error Rates

Track error types and rates to detect issues early.

---

## See Also

- [02-MESSAGES-API.md](./02-MESSAGES-API.md) - Messages API reference
- [03-STREAMING.md](./03-STREAMING.md) - Streaming guide
- [06-RATE-LIMITING.md](./06-RATE-LIMITING.md) - Rate limit management
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [Official Error Handling Docs](https://docs.anthropic.com/claude/reference/errors)
