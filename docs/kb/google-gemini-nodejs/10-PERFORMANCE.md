---
id: google-gemini-nodejs-10-performance
topic: google-gemini-nodejs
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [google-gemini-fundamentals]
related_topics: [google-gemini, performance, optimization, cost-optimization]
embedding_keywords: [google-gemini, performance, optimization, cost-optimization, token-management, caching]
last_reviewed: 2025-11-13
---

# Gemini Performance Optimization

**Purpose**: Optimize token usage, latency, and costs for production deployments.

---

## 1. Model Selection

### Flash vs Pro

```typescript
// ✅ Default to Flash (17x cheaper, 2-5x faster)
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

// ❌ Only use Pro when you need:
// - Context > 1M tokens
// - Function calling (Pro only currently)
// - Maximum reasoning quality
const proModel = genAI.getGenerativeModel({ model: 'gemini-1.5-pro-latest' });
```

**Cost Comparison**:
- Flash input: $0.075 / 1M tokens
- Flash output: $0.30 / 1M tokens
- Pro input: $1.25 / 1M tokens (17x more)
- Pro output: $5.00 / 1M tokens (17x more)

---

## 2. Token Optimization

### Limit Output Tokens

```typescript
const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: prompt }] }],
  generationConfig: {
    maxOutputTokens: 500, // Limit response length
  },
});
```

### Count Tokens Before Generation

```typescript
const countResult = await model.countTokens(prompt);
console.log('Prompt tokens:', countResult.totalTokens);

if (countResult.totalTokens > 100000) {
  // Truncate or chunk prompt
  const truncatedPrompt = truncatePrompt(prompt, 100000);
}
```

---

## 3. Context Management

### Conversation Trimming

```typescript
function trimConversation(messages: any[], maxTokens = 50000): any[] {
  // Keep system message and recent messages
  const systemMessages = messages.filter((m) => m.role === 'system');
  const otherMessages = messages.filter((m) => m.role !== 'system');

  // Take last N messages that fit in token budget
  let tokenCount = 0;
  const trimmedMessages = [];

  for (let i = otherMessages.length - 1; i >= 0; i--) {
    const msgTokens = estimateTokens(otherMessages[i].content);
    if (tokenCount + msgTokens > maxTokens) break;

    trimmedMessages.unshift(otherMessages[i]);
    tokenCount += msgTokens;
  }

  return [...systemMessages, ...trimmedMessages];
}

function estimateTokens(text: string): number {
  // Rough estimate: 1 token ≈ 4 characters
  return Math.ceil(text.length / 4);
}
```

---

## 4. Caching Strategies

### Cache Embeddings

```typescript
// ❌ Bad - regenerate embeddings every time
const embedding = await model.embedContent(text);

// ✅ Good - cache embeddings
const embeddingCache = new Map<string, number[]>();

async function getEmbedding(text: string): Promise<number[]> {
  if (embeddingCache.has(text)) {
    return embeddingCache.get(text)!;
  }

  const result = await model.embedContent(text);
  const embedding = result.embedding.values;
  embeddingCache.set(text, embedding);
  return embedding;
}
```

### Cache Responses (with Redis)

```typescript
import { Redis } from '@upstash/redis';

const redis = new Redis({ url: process.env.REDIS_URL, token: process.env.REDIS_TOKEN });

async function cachedGenerate(prompt: string): Promise<string> {
  const cacheKey = `gemini:${hashPrompt(prompt)}`;

  // Check cache
  const cached = await redis.get(cacheKey);
  if (cached) {
    console.log('Cache hit');
    return cached as string;
  }

  // Generate
  const result = await model.generateContent(prompt);
  const text = result.response.text();

  // Cache for 1 hour
  await redis.set(cacheKey, text, { ex: 3600 });

  return text;
}

function hashPrompt(prompt: string): string {
  return require('crypto').createHash('sha256').update(prompt).digest('hex');
}
```

---

## 5. Parallel Processing

### Batch Independent Requests

```typescript
// ❌ Bad - sequential processing
for (const question of questions) {
  const answer = await model.generateContent(question);
  answers.push(answer.response.text());
}

// ✅ Good - parallel processing
const answers = await Promise.all(
  questions.map(async (question) => {
    const result = await model.generateContent(question);
    return result.response.text();
  })
);
```

---

## 6. Streaming for Large Outputs

```typescript
// ✅ Use streaming for responses > 100 tokens
const result = await model.generateContentStream(prompt);

for await (const chunk of result.stream) {
  // Process chunks as they arrive
  process.stdout.write(chunk.text());
}
```

---

## 7. Rate Limit Optimization

### Batch Requests

```typescript
// Group multiple small requests into one
const batchPrompt = questions.map((q, i) => `Question ${i + 1}: ${q}`).join('\n\n');

const result = await model.generateContent(`Answer the following questions:\n\n${batchPrompt}`);

// Parse responses
const answers = result.response.text().split('\n\n');
```

---

## 8. Monitoring & Metrics

### Track Token Usage

```typescript
class TokenTracker {
  private totalInputTokens = 0;
  private totalOutputTokens = 0;

  async generateAndTrack(prompt: string): Promise<string> {
    const result = await model.generateContent(prompt);
    const usage = result.response.usageMetadata;

    if (usage) {
      this.totalInputTokens += usage.promptTokenCount || 0;
      this.totalOutputTokens += usage.candidatesTokenCount || 0;

      console.log('Cumulative usage:', {
        input: this.totalInputTokens,
        output: this.totalOutputTokens,
        cost: this.calculateCost(),
      });
    }

    return result.response.text();
  }

  calculateCost(): number {
    // Flash pricing
    const inputCost = (this.totalInputTokens / 1000000) * 0.075;
    const outputCost = (this.totalOutputTokens / 1000000) * 0.30;
    return inputCost + outputCost;
  }
}
```

---

## 9. Best Practices

### ✅ DO

- Use Flash by default (17x cheaper)
- Limit `maxOutputTokens` to prevent runaway costs
- Cache embeddings and responses
- Process requests in parallel when possible
- Monitor token usage and costs
- Trim conversation history
- Use streaming for long responses

### ❌ DON'T

- Don't use Pro when Flash suffices
- Don't send entire conversation history every time
- Don't regenerate embeddings for same text
- Don't process requests sequentially when parallel is possible
- Don't ignore token counts

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Flash is 17x cheaper than Pro - use it by default
2. Always set `maxOutputTokens` to control costs
3. Cache embeddings - never regenerate
4. Trim conversation history to reduce tokens
5. Monitor token usage for cost optimization

---

**Next**: [11-CONFIG-OPERATIONS.md](11-CONFIG-OPERATIONS.md) for deployment and configuration.
