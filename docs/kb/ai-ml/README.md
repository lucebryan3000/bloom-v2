---
id: ai-ml-readme
topic: ai-ml
file_role: overview
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['ai-ml']
embedding_keywords: [ai-ml, overview, introduction, getting-started]
last_reviewed: 2025-11-13
---

# AI/ML Knowledge Base - Vercel AI SDK & Claude Integration

Welcome to the AI/ML knowledge base covering Vercel AI SDK, Anthropic Claude integration, streaming responses, and conversational AI patterns used in this application.

## 📚 Documentation Structure (8-Part Series)

### **Quick Navigation**
- **<!-- [INDEX.md](./INDEX.md) -->** - Complete index with learning paths
- **<!-- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) -->** - Cheat sheet for quick lookups
- **<!-- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) -->** - AI agent patterns
- **<!-- <!-- <!-- [AI-ML-HANDBOOK.md](./AI-ML-HANDBOOK.md) --> (file not created) --> (File not yet created) -->** - Comprehensive reference

### **Core Topics (8 Files)**

| # | Topic | File | Focus |
|---|-------|------|-------|
| 1 | **Fundamentals** | <!-- <!-- <!-- [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) --> (file not created) --> (File not yet created) --> | AI basics, concepts |
| 2 | **Vercel AI SDK** | <!-- <!-- <!-- [02-VERCEL-AI-SDK.md](./02-VERCEL-AI-SDK.md) --> (file not created) --> (File not yet created) --> | SDK setup, usage |
| 3 | **Streaming** | <!-- <!-- <!-- <!-- [03-STREAMING.md](./03-STREAMING.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Streaming responses |
| 4 | **Claude Integration** | <!-- <!-- <!-- [04-CLAUDE.md](./04-CLAUDE.md) --> (file not created) --> (File not yet created) --> | Anthropic Claude API |
| 5 | **Prompts** | <!-- <!-- <!-- <!-- [05-PROMPT-ENGINEERING.md](./05-PROMPT-ENGINEERING.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Effective prompting |
| 6 | **Conversational AI** | <!-- <!-- <!-- <!-- [06-CONVERSATIONAL-AI.md](./06-CONVERSATIONAL-AI.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Multi-turn conversations |
| 7 | **Error Handling** | <!-- <!-- <!-- <!-- [07-ERROR-HANDLING.md](./07-ERROR-HANDLING.md) --> (file not created) --> (file not created) --> (File not yet created) --> | Handling AI errors |
| 8 | **Best Practices** | <!-- <!-- <!-- [08-BEST-PRACTICES.md](./08-BEST-PRACTICES.md) --> (file not created) --> (File not yet created) --> | Production patterns |

---

## 🚀 Getting Started

### Installation
```bash
npm install ai @ai-sdk/anthropic
npm install @anthropic-ai/sdk
```

### Basic Chat Completion
```typescript
// app/api/chat/route.ts
import { anthropic } from '@ai-sdk/anthropic';
import { streamText } from 'ai';

export async function POST(req: Request) {
 const { messages } = await req.json;

 const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 messages,
 system: 'You are a helpful AI assistant.',
 });

 return result.toDataStreamResponse;
}
```

### Client-Side Hook
```typescript
'use client';

import { useChat } from 'ai/react';

export function Chat {
 const { messages, input, handleInputChange, handleSubmit } = useChat({
 api: '/api/chat',
 });

 return (
 <div>
 {messages.map(m => (
 <div key={m.id}>
 <strong>{m.role}:</strong> {m.content}
 </div>
 ))}

 <form onSubmit={handleSubmit}>
 <input value={input} onChange={handleInputChange} />
 <button type="submit">Send</button>
 </form>
 </div>
 );
}
```

---

## 📋 Common Tasks

### "I need to stream AI responses"
1. Read: **<!-- <!-- <!-- <!-- [03-STREAMING.md](./03-STREAMING.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Examples: **[FRAMEWORK-INTEGRATION-PATTERNS.md - Streaming](./FRAMEWORK-INTEGRATION-PATTERNS.md#streaming)**

### "I need to improve prompts"
1. Read: **<!-- <!-- <!-- <!-- [05-PROMPT-ENGINEERING.md](./05-PROMPT-ENGINEERING.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Patterns: **[QUICK-REFERENCE.md - Prompts](./QUICK-REFERENCE.md#prompts)**

### "I need multi-turn conversations"
1. Read: **<!-- <!-- <!-- <!-- [06-CONVERSATIONAL-AI.md](./06-CONVERSATIONAL-AI.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Examples: **[FRAMEWORK-INTEGRATION-PATTERNS.md - Melissa](./FRAMEWORK-INTEGRATION-PATTERNS.md#melissa-agent)**

### "I need to handle errors"
1. Read: **<!-- <!-- <!-- <!-- [07-ERROR-HANDLING.md](./07-ERROR-HANDLING.md) --> (file not created) --> (file not created) --> (File not yet created) -->**
2. Patterns: **[QUICK-REFERENCE.md - Errors](./QUICK-REFERENCE.md#error-handling)**

---

## 🎯 Key Principles

### 1. **Always Stream for Better UX**
```typescript
// ✅ Good - Stream responses
export async function POST(req: Request) {
 const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 messages,
 });

 return result.toDataStreamResponse;
}

// ❌ Bad - Wait for full response
export async function POST(req: Request) {
 const result = await generateText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 messages,
 });

 return Response.json({ text: result.text }); // Slow
}
```

### 2. **Use System Prompts for Behavior**
```typescript
// ✅ Good - Clear system prompt
const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 system: `You are Melissa, an AI facilitator for 15-minute ROI discovery workshops.
Your role is to:
1. Ask targeted questions about business processes
2. Identify improvement opportunities
3. Guide users to quantify potential ROI
4. Keep sessions focused and under 15 minutes`,
 messages,
});

// ❌ Bad - No system prompt
const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 messages, // Unpredictable behavior
});
```

### 3. **Handle Errors Gracefully**
```typescript
// ✅ Good - Proper error handling
export async function POST(req: Request) {
 try {
 const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 messages,
 });

 return result.toDataStreamResponse;
 } catch (error) {
 if (error.status === 429) {
 return new Response('Rate limit exceeded', { status: 429 });
 }
 console.error('AI error:', error);
 return new Response('AI service unavailable', { status: 503 });
 }
}
```

### 4. **Maintain Conversation Context**
```typescript
// ✅ Good - Include full conversation history
const messages = [
 { role: 'system', content: systemPrompt },
 { role: 'user', content: 'What is ROI?' },
 { role: 'assistant', content: 'ROI is Return on Investment...' },
 { role: 'user', content: 'How do I calculate it?' }, // AI has context
];

// ❌ Bad - Lose context
const messages = [
 { role: 'user', content: 'How do I calculate it?' }, // No context
];
```

### 5. **Use Structured Output for Data**
```typescript
// ✅ Good - Structured extraction
const result = await generateObject({
 model: anthropic('claude-sonnet-4-5-20250929'),
 schema: z.object({
 processName: z.string,
 currentCost: z.number,
 estimatedSavings: z.number,
 confidence: z.enum(['low', 'medium', 'high']),
 }),
 prompt: 'Extract ROI data from the conversation',
});

// ❌ Bad - Parse text manually
const result = await generateText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 prompt: 'Give me the ROI data',
});
// Manual parsing of result.text - error-prone
```

---

## 📊 the project's AI Agent Example

```typescript
// Simplified AI agent structure
export async function aiAgent(sessionId: string, userMessage: string) {
 const session = await getSession(sessionId);

 const systemPrompt = `You are an AI assistant.

Current session state: ${session.messages.length} messages
Time elapsed: ${getElapsedTime(session)}

Your next task: ${getNextTask(session)}`;

 const result = await streamText({
 model: anthropic('claude-sonnet-4-5-20250929'),
 system: systemPrompt,
 messages: session.messages,
 });

 return result.toDataStreamResponse;
}
```

---

## ⚠️ Common Issues & Solutions

### "Rate limit errors"
**Cause**: Too many requests
**Fix**: Implement rate limiting and retry logic
```typescript
import { Ratelimit } from '@upstash/ratelimit';

const ratelimit = new Ratelimit({
 redis,
 limiter: Ratelimit.slidingWindow(10, '1 m'),
});

const { success } = await ratelimit.limit(userId);
if (!success) {
 return new Response('Rate limit exceeded', { status: 429 });
}
```

### "Streaming doesn't work"
**Cause**: Missing headers or incorrect setup
**Fix**: Use Vercel AI SDK's toDataStreamResponse
```typescript
// ✅ Good - Use SDK helper
return result.toDataStreamResponse;

// ❌ Bad - Manual streaming
return new Response(result.textStream);
```

### "Context window exceeded"
**Cause**: Too many messages in conversation
**Fix**: Summarize or trim old messages
```typescript
// Trim to last N messages
const messages = conversation.slice(-10);

// Or summarize old context
const summary = await summarize(oldMessages);
const messages = [
 { role: 'system', content: summary },
...recentMessages,
];
```

---

## 📚 Files in This Directory

```
docs/kb/ai-ml/
├── README.md # This file
├── INDEX.md # Complete index
├── QUICK-REFERENCE.md # Cheat sheet
├── AI-ML-HANDBOOK.md # Full reference
├── FRAMEWORK-INTEGRATION-PATTERNS.md # AI agent patterns
├── 01-FUNDAMENTALS.md # AI basics
├── 02-VERCEL-AI-SDK.md # SDK usage
├── 03-STREAMING.md # Streaming responses
├── 04-CLAUDE.md # Claude integration
├── 05-PROMPT-ENGINEERING.md # Prompting techniques
├── 06-CONVERSATIONAL-AI.md # Multi-turn conversations
├── 07-ERROR-HANDLING.md # Error handling
└── 08-BEST-PRACTICES.md # Best practices
```

---

## 🎓 External Resources

- **Vercel AI SDK Docs**: https://sdk.vercel.ai/docs
- **Anthropic Claude API**: https://docs.anthropic.com/
- **Prompt Engineering Guide**: https://www.promptingguide.ai/
- **Claude Model Info**: https://docs.anthropic.com/en/docs/models-overview

---

**Last Updated**: November 9, 2025
**AI SDK Version**: 4.0.0
**Claude Model**: claude-sonnet-4-5-20250929
**Status**: Production-Ready

Happy prompting! 🤖
