---
id: google-gemini-nodejs-05-function-calling
topic: google-gemini-nodejs
file_role: practical
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: [google-gemini-fundamentals, google-gemini-messages-api]
related_topics: [google-gemini, function-calling, tool-use, api-integration]
embedding_keywords: [google-gemini, function-calling, tool-use, api-integration, agents]
last_reviewed: 2025-11-13
---

# Gemini Function Calling

**Purpose**: Enable Gemini to call external APIs and tools. Build agents that can take actions.

---

## 1. Function Declaration

```typescript
const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather for a location',
    parameters: {
      type: 'object',
      properties: {
        location: {
          type: 'string',
          description: 'City and state, e.g., San Francisco, CA',
        },
        unit: {
          type: 'string',
          enum: ['celsius', 'fahrenheit'],
          description: 'Temperature unit',
        },
      },
      required: ['location'],
    },
  },
];
```

---

## 2. Using Functions

```typescript
const chat = model.startChat({
  tools: [{ functionDeclarations: functions }],
});

// User asks question that requires function call
const result = await chat.sendMessage('What is the weather in Boston?');

// Check if Gemini wants to call a function
const functionCalls = result.response.functionCalls();

if (functionCalls) {
  for (const call of functionCalls) {
    console.log('Function:', call.name);
    console.log('Args:', call.args);

    // Execute the function
    const functionResult = await getWeather(call.args.location, call.args.unit);

    // Send result back to Gemini
    const result2 = await chat.sendMessage([{
      functionResponse: {
        name: call.name,
        response: functionResult,
      },
    }]);

    console.log('Final response:', result2.response.text());
  }
}
```

---

## 3. Multiple Functions

```typescript
const functions = [
  {
    name: 'get_weather',
    description: 'Get current weather',
    parameters: { /* ... */ },
  },
  {
    name: 'get_stock_price',
    description: 'Get stock price',
    parameters: {
      type: 'object',
      properties: {
        ticker: { type: 'string', description: 'Stock ticker symbol' },
      },
      required: ['ticker'],
    },
  },
  {
    name: 'search_database',
    description: 'Search internal database',
    parameters: { /* ... */ },
  },
];

const chat = model.startChat({
  tools: [{ functionDeclarations: functions }],
});

// Gemini can call multiple functions in one turn
const result = await chat.sendMessage(
  'What is the weather in NYC and the price of GOOGL stock?'
);

const functionCalls = result.response.functionCalls();
// May return multiple function calls

// Execute all functions in parallel
const responses = await Promise.all(
  functionCalls.map(async (call) => {
    const result = await executeFunction(call.name, call.args);
    return {
      functionResponse: {
        name: call.name,
        response: result,
      },
    };
  })
);

// Send all responses back
const finalResult = await chat.sendMessage(responses);
```

---

## 4. Function Execution Pattern

```typescript
async function executeFunction(name: string, args: any) {
  switch (name) {
    case 'get_weather':
      return await getWeather(args.location, args.unit);
    case 'get_stock_price':
      return await getStockPrice(args.ticker);
    case 'search_database':
      return await searchDatabase(args.query);
    default:
      return { error: 'Unknown function' };
  }
}
```

---

## 5. Common Use Cases

### Use Case: Database Query Agent

```typescript
const functions = [
  {
    name: 'query_users',
    description: 'Query users from database',
    parameters: {
      type: 'object',
      properties: {
        filters: { type: 'object' },
        limit: { type: 'number' },
      },
    },
  },
];

// User: "Show me all admin users created this week"
// Gemini calls: query_users({ filters: { role: 'admin', createdAfter: '2025-11-07' }, limit: 100 })
```

### Use Case: Booking Assistant

```typescript
const functions = [
  {
    name: 'check_availability',
    description: 'Check room availability',
    parameters: { /* ... */ },
  },
  {
    name: 'create_booking',
    description: 'Create a new booking',
    parameters: { /* ... */ },
  },
  {
    name: 'send_confirmation_email',
    description: 'Send booking confirmation',
    parameters: { /* ... */ },
  },
];
```

---

## 6. Best Practices

### ✅ DO

- Provide clear, detailed function descriptions
- Use JSON Schema for parameter validation
- Handle function errors gracefully
- Return structured data from functions
- Validate function results before sending to Gemini

### ❌ DON'T

- Don't execute unsafe operations without confirmation
- Don't return too much data (token limits)
- Don't forget to handle missing required parameters
- Don't expose sensitive APIs without authentication

---

## 7. Error Handling

```typescript
try {
  const result = await executeFunction(call.name, call.args);
  return result;
} catch (error) {
  return {
    error: true,
    message: error.message,
  };
}
```

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Function calling only works with Pro models (not Flash yet)
2. Gemini decides when to call functions based on user intent
3. Always execute functions on server-side (never client-side)
4. Return structured data for best results
5. Implement proper error handling

---

**Next**: [06-GROUNDING.md](06-GROUNDING.md) for Google Search integration.
