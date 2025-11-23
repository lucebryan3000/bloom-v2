# KB Fallback Quick Start

**What**: Melissa searches knowledge base without tool calling
**Status**: ✅ Working
**Test**: `npx tsx scripts/test-kb-unit.ts`

## Try It Now

```bash
# 1. Run unit tests (14 tests should pass)
npx tsx scripts/test-kb-unit.ts

# 2. Test search functionality
npx tsx scripts/test-kb-fallback.ts

# 3. Debug search scores
npx tsx scripts/debug-kb-search.ts
```

## How It Works

**User asks**: "What is ROI?"

1. **Pattern detected**: `/what\s+(is|are)\s+/i` matches
2. **KB searched**: TF-IDF finds 3 articles
3. **Context added**: Articles prepended to LLM prompt
4. **Response returned**: With KB citations

## Code Example

```typescript
import { isKBQuestion, searchKBFallback } from '@/lib/melissa/kb-fallback';

// Check if message is KB-related
if (isKBQuestion('What is ROI?')) {
  // Search KB
  const results = await searchKBFallback('What is ROI?', 'discovery', 3);

  // Use results
  console.log(`Found ${results.results.length} articles`);
}
```

## API Response

```json
{
  "message": "ROI, or Return on Investment...",
  "phase": "discovery",
  "kbCitations": [
    {
      "title": "ROI Basics - Understanding Return on Investment",
      "docPath": "concepts/roi-basics.md",
      "relevanceScore": 0.0704
    }
  ]
}
```

## Detection Patterns

- `what is`, `what are`
- `how to`, `how do`, `how does`
- `explain`, `define`, `tell me about`
- `roi`, `payback period`, `npv`, `irr`
- `calculate`, `metric`, `formula`, `measure`
- `workshop`, `process`, `automation`, `efficiency`

## Files

| File | Purpose |
|------|---------|
| `lib/melissa/kb-fallback.ts` | Core logic |
| `lib/melissa/agent.ts` | Integration |
| `lib/melissa/types.ts` | Type definitions |
| `scripts/test-kb-unit.ts` | Tests |

## Performance

- Search: < 1ms
- Index: 20 chunks, 5 docs
- Results: 3 per query
- Context: ~2KB

## Testing

```bash
# Unit tests (recommended)
npx tsx scripts/test-kb-unit.ts

# Integration test
npx tsx scripts/test-kb-fallback.ts

# Debug search
npx tsx scripts/debug-kb-search.ts
```

## Troubleshooting

**No results?**
- Check minConfidence (default: 0.01)
- Verify KB index exists: `lib/melissa/rag/index.json`
- Rebuild index: `npx tsx scripts/rebuild-kb-index.ts` (if exists)

**Pattern not matching?**
- Add pattern to `KB_DETECTION_PATTERNS` in `kb-fallback.ts`
- Test with `isKBQuestion('your query')`

**Search too slow?**
- Index is cached in memory after first load
- Should be < 1ms after initialization

## Next Steps

1. ✅ Test with `npx tsx scripts/test-kb-unit.ts`
2. ✅ Read `/docs/kb/kb-fallback-implementation.md`
3. ⏭️ Integrate citations into frontend UI
4. ⏭️ Add more detection patterns based on usage

---

**Full docs**: `/docs/kb/kb-fallback-implementation.md`
