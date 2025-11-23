# Streaming Responses Guide

Complete guide to streaming OpenAI responses for real-time UX.

## Basic Streaming

```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "Tell me a story" }],
  stream: true,
});

for await (const chunk of stream) {
  const content = chunk.choices[0]?.delta?.content || '';
  process.stdout.write(content);
}
```

## Next.js API Route

```typescript
// app/api/chat/route.ts
import OpenAI from 'openai';
import { OpenAIStream, StreamingTextResponse } from 'ai';

const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

export async function POST(req: Request) {
  const { messages } = await req.json();

  const response = await openai.chat.completions.create({
    model: 'gpt-4',
    stream: true,
    messages,
  });

  const stream = OpenAIStream(response);
  return new StreamingTextResponse(stream);
}
```

## Client-Side (React)

```typescript
'use client';

import { useChat } from 'ai/react';

export function ChatInterface() {
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
        <input
          value={input}
          onChange={handleInputChange}
          placeholder="Type a message..."
        />
        <button type="submit">Send</button>
      </form>
    </div>
  );
}
```

## Server-Sent Events (Manual)

```typescript
// app/api/stream/route.ts
export async function POST(request: Request) {
  const { prompt } = await request.json();

  const stream = new ReadableStream({
    async start(controller) {
      const completion = await openai.chat.completions.create({
        model: 'gpt-4',
        messages: [{ role: 'user', content: prompt }],
        stream: true,
      });

      for await (const chunk of completion) {
        const content = chunk.choices[0]?.delta?.content || '';
        const data = `data: ${JSON.stringify({ content })}\n\n`;
        controller.enqueue(new TextEncoder().encode(data));
      }

      controller.close();
    },
  });

  return new Response(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      'Connection': 'keep-alive',
    },
  });
}
```

## Client-Side SSE

```typescript
function streamChat(prompt: string) {
  const eventSource = new EventSource(`/api/stream?prompt=${prompt}`);

  eventSource.onmessage = (event) => {
    const data = JSON.parse(event.data);
    console.log(data.content);
  };

  eventSource.onerror = () => {
    eventSource.close();
  };

  return eventSource;
}
```

## Streaming with Function Calls

```typescript
const stream = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [...],
  functions: [...],
  stream: true,
});

let functionCall = { name: '', arguments: '' };

for await (const chunk of stream) {
  const delta = chunk.choices[0]?.delta;

  if (delta?.function_call) {
    functionCall.name += delta.function_call.name || '';
    functionCall.arguments += delta.function_call.arguments || '';
  } else if (delta?.content) {
    process.stdout.write(delta.content);
  }
}

if (functionCall.name) {
  const args = JSON.parse(functionCall.arguments);
  const result = await executeFunction(functionCall.name, args);
  // Handle result
}
```

## Error Handling

```typescript
try {
  const stream = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [...],
    stream: true,
  });

  for await (const chunk of stream) {
    // Process chunk
  }
} catch (error) {
  if (error instanceof OpenAI.APIError) {
    console.error('Stream error:', error.status, error.message);
  }
}
```

---

**Last Updated**: 2025-01-13
