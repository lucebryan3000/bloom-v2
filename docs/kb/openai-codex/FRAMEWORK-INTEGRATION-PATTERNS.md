---
id: openai-codex-framework-integration
topic: openai-codex
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [openai-codex-fundamentals]
last_reviewed: 2025-11-16
---

# OpenAI Codex - Framework Integration Patterns

## Next.js Integration

```typescript
// app/api/chat/route.ts
import { OpenAI } from 'openai'
import { NextResponse } from 'next/server'

const openai = new OpenAI({
  apiKey: process.env.OPENAI_API_KEY
})

export async function POST(request: Request) {
  const { message } = await request.json()
  
  const completion = await openai.chat.completions.create({
    model: 'gpt-4',
    messages: [{ role: 'user', content: message }]
  })
  
  return NextResponse.json({ 
    response: completion.choices[0].message.content 
  })
}
```

## TypeScript Patterns

```typescript
import { OpenAI } from 'openai'

// Type-safe configuration
interface ChatConfig {
  model: string
  temperature: number
  maxTokens: number
}

// Reusable chat function
async function chat(
  prompt: string, 
  config: ChatConfig
): Promise<string> {
  const openai = new OpenAI()
  
  const completion = await openai.chat.completions.create({
    model: config.model,
    temperature: config.temperature,
    max_tokens: config.maxTokens,
    messages: [{ role: 'user', content: prompt }]
  })
  
  return completion.choices[0].message.content || ''
}
```

## Best Practices

- Use environment variables for API keys
- Implement rate limiting
- Handle errors gracefully
- Stream responses for better UX

## AI Pair Programming Notes

**When to load:** Integrating OpenAI API with Next.js, React, or TypeScript projects
