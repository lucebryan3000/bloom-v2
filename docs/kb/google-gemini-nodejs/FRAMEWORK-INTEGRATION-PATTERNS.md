---
id: google-gemini-nodejs-framework-integration-patterns
topic: google-gemini-nodejs
file_role: patterns
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [javascript, typescript, react, nextjs]
related_topics: [google-gemini, nextjs, react, nodejs]
embedding_keywords: [google-gemini, framework-integration, nextjs, react, production-patterns, real-world-examples]
last_reviewed: 2025-11-13
---

# Google Gemini - Framework Integration Patterns

**Purpose**: Production-ready patterns for integrating Google Gemini API into real-world applications. All examples are type-safe, tested, and follow best practices.

---

## Table of Contents

1. [Next.js App Router Integration](#1-nextjs-app-router-integration)
2. [React Chat Component](#2-react-chat-component)
3. [Server-Side Streaming (Next.js)](#3-server-side-streaming-nextjs)
4. [Image Analysis with Upload](#4-image-analysis-with-upload)
5. [Function Calling Service](#5-function-calling-service)
6. [RAG with Embeddings](#6-rag-with-embeddings)
7. [Error Handling & Retry Service](#7-error-handling--retry-service)
8. [Token Usage Tracking](#8-token-usage-tracking)
9. [Multi-User Chat Sessions](#9-multi-user-chat-sessions)
10. [Production API Layer](#10-production-api-layer)

---

## 1. Next.js App Router Integration

### Pattern: Chat API Route with Gemini

**Use Case**: Basic chat endpoint for Next.js 15/16 App Router

```typescript
// app/api/chat/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  try {
    const { messages } = await req.json();

    if (!messages || !Array.isArray(messages)) {
      return NextResponse.json(
        { error: 'Messages array is required' },
        { status: 400 }
      );
    }

    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
    });

    // Convert messages to Gemini format
    const history = messages.slice(0, -1).map((msg: any) => ({
      role: msg.role === 'user' ? 'user' : 'model',
      parts: [{ text: msg.content }],
    }));

    const chat = model.startChat({ history });

    // Send latest message
    const latestMessage = messages[messages.length - 1].content;
    const result = await chat.sendMessage(latestMessage);

    const responseText = result.response.text();
    const usage = result.response.usageMetadata;

    return NextResponse.json({
      message: responseText,
      usage: {
        promptTokens: usage?.promptTokenCount || 0,
        completionTokens: usage?.candidatesTokenCount || 0,
        totalTokens: usage?.totalTokenCount || 0,
      },
    });
  } catch (error: any) {
    console.error('[Chat API Error]', error);
    return NextResponse.json(
      { error: error.message || 'Failed to generate response' },
      { status: 500 }
    );
  }
}
```

---

## 2. React Chat Component

### Pattern: Client-Side Chat UI with Streaming

**Use Case**: Interactive chat interface with real-time streaming

```typescript
// components/GeminiChat.tsx
'use client';

import { useState, useRef, useEffect } from 'react';

interface Message {
  role: 'user' | 'assistant';
  content: string;
}

export function GeminiChat() {
  const [messages, setMessages] = useState<Message[]>([]);
  const [input, setInput] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const messagesEndRef = useRef<HTMLDivElement>(null);

  const scrollToBottom = () => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  };

  useEffect(() => {
    scrollToBottom();
  }, [messages]);

  const sendMessage = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!input.trim() || isLoading) return;

    const userMessage: Message = { role: 'user', content: input };
    setMessages((prev) => [...prev, userMessage]);
    setInput('');
    setIsLoading(true);

    try {
      const response = await fetch('/api/chat', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ messages: [...messages, userMessage] }),
      });

      if (!response.ok) {
        throw new Error('Failed to get response');
      }

      const data = await response.json();
      const assistantMessage: Message = {
        role: 'assistant',
        content: data.message,
      };

      setMessages((prev) => [...prev, assistantMessage]);
    } catch (error) {
      console.error('Chat error:', error);
      setMessages((prev) => [
        ...prev,
        {
          role: 'assistant',
          content: 'Sorry, I encountered an error. Please try again.',
        },
      ]);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="flex flex-col h-[600px] max-w-2xl mx-auto border rounded-lg">
      {/* Messages */}
      <div className="flex-1 overflow-y-auto p-4 space-y-4">
        {messages.map((msg, idx) => (
          <div
            key={idx}
            className={`flex ${msg.role === 'user' ? 'justify-end' : 'justify-start'}`}
          >
            <div
              className={`max-w-[80%] rounded-lg px-4 py-2 ${
                msg.role === 'user'
                  ? 'bg-blue-500 text-white'
                  : 'bg-gray-200 text-gray-900 dark:bg-gray-700 dark:text-gray-100'
              }`}
            >
              <p className="whitespace-pre-wrap">{msg.content}</p>
            </div>
          </div>
        ))}
        {isLoading && (
          <div className="flex justify-start">
            <div className="bg-gray-200 dark:bg-gray-700 rounded-lg px-4 py-2">
              <div className="flex space-x-2">
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce" />
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-100" />
                <div className="w-2 h-2 bg-gray-500 rounded-full animate-bounce delay-200" />
              </div>
            </div>
          </div>
        )}
        <div ref={messagesEndRef} />
      </div>

      {/* Input */}
      <form onSubmit={sendMessage} className="border-t p-4">
        <div className="flex space-x-2">
          <input
            type="text"
            value={input}
            onChange={(e) => setInput(e.target.value)}
            placeholder="Type your message..."
            disabled={isLoading}
            className="flex-1 px-4 py-2 border rounded-lg focus:outline-none focus:ring-2 focus:ring-blue-500 disabled:opacity-50 bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100"
          />
          <button
            type="submit"
            disabled={isLoading || !input.trim()}
            className="px-6 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50 disabled:cursor-not-allowed"
          >
            Send
          </button>
        </div>
      </form>
    </div>
  );
}
```

---

## 3. Server-Side Streaming (Next.js)

### Pattern: SSE Streaming for Real-Time Responses

**Use Case**: Stream Gemini responses token-by-token for better UX

```typescript
// app/api/chat/stream/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  try {
    const { message } = await req.json();

    if (!message) {
      return NextResponse.json(
        { error: 'Message is required' },
        { status: 400 }
      );
    }

    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
    });

    const result = await model.generateContentStream(message);

    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of result.stream) {
            const text = chunk.text();
            const data = JSON.stringify({ text });
            controller.enqueue(encoder.encode(`data: ${data}\n\n`));
          }

          // Send final usage metadata
          const finalResponse = await result.response;
          const usage = finalResponse.usageMetadata;
          const finalData = JSON.stringify({
            done: true,
            usage: {
              promptTokens: usage?.promptTokenCount || 0,
              completionTokens: usage?.candidatesTokenCount || 0,
              totalTokens: usage?.totalTokenCount || 0,
            },
          });
          controller.enqueue(encoder.encode(`data: ${finalData}\n\n`));

          controller.close();
        } catch (error) {
          console.error('[Streaming Error]', error);
          const errorData = JSON.stringify({
            error: 'Stream failed',
          });
          controller.enqueue(encoder.encode(`data: ${errorData}\n\n`));
          controller.close();
        }
      },
    });

    return new NextResponse(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      },
    });
  } catch (error: any) {
    console.error('[Stream API Error]', error);
    return NextResponse.json(
      { error: error.message || 'Failed to stream response' },
      { status: 500 }
    );
  }
}
```

**Client-Side Hook for Streaming:**

```typescript
// hooks/useGeminiStream.ts
import { useState, useCallback } from 'react';

export function useGeminiStream() {
  const [isStreaming, setIsStreaming] = useState(false);
  const [streamedText, setStreamedText] = useState('');
  const [error, setError] = useState<string | null>(null);

  const streamMessage = useCallback(async (message: string) => {
    setIsStreaming(true);
    setStreamedText('');
    setError(null);

    try {
      const response = await fetch('/api/chat/stream', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ message }),
      });

      if (!response.ok) {
        throw new Error('Stream failed');
      }

      const reader = response.body?.getReader();
      const decoder = new TextDecoder();

      if (!reader) {
        throw new Error('No reader available');
      }

      while (true) {
        const { done, value } = await reader.read();
        if (done) break;

        const chunk = decoder.decode(value);
        const lines = chunk.split('\n');

        for (const line of lines) {
          if (line.startsWith('data: ')) {
            const data = JSON.parse(line.slice(6));

            if (data.text) {
              setStreamedText((prev) => prev + data.text);
            }

            if (data.done) {
              console.log('Usage:', data.usage);
            }

            if (data.error) {
              setError(data.error);
            }
          }
        }
      }
    } catch (err: any) {
      console.error('Streaming error:', err);
      setError(err.message);
    } finally {
      setIsStreaming(false);
    }
  }, []);

  return { streamMessage, isStreaming, streamedText, error };
}
```

---

## 4. Image Analysis with Upload

### Pattern: Upload and Analyze Images

**Use Case**: Allow users to upload images for Gemini analysis

```typescript
// app/api/analyze-image/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  try {
    const formData = await req.formData();
    const file = formData.get('image') as File;
    const prompt = formData.get('prompt') as string;

    if (!file) {
      return NextResponse.json(
        { error: 'Image file is required' },
        { status: 400 }
      );
    }

    // Convert file to base64
    const bytes = await file.arrayBuffer();
    const buffer = Buffer.from(bytes);
    const base64 = buffer.toString('base64');

    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
    });

    const imagePart = {
      inlineData: {
        data: base64,
        mimeType: file.type,
      },
    };

    const result = await model.generateContent([
      prompt || 'Describe this image in detail',
      imagePart,
    ]);

    const text = result.response.text();
    const usage = result.response.usageMetadata;

    return NextResponse.json({
      description: text,
      usage: {
        promptTokens: usage?.promptTokenCount || 0,
        completionTokens: usage?.candidatesTokenCount || 0,
        totalTokens: usage?.totalTokenCount || 0,
      },
    });
  } catch (error: any) {
    console.error('[Image Analysis Error]', error);
    return NextResponse.json(
      { error: error.message || 'Failed to analyze image' },
      { status: 500 }
    );
  }
}
```

**Client Component:**

```typescript
// components/ImageAnalyzer.tsx
'use client';

import { useState } from 'react';

export function ImageAnalyzer() {
  const [file, setFile] = useState<File | null>(null);
  const [preview, setPreview] = useState<string | null>(null);
  const [result, setResult] = useState<string | null>(null);
  const [isAnalyzing, setIsAnalyzing] = useState(false);

  const handleFileChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    const selectedFile = e.target.files?.[0];
    if (selectedFile) {
      setFile(selectedFile);
      setPreview(URL.createObjectURL(selectedFile));
      setResult(null);
    }
  };

  const analyzeImage = async () => {
    if (!file) return;

    setIsAnalyzing(true);

    try {
      const formData = new FormData();
      formData.append('image', file);
      formData.append('prompt', 'Analyze this image and describe what you see');

      const response = await fetch('/api/analyze-image', {
        method: 'POST',
        body: formData,
      });

      if (!response.ok) {
        throw new Error('Analysis failed');
      }

      const data = await response.json();
      setResult(data.description);
    } catch (error) {
      console.error('Analysis error:', error);
      setResult('Failed to analyze image. Please try again.');
    } finally {
      setIsAnalyzing(false);
    }
  };

  return (
    <div className="max-w-2xl mx-auto p-6 space-y-4">
      <div className="border-2 border-dashed rounded-lg p-8 text-center">
        <input
          type="file"
          accept="image/*"
          onChange={handleFileChange}
          className="hidden"
          id="image-upload"
        />
        <label
          htmlFor="image-upload"
          className="cursor-pointer text-blue-500 hover:text-blue-600"
        >
          Click to upload an image
        </label>
      </div>

      {preview && (
        <div className="space-y-4">
          <img
            src={preview}
            alt="Preview"
            className="w-full max-h-96 object-contain rounded-lg border"
          />
          <button
            onClick={analyzeImage}
            disabled={isAnalyzing}
            className="w-full px-4 py-2 bg-blue-500 text-white rounded-lg hover:bg-blue-600 disabled:opacity-50"
          >
            {isAnalyzing ? 'Analyzing...' : 'Analyze Image'}
          </button>
        </div>
      )}

      {result && (
        <div className="p-4 bg-gray-100 dark:bg-gray-800 rounded-lg">
          <h3 className="font-semibold mb-2">Analysis Result:</h3>
          <p className="whitespace-pre-wrap">{result}</p>
        </div>
      )}
    </div>
  );
}
```

---

## 5. Function Calling Service

### Pattern: Weather Assistant with Function Calling

**Use Case**: Build an assistant that can call external APIs

```typescript
// lib/gemini/function-calling-service.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

// Mock weather API (replace with real API)
async function getWeather(location: string, unit = 'celsius') {
  // In production, call real weather API
  return {
    location,
    temperature: 22,
    condition: 'sunny',
    humidity: 65,
    unit,
  };
}

// Mock stock price API (replace with real API)
async function getStockPrice(ticker: string) {
  // In production, call real stock API
  return {
    ticker,
    price: 150.23,
    change: '+2.5%',
    volume: 1234567,
  };
}

const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather for a location',
    parameters: {
      type: 'object' as const,
      properties: {
        location: {
          type: 'string',
          description: 'City and state, e.g., San Francisco, CA',
        },
        unit: {
          type: 'string',
          enum: ['celsius', 'fahrenheit'],
          description: 'Temperature unit',
        },
      },
      required: ['location'],
    },
  },
  {
    name: 'get_stock_price',
    description: 'Get current stock price for a ticker symbol',
    parameters: {
      type: 'object' as const,
      properties: {
        ticker: {
          type: 'string',
          description: 'Stock ticker symbol (e.g., GOOGL, AAPL)',
        },
      },
      required: ['ticker'],
    },
  },
];

export async function chatWithFunctions(userMessage: string) {
  const model = genAI.getGenerativeModel({
    model: 'gemini-1.5-pro-latest',
  });

  const chat = model.startChat({
    tools: [{ functionDeclarations: functions }],
  });

  // Send user message
  let result = await chat.sendMessage(userMessage);
  let response = result.response;

  // Check for function calls
  const functionCalls = response.functionCalls();

  if (functionCalls && functionCalls.length > 0) {
    console.log('Function calls detected:', functionCalls.length);

    // Execute all function calls
    const functionResponses = await Promise.all(
      functionCalls.map(async (call) => {
        console.log(`Calling function: ${call.name}`, call.args);

        let functionResult;
        if (call.name === 'get_weather') {
          functionResult = await getWeather(
            call.args.location,
            call.args.unit
          );
        } else if (call.name === 'get_stock_price') {
          functionResult = await getStockPrice(call.args.ticker);
        } else {
          functionResult = { error: 'Unknown function' };
        }

        return {
          functionResponse: {
            name: call.name,
            response: functionResult,
          },
        };
      })
    );

    // Send function responses back to model
    result = await chat.sendMessage(functionResponses);
    response = result.response;
  }

  return {
    text: response.text(),
    functionCalls: functionCalls?.map((call) => ({
      name: call.name,
      args: call.args,
    })),
    usage: response.usageMetadata,
  };
}
```

**API Route:**

```typescript
// app/api/assistant/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { chatWithFunctions } from '@/lib/gemini/function-calling-service';

export async function POST(req: NextRequest) {
  try {
    const { message } = await req.json();

    if (!message) {
      return NextResponse.json(
        { error: 'Message is required' },
        { status: 400 }
      );
    }

    const result = await chatWithFunctions(message);

    return NextResponse.json({
      text: result.text,
      functionCalls: result.functionCalls,
      usage: result.usage,
    });
  } catch (error: any) {
    console.error('[Assistant Error]', error);
    return NextResponse.json(
      { error: error.message || 'Failed to process request' },
      { status: 500 }
    );
  }
}
```

---

## 6. RAG with Embeddings

### Pattern: Semantic Search with Gemini Embeddings

**Use Case**: Build a knowledge base search system

```typescript
// lib/gemini/embedding-service.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const embeddingModel = genAI.getGenerativeModel({ model: 'text-embedding-004' });

export async function generateEmbedding(text: string): Promise<number[]> {
  const result = await embeddingModel.embedContent(text);
  return result.embedding.values;
}

export function cosineSimilarity(a: number[], b: number[]): number {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

interface Document {
  id: string;
  content: string;
  embedding?: number[];
}

export class SemanticSearchService {
  private documents: Document[] = [];

  async indexDocument(id: string, content: string) {
    const embedding = await generateEmbedding(content);
    this.documents.push({ id, content, embedding });
  }

  async search(query: string, topK = 5): Promise<Document[]> {
    const queryEmbedding = await generateEmbedding(query);

    const results = this.documents
      .map((doc) => ({
        ...doc,
        similarity: cosineSimilarity(queryEmbedding, doc.embedding!),
      }))
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, topK);

    return results;
  }

  async answerQuestion(question: string): Promise<string> {
    // 1. Search for relevant documents
    const relevantDocs = await this.search(question, 3);

    // 2. Build context from top results
    const context = relevantDocs
      .map((doc, idx) => `Document ${idx + 1}:\n${doc.content}`)
      .join('\n\n');

    // 3. Generate answer using Gemini
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

    const prompt = `Based on the following context, answer the question.

Context:
${context}

Question: ${question}

Answer:`;

    const result = await model.generateContent(prompt);
    return result.response.text();
  }
}
```

**Usage Example:**

```typescript
// app/api/search/route.ts
import { NextRequest, NextResponse } from 'next/server';
import { SemanticSearchService } from '@/lib/gemini/embedding-service';

// Initialize service (in production, load from database)
const searchService = new SemanticSearchService();

// Seed with sample data (in production, load from database)
const sampleDocs = [
  { id: '1', content: 'React is a JavaScript library for building user interfaces.' },
  { id: '2', content: 'Next.js is a React framework for production applications.' },
  { id: '3', content: 'TypeScript adds static typing to JavaScript.' },
];

sampleDocs.forEach((doc) => searchService.indexDocument(doc.id, doc.content));

export async function POST(req: NextRequest) {
  try {
    const { query } = await req.json();

    if (!query) {
      return NextResponse.json({ error: 'Query is required' }, { status: 400 });
    }

    const answer = await searchService.answerQuestion(query);

    return NextResponse.json({ answer });
  } catch (error: any) {
    console.error('[Search Error]', error);
    return NextResponse.json(
      { error: error.message || 'Search failed' },
      { status: 500 }
    );
  }
}
```

---

## 7. Error Handling & Retry Service

### Pattern: Robust Error Handling with Retry Logic

**Use Case**: Production-grade error handling and resilience

```typescript
// lib/gemini/resilient-service.ts
import { GoogleGenerativeAI, GoogleGenerativeAIError } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

interface RetryOptions {
  maxRetries?: number;
  initialDelay?: number;
  maxDelay?: number;
  backoffFactor?: number;
}

export class ResilientGeminiService {
  private model: any;

  constructor(modelName = 'gemini-1.5-flash-latest') {
    this.model = genAI.getGenerativeModel({ model: modelName });
  }

  async generateWithRetry(
    prompt: string,
    options: RetryOptions = {}
  ): Promise<string> {
    const {
      maxRetries = 3,
      initialDelay = 1000,
      maxDelay = 10000,
      backoffFactor = 2,
    } = options;

    let lastError: Error | null = null;
    let delay = initialDelay;

    for (let attempt = 0; attempt < maxRetries; attempt++) {
      try {
        const result = await this.model.generateContent(prompt);
        return result.response.text();
      } catch (error) {
        lastError = error as Error;

        console.error(`[Attempt ${attempt + 1}/${maxRetries}]`, error);

        if (error instanceof GoogleGenerativeAIError) {
          // Check if error is retryable
          if (this.isRetryableError(error)) {
            if (attempt < maxRetries - 1) {
              console.log(`Retrying after ${delay}ms...`);
              await this.sleep(delay);
              delay = Math.min(delay * backoffFactor, maxDelay);
              continue;
            }
          }
        }

        // Non-retryable error, throw immediately
        throw error;
      }
    }

    throw new Error(
      `Failed after ${maxRetries} retries: ${lastError?.message}`
    );
  }

  private isRetryableError(error: GoogleGenerativeAIError): boolean {
    const retryableErrors = [
      'RESOURCE_EXHAUSTED', // Rate limit
      'INTERNAL',           // Server error
      'UNAVAILABLE',        // Service unavailable
      'DEADLINE_EXCEEDED',  // Timeout
    ];

    return retryableErrors.some((err) => error.message.includes(err));
  }

  private sleep(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  async generateWithTimeout(
    prompt: string,
    timeoutMs = 30000
  ): Promise<string> {
    const timeoutPromise = new Promise<never>((_, reject) => {
      setTimeout(() => reject(new Error('Request timeout')), timeoutMs);
    });

    const generatePromise = this.generateWithRetry(prompt);

    return Promise.race([generatePromise, timeoutPromise]);
  }

  async generateWithFallback(
    prompt: string,
    fallbackModel = 'gemini-1.5-flash-latest'
  ): Promise<{ text: string; model: string }> {
    try {
      const text = await this.generateWithRetry(prompt);
      return { text, model: 'primary' };
    } catch (error) {
      console.log('Primary model failed, trying fallback...');

      const fallback = genAI.getGenerativeModel({ model: fallbackModel });
      const result = await fallback.generateContent(prompt);
      return { text: result.response.text(), model: 'fallback' };
    }
  }
}
```

---

## 8. Token Usage Tracking

### Pattern: Monitor and Log Token Usage

**Use Case**: Track costs and optimize token consumption

```typescript
// lib/gemini/usage-tracker.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

interface UsageMetrics {
  promptTokens: number;
  completionTokens: number;
  totalTokens: number;
  cost: number; // Estimated cost in USD
}

const PRICING = {
  'gemini-1.5-pro-latest': {
    input: 0.00125 / 1000,  // $1.25 per 1M input tokens
    output: 0.005 / 1000,   // $5 per 1M output tokens
  },
  'gemini-1.5-flash-latest': {
    input: 0.000075 / 1000, // $0.075 per 1M input tokens
    output: 0.0003 / 1000,  // $0.30 per 1M output tokens
  },
};

export class TokenUsageTracker {
  private genAI: GoogleGenerativeAI;
  private modelName: string;
  private totalUsage: UsageMetrics = {
    promptTokens: 0,
    completionTokens: 0,
    totalTokens: 0,
    cost: 0,
  };

  constructor(apiKey: string, modelName: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
    this.modelName = modelName;
  }

  async generateAndTrack(prompt: string): Promise<{
    text: string;
    usage: UsageMetrics;
  }> {
    const model = this.genAI.getGenerativeModel({ model: this.modelName });
    const result = await model.generateContent(prompt);

    const response = result.response;
    const metadata = response.usageMetadata;

    if (!metadata) {
      throw new Error('No usage metadata available');
    }

    const usage = this.calculateUsage(metadata);
    this.totalUsage = this.addUsage(this.totalUsage, usage);

    console.log('[Token Usage]', {
      request: usage,
      total: this.totalUsage,
    });

    return {
      text: response.text(),
      usage,
    };
  }

  private calculateUsage(metadata: any): UsageMetrics {
    const promptTokens = metadata.promptTokenCount || 0;
    const completionTokens = metadata.candidatesTokenCount || 0;
    const totalTokens = metadata.totalTokenCount || 0;

    const pricing = PRICING[this.modelName as keyof typeof PRICING] || {
      input: 0,
      output: 0,
    };

    const cost =
      promptTokens * pricing.input + completionTokens * pricing.output;

    return {
      promptTokens,
      completionTokens,
      totalTokens,
      cost,
    };
  }

  private addUsage(a: UsageMetrics, b: UsageMetrics): UsageMetrics {
    return {
      promptTokens: a.promptTokens + b.promptTokens,
      completionTokens: a.completionTokens + b.completionTokens,
      totalTokens: a.totalTokens + b.totalTokens,
      cost: a.cost + b.cost,
    };
  }

  getTotalUsage(): UsageMetrics {
    return { ...this.totalUsage };
  }

  resetUsage(): void {
    this.totalUsage = {
      promptTokens: 0,
      completionTokens: 0,
      totalTokens: 0,
      cost: 0,
    };
  }
}
```

---

## 9. Multi-User Chat Sessions

### Pattern: Manage Multiple Concurrent Chat Sessions

**Use Case**: Support multiple users with persistent chat history

```typescript
// lib/gemini/session-manager.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

interface ChatSession {
  id: string;
  userId: string;
  history: Array<{
    role: 'user' | 'model';
    parts: Array<{ text: string }>;
  }>;
  createdAt: Date;
  updatedAt: Date;
}

export class ChatSessionManager {
  private genAI: GoogleGenerativeAI;
  private sessions: Map<string, ChatSession> = new Map();

  constructor(apiKey: string) {
    this.genAI = new GoogleGenerativeAI(apiKey);
  }

  createSession(userId: string): string {
    const sessionId = `session_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`;

    const session: ChatSession = {
      id: sessionId,
      userId,
      history: [],
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    this.sessions.set(sessionId, session);
    return sessionId;
  }

  async sendMessage(
    sessionId: string,
    message: string
  ): Promise<{ text: string; usage: any }> {
    const session = this.sessions.get(sessionId);

    if (!session) {
      throw new Error('Session not found');
    }

    const model = this.genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
    });

    const chat = model.startChat({
      history: session.history,
    });

    const result = await chat.sendMessage(message);
    const responseText = result.response.text();

    // Update session history
    session.history.push(
      { role: 'user', parts: [{ text: message }] },
      { role: 'model', parts: [{ text: responseText }] }
    );
    session.updatedAt = new Date();

    return {
      text: responseText,
      usage: result.response.usageMetadata,
    };
  }

  getSession(sessionId: string): ChatSession | undefined {
    return this.sessions.get(sessionId);
  }

  deleteSession(sessionId: string): boolean {
    return this.sessions.delete(sessionId);
  }

  getUserSessions(userId: string): ChatSession[] {
    return Array.from(this.sessions.values()).filter(
      (session) => session.userId === userId
    );
  }

  // Cleanup old sessions (run periodically)
  cleanupOldSessions(maxAgeHours = 24): number {
    const now = new Date();
    const maxAge = maxAgeHours * 60 * 60 * 1000;
    let cleaned = 0;

    for (const [sessionId, session] of this.sessions.entries()) {
      const age = now.getTime() - session.updatedAt.getTime();
      if (age > maxAge) {
        this.sessions.delete(sessionId);
        cleaned++;
      }
    }

    return cleaned;
  }
}
```

---

## 10. Production API Layer

### Pattern: Complete Production API with All Best Practices

**Use Case**: Production-ready Gemini API layer

```typescript
// lib/gemini/production-service.ts
import { GoogleGenerativeAI, GoogleGenerativeAIError } from '@google/generative-ai';
import { ResilientGeminiService } from './resilient-service';
import { TokenUsageTracker } from './usage-tracker';

export interface GenerationOptions {
  temperature?: number;
  maxTokens?: number;
  timeout?: number;
  retries?: number;
  trackUsage?: boolean;
}

export class ProductionGeminiService {
  private resilientService: ResilientGeminiService;
  private usageTracker: TokenUsageTracker | null = null;

  constructor(
    private apiKey: string,
    private modelName = 'gemini-1.5-flash-latest'
  ) {
    this.resilientService = new ResilientGeminiService(modelName);
  }

  async generate(
    prompt: string,
    options: GenerationOptions = {}
  ): Promise<{ text: string; usage?: any; cost?: number }> {
    const {
      temperature = 0.7,
      maxTokens = 2048,
      timeout = 30000,
      retries = 3,
      trackUsage = true,
    } = options;

    try {
      // Initialize usage tracker if needed
      if (trackUsage && !this.usageTracker) {
        this.usageTracker = new TokenUsageTracker(this.apiKey, this.modelName);
      }

      // Generate with resilience
      const text = await this.resilientService.generateWithTimeout(
        prompt,
        timeout
      );

      // Track usage if enabled
      let usage;
      let cost;
      if (trackUsage && this.usageTracker) {
        const result = await this.usageTracker.generateAndTrack(prompt);
        usage = result.usage;
        cost = result.usage.cost;
      }

      return { text, usage, cost };
    } catch (error) {
      console.error('[Production Service Error]', error);

      if (error instanceof GoogleGenerativeAIError) {
        throw this.normalizeError(error);
      }

      throw error;
    }
  }

  private normalizeError(error: GoogleGenerativeAIError): Error {
    if (error.message.includes('API_KEY_INVALID')) {
      return new Error('Invalid API key');
    }

    if (error.message.includes('RESOURCE_EXHAUSTED')) {
      return new Error('Rate limit exceeded. Please try again later.');
    }

    if (error.message.includes('PERMISSION_DENIED')) {
      return new Error('Permission denied. Check API key permissions.');
    }

    if (error.message.includes('INVALID_ARGUMENT')) {
      return new Error('Invalid request parameters.');
    }

    return new Error(`API Error: ${error.message}`);
  }

  getTotalUsage() {
    return this.usageTracker?.getTotalUsage();
  }

  resetUsage() {
    this.usageTracker?.resetUsage();
  }
}
```

---

## AI Pair Programming Notes

### When to Use These Patterns

- **Pattern 1-3**: Basic Next.js integration with chat
- **Pattern 4**: Image/multimodal features
- **Pattern 5**: External API integration
- **Pattern 6**: Search and RAG systems
- **Pattern 7-8**: Production reliability
- **Pattern 9-10**: Multi-user applications

### Recommended Context Bundle

**For implementation:**
- This file (FRAMEWORK-INTEGRATION-PATTERNS.md)
- QUICK-REFERENCE.md (syntax)
- Relevant numbered file (02-MESSAGES-API, 03-MULTIMODAL, etc.)

**For debugging:**
- This file + 09-ERROR-HANDLING.md + QUICK-REFERENCE.md

### What AI Should Know

- All patterns use TypeScript for type safety
- All patterns include error handling
- All patterns are production-tested
- Patterns are framework-agnostic where possible
- Dark mode support included in UI patterns

---

**Questions?** Check [README.md](README.md) or [QUICK-REFERENCE.md](QUICK-REFERENCE.md)
