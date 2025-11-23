# Function Calling Guide

Complete guide to OpenAI function calling for structured outputs.

## Overview

Function calling allows models to:
- Generate structured JSON outputs
- Call external APIs/functions
- Extract data reliably
- Build tool-using agents

## Basic Function Definition

```typescript
const functions: OpenAI.Chat.ChatCompletionCreateParams.Function[] = [{
  name: "get_weather",
  description: "Get current weather in a location",
  parameters: {
    type: "object",
    properties: {
      location: {
        type: "string",
        description: "City and state, e.g. San Francisco, CA",
      },
      unit: {
        type: "string",
        enum: ["celsius", "fahrenheit"],
        description: "Temperature unit",
      },
    },
    required: ["location"],
  },
}];
```

## Using Functions

```typescript
const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [
    { role: "user", content: "What's the weather in Boston?" }
  ],
  functions,
  function_call: "auto", // or { name: "get_weather" }
});

const message = completion.choices[0].message;

if (message.function_call) {
  const args = JSON.parse(message.function_call.arguments);
  const result = await getWeather(args.location, args.unit);

  // Send result back
  const followUp = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [
      { role: "user", content: "What's the weather in Boston?" },
      message,
      {
        role: "function",
        name: message.function_call.name,
        content: JSON.stringify(result),
      },
    ],
  });
}
```

## Structured Data Extraction

```typescript
async function extractPerson(text: string) {
  const completion = await openai.chat.completions.create({
    model: "gpt-4",
    messages: [{ role: "user", content: text }],
    functions: [{
      name: "extract_person",
      description: "Extract person information",
      parameters: {
        type: "object",
        properties: {
          name: { type: "string" },
          age: { type: "number" },
          occupation: { type: "string" },
          location: { type: "string" },
        },
        required: ["name"],
      },
    }],
    function_call: { name: "extract_person" },
  });

  return JSON.parse(
    completion.choices[0].message.function_call?.arguments || '{}'
  );
}

// Usage
const data = await extractPerson("John is a 30 year old engineer from NYC");
// { name: "John", age: 30, occupation: "engineer", location: "NYC" }
```

## Multiple Functions

```typescript
const functions = [
  {
    name: "search_docs",
    description: "Search documentation",
    parameters: {
      type: "object",
      properties: {
        query: { type: "string" },
      },
      required: ["query"],
    },
  },
  {
    name: "create_ticket",
    description: "Create support ticket",
    parameters: {
      type: "object",
      properties: {
        title: { type: "string" },
        priority: { type: "string", enum: ["low", "medium", "high"] },
      },
      required: ["title"],
    },
  },
];

const completion = await openai.chat.completions.create({
  model: "gpt-4",
  messages: [{ role: "user", content: "I need help with deployment" }],
  functions,
  function_call: "auto",
});
```

## Agent Pattern

```typescript
class Agent {
  private tools: Map<string, Function> = new Map();

  register(name: string, fn: Function, description: string, params: any) {
    this.tools.set(name, fn);
  }

  async run(prompt: string) {
    const functions = Array.from(this.tools.entries()).map(([name, fn]) => ({
      name,
      // description and parameters from registration
    }));

    let messages = [{ role: "user" as const, content: prompt }];

    while (true) {
      const completion = await openai.chat.completions.create({
        model: "gpt-4",
        messages,
        functions,
        function_call: "auto",
      });

      const message = completion.choices[0].message;
      messages.push(message);

      if (!message.function_call) {
        return message.content;
      }

      // Execute function
      const fn = this.tools.get(message.function_call.name);
      const args = JSON.parse(message.function_call.arguments);
      const result = await fn(args);

      messages.push({
        role: "function",
        name: message.function_call.name,
        content: JSON.stringify(result),
      });
    }
  }
}
```

---

**Last Updated**: 2025-01-13
