---
id: google-gemini-nodejs-08-safety-content
topic: google-gemini-nodejs
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [google-gemini-fundamentals]
related_topics: [google-gemini, safety, content-filtering, moderation]
embedding_keywords: [google-gemini, safety-filters, content-filtering, moderation, harm-categories]
last_reviewed: 2025-11-13
---

# Gemini Safety & Content Filtering

**Purpose**: Configure content safety filters and handle blocked responses.

---

## 1. Safety Settings

```typescript
import { HarmCategory, HarmBlockThreshold } from '@google/generative-ai';

const safetySettings = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_MEDIUM_AND_ABOVE,
  },
];

const model = genAI.getGenerativeModel({
  model: 'gemini-1.5-flash-latest',
  safetySettings,
});
```

---

## 2. Harm Categories

- `HARM_CATEGORY_HARASSMENT` - Negative or harmful content targeting identity/attributes
- `HARM_CATEGORY_HATE_SPEECH` - Content promoting hate based on protected attributes
- `HARM_CATEGORY_SEXUALLY_EXPLICIT` - Sexually explicit content
- `HARM_CATEGORY_DANGEROUS_CONTENT` - Content promoting dangerous acts

---

## 3. Block Thresholds

- `BLOCK_NONE` - Don't block any content
- `BLOCK_ONLY_HIGH` - Block only high probability of harm
- `BLOCK_MEDIUM_AND_ABOVE` - Block medium and high (default)
- `BLOCK_LOW_AND_ABOVE` - Block low, medium, and high
- `HARM_BLOCK_THRESHOLD_UNSPECIFIED` - Use default

---

## 4. Checking Safety Ratings

```typescript
const result = await model.generateContent('Some potentially sensitive content');

const candidate = result.response.candidates?.[0];

if (candidate?.finishReason === 'SAFETY') {
  console.log('Response blocked due to safety filters');
  console.log('Safety ratings:', candidate.safetyRatings);
}

// Safety ratings structure
candidate.safetyRatings?.forEach((rating) => {
  console.log(`Category: ${rating.category}`);
  console.log(`Probability: ${rating.probability}`);
  console.log(`Blocked: ${rating.blocked}`);
});
```

---

## 5. Handling Blocked Responses

```typescript
try {
  const result = await model.generateContent(prompt);
  const candidate = result.response.candidates?.[0];

  if (candidate?.finishReason === 'SAFETY') {
    // Handle safety block
    return {
      success: false,
      message: 'Content filtered due to safety policies',
      categories: candidate.safetyRatings?.map((r) => r.category),
    };
  }

  return {
    success: true,
    text: result.response.text(),
  };
} catch (error) {
  // Handle errors
}
```

---

## 6. Permissive Settings (Use with Caution)

```typescript
const permissiveSettings = [
  {
    category: HarmCategory.HARM_CATEGORY_HARASSMENT,
    threshold: HarmBlockThreshold.BLOCK_NONE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_HATE_SPEECH,
    threshold: HarmBlockThreshold.BLOCK_NONE,
  },
  {
    category: HarmCategory.HARM_CATEGORY_SEXUALLY_EXPLICIT,
    threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
  },
  {
    category: HarmCategory.HARM_CATEGORY_DANGEROUS_CONTENT,
    threshold: HarmBlockThreshold.BLOCK_ONLY_HIGH,
  },
];
```

**Warning**: Only use permissive settings if:
- You have a legitimate business need
- You implement additional safety layers
- You understand legal/compliance implications

---

## 7. Best Practices

### ✅ DO

- Use default safety settings for most use cases
- Log blocked responses for monitoring
- Implement fallback responses for blocks
- Combine with application-level moderation

### ❌ DON'T

- Don't disable safety filters without good reason
- Don't expose raw safety ratings to users
- Don't rely solely on Gemini safety (add your own checks)
- Don't ignore compliance requirements

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Safety filters are enabled by default
2. Check `finishReason === 'SAFETY'` for blocks
3. Adjust thresholds based on use case
4. Always have fallback for blocked responses
5. Comply with usage policies

---

**Next**: [09-ERROR-HANDLING.md](09-ERROR-HANDLING.md) for production error management.
