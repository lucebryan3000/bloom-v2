---
id: google-gemini-nodejs-01-fundamentals
topic: google-gemini-nodejs
file_role: fundamentals
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [javascript-basics, api-basics]
related_topics: [google-gemini, ai-ml, anthropic-sdk-typescript]
embedding_keywords: [google-gemini, fundamentals, basics, models, capabilities, getting-started]
last_reviewed: 2025-11-13
---

# Google Gemini Fundamentals

**Purpose**: Understand core Gemini concepts, models, capabilities, and when to use each feature. This is the foundation for all Gemini API integration.

---

## 1. What is Google Gemini?

### Overview

Google Gemini is Google's most capable multimodal AI model family, designed to understand and generate content across multiple modalities (text, images, audio, video). It's the successor to PaLM 2 and represents Google's latest advancement in generative AI.

**Key Differentiators**:
- **Native Multimodal**: Trained from the ground up on multimodal data (not separate models fused together)
- **Massive Context Window**: Up to 2 million tokens (Gemini 1.5 Pro)
- **Grounding**: Can connect to Google Search and custom data sources
- **Function Calling**: Built-in tool use capabilities
- **Production Ready**: Deployed at Google scale with enterprise SLAs

---

## 2. Model Family

### Gemini 1.5 Models (Current Generation)

#### gemini-1.5-pro-latest

**Best For**: Complex reasoning, long context tasks, multimodal analysis

```typescript
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });
```

**Capabilities**:
- Context Window: 2 million tokens (equivalent to ~1,400 pages or 2 hours of video)
- Multimodal: Text, image, audio, video, PDF
- Function Calling: Yes
- Grounding: Yes
- Streaming: Yes

**Use Cases**:
- Analyzing entire codebases
- Processing long documents or videos
- Complex reasoning tasks
- Multimodal content analysis
- Research and summarization

**Pricing** (as of Nov 2025):
- Input: $1.25 per 1M tokens
- Output: $5.00 per 1M tokens

---

#### gemini-1.5-flash-latest

**Best For**: Fast responses, high throughput, cost efficiency

```typescript
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
```

**Capabilities**:
- Context Window: 1 million tokens
- Multimodal: Text, image, audio, video, PDF
- Function Calling: Yes (Pro models only)
- Grounding: Yes
- Streaming: Yes
- Speed: 2-5x faster than Pro

**Use Cases**:
- Chat applications
- Simple content generation
- High-volume inference
- Real-time applications
- Cost-sensitive workloads

**Pricing** (as of Nov 2025):
- Input: $0.075 per 1M tokens (17x cheaper than Pro)
- Output: $0.30 per 1M tokens (17x cheaper than Pro)

---

#### text-embedding-004

**Best For**: Semantic search, RAG, similarity tasks

```typescript
const model = genAI.getGenerativeModel({ model: 'text-embedding-004' });
```

**Capabilities**:
- Embedding Dimensions: 768
- Max Input Tokens: 2,048
- Output: Dense vector representation
- Use Case: Semantic search, clustering, classification

**Pricing** (as of Nov 2025):
- $0.00001 per 1K tokens (extremely cheap)

---

### Model Selection Guide

| Task | Recommended Model | Why |
|------|------------------|-----|
| **Chat** | gemini-1.5-flash | Fast, cheap, good quality |
| **Long documents** | gemini-1.5-pro | 2M token window |
| **Video analysis** | gemini-1.5-pro | Better multimodal understanding |
| **Function calling** | gemini-1.5-pro | Only Pro supports it currently |
| **High throughput** | gemini-1.5-flash | 2-5x faster |
| **Cost optimization** | gemini-1.5-flash | 17x cheaper |
| **Semantic search** | text-embedding-004 | Purpose-built |

**Golden Rule**: Start with Flash. Only use Pro if you need:
1. Context window > 1M tokens
2. Function calling
3. Maximum reasoning capability
4. Video/complex multimodal analysis

---

## 3. Core Capabilities

### 3.1 Multimodal Understanding

Gemini can process multiple modalities in a single request:

```typescript
const result = await model.generateContent([
  'Analyze this chart and describe the trends:',
  {
    inlineData: {
      data: base64Image,
      mimeType: 'image/png',
    },
  },
]);
```

**Supported Formats**:
- **Text**: UTF-8 text, Markdown, code
- **Images**: JPEG, PNG, WebP, HEIC, HEIF
- **Audio**: WAV, MP3, AIFF, AAC, OGG, FLAC
- **Video**: MP4, MPEG, MOV, AVI, FLV, MPG, WebM, WMV, 3GPP
- **Documents**: PDF (text extraction + image analysis)

**Key Insight**: Unlike other models that have separate vision/audio models, Gemini processes all modalities in a unified way, enabling better cross-modal reasoning.

---

### 3.2 Long Context Windows

Gemini 1.5 models have unprecedented context windows:

| Model | Context Window | Equivalent To |
|-------|---------------|---------------|
| gemini-1.5-pro | 2M tokens | ~1,400 pages, 2 hours video |
| gemini-1.5-flash | 1M tokens | ~700 pages, 1 hour video |

**What This Enables**:
- Process entire codebases in one request
- Analyze full-length movies
- Read entire books and provide summaries
- Work with massive datasets without chunking

**Example** - Analyze Entire Codebase:

```typescript
const codebase = await loadEntireCodebase(); // ~500K tokens

const result = await model.generateContent(`
Analyze this codebase and identify:
1. Main architecture patterns
2. Potential security vulnerabilities
3. Performance bottlenecks
4. Suggested refactoring opportunities

Codebase:
${codebase}
`);
```

---

### 3.3 Function Calling

Gemini can call external APIs and tools (Pro models only):

```typescript
const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather',
    parameters: {
      type: 'object',
      properties: {
        location: { type: 'string' },
      },
    },
  },
];

const chat = model.startChat({
  tools: [{ functionDeclarations: functions }],
});

const result = await chat.sendMessage('What is the weather in Boston?');

// Gemini returns function call request
const functionCall = result.response.functionCalls()?.[0];
// { name: 'get_weather', args: { location: 'Boston, MA' } }

// Execute function
const weatherData = await getWeather(functionCall.args.location);

// Send result back to Gemini
const finalResult = await chat.sendMessage([{
  functionResponse: {
    name: 'get_weather',
    response: weatherData,
  },
}]);

// Gemini generates natural language response
console.log(finalResult.response.text());
// "The weather in Boston is currently 72°F and sunny."
```

**When to Use**:
- Integrate with external APIs (weather, stocks, databases)
- Build agents that can take actions
- Create tools that combine AI with real-time data
- Implement RAG systems

---

### 3.4 Grounding with Google Search

Connect Gemini to Google Search for fact-based responses:

```typescript
// Vertex AI only (not available in Google AI yet)
const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-pro',
  tools: [{
    googleSearchRetrieval: {
      dynamicRetrievalConfig: {
        mode: 'MODE_DYNAMIC',
        dynamicThreshold: 0.7,
      },
    },
  }],
});

const result = await model.generateContent(
  'What are the latest developments in quantum computing in 2025?'
);
```

**Benefits**:
- Up-to-date information (not limited to training cutoff)
- Fact-checking and citation
- Reduced hallucinations
- Access to current events

**Note**: Grounding is currently Vertex AI only (Google Cloud). Not available in Google AI direct API yet.

---

### 3.5 Streaming Responses

Generate responses token-by-token for better UX:

```typescript
const result = await model.generateContentStream('Write a long story');

for await (const chunk of result.stream) {
  process.stdout.write(chunk.text());
}

// Get final metadata
const finalResponse = await result.response;
console.log('Usage:', finalResponse.usageMetadata);
```

**Benefits**:
- Perceived latency reduction (users see output immediately)
- Better UX for long-form content
- Ability to cancel long-running requests
- Real-time feedback

---

## 4. API Access Methods

### 4.1 Google AI (Direct API)

**Best For**: Rapid prototyping, personal projects, simple deployments

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
```

**Pros**:
- Simple setup (just API key)
- No cloud account needed
- Free tier available
- Fast onboarding

**Cons**:
- Lower rate limits
- No enterprise SLAs
- Fewer features (no grounding yet)
- Less control over deployment

**Pricing**: Pay-per-token (see model pricing above)

---

### 4.2 Vertex AI (Google Cloud)

**Best For**: Enterprise deployments, production apps, high volume

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: 'your-project-id',
  location: 'us-central1',
});

const model = vertexAI.getGenerativeModel({ model: 'gemini-1.5-pro' });
```

**Pros**:
- Enterprise SLAs
- Higher rate limits
- Grounding with Google Search
- Data residency controls
- Integration with Google Cloud services
- Caching support (coming soon)

**Cons**:
- Requires Google Cloud account
- More complex setup
- Higher minimum spend

**Pricing**: Same per-token pricing + potential Google Cloud fees

---

### When to Use Which?

| Criterion | Google AI | Vertex AI |
|-----------|-----------|-----------|
| **Getting started** | ✅ Easy | ❌ Complex |
| **Production scale** | ❌ Limited | ✅ Enterprise |
| **Rate limits** | ❌ Low | ✅ High |
| **Grounding** | ❌ No | ✅ Yes |
| **SLAs** | ❌ No | ✅ Yes |
| **Data residency** | ❌ No control | ✅ Full control |

**Recommendation**: Start with Google AI for prototyping. Migrate to Vertex AI when you need:
- Production scale (>100K requests/day)
- Enterprise SLAs
- Grounding with Google Search
- Compliance requirements (HIPAA, GDPR, etc.)

---

## 5. Authentication

### Google AI Authentication

```bash
# Get API key from: https://aistudio.google.com/app/apikey
export GOOGLE_AI_API_KEY="AIzaSy...your-key"
```

```typescript
const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
```

**Security**:
- Never hardcode API keys
- Never expose keys in client-side code
- Use environment variables
- Rotate keys regularly
- Use key restrictions (HTTP referrers, IP addresses)

---

### Vertex AI Authentication

```bash
# 1. Install gcloud CLI
# 2. Authenticate
gcloud auth application-default login

# 3. Set project
gcloud config set project YOUR_PROJECT_ID

# 4. Set service account key path
export GOOGLE_APPLICATION_CREDENTIALS="/path/to/service-account-key.json"
```

```typescript
const vertexAI = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT,
  location: 'us-central1', // or your preferred region
});
```

**Best Practices**:
- Use service accounts for production
- Grant minimum required permissions (Vertex AI User role)
- Enable Workload Identity for GKE
- Use Secret Manager for credentials
- Audit access logs regularly

---

## 6. Mental Models

### 6.1 Conversations vs One-Shot Generation

**One-Shot** (stateless):

```typescript
const result = await model.generateContent('What is AI?');
```

**Chat** (stateful):

```typescript
const chat = model.startChat();
await chat.sendMessage('What is AI?');
await chat.sendMessage('How does it work?'); // Remembers context
```

**When to Use**:
- **One-Shot**: Independent tasks, batch processing, data extraction
- **Chat**: Conversational UIs, multi-turn reasoning, context-dependent tasks

---

### 6.2 Temperature and Creativity

Temperature controls randomness (0.0 to 2.0):

```typescript
// Deterministic (factual, consistent)
generationConfig: { temperature: 0.2 }

// Balanced (default)
generationConfig: { temperature: 0.7 }

// Creative (varied, unexpected)
generationConfig: { temperature: 1.2 }
```

**Use Cases by Temperature**:
- **0.0 - 0.3**: Code generation, data extraction, factual Q&A
- **0.4 - 0.7**: General chat, summaries, explanations
- **0.8 - 1.2**: Creative writing, brainstorming, storytelling
- **1.3 - 2.0**: Maximum creativity (may be incoherent)

---

### 6.3 Tokens and Context

**What is a token?**
- Approximate: 1 token ≈ 4 characters ≈ 0.75 words
- Varies by language (English is efficient, Asian languages less so)
- Code tokens are similar to text tokens

**Context Window**:
- Input + Output must fit within context window
- Example: 1M context = 900K input + 100K output

**Cost Optimization**:
- Use Flash instead of Pro (17x cheaper)
- Limit `maxOutputTokens` to prevent runaway costs
- Cache system prompts (Vertex AI feature, coming to Google AI)
- Only send relevant context, not entire conversation history

---

## 7. Common Pitfalls

### Pitfall 1: Using Pro When Flash Suffices

**Problem**: Pro costs 17x more than Flash

```typescript
// ❌ Expensive
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });

// ✅ Cheaper for most tasks
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });
```

**Solution**: Use Flash by default. Only use Pro for:
- Context > 1M tokens
- Function calling (Pro only currently)
- Maximum reasoning quality needed

---

### Pitfall 2: Ignoring Safety Filters

**Problem**: Responses blocked without handling

```typescript
const result = await model.generateContent('Sensitive topic');

if (result.response.candidates?.[0]?.finishReason === 'SAFETY') {
  console.log('Response blocked by safety filters');
  // Handle gracefully
}
```

**Solution**: Always check `finishReason` and handle `SAFETY` blocks

---

### Pitfall 3: Not Handling Rate Limits

**Problem**: 429 errors crash the app

```typescript
try {
  const result = await model.generateContent(prompt);
} catch (error) {
  if (error.message.includes('RESOURCE_EXHAUSTED')) {
    // Retry with exponential backoff
    await sleep(1000 * Math.pow(2, attempt));
    // Retry logic
  }
}
```

**Solution**: Implement exponential backoff retry logic

---

### Pitfall 4: Exceeding Context Windows

**Problem**: Request fails silently or truncates

```typescript
// ❌ No token counting
const hugePrompt = loadEntireDatabase(); // 5M tokens
await model.generateContent(hugePrompt); // Fails

// ✅ Check token count first
import { countTokens } from '@google/generative-ai';
const count = await model.countTokens(hugePrompt);
if (count.totalTokens > 1000000) {
  // Chunk the input
}
```

**Solution**: Use `countTokens()` API before generation

---

## 8. AI Pair Programming Notes

### When to Load This File

Load this file when:
- First-time Gemini integration
- Choosing between models
- Understanding capabilities and limits
- Troubleshooting fundamental issues
- Learning Gemini architecture

### Recommended Context Bundle

**For beginners:**
- This file (01-FUNDAMENTALS.md)
- README.md
- QUICK-REFERENCE.md

**For implementation:**
- This file
- 02-MESSAGES-API.md (for chat)
- FRAMEWORK-INTEGRATION-PATTERNS.md

**For optimization:**
- This file
- 10-PERFORMANCE.md
- QUICK-REFERENCE.md

### Key Takeaways for AI

1. **Default to Flash**: Use gemini-1.5-flash-latest unless you have a specific reason for Pro
2. **Multimodal First**: Gemini is natively multimodal - use it for images/audio/video
3. **Long Context**: Don't chunk unless necessary - Gemini handles massive contexts
4. **Error Handling**: Always implement retry logic for rate limits
5. **Safety Filters**: Check `finishReason` for safety blocks
6. **Cost Awareness**: Flash is 17x cheaper than Pro

---

**Next Steps**: Read [02-MESSAGES-API.md](02-MESSAGES-API.md) for text generation patterns, or [QUICK-REFERENCE.md](QUICK-REFERENCE.md) for quick syntax lookups.
