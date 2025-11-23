# Tool Calling Schema Error: Root Cause & Solution

**Error**: `tools.0.custom.input_schema.type: Field required`

**Status**: ✅ **SOLVED**

## Problem Summary

All tool calling attempts with AI SDK v5.0.93 + @ai-sdk/anthropic v2.0.44 failed with:

```
APICallError: tools.0.custom.input_schema.type: Field required
Status: 400 (invalid_request_error)
```

## Root Cause

The AI SDK `tool()` helper has **two different field names** for defining schemas:
- ✅ `inputSchema` - Correct field name (properly converts Zod to JSON Schema)
- ❌ `parameters` - **WRONG** field name (broken conversion, missing `type` field)

### What Was Being Sent (Broken)

When using `parameters`:

```json
{
  "name": "weather",
  "description": "Get the weather",
  "input_schema": {
    "properties": {},
    "additionalProperties": false
    // ❌ MISSING: "type": "object"
  }
}
```

Anthropic API correctly rejected this because JSON Schema requires a `type` field at the root level.

### What Should Be Sent (Fixed)

When using `inputSchema`:

```json
{
  "name": "weather",
  "description": "Get the weather",
  "input_schema": {
    "type": "object",  // ✅ PRESENT
    "properties": {
      "location": {
        "type": "string",
        "description": "The location to get the weather for"
      }
    },
    "required": ["location"],
    "additionalProperties": false
  }
}
```

## Solution

### ❌ WRONG (Broken Code)

```typescript
import { tool } from 'ai';
import { z } from 'zod';

const weatherTool = tool({
  description: 'Get the weather in a location',
  parameters: z.object({  // ❌ WRONG FIELD NAME
    location: z.string().describe('The location'),
  }),
  execute: async ({ location }) => {
    return { temperature: 72 };
  },
});
```

### ✅ CORRECT (Working Code)

```typescript
import { tool } from 'ai';
import { z } from 'zod';

const weatherTool = tool({
  description: 'Get the weather in a location',
  inputSchema: z.object({  // ✅ CORRECT FIELD NAME
    location: z.string().describe('The location'),
  }),
  execute: async ({ location }) => {
    return { temperature: 72 };
  },
});
```

## Complete Working Example

```typescript
import { generateText, tool } from 'ai';
import { createAnthropic } from '@ai-sdk/anthropic';
import { z } from 'zod';

const anthropic = createAnthropic({
  apiKey: process.env.ANTHROPIC_API_KEY,
});

const result = await generateText({
  model: anthropic('claude-sonnet-4-5-20250929'),
  tools: {
    weather: tool({
      description: 'Get the weather in a location',
      inputSchema: z.object({  // ✅ Use inputSchema
        location: z.string().describe('The location to get the weather for'),
      }),
      execute: async ({ location }) => ({
        location,
        temperature: 72,
      }),
    }),
    calculator: tool({
      description: 'Perform a calculation',
      inputSchema: z.object({  // ✅ Use inputSchema
        operation: z.enum(['add', 'subtract', 'multiply', 'divide']),
        a: z.number(),
        b: z.number(),
      }),
      execute: async ({ operation, a, b }) => {
        const ops = {
          add: a + b,
          subtract: a - b,
          multiply: a * b,
          divide: a / b,
        };
        return { result: ops[operation] };
      },
    }),
  },
  prompt: 'What is the weather in San Francisco? Also calculate 15 * 3.',
});

console.log(result.text);
console.log('Tool calls:', result.toolCalls);
```

## Why This Happened

### API Field Name Confusion

The AI SDK documentation and examples are inconsistent:
- Official docs (v5.0.93): Show `inputSchema`
- Some examples/older docs: Show `parameters`
- TypeScript types: **Accept both** without error

The `tool()` helper's TypeScript definition accepts both field names but only `inputSchema` works correctly with Anthropic's provider. Using `parameters` silently produces invalid JSON Schema.

### The `.custom.` Path Mystery

The error path `tools.0.custom.input_schema.type` initially suggested custom tool types. Actually:
- Anthropic's API uses this path for **all** user-defined tools
- "custom" = client-side tools (vs server-side tools like `web_search_20250305`)
- The path doesn't indicate the bug, it's just Anthropic's internal naming

## Model Name Issue (Bonus Fix)

### ❌ Old Model Names (404 Not Found)

```typescript
'claude-3-5-sonnet-20241022'  // ❌ Deprecated
'claude-3-5-sonnet-latest'     // ❌ Doesn't exist
'claude-3-sonnet-20240229'     // ❌ Deprecated
```

### ✅ Current Working Models

```typescript
'claude-sonnet-4-5-20250929'   // ✅ Latest Sonnet (recommended)
'claude-3-haiku-20240307'      // ✅ Fast/cheap model
```

## Testing

Verified tests:
- ✅ Single tool calling
- ✅ Multiple tools in one call
- ✅ Complex Zod schemas (nested objects, enums, arrays)
- ✅ Native Anthropic SDK (baseline comparison)
- ✅ AI SDK with `inputSchema` field

Test files:
- `/home/luce/apps/bloom/scripts/test-solution.ts` - Complete working example
- `/home/luce/apps/bloom/scripts/test-native-anthropic-tools.ts` - Baseline test
- `/home/luce/apps/bloom/scripts/test-input-schema-vs-parameters.ts` - A/B comparison

## Migration Guide

### Step 1: Update Tool Definitions

Find all `tool()` calls:
```bash
grep -r "parameters:" --include="*.ts" --include="*.tsx"
```

Replace `parameters` with `inputSchema`:
```diff
  const myTool = tool({
    description: '...',
-   parameters: z.object({
+   inputSchema: z.object({
      field: z.string(),
    }),
    execute: async ({ field }) => { ... },
  });
```

### Step 2: Update Model Names

Find deprecated model names:
```bash
grep -r "claude-3-5-sonnet" --include="*.ts" --include="*.env"
```

Replace with current name:
```diff
- model: anthropic('claude-3-5-sonnet-20241022')
+ model: anthropic('claude-sonnet-4-5-20250929')
```

### Step 3: Test

Run your tool calling code and verify:
- No schema validation errors
- Tools are called correctly
- Zod types still infer properly

## Versions

This fix applies to:
- **AI SDK**: v5.0.93
- **@ai-sdk/anthropic**: v2.0.44
- **Zod**: v3.25.76
- **@anthropic-ai/sdk**: v0.69.0 (for baseline testing)

## Future Notes

### Upgrading to AI SDK v6

AI SDK v6 beta exists (v6.0.0-beta.99 as of Nov 2025) but requires:
- **@ai-sdk/anthropic** v3.x (breaking change)
- Migration testing for new APIs
- Potential breaking changes to tool calling

**Recommendation**: Stay on v5 until v6 stable release unless you need specific v6 features.

### Alternative: Native Anthropic SDK

If AI SDK tool calling continues to be problematic, you can use the native SDK:

```typescript
import Anthropic from '@anthropic-ai/sdk';

const client = new Anthropic({ apiKey: '...' });

const response = await client.messages.create({
  model: 'claude-sonnet-4-5-20250929',
  max_tokens: 1024,
  messages: [{ role: 'user', content: 'What is ROI?' }],
  tools: [
    {
      name: 'search_knowledge_base',
      description: 'Searches the knowledge base',
      input_schema: {
        type: 'object',  // Must include explicitly
        properties: {
          query: {
            type: 'string',
            description: 'Search query',
          },
        },
        required: ['query'],
      },
    },
  ],
});
```

**Pros**: Direct control, no abstraction bugs
**Cons**: No Zod validation, no type inference, more boilerplate

## Key Takeaways

1. **Always use `inputSchema`** with AI SDK tool() helper
2. **Never use `parameters`** - it produces invalid JSON Schema
3. **TypeScript won't catch this** - both field names are accepted
4. **Test tool calling** after any AI SDK upgrade
5. **Use current model names** - check docs for latest IDs

---

**Document Author**: Claude (AI Assistant)
**Date**: November 16, 2025
**Status**: Production Ready
**Last Verified**: AI SDK v5.0.93, @ai-sdk/anthropic v2.0.44
