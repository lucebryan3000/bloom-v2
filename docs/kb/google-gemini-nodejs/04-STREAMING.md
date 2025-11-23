---
id: google-gemini-nodejs-04-streaming
topic: google-gemini-nodejs
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [google-gemini-fundamentals, google-gemini-messages-api]
related_topics: [google-gemini, streaming, real-time, sse]
embedding_keywords: [google-gemini, streaming, real-time-responses, sse, server-sent-events]
last_reviewed: 2025-11-13
---

# Gemini Streaming Responses

**Purpose**: Implement real-time streaming for better user experience with long-form generation.

---

## 1. Basic Streaming

### Stream Text Generation

```typescript
const result = await model.generateContentStream('Write a long story about AI');

for await (const chunk of result.stream) {
  const chunkText = chunk.text();
  process.stdout.write(chunkText);
}

// Get final response after streaming
const finalResponse = await result.response;
console.log('\n\nTotal tokens:', finalResponse.usageMetadata?.totalTokenCount);
```

---

## 2. Streaming with Chat

```typescript
const chat = model.startChat();

const result = await chat.sendMessageStream('Explain machine learning in detail');

for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}

const finalResponse = await result.response;
console.log('\n\nUsage:', finalResponse.usageMetadata);
```

---

## 3. Next.js SSE Streaming

### API Route

```typescript
// app/api/chat/stream/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  const { message } = await req.json();

  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
  const result = await model.generateContentStream(message);

  const encoder = new TextEncoder();
  const stream = new ReadableStream({
    async start(controller) {
      for await (const chunk of result.stream) {
        const text = chunk.text();
        controller.enqueue(encoder.encode(`data: ${JSON.stringify({ text })}\n\n`));
      }

      const finalResponse = await result.response;
      controller.enqueue(
        encoder.encode(`data: ${JSON.stringify({ done: true, usage: finalResponse.usageMetadata })}\n\n`)
      );
      controller.close();
    },
  });

  return new NextResponse(stream, {
    headers: {
      'Content-Type': 'text/event-stream',
      'Cache-Control': 'no-cache',
      Connection: 'keep-alive',
    },
  });
}
```

### Client Hook

```typescript
export function useGeminiStream() {
  const [isStreaming, setIsStreaming] = useState(false);
  const [streamedText, setStreamedText] = useState('');

  const streamMessage = useCallback(async (message: string) => {
    setIsStreaming(true);
    setStreamedText('');

    const response = await fetch('/api/chat/stream', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ message }),
    });

    const reader = response.body?.getReader();
    const decoder = new TextDecoder();

    while (true) {
      const { done, value } = await reader!.read();
      if (done) break;

      const chunk = decoder.decode(value);
      const lines = chunk.split('\n');

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = JSON.parse(line.slice(6));
          if (data.text) {
            setStreamedText((prev) => prev + data.text);
          }
        }
      }
    }

    setIsStreaming(false);
  }, []);

  return { streamMessage, isStreaming, streamedText };
}
```

---

## 4. Why Streaming Matters

### UX Benefits

- **Perceived Latency**: Users see output immediately
- **Interactivity**: Can cancel long-running requests
- **Engagement**: Real-time feedback keeps users engaged
- **Progressive Rendering**: Render as content arrives

### Cost Benefits

- **Early Cancellation**: Stop generation if user navigates away
- **Token Savings**: Only pay for tokens generated before cancellation

---

## 5. Best Practices

### ✅ DO

- Use streaming for responses > 100 tokens
- Show loading indicators during initial latency
- Handle stream errors gracefully
- Close streams properly on unmount

### ❌ DON'T

- Don't stream for very short responses (overhead > benefit)
- Don't forget to await finalResponse for usage metadata
- Don't ignore stream errors (they can hang connections)

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Use `generateContentStream()` instead of `generateContent()`
2. Always await `finalResponse` after stream completes for metadata
3. Implement proper error handling for broken streams
4. Close streams on component unmount

---

**Next**: [05-FUNCTION-CALLING.md](05-FUNCTION-CALLING.md) for tool use and API integration.
