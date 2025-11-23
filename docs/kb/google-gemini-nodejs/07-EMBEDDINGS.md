---
id: google-gemini-nodejs-07-embeddings
topic: google-gemini-nodejs
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [google-gemini-fundamentals]
related_topics: [google-gemini, embeddings, semantic-search, rag, vector-search]
embedding_keywords: [google-gemini, embeddings, semantic-search, rag, vector-database, similarity]
last_reviewed: 2025-11-13
---

# Gemini Text Embeddings

**Purpose**: Build semantic search, RAG systems, and similarity matching with Gemini embeddings.

---

## 1. Generate Embeddings

```typescript
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
const model = genAI.getGenerativeModel({ model: 'text-embedding-004' });

const result = await model.embedContent('What is the meaning of life?');
const embedding = result.embedding;

console.log('Embedding vector:', embedding.values);
console.log('Dimensions:', embedding.values.length); // 768
```

---

## 2. Batch Embeddings

```typescript
const texts = [
  'Machine learning is a subset of AI',
  'Deep learning uses neural networks',
  'Natural language processing handles text',
  'Computer vision analyzes images',
];

const embeddings = await Promise.all(
  texts.map(async (text) => {
    const result = await model.embedContent(text);
    return result.embedding.values;
  })
);

console.log('Generated', embeddings.length, 'embeddings');
```

---

## 3. Cosine Similarity

```typescript
function cosineSimilarity(a: number[], b: number[]): number {
  const dotProduct = a.reduce((sum, val, i) => sum + val * b[i], 0);
  const magnitudeA = Math.sqrt(a.reduce((sum, val) => sum + val * val, 0));
  const magnitudeB = Math.sqrt(b.reduce((sum, val) => sum + val * val, 0));
  return dotProduct / (magnitudeA * magnitudeB);
}

const query = await model.embedContent('AI and machine learning');
const doc1 = await model.embedContent('Deep learning is a type of machine learning');
const doc2 = await model.embedContent('Cats are popular pets');

const similarity1 = cosineSimilarity(query.embedding.values, doc1.embedding.values);
const similarity2 = cosineSimilarity(query.embedding.values, doc2.embedding.values);

console.log('Query-Doc1 similarity:', similarity1); // High (~0.8)
console.log('Query-Doc2 similarity:', similarity2); // Low (~0.2)
```

---

## 4. Semantic Search System

```typescript
interface Document {
  id: string;
  content: string;
  embedding: number[];
}

class SemanticSearchEngine {
  private documents: Document[] = [];

  async indexDocument(id: string, content: string) {
    const result = await model.embedContent(content);
    this.documents.push({
      id,
      content,
      embedding: result.embedding.values,
    });
  }

  async search(query: string, topK = 5): Promise<Document[]> {
    const queryResult = await model.embedContent(query);
    const queryEmbedding = queryResult.embedding.values;

    const results = this.documents
      .map((doc) => ({
        ...doc,
        similarity: cosineSimilarity(queryEmbedding, doc.embedding),
      }))
      .sort((a, b) => b.similarity - a.similarity)
      .slice(0, topK);

    return results;
  }
}

// Usage
const searchEngine = new SemanticSearchEngine();
await searchEngine.indexDocument('doc1', 'Machine learning tutorial');
await searchEngine.indexDocument('doc2', 'Cooking recipes');

const results = await searchEngine.search('AI learning', 5);
```

---

## 5. RAG (Retrieval-Augmented Generation)

```typescript
class RAGSystem {
  private searchEngine: SemanticSearchEngine;

  constructor() {
    this.searchEngine = new SemanticSearchEngine();
  }

  async indexDocuments(documents: Array<{ id: string; content: string }>) {
    for (const doc of documents) {
      await this.searchEngine.indexDocument(doc.id, doc.content);
    }
  }

  async answerQuestion(question: string): Promise<string> {
    // 1. Search for relevant documents
    const relevantDocs = await this.searchEngine.search(question, 3);

    // 2. Build context from top results
    const context = relevantDocs
      .map((doc, idx) => `Document ${idx + 1}:\n${doc.content}`)
      .join('\n\n');

    // 3. Generate answer using Gemini with context
    const genModel = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

    const prompt = `Based on the following context, answer the question.

Context:
${context}

Question: ${question}

Answer:`;

    const result = await genModel.generateContent(prompt);
    return result.response.text();
  }
}

// Usage
const rag = new RAGSystem();
await rag.indexDocuments([
  { id: '1', content: 'React is a JavaScript library for building UIs' },
  { id: '2', content: 'Next.js is a React framework' },
  { id: '3', content: 'TypeScript adds types to JavaScript' },
]);

const answer = await rag.answerQuestion('What is React?');
```

---

## 6. Vector Database Integration

### With Pinecone

```typescript
import { Pinecone } from '@pinecone-database/pinecone';

const pinecone = new Pinecone({ apiKey: process.env.PINECONE_API_KEY! });
const index = pinecone.index('your-index');

// Store embedding
const result = await model.embedContent('Document text');
await index.upsert([{
  id: 'doc1',
  values: result.embedding.values,
  metadata: { text: 'Document text' },
}]);

// Query
const queryResult = await model.embedContent('Search query');
const matches = await index.query({
  vector: queryResult.embedding.values,
  topK: 5,
  includeMetadata: true,
});
```

---

## 7. Model Specifications

### text-embedding-004

- **Dimensions**: 768
- **Max Input**: 2,048 tokens
- **Output**: Dense vector (array of floats)
- **Use Case**: General-purpose semantic search
- **Pricing**: $0.00001 per 1K tokens (extremely cheap)

---

## 8. Best Practices

### ✅ DO

- Cache embeddings (don't regenerate for same text)
- Use batch processing for multiple documents
- Store embeddings in vector databases for large datasets
- Normalize vectors before computing similarity

### ❌ DON'T

- Don't regenerate embeddings on every search
- Don't use embeddings for exact keyword matching
- Don't compare raw embedding arrays without similarity function
- Don't exceed 2,048 token input limit

---

## 9. Common Use Cases

### Use Case: Document Search

```typescript
// Index all documents
for (const doc of allDocuments) {
  await searchEngine.indexDocument(doc.id, doc.content);
}

// Search
const results = await searchEngine.search('user query', 10);
```

### Use Case: Content Recommendation

```typescript
// Get embedding for current item
const currentEmbedding = await model.embedContent(currentItem.description);

// Find similar items
const similarItems = items
  .map((item) => ({
    ...item,
    similarity: cosineSimilarity(currentEmbedding, item.embedding),
  }))
  .sort((a, b) => b.similarity - a.similarity)
  .slice(0, 5);
```

### Use Case: Duplicate Detection

```typescript
// Check if document is duplicate
const newDocEmbedding = await model.embedContent(newDoc);

const duplicates = existingDocs.filter((doc) => {
  const similarity = cosineSimilarity(newDocEmbedding, doc.embedding);
  return similarity > 0.95; // High similarity threshold
});
```

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Use text-embedding-004 model for embeddings
2. 768-dimensional vectors
3. Cosine similarity for comparing embeddings
4. Cache embeddings - don't regenerate
5. Use vector databases for production scale

---

**Next**: [08-SAFETY-CONTENT.md](08-SAFETY-CONTENT.md) for content filtering.
