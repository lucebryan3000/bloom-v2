# Chat API Complete Guide

Comprehensive guide to the OpenAI Chat Completions API.

## Table of Contents
- [Overview](#overview)
- [Basic Usage](#basic-usage)
- [Advanced Parameters](#advanced-parameters)
- [Conversation Management](#conversation-management)
- [Common Patterns](#common-patterns)
- [Performance Optimization](#performance-optimization)

---

## Overview

The Chat API (`/v1/chat/completions`) is the primary interface for interacting with GPT models.

**Key Features**:
- Multi-turn conversations
- System message context
- Function calling support
- JSON mode
- Streaming responses

---

## Basic Usage

### Simple Request

```typescript
import OpenAI from 'openai';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "system", content: "You are a helpful assistant." },
    { role: "user", content: "What is TypeScript?" }
  ],
});

console.log(completion.choices[0].message.content);
```

### With Error Handling

```typescript
async function chat(prompt: string): Promise<string> {
  try {
    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: [
        { role: "user", content: prompt }
      ],
    });

    return completion.choices[0].message.content || '';
  } catch (error) {
    if (error instanceof OpenAI.APIError) {
      throw new Error(`OpenAI API error: ${error.message}`);
    }
    throw error;
  }
}
```

---

## Advanced Parameters

### Complete Parameter Set

```typescript
const completion = await openai.chat.completions.create({
  // Required
  model: "gpt-4",
  messages: [...],

  // Response control
  temperature: 0.7,          // 0-2, default 1
  top_p: 1,                  // 0-1, nucleus sampling
  n: 1,                      // Number of responses
  max_tokens: 1000,          // Max response tokens
  stop: ["\n\n", "###"],    // Stop sequences

  // Behavior modifiers
  presence_penalty: 0,       // -2 to 2, penalize new topics
  frequency_penalty: 0,      // -2 to 2, penalize repetition

  // Output format
  response_format: { type: "json_object" }, // JSON mode

  // Function calling
  functions: [...],
  function_call: "auto",

  // User tracking
  user: "user-123",          // For abuse monitoring

  // Streaming
  stream: false,
});
```

### Parameter Details

#### Temperature (0-2)

Controls randomness:

```typescript
// Focused, deterministic (code, facts)
temperature: 0.2

// Balanced (general chat)
temperature: 0.7

// Creative (storytelling, brainstorming)
temperature: 1.5
```

#### Top-P (0-1)

Alternative to temperature (nucleus sampling):

```typescript
// Consider only top 10% likely tokens
top_p: 0.1

// Consider all tokens (default)
top_p: 1
```

**Note**: Use temperature OR top_p, not both.

#### Presence Penalty (-2 to 2)

Encourages new topics:

```typescript
// Encourage diversity
presence_penalty: 0.5

// Strongly encourage new topics
presence_penalty: 1.5
```

#### Frequency Penalty (-2 to 2)

Reduces repetition:

```typescript
// Slight repetition reduction
frequency_penalty: 0.3

// Strong anti-repetition
frequency_penalty: 1.0
```

---

## Conversation Management

### Multi-Turn Conversations

```typescript
interface ConversationMessage {
  role: 'system' | 'user' | 'assistant';
  content: string;
}

class Conversation {
  private messages: ConversationMessage[] = [];

  constructor(systemPrompt?: string) {
    if (systemPrompt) {
      this.messages.push({
        role: 'system',
        content: systemPrompt,
      });
    }
  }

  addUserMessage(content: string) {
    this.messages.push({ role: 'user', content });
  }

  addAssistantMessage(content: string) {
    this.messages.push({ role: 'assistant', content });
  }

  async sendMessage(prompt: string): Promise<string> {
    this.addUserMessage(prompt);

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: this.messages,
    });

    const response = completion.choices[0].message.content || '';
    this.addAssistantMessage(response);

    return response;
  }

  getMessages() {
    return this.messages;
  }

  clear() {
    const system = this.messages.find(m => m.role === 'system');
    this.messages = system ? [system] : [];
  }
}

// Usage
const conv = new Conversation("You are a helpful coding assistant.");
await conv.sendMessage("What is TypeScript?");
await conv.sendMessage("How do I use generics?");
```

### Context Window Management

```typescript
class ManagedConversation extends Conversation {
  private maxTokens = 4000; // Reserve space for response
  private maxMessages = 20;

  async sendMessage(prompt: string): Promise<string> {
    this.addUserMessage(prompt);

    // Trim old messages if needed
    this.trimMessages();

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages: this.messages,
      max_tokens: 1000,
    });

    const response = completion.choices[0].message.content || '';
    this.addAssistantMessage(response);

    return response;
  }

  private trimMessages() {
    // Keep system message
    const system = this.messages.find(m => m.role === 'system');
    let messages = this.messages.filter(m => m.role !== 'system');

    // Keep only recent messages
    if (messages.length > this.maxMessages) {
      messages = messages.slice(-this.maxMessages);
    }

    this.messages = system ? [system, ...messages] : messages;
  }
}
```

---

## Common Patterns

### 1. Chat Interface

```typescript
// app/api/chat/route.ts
import OpenAI from 'openai';
import { NextRequest, NextResponse } from 'next/server';

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY,
});

export async function POST(request: NextRequest) {
  try {
    const { messages } = await request.json();

    const completion = await openai.chat.completions.create({
      model: "gpt-4",
      messages,
      temperature: 0.7,
    });

    return NextResponse.json({
      message: completion.choices[0].message,
      usage: completion.usage,
    });
  } catch (error) {
    return NextResponse.json(
      { error: 'Chat request failed' },
      { status: 500 }
    );
  }
}
```

### 2. Content Generation

```typescript
async function generateContent(
  topic: string,
  type: 'blog' | 'social' | 'email'
): Promise<string> {
  const prompts = {
    blog: `Write a 500-word blog post about: ${topic}`,
    social: `Write a compelling social media post about: ${topic}`,
    email: `Write a professional email about: ${topic}`,
  };

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      {
        role: "system",
        content: "You are an expert content writer.",
      },
      {
        role: "user",
        content: prompts[type],
      },
    ],
    temperature: 0.8, // More creative
  });

  return completion.choices[0].message.content || '';
}
```

### 3. Code Generation

```typescript
async function generateCode(
  description: string,
  language: string
): Promise<string> {
  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      {
        role: "system",
        content: `You are an expert ${language} programmer.
        Generate clean, well-commented, production-ready code.
        Include error handling and type annotations.`,
      },
      {
        role: "user",
        content: description,
      },
    ],
    temperature: 0.2, // More focused
  });

  return completion.choices[0].message.content || '';
}

// Usage
const code = await generateCode(
  "Create a TypeScript function that validates email addresses",
  "TypeScript"
);
```

### 4. Q&A System

```typescript
interface QAContext {
  question: string;
  context: string;
}

async function answerQuestion({ question, context }: QAContext): Promise<string> {
  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      {
        role: "system",
        content: `Answer questions based only on the provided context.
        If the answer is not in the context, say "I don't have enough information."`,
      },
      {
        role: "user",
        content: `Context: ${context}\n\nQuestion: ${question}`,
      },
    ],
    temperature: 0.3, // Factual
  });

  return completion.choices[0].message.content || '';
}
```

### 5. Text Summarization

```typescript
async function summarize(
  text: string,
  length: 'short' | 'medium' | 'long' = 'medium'
): Promise<string> {
  const lengthInstructions = {
    short: '1-2 sentences',
    medium: '3-5 sentences',
    long: '1-2 paragraphs',
  };

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      {
        role: "system",
        content: `Summarize the following text in ${lengthInstructions[length]}.`,
      },
      {
        role: "user",
        content: text,
      },
    ],
    temperature: 0.3,
  });

  return completion.choices[0].message.content || '';
}
```

---

## Performance Optimization

### 1. Response Caching

```typescript
import { LRUCache } from 'lru-cache';

const cache = new LRUCache<string, string>({
  max: 1000,
  ttl: 1000 * 60 * 60, // 1 hour
});

async function cachedChat(
  messages: ChatCompletionMessageParam[]
): Promise<string> {
  const cacheKey = JSON.stringify(messages);
  const cached = cache.get(cacheKey);

  if (cached) {
    console.log('Cache hit');
    return cached;
  }

  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages,
  });

  const response = completion.choices[0].message.content || '';
  cache.set(cacheKey, response);

  return response;
}
```

### 2. Batch Processing

```typescript
async function batchChat(
  prompts: string[]
): Promise<string[]> {
  const requests = prompts.map(prompt =>
    openai.chat.completions.create({
      model: "gpt-3.5-turbo", // Cheaper for batch
      messages: [{ role: "user", content: prompt }],
    })
  );

  const completions = await Promise.all(requests);

  return completions.map(c => c.choices[0].message.content || '');
}
```

### 3. Model Selection

```typescript
function selectModel(taskComplexity: 'simple' | 'complex'): string {
  return taskComplexity === 'complex'
    ? 'gpt-4'
    : 'gpt-3.5-turbo';
}

async function smartChat(
  prompt: string,
  complexity: 'simple' | 'complex'
): Promise<string> {
  const model = selectModel(complexity);

  const completion = await openai.chat.completions.create({
    model,
    messages: [{ role: "user", content: prompt }],
  });

  return completion.choices[0].message.content || '';
}
```

---

## Next Steps

- [Function Calling](./03-FUNCTION-CALLING.md) - Structured outputs
- [Streaming](./04-STREAMING.md) - Real-time responses
- [Error Handling](./05-ERROR-HANDLING.md) - Robust error management

---

**Last Updated**: 2025-01-13
