---
id: anthropic-sdk-typescript-03-streaming
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

# Anthropic SDK TypeScript - Streaming Guide

Complete guide to streaming responses from Claude for real-time, interactive user experiences.

---

## Table of Contents

1. [Overview](#overview)
2. [Why Use Streaming](#why-use-streaming)
3. [Two Streaming Approaches](#two-streaming-approaches)
4. [Stream Event Types](#stream-event-types)
5. [Handling Stream Events](#handling-stream-events)
6. [Canceling Streams](#canceling-streams)
7. [Error Handling](#error-handling)
8. [Next.js App Router SSE Pattern](#nextjs-app-router-sse-pattern)
9. [React Hooks for Streaming](#react-hooks-for-streaming)
10. [Backpressure Management](#backpressure-management)
11. [Testing Streaming Responses](#testing-streaming-responses)

---

## Overview

Streaming allows Claude's responses to be delivered incrementally as they're generated, rather than waiting for the complete response. This creates a more responsive, ChatGPT-like user experience.

**Benefits:**
- Faster perceived performance (TTFB < 1s)
- Better UX for long responses
- Reduced user wait time
- Real-time feedback

**When to use streaming:**
- Conversational interfaces
- Long-form content generation
- Real-time analysis
- Interactive assistants

**When NOT to use streaming:**
- Batch processing
- Automated workflows
- When full response validation is required before display
- Background jobs

---

## Why Use Streaming

### UX Benefits

**Without Streaming:**
```
User sends message → [10 second wait] → Full response appears
```

**With Streaming:**
```
User sends message → [0.5s] → Response starts appearing word-by-word → [10s total] → Complete
```

### Perceived Performance

```typescript
// Non-streaming: 10s wait, then instant display
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Write a long essay" }],
});
// User waits 10 full seconds before seeing anything

// Streaming: Content appears in 500ms, full response in 10s
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Write a long essay" }],
});
// User sees first words in 500ms, response continues streaming
```

### Performance Comparison

| Metric | Non-Streaming | Streaming |
| ------------------------------- | ------------- | --------- |
| Time to First Byte (TTFB) | ~10s | ~0.5s |
| Perceived response time | 10s | 0.5s |
| Total generation time | 10s | 10s |
| User engagement | Low (waiting) | High (reading) |

---

## Two Streaming Approaches

### Approach 1: `.stream` Helper (Recommended)

Simplified streaming API with automatic event handling.

```typescript
import Anthropic from "@anthropic-ai/sdk";

const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});

const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Tell me a story" }],
});

// Simple iteration
for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 }
}

// Get final message with usage data
const finalMessage = await stream.finalMessage;
console.log("\nTokens used:", finalMessage.usage);
```

**Pros:**
- Simpler API
- Automatic event filtering
- Access to `finalMessage` helper
- Less boilerplate

**Cons:**
- Less control over event handling
- Slightly higher-level abstraction

### Approach 2: `stream: true` Parameter

Lower-level streaming with full event control.

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 stream: true, // Enable streaming
 messages: [{ role: "user", content: "Tell me a story" }],
});

for await (const event of response) {
 switch (event.type) {
 case "message_start":
 console.log("Message started:", event.message);
 break;
 case "content_block_start":
 console.log("Content block started:", event.index);
 break;
 case "content_block_delta":
 if (event.delta.type === "text_delta") {
 process.stdout.write(event.delta.text);
 }
 break;
 case "content_block_stop":
 console.log("\nContent block finished");
 break;
 case "message_delta":
 console.log("Message delta:", event.delta);
 break;
 case "message_stop":
 console.log("Message complete");
 break;
 }
}
```

**Pros:**
- Full control over all events
- Access to message metadata throughout stream
- Better for complex event handling

**Cons:**
- More boilerplate
- Manual event filtering required

---

## Stream Event Types

### Complete Event Reference

```typescript
type MessageStreamEvent =
 | MessageStartEvent
 | ContentBlockStartEvent
 | ContentBlockDeltaEvent
 | ContentBlockStopEvent
 | MessageDeltaEvent
 | MessageStopEvent;
```

### Event Sequence

```
1. message_start (once, at beginning)
2. content_block_start (once per content block)
3. content_block_delta (multiple times, actual content)
4. content_block_stop (once per content block)
5. message_delta (usage updates)
6. message_stop (once, at end)
```

### Event Details

#### 1. `message_start`

First event, provides initial message metadata.

```typescript
{
 type: "message_start",
 message: {
 id: "msg_01ABC123",
 type: "message",
 role: "assistant",
 content: [],
 model: "claude-sonnet-4-5-20250929",
 stop_reason: null,
 stop_sequence: null,
 usage: { input_tokens: 10, output_tokens: 0 }
 }
}
```

#### 2. `content_block_start`

Signals start of a content block.

```typescript
{
 type: "content_block_start",
 index: 0,
 content_block: {
 type: "text",
 text: ""
 }
}
```

#### 3. `content_block_delta`

Contains incremental text content (most frequent event).

```typescript
{
 type: "content_block_delta",
 index: 0,
 delta: {
 type: "text_delta",
 text: "Hello" // Incremental text chunk
 }
}
```

#### 4. `content_block_stop`

Signals end of a content block.

```typescript
{
 type: "content_block_stop",
 index: 0
}
```

#### 5. `message_delta`

Provides stop reason and updated usage.

```typescript
{
 type: "message_delta",
 delta: {
 stop_reason: "end_turn",
 stop_sequence: null
 },
 usage: {
 output_tokens: 150
 }
}
```

#### 6. `message_stop`

Final event, signals completion.

```typescript
{
 type: "message_stop"
}
```

---

## Handling Stream Events

### Basic Text Extraction

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

let fullText = "";

for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 fullText += chunk.delta.text;
 process.stdout.write(chunk.delta.text); // Real-time output
 }
}

console.log("\n\nFull response:", fullText);
```

### Tracking Usage During Stream

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

let inputTokens = 0;
let outputTokens = 0;

for await (const event of stream) {
 if (event.type === "message_start") {
 inputTokens = event.message.usage.input_tokens;
 } else if (event.type === "message_delta") {
 outputTokens = event.usage.output_tokens;
 }
}

console.log({
 inputTokens,
 outputTokens,
 totalTokens: inputTokens + outputTokens,
});
```

### Handling Multiple Content Blocks

```typescript
const contentBlocks: string[] = [];
let currentBlock = "";
let currentIndex = 0;

for await (const event of stream) {
 switch (event.type) {
 case "content_block_start":
 currentIndex = event.index;
 currentBlock = "";
 break;

 case "content_block_delta":
 if (event.delta.type === "text_delta") {
 currentBlock += event.delta.text;
 }
 break;

 case "content_block_stop":
 contentBlocks[currentIndex] = currentBlock;
 break;
 }
}

console.log("Content blocks:", contentBlocks);
```

---

## Canceling Streams

### Using `break` Statement

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

let charCount = 0;
const MAX_CHARS = 100;

for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 charCount += chunk.delta.text.length;

 if (charCount >= MAX_CHARS) {
 console.log("\n\nReached character limit, stopping stream");
 break; // Cancels the stream
 }
 }
}
```

### Using AbortController

```typescript
const controller = new AbortController;
const signal = controller.signal;

// Cancel after 5 seconds
setTimeout( => {
 console.log("Timeout reached, canceling stream");
 controller.abort;
}, 5000);

try {
 const stream = await anthropic.messages.stream(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 },
 {
 signal, // Pass abort signal
 }
 );

 for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 }
 }
} catch (error) {
 if (error.name === "AbortError") {
 console.log("\nStream canceled by user");
 } else {
 throw error;
 }
}
```

### React Example: Cancel Button

```typescript
function ChatComponent {
 const [isStreaming, setIsStreaming] = useState(false);
 const abortControllerRef = useRef<AbortController | null>(null);

 const handleSendMessage = async (message: string) => {
 abortControllerRef.current = new AbortController;
 setIsStreaming(true);

 try {
 const response = await fetch("/api/chat", {
 method: "POST",
 body: JSON.stringify({ message }),
 signal: abortControllerRef.current.signal,
 });

 // Process streaming response...
 } catch (error) {
 if (error.name === "AbortError") {
 console.log("User canceled stream");
 }
 } finally {
 setIsStreaming(false);
 }
 };

 const handleCancel = => {
 abortControllerRef.current?.abort;
 };

 return (
 <div>
 {isStreaming && (
 <button onClick={handleCancel}>Cancel Response</button>
 )}
 </div>
 );
}
```

---

## Error Handling

### Basic Error Handling

```typescript
import Anthropic from "@anthropic-ai/sdk";

try {
 const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 });

 for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 }
 }

 const finalMessage = await stream.finalMessage;
 console.log("\nStream completed successfully");
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 console.error("API Error:", error.status, error.message);
 } else if (error.name === "AbortError") {
 console.log("Stream canceled");
 } else {
 console.error("Unexpected error:", error);
 }
}
```

### Handling Stream Interruptions

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

let fullText = "";
let completed = false;

try {
 for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 fullText += chunk.delta.text;
 process.stdout.write(chunk.delta.text);
 } else if (chunk.type === "message_stop") {
 completed = true;
 }
 }
} catch (error) {
 console.error("Stream error:", error);
} finally {
 if (!completed) {
 console.warn("Stream did not complete normally");
 console.log("Partial response:", fullText);
 }
}
```

### Retry Logic for Failed Streams

```typescript
async function streamWithRetry(
 anthropic: Anthropic,
 params: Anthropic.MessageCreateParams,
 maxRetries = 3
) {
 for (let attempt = 1; attempt <= maxRetries; attempt++) {
 try {
 const stream = await anthropic.messages.stream(params);
 return stream; // Success
 } catch (error) {
 if (error instanceof Anthropic.RateLimitError && attempt < maxRetries) {
 const retryAfter = parseInt(error.headers?.["retry-after"] || "5");
 console.log(`Rate limited. Retrying in ${retryAfter}s...`);
 await new Promise((resolve) => setTimeout(resolve, retryAfter * 1000));
 } else {
 throw error; // Give up
 }
 }
 }
 throw new Error("Max retries exceeded");
}
```

---

## Next.js App Router SSE Pattern

### Server: Streaming API Route

```typescript
// app/api/chat/stream/route.ts
import { NextRequest } from "next/server";
import Anthropic from "@anthropic-ai/sdk";

export async function POST(request: NextRequest) {
 const { message } = await request.json;

 const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 });

 const encoder = new TextEncoder;

 const stream = new ReadableStream({
 async start(controller) {
 try {
 const messageStream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: message }],
 });

 for await (const chunk of messageStream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 // Send SSE-formatted data
 const data = encoder.encode(`data: ${chunk.delta.text}\n\n`);
 controller.enqueue(data);
 }
 }

 // Send final event
 controller.enqueue(encoder.encode("data: [DONE]\n\n"));
 controller.close;
 } catch (error) {
 console.error("Stream error:", error);
 controller.error(error);
 }
 },
 });

 return new Response(stream, {
 headers: {
 "Content-Type": "text/event-stream",
 "Cache-Control": "no-cache, no-transform",
 Connection: "keep-alive",
 "X-Accel-Buffering": "no", // Disable Nginx buffering
 },
 });
}
```

### Client: React Hook for SSE

```typescript
// hooks/useStreamingChat.ts
import { useState, useCallback } from "react";

export function useStreamingChat {
 const [response, setResponse] = useState("");
 const [isStreaming, setIsStreaming] = useState(false);
 const [error, setError] = useState<string | null>(null);

 const sendMessage = useCallback(async (message: string) => {
 setResponse("");
 setIsStreaming(true);
 setError(null);

 try {
 const res = await fetch("/api/chat/stream", {
 method: "POST",
 headers: { "Content-Type": "application/json" },
 body: JSON.stringify({ message }),
 });

 if (!res.ok) {
 throw new Error(`HTTP ${res.status}: ${res.statusText}`);
 }

 const reader = res.body?.getReader;
 const decoder = new TextDecoder;

 if (!reader) {
 throw new Error("No response body");
 }

 while (true) {
 const { done, value } = await reader.read;
 if (done) break;

 const chunk = decoder.decode(value);
 const lines = chunk.split("\n");

 for (const line of lines) {
 if (line.startsWith("data: ")) {
 const data = line.slice(6);
 if (data === "[DONE]") {
 setIsStreaming(false);
 return;
 }
 setResponse((prev) => prev + data);
 }
 }
 }
 } catch (err) {
 setError(err instanceof Error ? err.message: "Unknown error");
 setIsStreaming(false);
 }
 }, []);

 return { response, isStreaming, error, sendMessage };
}
```

### Client: Component Usage

```typescript
// components/StreamingChat.tsx
"use client";

import { useState } from "react";
import { useStreamingChat } from "@/hooks/useStreamingChat";

export function StreamingChat {
 const [input, setInput] = useState("");
 const { response, isStreaming, error, sendMessage } = useStreamingChat;

 const handleSubmit = async (e: React.FormEvent) => {
 e.preventDefault;
 if (!input.trim) return;
 await sendMessage(input);
 };

 return (
 <div className="space-y-4">
 <form onSubmit={handleSubmit}>
 <input
 type="text"
 value={input}
 onChange={(e) => setInput(e.target.value)}
 disabled={isStreaming}
 placeholder="Type a message..."
 className="w-full p-2 border rounded"
 />
 <button type="submit" disabled={isStreaming}>
 {isStreaming ? "Streaming...": "Send"}
 </button>
 </form>

 {error && <div className="text-red-500">{error}</div>}

 <div className="response-container">
 {response}
 {isStreaming && <span className="blinking-cursor">▊</span>}
 </div>
 </div>
 );
}
```

---

## React Hooks for Streaming

### Complete useStreamingAI Hook

```typescript
// hooks/useStreamingAI.ts
import { useState, useCallback, useRef } from "react";

interface UseStreamingAIOptions {
 onComplete?: (fullResponse: string) => void;
 onError?: (error: Error) => void;
 onChunk?: (chunk: string) => void;
}

export function useStreamingAI(options: UseStreamingAIOptions = {}) {
 const [response, setResponse] = useState("");
 const [isStreaming, setIsStreaming] = useState(false);
 const [error, setError] = useState<Error | null>(null);
 const abortControllerRef = useRef<AbortController | null>(null);

 const stream = useCallback(
 async (endpoint: string, body: unknown) => {
 // Reset state
 setResponse("");
 setError(null);
 setIsStreaming(true);

 // Create abort controller
 abortControllerRef.current = new AbortController;

 try {
 const res = await fetch(endpoint, {
 method: "POST",
 headers: { "Content-Type": "application/json" },
 body: JSON.stringify(body),
 signal: abortControllerRef.current.signal,
 });

 if (!res.ok) {
 throw new Error(`HTTP ${res.status}: ${res.statusText}`);
 }

 const reader = res.body?.getReader;
 const decoder = new TextDecoder;

 if (!reader) {
 throw new Error("No response body");
 }

 let fullResponse = "";

 while (true) {
 const { done, value } = await reader.read;
 if (done) break;

 const chunk = decoder.decode(value);
 const lines = chunk.split("\n");

 for (const line of lines) {
 if (line.startsWith("data: ")) {
 const data = line.slice(6);
 if (data === "[DONE]") {
 setIsStreaming(false);
 options.onComplete?.(fullResponse);
 return fullResponse;
 }

 fullResponse += data;
 setResponse(fullResponse);
 options.onChunk?.(data);
 }
 }
 }

 setIsStreaming(false);
 options.onComplete?.(fullResponse);
 return fullResponse;
 } catch (err) {
 const error = err instanceof Error ? err: new Error("Unknown error");
 setError(error);
 setIsStreaming(false);
 options.onError?.(error);
 throw error;
 }
 },
 [options]
 );

 const cancel = useCallback( => {
 abortControllerRef.current?.abort;
 setIsStreaming(false);
 }, []);

 const reset = useCallback( => {
 setResponse("");
 setError(null);
 setIsStreaming(false);
 }, []);

 return {
 response,
 isStreaming,
 error,
 stream,
 cancel,
 reset,
 };
}
```

---

## Backpressure Management

### Understanding Backpressure

Backpressure occurs when the consumer (frontend) can't process chunks as fast as they're produced.

**Symptoms:**
- Memory buildup
- UI freezing
- Dropped chunks

### Throttling Stream Updates

```typescript
// Throttle UI updates to every 50ms
let buffer = "";
let updateTimer: NodeJS.Timeout | null = null;

for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 buffer += chunk.delta.text;

 if (!updateTimer) {
 updateTimer = setTimeout( => {
 setResponse((prev) => prev + buffer);
 buffer = "";
 updateTimer = null;
 }, 50);
 }
 }
}

// Flush remaining buffer
if (buffer) {
 setResponse((prev) => prev + buffer);
}
```

### Batching Chunks

```typescript
const BATCH_SIZE = 10;
let chunkBuffer: string[] = [];

for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 chunkBuffer.push(chunk.delta.text);

 if (chunkBuffer.length >= BATCH_SIZE) {
 const batch = chunkBuffer.join("");
 setResponse((prev) => prev + batch);
 chunkBuffer = [];
 }
 }
}

// Flush remaining
if (chunkBuffer.length > 0) {
 setResponse((prev) => prev + chunkBuffer.join(""));
}
```

---

## Testing Streaming Responses

### Mock Streaming Response

```typescript
// __tests__/mocks/streamingMock.ts
export function createMockStream(text: string, chunkSize = 5) {
 const chunks = text.match(new RegExp(`.{1,${chunkSize}}`, "g")) || [];

 return {
 async *[Symbol.asyncIterator] {
 for (const chunk of chunks) {
 await new Promise((resolve) => setTimeout(resolve, 10)); // Simulate delay
 yield {
 type: "content_block_delta" as const,
 delta: {
 type: "text_delta" as const,
 text: chunk,
 },
 };
 }
 },
 async finalMessage {
 return {
 content: [{ type: "text" as const, text }],
 usage: { input_tokens: 10, output_tokens: text.length / 4 },
 };
 },
 };
}
```

### Jest Test Example

```typescript
// __tests__/streaming.test.ts
import { createMockStream } from "./mocks/streamingMock";

describe("Streaming", => {
 it("should process stream chunks correctly", async => {
 const mockText = "Hello, world!";
 const stream = createMockStream(mockText, 3);

 let result = "";
 for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 result += chunk.delta.text;
 }
 }

 expect(result).toBe(mockText);
 });

 it("should handle stream cancellation", async => {
 const stream = createMockStream("This is a long text", 3);

 let result = "";
 for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 result += chunk.delta.text;
 if (result.length >= 10) break; // Cancel early
 }
 }

 expect(result.length).toBeLessThan(19);
 });
});
```

### Testing SSE Endpoint

```typescript
// __tests__/api/chat/stream.test.ts
import { POST } from "@/app/api/chat/stream/route";
import { NextRequest } from "next/server";

describe("POST /api/chat/stream", => {
 it("should stream response as SSE", async => {
 const request = new NextRequest("http://localhost:3001/api/chat/stream", {
 method: "POST",
 body: JSON.stringify({ message: "Hello" }),
 });

 const response = await POST(request);

 expect(response.status).toBe(200);
 expect(response.headers.get("Content-Type")).toBe("text/event-stream");

 const reader = response.body?.getReader;
 const decoder = new TextDecoder;

 let fullText = "";
 while (reader) {
 const { done, value } = await reader.read;
 if (done) break;

 const chunk = decoder.decode(value);
 const lines = chunk.split("\n");

 for (const line of lines) {
 if (line.startsWith("data: ")) {
 const data = line.slice(6);
 if (data !== "[DONE]") {
 fullText += data;
 }
 }
 }
 }

 expect(fullText.length).toBeGreaterThan(0);
 });
});
```

---

## Best Practices

### 1. Always Handle Errors

```typescript
try {
 for await (const chunk of stream) {
 // Process chunk
 }
} catch (error) {
 // Handle error
}
```

### 2. Provide Cancellation UI

```typescript
{isStreaming && <button onClick={cancel}>Stop Generating</button>}
```

### 3. Show Streaming Indicator

```typescript
{isStreaming && <span className="animate-pulse">●</span>}
```

### 4. Throttle UI Updates

Avoid updating UI on every chunk for performance.

### 5. Track Token Usage

```typescript
const finalMessage = await stream.finalMessage;
console.log("Tokens used:", finalMessage.usage);
```

---

## See Also

- [02-MESSAGES-API.md](./02-MESSAGES-API.md) - Messages API reference
- [04-ERROR-HANDLING.md](./04-ERROR-HANDLING.md) - Error handling patterns
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [Official Streaming Docs](https://docs.anthropic.com/claude/reference/streaming)
