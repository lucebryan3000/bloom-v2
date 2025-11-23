# KB Fallback Implementation (Tool-Free Search)

**Status**: ✅ Implemented and Tested
**Date**: 2025-11-16
**Phase**: 13 (Melissa RAG)

## Overview

The KB fallback system enables Melissa to search the knowledge base **without tool calling infrastructure**. This is a pragmatic solution that works around the current tool calling issues while still delivering KB-powered responses.

## Architecture

### Components

1. **Pattern Detection** (`lib/melissa/kb-fallback.ts`)
   - Regex-based detection of KB-related questions
   - Patterns: "what is", "how to", "explain", ROI terms, metrics, etc.
   - ~15 detection patterns covering common question types

2. **Direct Search** (`lib/melissa/kb-fallback.ts`)
   - Calls TF-IDF search engine directly (no tool layer)
   - Returns top 3 results by default
   - Uses low confidence threshold (0.01) to ensure results

3. **Context Injection** (`lib/melissa/agent.ts`)
   - KB results formatted as context in system prompt
   - Injected **before** conversation context
   - LLM sees KB articles as reference material

4. **Citation Tracking** (`lib/melissa/types.ts`)
   - KB citations returned in ResponseData
   - Frontend can display sources
   - Includes title, docPath, relevanceScore

## How It Works

### Message Processing Flow

```
User message → Pattern detection → KB search (if match) → Context formatting
                                    ↓
                               Results found
                                    ↓
                          Format as KB context
                                    ↓
                        Prepend to LLM prompt
                                    ↓
                          LLM generates response
                                    ↓
                      Return response + citations
```

### Example

**User asks**: "What is ROI?"

1. **Detection**: Pattern `/what\s+(is|are)\s+/i` matches
2. **Search**: TF-IDF search finds 3 chunks:
   - ROI Basics (7.0% relevance)
   - Probing Techniques (6.7% relevance)
   - Discovery Phase (5.8% relevance)
3. **Context Injection**:
   ```
   [KNOWLEDGE BASE CONTEXT]

   Found 3 relevant knowledge base article(s):

   [KB Article 1]
   Title: ROI Basics - Understanding Return on Investment
   Section: ROI Basics - Understanding Return on Investment > What is ROI?
   Relevance: 7%
   Content:
   ## What is ROI?
   Return on Investment (ROI) is a financial metric...

   [END KNOWLEDGE BASE CONTEXT]

   Use the above knowledge base articles to inform your response.
   Cite sources when using information from the KB.

   [CONVERSATION CONTEXT]
   Session ID: ...
   ```
4. **LLM Response**: Claude generates answer using KB context
5. **Citations Returned**:
   ```json
   {
     "message": "ROI, or Return on Investment...",
     "kbCitations": [
       {
         "title": "ROI Basics - Understanding Return on Investment",
         "docPath": "concepts/roi-basics.md",
         "relevanceScore": 0.0704
       }
     ]
   }
   ```

## Code Structure

### `/lib/melissa/kb-fallback.ts`

```typescript
// Pattern detection
export function isKBQuestion(message: string): boolean

// Direct search (no tools)
export async function searchKBFallback(
  query: string,
  phase?: string,
  limit: number = 3
): Promise<KBSearchResponse | null>

// Context formatting for LLM
export function formatKBContext(results: KBSearchResponse): string

// Extract citations for response
export function extractCitations(results: KBSearchResponse): Citation[]
```

### `/lib/melissa/agent.ts` Integration

```typescript
// In processMessage()
if (isKBQuestion(userMessage)) {
  kbSearchResults = await searchKBFallback(userMessage, this.state.phase, 3);
  kbCitations = extractCitations(kbSearchResults);
}

// In generateAIResponse()
if (kbSearchResults && kbSearchResults.results.length > 0) {
  const kbContext = formatKBContext(kbSearchResults);
  context = kbContext + context; // Prepend to prompt
}

// In return statement
return {
  message: aiResponse,
  kbCitations: kbCitations.length > 0 ? kbCitations : undefined,
  // ... other fields
}
```

## Testing

### Unit Tests (`scripts/test-kb-unit.ts`)

**All 14 tests passing:**

1. ✅ Pattern detection - positive cases (5 tests)
2. ✅ Pattern detection - negative cases (4 tests)
3. ✅ Search functionality (3 tests)
4. ✅ Context formatting (1 test)
5. ✅ Citation extraction (1 test)

**Run tests:**
```bash
npx tsx scripts/test-kb-unit.ts
```

### Manual Testing

```bash
# Test pattern detection and search
npx tsx scripts/test-kb-fallback.ts

# Debug search scores
npx tsx scripts/debug-kb-search.ts
```

## Performance

| Metric | Value |
|--------|-------|
| Index size | 20 chunks, 5 documents, 2,768 tokens |
| Search time | < 1ms (TF-IDF in-memory) |
| Results returned | 3 (configurable) |
| Min confidence | 0.01 (accepts most results) |
| Context size | ~1,500-2,500 chars (3 snippets) |

## Detection Patterns

### ROI-specific
- `/roi/i`
- `/return\s+on\s+investment/i`
- `/payback\s+period/i`
- `/npv/i`, `/net\s+present\s+value/i`
- `/irr/i`, `/internal\s+rate\s+of\s+return/i`

### Question patterns
- `/what\s+(is|are)\s+/i`
- `/how\s+(do|to|does)\s+/i`
- `/explain\s+/i`
- `/define\s+/i`
- `/tell\s+me\s+about\s+/i`

### Metrics patterns
- `/calculate\s+/i`
- `/metric/i`
- `/formula/i`
- `/measure/i`

### Workshop patterns
- `/workshop/i`
- `/process/i`
- `/automation/i`
- `/efficiency/i`

## Advantages vs. Tool Calling

| Feature | Tool Calling | KB Fallback |
|---------|-------------|-------------|
| Works today | ❌ Broken | ✅ Working |
| Implementation | Complex | Simple |
| Latency | 2 LLM calls | 1 LLM call |
| Debugging | Hard | Easy |
| Control | LLM decides | Pattern-based |
| Citations | Via tool results | Direct return |

## Future Enhancements

1. **Hybrid approach**: Use fallback when tools fail
2. **Smarter patterns**: ML-based question classification
3. **Phase-aware boosting**: Stronger phase alignment scoring
4. **User feedback**: Track which KB articles are most helpful
5. **Caching**: Cache frequent queries (e.g., "What is ROI?")

## Migration Path

When tool calling is fixed:

1. Keep fallback as backup
2. Add feature flag: `USE_KB_TOOL_CALLING`
3. Implement tool-based search as primary
4. Fallback triggers on tool errors
5. Compare performance and accuracy
6. Choose best approach or use hybrid

## Known Limitations

1. **Pattern-based detection**: May miss non-obvious KB questions
2. **No query refinement**: Can't ask follow-up questions
3. **Fixed limit**: Always returns 3 results (configurable but static)
4. **No semantic search**: TF-IDF only (no embeddings)
5. **No multi-turn context**: Each query is independent

## Monitoring

**Logs to watch:**
```
[MelissaAgent] KB question detected, searching knowledge base...
[KB Fallback] Search engine initialized: 20 chunks indexed
[KB Fallback] Search completed: "query" → N results in Xms
[MelissaAgent] Found N KB results
```

**Metrics to track:**
- KB question detection rate
- Search result count distribution
- Citation usage in responses
- User satisfaction with KB-powered answers

## Configuration

**Environment variables:**
- None required (uses existing KB index)

**Default settings:**
```typescript
const DEFAULT_LIMIT = 3;           // Results per search
const MIN_CONFIDENCE = 0.01;       // Accept low scores
const DETECTION_PATTERNS = 15;     // Regex patterns
```

## Files Changed

| File | Changes |
|------|---------|
| `lib/melissa/kb-fallback.ts` | ✅ Created (150 lines) |
| `lib/melissa/agent.ts` | ✅ Modified (KB detection + injection) |
| `lib/melissa/types.ts` | ✅ Modified (added kbCitations field) |
| `scripts/test-kb-unit.ts` | ✅ Created (unit tests) |
| `scripts/test-kb-fallback.ts` | ✅ Created (integration tests) |
| `scripts/debug-kb-search.ts` | ✅ Created (debug utility) |

## Conclusion

The KB fallback implementation provides **working KB search today** without waiting for tool calling to be fixed. It's simple, fast, tested, and ready for production use.

**Next step**: Integrate with frontend to display KB citations in chat UI.
