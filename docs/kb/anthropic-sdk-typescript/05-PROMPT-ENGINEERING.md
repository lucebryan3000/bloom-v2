---
id: anthropic-sdk-typescript-05-prompt-engineering
topic: anthropic-sdk-typescript
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [anthropic-sdk-typescript-basics]
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Prompt Engineering Guide

Effective prompting techniques for Claude to achieve better results.

---

## Table of Contents

1. [Overview](#overview)
2. [System Prompt Best Practices](#system-prompt-best-practices)
3. [Message Role Patterns](#message-role-patterns)
4. [Few-Shot Examples](#few-shot-examples)
5. [Chain-of-Thought Prompting](#chain-of-thought-prompting)
6. [XML Tag Usage](#xml-tag-usage)
7. [Context Window Management](#context-window-management)
8. [Response Formatting](#response-formatting)
9. [Common Pitfalls](#common-pitfalls)
10. [Example: Complex System Prompt](#example-complex-system-prompt)
11. [Extracting Structured Data](#extracting-structured-data)
12. [Handling Ambiguous Inputs](#handling-ambiguous-inputs)
13. [Multi-Stage Conversations](#multi-stage-conversations)

---

## Overview

Prompt engineering is the art of crafting effective instructions for Claude to produce desired outputs. Good prompts are:

- **Clear**: Unambiguous instructions
- **Specific**: Concrete examples and constraints
- **Contextual**: Relevant background information
- **Structured**: Well-organized with formatting

**Key principle**: Claude responds best to detailed, well-structured prompts with examples.

---

## System Prompt Best Practices

### What is a System Prompt?

The system prompt defines Claude's role, personality, and behavior constraints. It's separate from conversation messages.

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: "You are a helpful assistant that explains technical concepts clearly.",
 messages: [{ role: "user", content: "What is TypeScript?" }],
});
```

### System Prompt Structure

```typescript
const systemPrompt = `
[ROLE DEFINITION]
You are [specific role with expertise].

[PERSONALITY TRAITS]
- Trait 1
- Trait 2
- Trait 3

[CORE RESPONSIBILITIES]
1. Responsibility 1
2. Responsibility 2
3. Responsibility 3

[COMMUNICATION GUIDELINES]
- Guideline 1
- Guideline 2
- Guideline 3

[CONSTRAINTS/RULES]
- Rule 1
- Rule 2
- Rule 3
`.trim;
```

### Example: Technical Advisor

```typescript
const systemPrompt = `
You are an expert software architect with 15+ years of experience in distributed systems and cloud infrastructure.

Your personality traits:
- Pragmatic and solution-oriented
- Patient and encouraging with junior developers
- Direct and concise in communication
- Data-driven in recommendations

Your core responsibilities:
1. Analyze technical requirements and constraints
2. Recommend appropriate architectures and technologies
3. Identify potential risks and trade-offs
4. Provide code examples when helpful
5. Explain complex concepts in simple terms

Communication guidelines:
- Start with a brief summary
- Use bullet points for clarity
- Include pros/cons for recommendations
- Ask clarifying questions when requirements are unclear
- Keep responses under 300 words unless more detail is requested

Constraints:
- Only recommend technologies you're confident in
- Always mention trade-offs and limitations
- Avoid over-engineering solutions
- Consider cost, complexity, and maintainability
`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: [
 {
 role: "user",
 content: "Should I use microservices or a monolith for a new SaaS product?",
 },
 ],
});
```

### System Prompt Anti-Patterns

❌ **Too vague:**

```typescript
system: "You are helpful.";
```

❌ **Contradictory:**

```typescript
system: "Be extremely concise. Provide detailed explanations with many examples.";
```

❌ **Too complex:**

```typescript
// 5000-word system prompt with excessive rules
```

✅ **Good balance:**

```typescript
system: `You are a Python expert. Provide clear, working code examples with brief explanations. Keep responses under 200 words unless asked for more detail.`;
```

---

## Message Role Patterns

### Role Alternation Rule

Messages must alternate between `user` and `assistant` roles.

✅ **Correct:**

```typescript
const messages = [
 { role: "user", content: "What is React?" },
 { role: "assistant", content: "React is a JavaScript library..." },
 { role: "user", content: "How do I install it?" },
];
```

❌ **Incorrect:**

```typescript
const messages = [
 { role: "user", content: "What is React?" },
 { role: "user", content: "How do I install it?" }, // Error: consecutive user messages
];
```

### Priming the Assistant

Use an assistant message to guide response format.

```typescript
const messages = [
 {
 role: "user",
 content: "List 3 benefits of TypeScript",
 },
 {
 role: "assistant",
 content: "Here are 3 benefits of TypeScript:\n\n1.", // Prime the format
 },
];

// Claude will continue from "1." and follow the numbered list format
```

### Multi-Turn Context

Maintain conversation history for context.

```typescript
const conversationHistory: Anthropic.MessageParam[] = [];

// Turn 1
conversationHistory.push({
 role: "user",
 content: "What's the capital of France?",
});

let response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: conversationHistory,
});

conversationHistory.push({
 role: "assistant",
 content: response.content[0].text,
});

// Turn 2 (Claude remembers previous context)
conversationHistory.push({
 role: "user",
 content: "What's its population?", // "its" refers to Paris from context
});

response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: conversationHistory,
});
```

---

## Few-Shot Examples

### When to Use Few-Shot

Use examples when you want Claude to:

- Follow a specific output format
- Mimic a particular style
- Handle edge cases consistently
- Perform complex transformations

### Basic Few-Shot Pattern

```typescript
const messages = [
 {
 role: "user",
 content: "Classify: This product is amazing!",
 },
 {
 role: "assistant",
 content: "Sentiment: Positive\nConfidence: High",
 },
 {
 role: "user",
 content: "Classify: The service was okay.",
 },
 {
 role: "assistant",
 content: "Sentiment: Neutral\nConfidence: Medium",
 },
 {
 role: "user",
 content: "Classify: I'm very disappointed.",
 },
 {
 role: "assistant",
 content: "Sentiment: Negative\nConfidence: High",
 },
 {
 role: "user",
 content: "Classify: The interface could be better but it works.",
 },
];

// Claude will follow the established format
```

### Few-Shot for Structured Output

```typescript
const messages = [
 {
 role: "user",
 content: "Extract: John Smith works at Google as a Software Engineer.",
 },
 {
 role: "assistant",
 content: JSON.stringify({
 name: "John Smith",
 company: "Google",
 role: "Software Engineer",
 }),
 },
 {
 role: "user",
 content: "Extract: Sarah Johnson is the CEO of TechCorp.",
 },
 {
 role: "assistant",
 content: JSON.stringify({
 name: "Sarah Johnson",
 company: "TechCorp",
 role: "CEO",
 }),
 },
 {
 role: "user",
 content: "Extract: Mike Brown is a Data Scientist at Amazon.",
 },
];

// Claude will return structured JSON
```

### How Many Examples?

- **0-shot**: No examples (for simple, clear tasks)
- **1-shot**: One example (for straightforward patterns)
- **2-3 shot**: Most common (balances clarity and token usage)
- **5+ shot**: For complex patterns with edge cases

---

## Chain-of-Thought Prompting

### What is Chain-of-Thought?

Asking Claude to "think step-by-step" improves reasoning for complex tasks.

### Basic CoT Pattern

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
A company has 150 employees. 60% work remotely. Of the remote workers, 40% are in different time zones. How many employees work remotely in different time zones?

Think step-by-step and show your work.
 `.trim,
 },
 ],
});

// Claude will show reasoning:
// "Let me work through this step-by-step:
// 1. Total employees: 150
// 2. Remote workers: 150 × 0.60 = 90
// 3. Remote in different time zones: 90 × 0.40 = 36
// Therefore, 36 employees work remotely in different time zones."
```

### CoT with XML Tags

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Analyze the following code for bugs:

\`\`\`typescript
function divide(a, b) {
 return a / b;
}
\`\`\`

First, think through potential issues in <thinking> tags, then provide your final answer in <answer> tags.
 `.trim,
 },
 ],
});

// Claude will structure response:
// <thinking>
// 1. No type checking
// 2. No validation for b === 0
// 3. No error handling
// </thinking>
//
// <answer>
// The main bug is division by zero...
// </answer>
```

### Multi-Step Reasoning

```typescript
const systemPrompt = `You are a business analyst. When solving problems:
1. State assumptions
2. Break down the problem
3. Calculate each step
4. Verify your logic
5. Provide the final answer`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: [
 {
 role: "user",
 content:
 "If automating a process saves 2 hours per week per employee, and we have 50 employees, what's the annual time savings in hours?",
 },
 ],
});
```

---

## XML Tag Usage

### Why Use XML Tags?

XML tags help structure prompts and responses for:

- Separating reasoning from final answers
- Organizing complex information
- Guiding Claude's output format
- Extracting specific sections programmatically

### Common XML Patterns

#### 1. Thinking and Answer

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Solve this problem. Show your reasoning in <thinking> tags and your final answer in <answer> tags.

Problem: What's 15% of 240?
 `.trim,
 },
 ],
});

// Extract answer
const text = response.content[0].text;
const answerMatch = text.match(/<answer>(.*?)<\/answer>/s);
const answer = answerMatch ? answerMatch[1].trim: null;
```

#### 2. Multiple Sections

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Analyze this code review comment:

<comment>
This function is too complex and should be refactored.
</comment>

Provide your analysis in these sections:
<severity>Low/Medium/High</severity>
<reasoning>Why this matters</reasoning>
<recommendation>What to do</recommendation>
 `.trim,
 },
 ],
});
```

#### 3. Input/Output Separation

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Given this user profile:

<user_profile>
Name: John Doe
Industry: Healthcare
Company Size: 500 employees
Pain Point: Manual data entry
</user_profile>

Recommend solutions in <recommendations> tags.
 `.trim,
 },
 ],
});
```

### Extracting XML Content

```typescript
function extractXMLContent(text: string, tag: string): string | null {
 const regex = new RegExp(`<${tag}>(.*?)</${tag}>`, "s");
 const match = text.match(regex);
 return match ? match[1].trim: null;
}

const responseText = response.content[0].text;
const thinking = extractXMLContent(responseText, "thinking");
const answer = extractXMLContent(responseText, "answer");

console.log("Reasoning:", thinking);
console.log("Answer:", answer);
```

---

## Context Window Management

### Claude Sonnet 4.5 Context

- **Context window**: 200,000 tokens (~150,000 words)
- **Input**: Practically unlimited within 200K
- **Output**: Up to 8,192 tokens

### Estimating Token Usage

```typescript
// Rough estimates:
// - 1 token ≈ 4 characters
// - 1 token ≈ 0.75 words
// - 100 tokens ≈ 75 words

function estimateTokens(text: string): number {
 return Math.ceil(text.length / 4);
}

const systemPrompt = "You are a helpful assistant.";
const userMessage = "Explain quantum computing.";

const estimatedTokens =
 estimateTokens(systemPrompt) + estimateTokens(userMessage);
console.log(`Estimated input tokens: ${estimatedTokens}`);
```

### Managing Long Conversations

```typescript
const MAX_HISTORY_TOKENS = 100000; // Leave room for response

function trimConversationHistory(
 messages: Anthropic.MessageParam[],
 maxTokens: number
): Anthropic.MessageParam[] {
 let totalTokens = 0;
 const trimmedMessages: Anthropic.MessageParam[] = [];

 // Keep most recent messages within token limit
 for (let i = messages.length - 1; i >= 0; i--) {
 const message = messages[i];
 const messageTokens = estimateTokens(
 typeof message.content === "string" ? message.content: ""
 );

 if (totalTokens + messageTokens > maxTokens) {
 break; // Stop adding older messages
 }

 trimmedMessages.unshift(message); // Add to beginning
 totalTokens += messageTokens;
 }

 // Ensure first message is from user
 if (trimmedMessages[0]?.role !== "user") {
 trimmedMessages.shift;
 }

 return trimmedMessages;
}

// Usage
const trimmedMessages = trimConversationHistory(conversationHistory, MAX_HISTORY_TOKENS);
```

### Summarizing Long Context

```typescript
async function summarizeConversation(
 anthropic: Anthropic,
 messages: Anthropic.MessageParam[]
): Promise<string> {
 const conversationText = messages
.map((m) => `${m.role}: ${m.content}`)
.join("\n\n");

 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 500,
 messages: [
 {
 role: "user",
 content: `Summarize this conversation in 2-3 sentences:\n\n${conversationText}`,
 },
 ],
 });

 return response.content[0].text;
}

// Use summary as context for new conversation
const summary = await summarizeConversation(anthropic, oldMessages);
const newSystemPrompt = `Previous conversation summary: ${summary}\n\nYou are a helpful assistant.`;
```

---

## Response Formatting

### Requesting Specific Formats

#### JSON Output

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Extract information from this text and return ONLY valid JSON (no additional text):

"John Smith is a 35-year-old software engineer living in San Francisco."

Format:
{
 "name": "string",
 "age": number,
 "occupation": "string",
 "location": "string"
}
 `.trim,
 },
 ],
});

const jsonText = response.content[0].text;
const data = JSON.parse(jsonText);
```

#### Markdown Table

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Compare TypeScript and JavaScript in a markdown table with these columns: Feature, TypeScript, JavaScript

Include 5 key differences.
 `.trim,
 },
 ],
});
```

#### Bullet Points

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: "List 5 benefits of using Docker. Use bullet points.",
 },
 ],
});
```

### Constraining Response Length

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 150, // Hard limit
 messages: [
 {
 role: "user",
 content:
 "Explain React in 2 sentences or less.", // Soft constraint in prompt
 },
 ],
});
```

---

## Common Pitfalls

### 1. Vague Instructions

❌ **Bad:**

```typescript
"Tell me about databases.";
```

✅ **Good:**

```typescript
"Explain the difference between SQL and NoSQL databases. Include 2 examples of each and when to use them. Keep it under 200 words.";
```

### 2. Contradictory Prompts

❌ **Bad:**

```typescript
system: "Be extremely concise.",
user: "Provide a detailed, comprehensive explanation with many examples.";
```

✅ **Good:**

```typescript
system: "Provide concise explanations with 1-2 examples.",
user: "Explain React hooks with examples.";
```

### 3. Assuming Knowledge

❌ **Bad:**

```typescript
"Fix the bug in my code.";
// No code provided!
```

✅ **Good:**

```typescript
`
I have this TypeScript function that's throwing an error:

\`\`\`typescript
function divide(a, b) {
 return a / b;
}
\`\`\`

Error: "Division by zero"

How should I fix this?
`;
```

### 4. Overloading with Context

❌ **Bad:**

```typescript
// Paste 50,000 lines of code
"Find the bug in this codebase.";
```

✅ **Good:**

```typescript
// Paste relevant 50-100 lines
"Find the bug in this authentication function.";
```

### 5. No Examples for Complex Tasks

❌ **Bad:**

```typescript
"Parse this data into the format I need.";
// No format specified!
```

✅ **Good:**

```typescript
`
Parse this data:
"John, 25, Engineer"

Into this format:
{ "name": "John", "age": 25, "role": "Engineer" }
`;
```

---

## Example: Complex System Prompt

### Complete Melissa Prompt

```typescript
export const MELISSA_SYSTEM_PROMPT = `
You are Melissa, an expert AI business consultant specializing in ROI discovery and process optimization for organizational knowledge management and AI implementation.

Your personality traits:
- Professional yet approachable and warm
- Insightful and asks clarifying questions
- Encouraging and supportive
- Data-driven but explains concepts simply
- Patient and non-judgmental

Your role in this 15-minute discovery workshop:
1. Welcome users and explain the workshop structure
2. Guide them through discovery questions to understand their current state
3. Identify automation and AI opportunities
4. Quantify potential business value and ROI
5. Gather metrics needed for ROI calculations (time savings, cost reduction, efficiency gains)
6. Validate assumptions and flag uncertainties
7. Calculate ROI with confidence scores
8. Provide actionable insights and next steps

Workshop phases:
- Phase 1: Introduction and goal setting (2 min)
- Phase 2: Current state assessment (3 min)
- Phase 3: Pain point identification (3 min)
- Phase 4: Solution exploration (3 min)
- Phase 5: ROI quantification (3 min)
- Phase 6: Summary and next steps (1 min)

Communication guidelines:
- Keep responses concise (2-3 sentences typically, max 4-5 sentences)
- Ask ONE focused question at a time
- Validate understanding before proceeding to next topic
- Use examples to clarify abstract concepts
- Acknowledge concerns and address them directly
- Keep the conversation focused and efficient
- Track time implicitly to stay within 15 minutes
- Use encouraging language to maintain engagement

Data collection priorities:
- Number of employees affected
- Time spent on manual tasks (hours/week)
- Error rates and rework
- Current costs (tools, labor)
- Expected improvement percentages
- Implementation timeline and costs

Response format:
- Brief acknowledgment of user's input
- One insight or observation
- One focused follow-up question
- (Optional) Transition signal when moving to next phase

Constraints:
- Do NOT make up numbers or statistics
- Do NOT provide overly optimistic ROI projections
- DO flag when you need more information for accurate calculations
- DO provide confidence scores reflecting data quality
- DO acknowledge limitations and assumptions explicitly

Remember: Your goal is to help users discover tangible, measurable value in 15 minutes or less.
`.trim;
```

### Using Melissa Prompt

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.7,
 system: MELISSA_SYSTEM_PROMPT,
 messages: conversationHistory,
});
```

---

## Extracting Structured Data

### Pattern: Extraction with Validation

```typescript
const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [
 {
 role: "user",
 content: `
Extract ROI metrics from this conversation:

User: "We have 50 employees spending 5 hours per week on manual data entry. Our average hourly cost is $40."

Return ONLY valid JSON:
{
 "employeeCount": number,
 "hoursPerWeek": number,
 "hourlyCost": number,
 "confidenceScore": number (0-1),
 "missingData": string[]
}
 `.trim,
 },
 ],
});

const jsonText = response.content[0].text;
const metrics = JSON.parse(jsonText);

if (metrics.confidenceScore < 0.7) {
 console.warn("Low confidence extraction:", metrics.missingData);
}
```

---

## Handling Ambiguous Inputs

### Pattern: Clarification Loop

```typescript
const systemPrompt = `When a user's input is ambiguous, ask ONE specific clarifying question before proceeding. Do not make assumptions.`;

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: systemPrompt,
 messages: [
 {
 role: "user",
 content: "We want to improve our process.",
 },
 ],
});

// Claude will ask: "Which specific process are you referring to? For example: customer onboarding, data analysis, report generation, etc."
```

---

## Multi-Stage Conversations

### Pattern: Phase Tracking

```typescript
interface ConversationState {
 phase:
 | "introduction"
 | "assessment"
 | "pain_points"
 | "solutions"
 | "roi"
 | "summary";
 collectedData: Record<string, unknown>;
}

function buildSystemPrompt(state: ConversationState): string {
 return `
${MELISSA_SYSTEM_PROMPT}

Current phase: ${state.phase}
Data collected so far: ${JSON.stringify(state.collectedData)}

Focus on collecting data relevant to ${state.phase} phase.
 `.trim;
}

const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 system: buildSystemPrompt(conversationState),
 messages: conversationHistory,
});
```

---

## Best Practices Summary

1. **Be specific**: Clear, detailed instructions > vague requests
2. **Use examples**: Show the desired format with 2-3 examples
3. **Structure prompts**: Use sections, XML tags, formatting
4. **Request reasoning**: Ask Claude to think step-by-step for complex tasks
5. **Constrain responses**: Specify length, format, and constraints
6. **Validate inputs**: Check assumptions with clarifying questions
7. **Manage context**: Trim conversation history when approaching limits
8. **Test iteratively**: Refine prompts based on actual outputs

---

## See Also

- [02-MESSAGES-API.md](./02-MESSAGES-API.md) - Messages API reference
- [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) - Integration examples
- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Quick lookup patterns
- [Official Prompt Engineering Guide](https://docs.anthropic.com/claude/docs/prompt-engineering)
