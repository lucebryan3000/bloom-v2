---
id: google-gemini-nodejs-02-messages-api
topic: google-gemini-nodejs
file_role: core
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: [google-gemini-fundamentals]
related_topics: [google-gemini, ai-ml, chat-interfaces]
embedding_keywords: [google-gemini, messages-api, text-generation, conversations, chat]
last_reviewed: 2025-11-13
---

# Gemini Messages API - Text Generation & Conversations

**Purpose**: Master text generation and conversational AI patterns with Gemini. Learn single-turn generation, multi-turn chat, system instructions, and conversation management.

---

## 1. Single-Turn Generation

### Basic Text Generation

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

const result = await model.generateContent('Explain quantum computing');
const text = result.response.text();
console.log(text);
```

**Use Cases**:
- One-off content generation
- Batch processing
- Data extraction
- Independent queries

---

## 2. Multi-Turn Conversations

### Starting a Chat

```typescript
const chat = model.startChat({
  history: [],
  generationConfig: {
    temperature: 0.7,
    maxOutputTokens: 1024,
  },
});

// Turn 1
const msg1 = await chat.sendMessage('What is ROI?');
console.log(msg1.response.text());

// Turn 2 - model remembers context
const msg2 = await chat.sendMessage('How do I calculate it?');
console.log(msg2.response.text());

// Turn 3
const msg3 = await chat.sendMessage('Give me an example');
console.log(msg3.response.text());
```

**Context Management**: Chat sessions maintain full conversation history automatically.

---

## 3. System Instructions (Gemini 1.5+)

### Basic System Instruction

```typescript
const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-pro-latest',
  systemInstruction: 'You are a helpful ROI analyst. Always provide data-driven insights with specific numbers.',
});

const result = await model.generateContent('Calculate ROI for a $10k investment with $15k return');
```

### Complex System Instruction

```typescript
const systemInstruction = `You are Melissa, an AI facilitator for ROI discovery workshops.

Your responsibilities:
1. Ask targeted questions about business processes
2. Identify improvement opportunities
3. Guide users to quantify potential ROI
4. Keep sessions under 15 minutes

Guidelines:
- Be concise and professional
- Ask one question at a time
- Validate inputs before proceeding
- Provide confidence scores (0-100)

Output Format:
- Use JSON for structured data
- Use plain text for explanations
- Include reasoning for recommendations`;

const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-pro-latest',
  systemInstruction,
});
```

---

## 4. Generation Configuration

### Temperature Control

```typescript
// Deterministic (factual)
const factualModel = genAI.getGenerativeModel({
  model: 'gemini-1.5-flash-latest',
  generationConfig: {
    temperature: 0.2,
    topK: 10,
    topP: 0.8,
  },
});

// Creative
const creativeModel = genAI.getGenerativeModel({
  model: 'gemini-1.5-flash-latest',
  generationConfig: {
    temperature: 1.2,
    topK: 50,
    topP: 0.95,
  },
});
```

### Output Length Control

```typescript
const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: 'Write a summary' }] }],
  generationConfig: {
    maxOutputTokens: 500, // Limit response length
    stopSequences: ['END', '---'], // Stop at these strings
  },
});
```

---

## 5. Conversation History Management

### Loading Existing History

```typescript
const previousHistory = [
  { role: 'user', parts: [{ text: 'What is AI?' }] },
  { role: 'model', parts: [{ text: 'AI is artificial intelligence...' }] },
  { role: 'user', parts: [{ text: 'How does it work?' }] },
  { role: 'model', parts: [{ text: 'AI works by...' }] },
];

const chat = model.startChat({
  history: previousHistory,
});

// Continue from where we left off
const result = await chat.sendMessage('Can you give examples?');
```

### Retrieving History

```typescript
const chat = model.startChat();

await chat.sendMessage('Hello');
await chat.sendMessage('Tell me about AI');

// Get full conversation history
const history = await chat.getHistory();
console.log('Total messages:', history.length);

history.forEach((msg, idx) => {
  console.log(`${msg.role}: ${msg.parts[0].text}`);
});
```

---

## 6. Token Counting

### Count Tokens Before Generation

```typescript
const prompt = 'Write a very long essay about quantum physics...';

// Count tokens in prompt
const countResult = await model.countTokens(prompt);
console.log('Prompt tokens:', countResult.totalTokens);

// Check if it fits in context window
if (countResult.totalTokens > 900000) {
  console.log('Prompt too long for Flash (1M token limit)');
  // Chunk or truncate
}
```

### Count Tokens in Conversation

```typescript
const chat = model.startChat();

await chat.sendMessage('Hello');
await chat.sendMessage('Tell me a story');

const history = await chat.getHistory();
const conversationText = history
  .map((msg) => msg.parts[0].text)
  .join('\n');

const countResult = await model.countTokens(conversationText);
console.log('Conversation tokens:', countResult.totalTokens);
```

---

## 7. Response Handling

### Extract Text

```typescript
const result = await model.generateContent('Hello');
const text = result.response.text();
```

### Access Raw Response

```typescript
const result = await model.generateContent('Hello');
const response = result.response;

console.log('Candidates:', response.candidates);
console.log('Usage:', response.usageMetadata);
console.log('Safety ratings:', response.candidates?.[0]?.safetyRatings);
console.log('Finish reason:', response.candidates?.[0]?.finishReason);
```

### Handle Multiple Candidates

```typescript
const result = await model.generateContent({
  contents: [{ role: 'user', parts: [{ text: 'Write a haiku' }] }],
  generationConfig: {
    candidateCount: 3, // Generate 3 variations
  },
});

const candidates = result.response.candidates;
candidates?.forEach((candidate, idx) => {
  console.log(`Candidate ${idx + 1}:`, candidate.content.parts[0].text);
});
```

---

## 8. Common Patterns

### Pattern: Q&A System

```typescript
async function askQuestion(question: string): Promise<string> {
  const model = genAI.getGenerativeModel({
    model: 'gemini-1.5-flash-latest',
    systemInstruction: 'You are a helpful assistant. Provide concise, accurate answers.',
  });

  const result = await model.generateContent(question);
  return result.response.text();
}

const answer = await askQuestion('What is the capital of France?');
```

### Pattern: Conversational Agent

```typescript
class ConversationalAgent {
  private chat: any;

  constructor(systemInstruction: string) {
    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
      systemInstruction,
    });
    this.chat = model.startChat();
  }

  async sendMessage(message: string): Promise<string> {
    const result = await this.chat.sendMessage(message);
    return result.response.text();
  }

  async getHistory() {
    return this.chat.getHistory();
  }
}

const agent = new ConversationalAgent('You are a coding tutor.');
await agent.sendMessage('How do I learn TypeScript?');
```

### Pattern: Batch Processing

```typescript
async function processQuestions(questions: string[]): Promise<string[]> {
  const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

  const results = await Promise.all(
    questions.map(async (q) => {
      const result = await model.generateContent(q);
      return result.response.text();
    })
  );

  return results;
}

const questions = [
  'What is AI?',
  'What is ML?',
  'What is NLP?',
];

const answers = await processQuestions(questions);
```

---

## 9. Best Practices

### ✅ DO

- **Use system instructions** for consistent behavior
- **Validate inputs** before sending to API
- **Track token usage** to monitor costs
- **Implement retry logic** for transient failures
- **Handle safety blocks** gracefully
- **Use Flash for most tasks** (cheaper, faster)
- **Cache system instructions** (Vertex AI feature)

### ❌ DON'T

- **Don't send PII** without user consent
- **Don't ignore rate limits** - implement backoff
- **Don't exceed context windows** without checking
- **Don't use Pro when Flash suffices** (17x more expensive)
- **Don't hardcode sensitive instructions** in system prompts
- **Don't send entire conversation history** if not needed

---

## 10. AI Pair Programming Notes

### When to Load This File

- Building chat interfaces
- Implementing conversational AI
- Working with text generation
- Managing conversation state

### Recommended Context Bundle

- This file (02-MESSAGES-API.md)
- QUICK-REFERENCE.md (syntax)
- FRAMEWORK-INTEGRATION-PATTERNS.md (implementation)

### Key Takeaways

1. Use `startChat()` for multi-turn conversations
2. System instructions provide consistent behavior
3. Token counting prevents context overflow
4. History management enables conversation persistence
5. Generation config controls output style

---

**Next**: [03-MULTIMODAL.md](03-MULTIMODAL.md) for image, audio, and video processing.
