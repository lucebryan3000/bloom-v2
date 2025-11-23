---
id: google-gemini-nodejs-quick-reference
topic: google-gemini-nodejs
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: [google-gemini, ai-ml]
embedding_keywords: [google-gemini, quick-reference, cheatsheet, code-examples, snippets]
last_reviewed: 2025-11-13
---

# Google Gemini API - Quick Reference

**Purpose**: Fast copy-paste reference for common Gemini API patterns. All examples are production-ready and type-safe.

**Model Names** (as of November 2025):
- `gemini-1.5-pro-latest` - Most capable, 2M tokens
- `gemini-1.5-flash-latest` - Fastest, 1M tokens
- `text-embedding-004` - Latest embedding model

---

## Table of Contents

1. [Setup & Installation](#setup--installation)
2. [Basic Text Generation](#basic-text-generation)
3. [Conversations & Chat](#conversations--chat)
4. [System Instructions](#system-instructions)
5. [Streaming Responses](#streaming-responses)
6. [Multimodal (Images, Audio, Video)](#multimodal-inputs)
7. [Function Calling](#function-calling)
8. [Embeddings](#embeddings)
9. [Safety Settings](#safety-settings)
10. [Error Handling](#error-handling)
11. [Configuration](#configuration)
12. [TypeScript Types](#typescript-types)

---

## Setup & Installation

### Install SDK

```bash
# Google AI SDK (direct API access)
npm install @google/generative-ai

# Or Vertex AI SDK (for Google Cloud)
npm install @google-cloud/vertexai
```

### Environment Variables

```bash
# .env.local

# For Google AI
GOOGLE_AI_API_KEY=AIzaSy...your-api-key

# For Vertex AI
GOOGLE_CLOUD_PROJECT=your-project-id
GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account-key.json
VERTEX_AI_LOCATION=us-central1
```

### Basic Initialization (Google AI)

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

// Get model
const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-flash-latest',
});
```

### Basic Initialization (Vertex AI)

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT!,
  location: process.env.VERTEX_AI_LOCATION || 'us-central1',
});

const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-flash',
});
```

---

## Basic Text Generation

### Simple Generation

```typescript
const result = await model.generateContent('Explain quantum computing in one paragraph');
const response = await result.response;
const text = response.text();

console.log(text);
```

### With Generation Config

```typescript
const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: 'Write a haiku about AI' }] }],
  generationConfig: {
    temperature: 0.9,
    topK: 40,
    topP: 0.95,
    maxOutputTokens: 1024,
  },
});

const text = result.response.text();
```

### Check Token Usage

```typescript
const result = await model.generateContent('Hello, Gemini!');
const response = await result.response;

console.log('Usage:', response.usageMetadata);
// { promptTokenCount: 5, candidatesTokenCount: 10, totalTokenCount: 15 }
```

---

## Conversations & Chat

### Start a Chat Session

```typescript
const chat = model.startChat({
  history: [
    { role: 'user', parts: [{ text: 'Hello!' }] },
    { role: 'model', parts: [{ text: 'Hi! How can I help you today?' }] },
  ],
});

// Send message
const result = await chat.sendMessage('What is the weather like?');
console.log(result.response.text());

// Continue conversation
const result2 = await chat.sendMessage('Tell me more');
console.log(result2.response.text());
```

### Get Chat History

```typescript
const history = await chat.getHistory();
console.log('Chat history:', history);
```

### Multi-Turn Conversation (Full Example)

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

async function chatExample() {
  const chat = model.startChat({
    history: [],
    generationConfig: {
      temperature: 0.7,
      maxOutputTokens: 1024,
    },
  });

  // Turn 1
  const msg1 = await chat.sendMessage('Hello! I need help with ROI calculations.');
  console.log('Bot:', msg1.response.text());

  // Turn 2
  const msg2 = await chat.sendMessage('How do I calculate NPV?');
  console.log('Bot:', msg2.response.text());

  // Turn 3
  const msg3 = await chat.sendMessage('Can you give me an example?');
  console.log('Bot:', msg3.response.text());

  // Get full history
  const history = await chat.getHistory();
  console.log('Total turns:', history.length / 2);
}

chatExample();
```

---

## System Instructions

### Simple System Instruction (Gemini 1.5+)

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-pro-latest',
  systemInstruction: 'You are a helpful ROI analyst. Always provide data-driven insights with specific numbers.',
});

const result = await model.generateContent('Calculate ROI for a $10k investment with $15k return');
console.log(result.response.text());
```

### Complex System Instruction

```typescript
const systemInstruction = `You are Melissa, an expert AI facilitator for ROI discovery workshops.

Your role:
1. Ask targeted questions about business processes
2. Identify improvement opportunities
3. Guide users to quantify potential ROI
4. Keep sessions focused and under 15 minutes

Guidelines:
- Be concise and professional
- Ask one question at a time
- Validate user inputs before proceeding
- Provide confidence scores for ROI estimates

Always respond in JSON format when calculating ROI.`;

const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-pro-latest',
  systemInstruction,
});
```

### System Instruction with Chat

```typescript
const chat = model.startChat({
  history: [],
  systemInstruction: 'You are a coding assistant. Always provide TypeScript examples with type safety.',
});

const result = await chat.sendMessage('Show me how to fetch data in React');
console.log(result.response.text());
```

---

## Streaming Responses

### Basic Streaming

```typescript
const result = await model.generateContentStream('Write a long story about AI');

for await (const chunk of result.stream) {
  const chunkText = chunk.text();
  process.stdout.write(chunkText);
}

// Get final response
const finalResponse = await result.response;
console.log('\n\nTotal tokens:', finalResponse.usageMetadata?.totalTokenCount);
```

### Streaming with Chat

```typescript
const chat = model.startChat();

const result = await chat.sendMessageStream('Explain machine learning in detail');

for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}

const finalResponse = await result.response;
```

### Next.js API Route with Streaming

```typescript
// app/api/chat/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  try {
    const { message } = await req.json();

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

    const result = await model.generateContentStream(message);

    // Create a ReadableStream for SSE
    const stream = new ReadableStream({
      async start(controller) {
        try {
          for await (const chunk of result.stream) {
            const text = chunk.text();
            controller.enqueue(new TextEncoder().encode(`data: ${JSON.stringify({ text })}\n\n`));
          }
          controller.enqueue(new TextEncoder().encode('data: [DONE]\n\n'));
          controller.close();
        } catch (error) {
          controller.error(error);
        }
      },
    });

    return new NextResponse(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  } catch (error) {
    console.error('Chat error:', error);
    return NextResponse.json({ error: 'Failed to generate response' }, { status: 500 });
  }
}
```

---

## Multimodal Inputs

### Image (Base64)

```typescript
import fs from 'fs';

const imagePart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('image.jpg')).toString('base64'),
    mimeType: 'image/jpeg',
  },
};

const result = await model.generateContent([
  'What is in this image? Describe in detail.',
  imagePart,
]);

console.log(result.response.text());
```

### Image (URL) - Vertex AI Only

```typescript
import { VertexAI, Part } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({ project: 'your-project', location: 'us-central1' });
const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-pro' });

const filePart: Part = {
  fileData: {
    mimeType: 'image/jpeg',
    fileUri: 'gs://your-bucket/image.jpg',
  },
};

const result = await model.generateContent(['Describe this image', filePart]);
```

### Multiple Images

```typescript
const image1 = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('chart1.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const image2 = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('chart2.png')).toString('base64'),
    mimeType: 'image/png',
  },
};

const result = await model.generateContent([
  'Compare these two charts and identify key differences:',
  image1,
  image2,
]);
```

### Audio Input

```typescript
const audioPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('audio.mp3')).toString('base64'),
    mimeType: 'audio/mp3',
  },
};

const result = await model.generateContent([
  'Transcribe this audio and summarize the main points:',
  audioPart,
]);
```

### Video Input

```typescript
const videoPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('video.mp4')).toString('base64'),
    mimeType: 'video/mp4',
  },
};

const result = await model.generateContent([
  'Describe what happens in this video:',
  videoPart,
]);
```

### PDF Input

```typescript
const pdfPart = {
  inlineData: {
    data: Buffer.from(fs.readFileSync('document.pdf')).toString('base64'),
    mimeType: 'application/pdf',
  },
};

const result = await model.generateContent([
  'Summarize this PDF document:',
  pdfPart,
]);
```

---

## Function Calling

### Define Functions

```typescript
const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather for a location',
    parameters: {
      type: 'object',
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
      type: 'object',
      properties: {
        ticker: {
          type: 'string',
          description: 'Stock ticker symbol (e.g., GOOGL)',
        },
      },
      required: ['ticker'],
    },
  },
];
```

### Call with Functions

```typescript
const chat = model.startChat({
  tools: [{ functionDeclarations: functions }],
});

const result = await chat.sendMessage('What is the weather in Boston and the price of GOOGL stock?');

// Check for function calls
const functionCalls = result.response.functionCalls();

if (functionCalls) {
  for (const call of functionCalls) {
    console.log('Function:', call.name);
    console.log('Args:', call.args);

    // Execute function
    let functionResponse;
    if (call.name === 'get_weather') {
      functionResponse = await getWeather(call.args.location, call.args.unit);
    } else if (call.name === 'get_stock_price') {
      functionResponse = await getStockPrice(call.args.ticker);
    }

    // Send function response back to model
    const result2 = await chat.sendMessage([{
      functionResponse: {
        name: call.name,
        response: functionResponse,
      },
    }]);

    console.log('Final response:', result2.response.text());
  }
}
```

### Complete Function Calling Example

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

// Mock functions
async function getWeather(location: string, unit = 'celsius') {
  return { temperature: 22, condition: 'sunny', location, unit };
}

async function getStockPrice(ticker: string) {
  return { ticker, price: 150.23, change: '+2.5%' };
}

async function functionCallingExample() {
  const functions = [
    {
      name: 'get_weather',
      description: 'Get current weather',
      parameters: {
        type: 'object',
        properties: {
          location: { type: 'string' },
          unit: { type: 'string', enum: ['celsius', 'fahrenheit'] },
        },
        required: ['location'],
      },
    },
    {
      name: 'get_stock_price',
      description: 'Get stock price',
      parameters: {
        type: 'object',
        properties: {
          ticker: { type: 'string' },
        },
        required: ['ticker'],
      },
    },
  ];

  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });
  const chat = model.startChat({
    tools: [{ functionDeclarations: functions }],
  });

  const result = await chat.sendMessage('What is the weather in London and the price of TSLA?');

  const functionCalls = result.response.functionCalls();
  if (!functionCalls) {
    console.log('No function calls');
    return;
  }

  // Execute all function calls
  const functionResponses = await Promise.all(
    functionCalls.map(async (call) => {
      let response;
      if (call.name === 'get_weather') {
        response = await getWeather(call.args.location, call.args.unit);
      } else if (call.name === 'get_stock_price') {
        response = await getStockPrice(call.args.ticker);
      }
      return {
        functionResponse: {
          name: call.name,
          response,
        },
      };
    })
  );

  // Send all responses back
  const result2 = await chat.sendMessage(functionResponses);
  console.log('Final:', result2.response.text());
}

functionCallingExample();
```

---

## Embeddings

### Generate Text Embeddings

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'text-embedding-004' });

const result = await model.embedContent('What is the meaning of life?');
const embedding = result.embedding;

console.log('Embedding vector:', embedding.values);
console.log('Dimensions:', embedding.values.length); // 768
```

### Batch Embeddings

```typescript
const texts = [
  'Machine learning is a subset of AI',
  'Deep learning uses neural networks',
  'Natural language processing handles text',
];

const embeddings = await Promise.all(
  texts.map(async (text) => {
    const result = await model.embedContent(text);
    return result.embedding.values;
  })
);

console.log('Generated', embeddings.length, 'embeddings');
```

### Semantic Similarity

```typescript
function cosineSimilarity(a: number[], b: number[]): number {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

// Generate embeddings
const query = await model.embedContent('AI and machine learning');
const doc1 = await model.embedContent('Deep learning is a type of machine learning');
const doc2 = await model.embedContent('Cats are popular pets');

// Calculate similarity
const similarity1 = cosineSimilarity(query.embedding.values, doc1.embedding.values);
const similarity2 = cosineSimilarity(query.embedding.values, doc2.embedding.values);

console.log('Query-Doc1 similarity:', similarity1); // High (~0.8)
console.log('Query-Doc2 similarity:', similarity2); // Low (~0.2)
```

---

## Safety Settings

### Default Safety Settings

```typescript
import { HarmCategory, HarmBlockThreshold } from '@google/generative-ai';

const safetySettings = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
];

const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-flash-latest',
  safetySettings,
});
```

### Permissive Settings

```typescript
const permissiveSafetySettings = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_NONE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_NONE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
    threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
  },
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
  },
];
```

### Check Safety Ratings

```typescript
const result = await model.generateContent('Write about sensitive topic');
const response = result.response;

console.log('Safety ratings:', response.candidates?.[0]?.safetyRatings);

// Check if blocked
if (response.candidates?.[0]?.finishReason === 'SAFETY') {
  console.log('Response blocked due to safety filters');
}
```

---

## Error Handling

### Basic Error Handling

```typescript
import { GoogleGenerativeAIError } from '@google/generative-ai';

try {
  const result = await model.generateContent('Hello');
  console.log(result.response.text());
} catch (error) {
  if (error instanceof GoogleGenerativeAIError) {
    console.error('Gemini API Error:', error.message);

    if (error.message.includes('API_KEY_INVALID')) {
      console.error('Invalid API key');
    } else if (error.message.includes('RESOURCE_EXHAUSTED')) {
      console.error('Rate limit exceeded');
    } else if (error.message.includes('PERMISSION_DENIED')) {
      console.error('Permission denied');
    }
  } else {
    console.error('Unexpected error:', error);
  }
}
```

### Retry Logic with Exponential Backoff

```typescript
async function generateWithRetry(
  model: any,
  prompt: string,
  maxRetries = 3
): Promise<string> {
  let lastError: Error | null = null;

  for (let attempt = 0; attempt < maxRetries; attempt++) {
    try {
      const result = await model.generateContent(prompt);
      return result.response.text();
    } catch (error) {
      lastError = error as Error;

      if (error instanceof GoogleGenerativeAIError) {
        // Only retry on rate limit or server errors
        if (
          error.message.includes('RESOURCE_EXHAUSTED') ||
          error.message.includes('INTERNAL') ||
          error.message.includes('UNAVAILABLE')
        ) {
          const delay = Math.min(1000 * Math.pow(2, attempt), 10000);
          console.log(`Retry attempt ${attempt + 1} after ${delay}ms`);
          await new Promise((resolve) => setTimeout(resolve, delay));
          continue;
        }
      }

      // Don't retry on other errors
      throw error;
    }
  }

  throw new Error(`Failed after ${maxRetries} retries: ${lastError?.message}`);
}

// Usage
const text = await generateWithRetry(model, 'Hello, Gemini!');
```

### Error Handling in Next.js API Route

```typescript
// app/api/generate/route.ts
import { GoogleGenerativeAI, GoogleGenerativeAIError } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export async function POST(req: NextRequest) {
  try {
    const { prompt } = await req.json();

    if (!prompt) {
      return NextResponse.json({ error: 'Prompt is required' }, { status: 400 });
    }

    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
    const result = await model.generateContent(prompt);

    return NextResponse.json({
      text: result.response.text(),
      usage: result.response.usageMetadata,
    });
  } catch (error) {
    console.error('Generation error:', error);

    if (error instanceof GoogleGenerativeAIError) {
      if (error.message.includes('RESOURCE_EXHAUSTED')) {
        return NextResponse.json(
          { error: 'Rate limit exceeded. Please try again later.' },
          { status: 429 }
        );
      } else if (error.message.includes('INVALID_ARGUMENT')) {
        return NextResponse.json(
          { error: 'Invalid request parameters' },
          { status: 400 }
        );
      } else if (error.message.includes('PERMISSION_DENIED')) {
        return NextResponse.json(
          { error: 'Authentication failed' },
          { status: 401 }
        );
      }
    }

    return NextResponse.json(
      { error: 'Failed to generate content' },
      { status: 500 }
    );
  }
}
```

---

## Configuration

### Generation Config

```typescript
const generationConfig = {
  temperature: 0.9,       // Creativity (0-2)
  topK: 40,              // Token selection diversity
  topP: 0.95,            // Nucleus sampling threshold
  maxOutputTokens: 2048, // Max response length
  stopSequences: ['END'], // Stop generation at these strings
};

const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: 'Write a poem' }] }],
  generationConfig,
});
```

### Model Config Comparison

```typescript
// Creative writing
const creativeConfig = {
  temperature: 1.2,
  topK: 50,
  topP: 0.95,
  maxOutputTokens: 4096,
};

// Factual/analytical
const factualConfig = {
  temperature: 0.2,
  topK: 10,
  topP: 0.8,
  maxOutputTokens: 1024,
};

// Code generation
const codeConfig = {
  temperature: 0.4,
  topK: 20,
  topP: 0.9,
  maxOutputTokens: 2048,
};
```

---

## TypeScript Types

### Import Common Types

```typescript
import type {
  GenerateContentResult,
  GenerateContentResponse,
  Content,
  Part,
  FunctionCall,
  FunctionResponse,
  SafetySetting,
  HarmCategory,
  HarmBlockThreshold,
  UsageMetadata,
} from '@google/generative-ai';
```

### Type-Safe Message Structure

```typescript
interface ChatMessage {
  role: 'user' | 'model';
  parts: Part[];
}

interface Part {
  text?: string;
  inlineData?: {
    data: string;
    mimeType: string;
  };
  functionCall?: FunctionCall;
  functionResponse?: FunctionResponse;
}
```

### Type-Safe Function Declaration

```typescript
interface FunctionDeclaration {
  name: string;
  description: string;
  parameters: {
    type: 'object';
    properties: Record<string, {
      type: string;
      description?: string;
      enum?: string[];
    }>;
    required?: string[];
  };
}

const weatherFunction: FunctionDeclaration = {
  name: 'get_weather',
  description: 'Get current weather',
  parameters: {
    type: 'object',
    properties: {
      location: {
        type: 'string',
        description: 'City and state',
      },
    },
    required: ['location'],
  },
};
```

---

## AI Pair Programming Notes

### When to Use This Reference

- **Quick implementation**: Copy-paste patterns for common tasks
- **Debugging**: Check syntax and parameter usage
- **Configuration**: Find optimal settings for your use case
- **Integration**: See framework-specific examples

### Recommended Context Bundle

**For quick tasks:**
- This file (QUICK-REFERENCE.md)

**For learning:**
- This file + README.md + 01-FUNDAMENTALS.md

**For complex features:**
- This file + relevant numbered file + FRAMEWORK-INTEGRATION-PATTERNS.md

### Common Gotchas

1. **Model names**: Use `-latest` suffix for automatic updates
2. **Token limits**: Flash = 1M, Pro = 2M tokens
3. **Safety filters**: Enabled by default, adjust if needed
4. **Function calling**: Only works with Pro models
5. **Streaming**: Use `generateContentStream` not `generateContent`
6. **Error handling**: Always catch `GoogleGenerativeAIError`

---

**Questions?** Check [README.md](README.md) or [FRAMEWORK-INTEGRATION-PATTERNS.md](FRAMEWORK-INTEGRATION-PATTERNS.md)
