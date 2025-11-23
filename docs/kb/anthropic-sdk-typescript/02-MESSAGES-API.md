---
id: anthropic-sdk-typescript-02-messages-api
topic: anthropic-sdk-typescript
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [anthropic-sdk-typescript-basics]
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, api]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Messages API Reference

Comprehensive guide to the Messages API - the core interface for interacting with Claude.

---

## Table of Contents

1. [Overview](#overview)
2. [Message Structure](#message-structure)
3. [Basic Message Creation](#basic-message-creation)
4. [System Prompts](#system-prompts)
5. [Multi-Turn Conversations](#multi-turn-conversations)
6. [Content Blocks](#content-blocks)
7. [Model Selection](#model-selection)
8. [Sampling Parameters](#sampling-parameters)
9. [Token Configuration](#token-configuration)
10. [Response Structure](#response-structure)
11. [Usage Tracking](#usage-tracking)
12. [Streaming Responses](#streaming-responses)
13. [Stop Sequences](#stop-sequences)
14. [Metadata](#metadata)
15. [Error Handling](#error-handling)

---

## Overview

The Messages API is the primary interface for sending requests to Claude. It supports:

- Single messages and multi-turn conversations
- System prompts for behavior customization
- Streaming and non-streaming responses
- Rich content (text, images, documents)
- Token usage tracking
- Fine-grained parameter control

**API Endpoint**: `anthropic.messages.create`

---

## Message Structure

### `MessageParam` Type

Every message in a conversation has this structure:

```typescript
interface MessageParam {
 role: "user" | "assistant";
 content: string | ContentBlock[];
}
```

**Rules:**

- Conversations must start with a `user` message
- Messages must alternate between `user` and `assistant` roles
- `system` messages are provided separately via the `system` parameter

### Example

```typescript
const messages: Anthropic.MessageParam[] = [
 {
 role: "user",
 content: "What is TypeScript?",
 },
 {
 role: "assistant",
 content: "TypeScript is a typed superset of JavaScript...",
 },
 {
 role: "user",
 content: "How do I install it?",
 },
];
```

---

## Basic Message Creation

### Minimal Example

```typescript
import Anthropic from "@anthropic-ai/sdk";

const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "Explain quantum computing in simple terms",
 },
 ],
});

console.log(response.content[0].text);
```

### With Error Handling

```typescript
try {
 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "Hello, Claude!",
 },
 ],
 });

 const textBlock = response.content.find((block) => block.type === "text");
 if (textBlock && textBlock.type === "text") {
 console.log(textBlock.text);
 }
} catch (error) {
 if (error instanceof Anthropic.APIError) {
 console.error("API Error:", error.status, error.message);
 } else {
 console.error("Unexpected error:", error);
 }
}
```

---

## System Prompts

System prompts define Claude's behavior, personality, and context. They are separate from the conversation messages.

### Basic System Prompt

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: "You are a helpful assistant that explains technical concepts clearly.",
 messages: [
 {
 role: "user",
 content: "What is a REST API?",
 },
 ],
});
```

### Example: Complex Multi-Purpose System Prompt

```typescript
const systemPrompt = `You are Melissa, an expert AI business consultant specializing in ROI discovery and process optimization.

Your personality traits:
- Professional yet approachable and warm
- Insightful and asks clarifying questions
- Encouraging and supportive
- Data-driven but explains concepts simply

Your role in this discovery workshop:
1. Welcome users and explain the process
2. Guide them through discovery questions to understand their business processes
3. Identify automation opportunities and quantify potential value
4. Gather metrics needed for ROI calculations
5. Validate assumptions and flag uncertainties
6. Calculate ROI with confidence scores
7. Provide actionable insights and next steps

Communication guidelines:
- Keep responses concise (2-3 sentences typically)
- Ask one question at a time
- Validate understanding before proceeding
- Use examples to clarify complex concepts
- Acknowledge concerns and address them
- Keep the conversation focused and efficient`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: messages,
});
```

### Multi-Paragraph System Prompts

```typescript
const systemPrompt = `You are an expert software architect.

Guidelines:
1. Prioritize simplicity and maintainability
2. Use industry best practices
3. Consider scalability and performance
4. Explain trade-offs clearly

Response format:
- Start with a brief summary
- Provide detailed reasoning
- End with specific recommendations`;
```

---

## Multi-Turn Conversations

### Pattern: Maintaining Conversation History

```typescript
// Store conversation history
const conversationHistory: Anthropic.MessageParam[] = [];

// First turn
conversationHistory.push({
 role: "user",
 content: "What's the capital of France?",
});

let response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: conversationHistory,
});

const firstResponse = response.content[0].text;
conversationHistory.push({
 role: "assistant",
 content: firstResponse,
});

// Second turn
conversationHistory.push({
 role: "user",
 content: "What's its population?",
});

response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: conversationHistory,
});

const secondResponse = response.content[0].text;
conversationHistory.push({
 role: "assistant",
 content: secondResponse,
});
```

### Pattern: Database-Backed Transcript Management

```typescript
// Load existing transcript from database
const existingTranscript = session.transcript
 ? JSON.parse(session.transcript as string)
: [];

// Add new user message
existingTranscript.push({
 id: `msg-${Date.now}-user`,
 role: "user",
 content: userMessage,
 timestamp: new Date,
});

// Convert to Anthropic format
const messages: Anthropic.MessageParam[] = existingTranscript
.filter((msg) => msg.role !== "system")
.map((msg) => ({
 role: msg.role === "user" ? ("user" as const): ("assistant" as const),
 content: msg.content,
 }));

// Generate response
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages,
});

// Add assistant response to transcript
existingTranscript.push({
 id: `msg-${Date.now}-assistant`,
 role: "assistant",
 content: response.content[0].text,
 timestamp: new Date,
});

// Save back to database
await prisma.session.update({
 where: { id: sessionId },
 data: { transcript: JSON.stringify(existingTranscript) },
});
```

---

## Content Blocks

### Text Content (Simple)

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "Hello!", // String content
 },
 ],
});
```

### Text Content (Explicit Block)

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: [
 {
 type: "text",
 text: "Hello!",
 },
 ],
 },
 ],
});
```

### Image Content (Base64)

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: [
 {
 type: "text",
 text: "What's in this image?",
 },
 {
 type: "image",
 source: {
 type: "base64",
 media_type: "image/jpeg",
 data: "/9j/4AAQSkZJRgABAQEASABIAAD...", // Base64 encoded image
 },
 },
 ],
 },
 ],
});
```

### Document Content (PDF)

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: [
 {
 type: "text",
 text: "Summarize this document",
 },
 {
 type: "document",
 source: {
 type: "base64",
 media_type: "application/pdf",
 data: "JVBERi0xLjQKJeLjz9MKMy...", // Base64 encoded PDF
 },
 },
 ],
 },
 ],
});
```

**Note**: Document support requires SDK version with PDF capabilities (current: 0.27.3).

---

## Model Selection

### Available Models

| Model ID | Description | Context Window | Recommended |
| ------------------------------------ | ---------------------------------- | -------------- | ----------- |
| `claude-sonnet-4-5-20250929` | Latest Sonnet 4.5 (best balance) | 200K tokens | ✅ Default |
| `claude-3-5-sonnet-20241022` | Previous Sonnet 3.5 | 200K tokens | - |
| `claude-3-5-haiku-20241022` | Fast, lightweight | 200K tokens | - |
| `claude-3-opus-20240229` | Most capable (legacy) | 200K tokens | - |

### Selecting Model

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929", // Recommended default
 max_tokens: 1000,
 messages: messages,
});
```

### Example Configuration

```typescript
// lib/melissa/config.ts
export const MELISSA_CONFIG = {
 model: {
 provider: "anthropic",
 id: "claude-sonnet-4-5-20250929",
 temperature: 0.7,
 maxTokens: 1000,
 topP: 0.9,
 },
};
```

---

## Sampling Parameters

### Temperature

Controls randomness (creativity vs. consistency).

- **Range**: 0.0 - 1.0
- **Default**: 1.0
- **Recommended**: 0.7

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.7, // Balanced creativity
 messages: messages,
});
```

**Temperature Guide:**

| Value | Use Case | Example |
| --------- | ------------------------------------ | --------------------- |
| 0.0 - 0.3 | Deterministic, factual, analytical | Data analysis, coding |
| 0.4 - 0.6 | Balanced | General conversation |
| 0.7 - 0.9 | Creative, varied | Brainstorming, writing|
| 1.0 | Maximum creativity | Poetry, storytelling |

### Top P (Nucleus Sampling)

Controls diversity by probability mass.

- **Range**: 0.0 - 1.0
- **Default**: 0.7
- **Recommended**: 0.9

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.7,
 top_p: 0.9, // Consider top 90% probability mass
 messages: messages,
});
```

### Top K

Limits sampling to top K tokens.

- **Range**: Integer > 0
- **Default**: None (no top-K filtering)
- **Rarely used**: top_p is usually sufficient

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 top_k: 40, // Consider only top 40 tokens
 messages: messages,
});
```

**Best Practice**: Use either `top_p` OR `top_k`, not both.

---

## Token Configuration

### Max Tokens (Required)

Maximum number of output tokens to generate.

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000, // REQUIRED parameter
 messages: messages,
});
```

**Token Limits by Model:**

- Claude Sonnet 4.5: 8,192 output tokens max
- Context window: 200,000 tokens (input + output)

**Example Configuration:**

- Default: 1000 tokens (~750 words)
- Sufficient for conversational responses
- Adjusted based on use case

### Estimating Token Usage

**Rough estimates:**

- 1 token ≈ 4 characters
- 1 token ≈ 0.75 words
- 100 tokens ≈ 75 words

```typescript
// Example: 200-word response needs ~270 tokens
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 300, // ~225 words
 messages: messages,
});
```

---

## Response Structure

### Complete Response Object

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
});

// Response structure:
{
 id: "msg_01ABC123",
 type: "message",
 role: "assistant",
 content: [
 {
 type: "text",
 text: "Hello! How can I help you today?"
 }
 ],
 model: "claude-sonnet-4-5-20250929",
 stop_reason: "end_turn",
 stop_sequence: null,
 usage: {
 input_tokens: 10,
 output_tokens: 15
 }
}
```

### Extracting Text Content

```typescript
// Safest approach
const textContent = response.content.find((block) => block.type === "text");
if (textContent && textContent.type === "text") {
 console.log(textContent.text);
}

// Or for single text block (common case)
if (response.content[0].type === "text") {
 console.log(response.content[0].text);
}

// Example pattern
const textContent = response.content.find((block) => block.type === "text");
if (!textContent || textContent.type !== "text") {
 throw new Error("No text content in Claude response");
}
return textContent.text;
```

### Stop Reason Values

| Stop Reason | Meaning |
| ---------------- | ---------------------------------------------- |
| `end_turn` | Natural completion |
| `max_tokens` | Hit max_tokens limit |
| `stop_sequence` | Hit custom stop sequence |
| `tool_use` | Requested tool use (advanced feature) |

---

## Usage Tracking

### Accessing Token Usage

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
});

console.log({
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
});
```

### Cost Calculation

**Claude Sonnet 4.5 Pricing (as of Jan 2025):**

- Input: $3.00 per million tokens
- Output: $15.00 per million tokens

```typescript
function calculateCost(usage: { input_tokens: number; output_tokens: number }) {
 const inputCost = (usage.input_tokens / 1_000_000) * 3.0;
 const outputCost = (usage.output_tokens / 1_000_000) * 15.0;
 return {
 inputCost,
 outputCost,
 totalCost: inputCost + outputCost,
 };
}

// Usage
const cost = calculateCost(response.usage);
console.log(`Cost: $${cost.totalCost.toFixed(4)}`);
```

### Example: Usage Tracking

```typescript
// After each message
logger.info("AI message processed", "melissa", {
 sessionId,
 inputTokens: response.usage.input_tokens,
 outputTokens: response.usage.output_tokens,
 totalTokens: response.usage.input_tokens + response.usage.output_tokens,
 phase: this.state.phase,
});
```

---

## Streaming Responses

### Using `.stream` Helper

```typescript
const stream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Tell me a story" }],
});

// Iterate over stream chunks
for await (const chunk of stream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 process.stdout.write(chunk.delta.text);
 }
}

// Get final message
const finalMessage = await stream.finalMessage;
console.log("\nUsage:", finalMessage.usage);
```

### Using `stream: true`

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 stream: true,
 messages: [{ role: "user", content: "Tell me a story" }],
});

// Process events
for await (const event of response) {
 if (event.type === "content_block_start") {
 console.log("Content block started");
 } else if (event.type === "content_block_delta") {
 if (event.delta.type === "text_delta") {
 process.stdout.write(event.delta.text);
 }
 } else if (event.type === "content_block_stop") {
 console.log("\nContent block finished");
 } else if (event.type === "message_stop") {
 console.log("Message complete");
 }
}
```

### Next.js Streaming (Server-Sent Events)

```typescript
// app/api/chat/stream/route.ts
export async function POST(request: NextRequest) {
 const encoder = new TextEncoder;

 const stream = new ReadableStream({
 async start(controller) {
 const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 });

 const messageStream = await anthropic.messages.stream({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 });

 for await (const chunk of messageStream) {
 if (
 chunk.type === "content_block_delta" &&
 chunk.delta.type === "text_delta"
 ) {
 const data = encoder.encode(`data: ${chunk.delta.text}\n\n`);
 controller.enqueue(data);
 }
 }

 controller.close;
 },
 });

 return new Response(stream, {
 headers: {
 "Content-Type": "text/event-stream",
 "Cache-Control": "no-cache",
 Connection: "keep-alive",
 },
 });
}
```

---

## Stop Sequences

### Custom Stop Sequences

Stop generation when specific strings are encountered.

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 stop_sequences: ["\n\nHuman:", "END_OF_RESPONSE"],
 messages: messages,
});

if (response.stop_reason === "stop_sequence") {
 console.log("Stopped at:", response.stop_sequence);
}
```

**Use cases:**

- Implement custom conversation boundaries
- Prevent verbose responses
- Control multi-part output format

---

## Metadata

### Attaching Metadata

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 metadata: {
 user_id: "user-123",
 session_id: "session-456",
 environment: "production",
 },
});
```

**Metadata use cases:**

- User tracking for analytics
- Session correlation
- A/B testing
- Cost attribution

**Note**: Metadata is not sent to Claude; it's for Anthropic's systems.

---

## Error Handling

### Error Types

```typescript
import Anthropic from "@anthropic-ai/sdk";

try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.BadRequestError) {
 // 400: Invalid request (e.g., missing required field)
 console.error("Bad request:", error.message);
 } else if (error instanceof Anthropic.AuthenticationError) {
 // 401: Invalid API key
 console.error("Authentication failed:", error.message);
 } else if (error instanceof Anthropic.PermissionDeniedError) {
 // 403: API key lacks permissions
 console.error("Permission denied:", error.message);
 } else if (error instanceof Anthropic.NotFoundError) {
 // 404: Resource not found
 console.error("Not found:", error.message);
 } else if (error instanceof Anthropic.RateLimitError) {
 // 429: Rate limit exceeded
 console.error("Rate limit hit:", error.message);
 console.log("Retry after:", error.headers?.["retry-after"]);
 } else if (error instanceof Anthropic.InternalServerError) {
 // 500+: Anthropic server error
 console.error("Server error:", error.message);
 } else if (error instanceof Anthropic.APIError) {
 // Generic API error
 console.error("API error:", error.status, error.message);
 } else {
 // Non-API error
 console.error("Unexpected error:", error);
 }
}
```

### Example: Error Handling

```typescript
// lib/melissa/agent.ts
try {
 const response = await this.anthropic.messages.create({
 model: this.config.model.id,
 max_tokens: this.config.model.maxTokens,
 temperature: this.config.model.temperature,
 system: this.config.systemPrompt,
 messages,
 });

 return response.content.find((block) => block.type === "text")?.text || "";
} catch (error) {
 console.error("Error generating AI response:", error);
 throw new Error("Failed to generate AI response");
}
```

### Retry Logic

See [QUICK-REFERENCE.md](./QUICK-REFERENCE.md#retry-logic-snippet) for retry implementation.

---

## See Also

- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Fast lookup patterns
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [01-INSTALLATION-SETUP.md](./01-INSTALLATION-SETUP.md) - Setup guide
- [Official Messages API Docs](https://docs.anthropic.com/claude/reference/messages_post)
