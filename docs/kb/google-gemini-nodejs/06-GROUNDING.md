---
id: google-gemini-nodejs-06-grounding
topic: google-gemini-nodejs
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [google-gemini-fundamentals]
related_topics: [google-gemini, grounding, google-search, rag]
embedding_keywords: [google-gemini, grounding, google-search, real-time-data, fact-checking]
last_reviewed: 2025-11-13
---

# Gemini Grounding with Google Search

**Purpose**: Connect Gemini to Google Search for up-to-date, fact-based responses.

---

## 1. What is Grounding?

Grounding connects Gemini to external data sources to:
- Get current, up-to-date information
- Reduce hallucinations
- Provide citations and sources
- Access real-time data

**Note**: Grounding is currently **Vertex AI only** (Google Cloud). Not available in Google AI direct API yet.

---

## 2. Google Search Grounding

```typescript
import { VertexAI } from '@google-cloud/vertexai';

const vertexAI = new VertexAI({
  project: 'your-project-id',
  location: 'us-central1',
});

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

console.log(result.response.text());
```

---

## 3. Dynamic Retrieval Modes

### MODE_DYNAMIC

Gemini decides when to use Google Search based on the query:

```typescript
dynamicRetrievalConfig: {
  mode: 'MODE_DYNAMIC',
  dynamicThreshold: 0.7, // 0.0 to 1.0 (higher = less likely to search)
}
```

**Best For**: General queries where some need search and others don't

---

### MODE_UNSPECIFIED

Always use Google Search:

```typescript
dynamicRetrievalConfig: {
  mode: 'MODE_UNSPECIFIED',
}
```

**Best For**: News, current events, real-time data queries

---

## 4. Grounding Metadata

```typescript
const result = await model.generateContent('Latest AI news');

const response = result.response;
const groundingMetadata = response.candidates?.[0]?.groundingMetadata;

if (groundingMetadata) {
  console.log('Search queries:', groundingMetadata.searchEntryPoint?.renderedContent);
  console.log('Grounding chunks:', groundingMetadata.groundingChunks);
  console.log('Grounding supports:', groundingMetadata.groundingSupports);
}
```

---

## 5. Custom Data Grounding (Vertex AI Search)

For enterprise data:

```typescript
const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-pro',
  tools: [{
    retrieval: {
      vertexAiSearch: {
        datastore: 'projects/your-project/locations/global/collections/default_collection/dataStores/your-datastore',
      },
    },
  }],
});

const result = await model.generateContent('Query against your custom data');
```

---

## 6. Use Cases

### Use Case: News Chatbot

```typescript
const model = vertexAI.getGenerativeModel({
  model: 'gemini-1.5-flash',
  tools: [{ googleSearchRetrieval: {} }],
  systemInstruction: 'You are a news assistant. Always provide sources and dates.',
});

const result = await model.generateContent('What happened in tech news today?');
```

### Use Case: Fact-Checking Assistant

```typescript
const result = await model.generateContent(
  'Is it true that AI can now write code as well as humans? Provide sources.'
);
```

---

## 7. Best Practices

### ✅ DO

- Use for current events and time-sensitive queries
- Verify citations in production
- Set appropriate dynamic thresholds
- Combine with system instructions for context

### ❌ DON'T

- Don't rely solely on grounding for critical facts
- Don't expect perfect citation accuracy
- Don't use for queries that don't need real-time data
- Don't forget Vertex AI setup requirements

---

## 8. Limitations

- Vertex AI only (not Google AI)
- Requires Google Cloud project
- Additional latency for search
- May increase costs
- Search quality depends on Google Search quality

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Grounding is Vertex AI only (not in Google AI yet)
2. Use MODE_DYNAMIC for automatic search decisions
3. Always check groundingMetadata for sources
4. Great for news, research, fact-checking
5. Requires Google Cloud setup

---

**Next**: [07-EMBEDDINGS.md](07-EMBEDDINGS.md) for semantic search and RAG.
