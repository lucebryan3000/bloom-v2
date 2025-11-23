---
id: anthropic-sdk-typescript-framework-specific-patterns
topic: anthropic-sdk-typescript
file_role: patterns
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: []
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript, patterns, examples, integration]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Framework-Specific Patterns

Real-world patterns from the this application codebase showing how the Anthropic SDK is integrated in production.

---

## Table of Contents

1. [Melissa Agent Integration Pattern](#melissa-agent-integration-pattern)
2. [Configuration Management](#configuration-management)
3. [Multi-Turn Conversation with State](#multi-turn-conversation-with-state)
4. [Message Persistence with Prisma](#message-persistence-with-prisma)
5. [Type-Safe API Route Handler](#type-safe-api-route-handler)
6. [File Attachments (PDF Documents)](#file-attachments-pdf-documents)
7. [Error Handling Strategy](#error-handling-strategy)
8. [Logging Integration](#logging-integration)
9. [Metrics Extraction](#metrics-extraction)
10. [Progress Tracking](#progress-tracking)

---

## Melissa Agent Integration Pattern

**Pattern**: Encapsulate Anthropic client in a stateful agent class that manages conversation flow, metrics extraction, and database persistence.

**Location**: `lib/melissa/agent.ts`

```typescript
import Anthropic from "@anthropic-ai/sdk";
import { prisma } from "@/lib/db/client";

export class MelissaAgent {
 private anthropic: Anthropic;
 private state: ConversationState;
 private sessionId: string;
 private config: MelissaConfigData;

 // Private constructor - use static create method
 private constructor(options: MelissaAgentOptions, config: MelissaConfigData) {
 const apiKey = process.env.ANTHROPIC_API_KEY;
 if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY environment variable is required");
 }

 this.anthropic = new Anthropic({ apiKey });
 this.sessionId = options.sessionId;
 this.config = config;

 // Initialize conversation state
 this.state = options.existingState
 ? this.hydrateState(options.existingState)
: this.initializeState;
 }

 /**
 * Create a new MelissaAgent instance with configuration loaded from database
 */
 static async create(options: MelissaAgentOptions): Promise<MelissaAgent> {
 const organizationId = options.organizationId || "default-org";
 const config = await getMelissaConfig(organizationId);
 return new MelissaAgent(options, config);
 }

 async processMessage(
 userMessage: string,
 attachments?: FileAttachment[],
 ): Promise<ResponseData> {
 // 1. Add user message to transcript
 this.state.transcript.push({
 id: `msg-${Date.now}-user`,
 role: "user",
 content: userMessage,
 timestamp: new Date,
 attachments,
 });

 // 2. Generate AI response
 const aiResponse = await this.generateAIResponse(userMessage);

 // 3. Add assistant message to transcript
 this.state.transcript.push({
 id: `msg-${Date.now}-assistant`,
 role: "assistant",
 content: aiResponse,
 timestamp: new Date,
 });

 // 4. Save progress to database
 await this.saveProgress;

 return {
 message: aiResponse,
 phase: this.state.phase,
 progress: this.calculateProgress,
 //... other metadata
 };
 }
}
```

**Key Benefits:**

- Encapsulates complexity
- Manages stateful conversations
- Provides clean API to callers
- Handles persistence automatically

---

## Configuration Management

**Pattern**: Load agent configuration from database with sensible defaults.

**Location**: `lib/melissa/config.ts` + `lib/melissa/services/configService.ts`

```typescript
// Configuration schema
export const MELISSA_CONFIG = {
 model: {
 provider: "anthropic",
 id: "claude-sonnet-4-5-20250929",
 temperature: 0.7,
 maxTokens: 1000,
 topP: 0.9,
 stream: true,
 },

 systemPrompt: `You are Melissa, an expert AI business consultant...`,

 conversationFlow: {
 phases: ["greeting", "discovery", "metrics", "validation", "calculation", "reporting"],
 maxQuestionsPerPhase: {
 greeting: 1,
 discovery: 5,
 metrics: 4,
 validation: 3,
 calculation: 2,
 reporting: 2,
 },
 },

 confidenceThresholds: {
 high: 0.8,
 medium: 0.6,
 low: 0.4,
 minimum: 0.3,
 },
};

// Load from database with fallback
async function getMelissaConfig(
 organizationId: string,
): Promise<MelissaConfigData> {
 const dbConfig = await prisma.melissaConfiguration.findUnique({
 where: { organizationId },
 });

 // Merge database config with defaults
 return {
...MELISSA_CONFIG,
...dbConfig?.settings,
 };
}
```

**Usage in agent:**

```typescript
const response = await this.anthropic.messages.create({
 model: this.config.model.id, // From config
 max_tokens: this.config.model.maxTokens,
 temperature: this.config.model.temperature,
 system: this.config.systemPrompt,
 messages: messages,
});
```

---

## Multi-Turn Conversation with State

**Pattern**: Build conversation context from stored transcript, including phase metadata and extracted metrics.

**Location**: `lib/melissa/agent.ts`

```typescript
private async generateAIResponse(userMessage: string): Promise<string> {
 // Build context for Claude
 const context = this.buildConversationContext;

 // Convert transcript to Anthropic format
 const messages: Anthropic.MessageParam[] = [
 {
 role: "user",
 content: context, // Rich context as first message
 },
...this.state.transcript
.filter((msg) => msg.role !== "system")
.map((msg) => ({
 role: msg.role === "user" ? ("user" as const): ("assistant" as const),
 content: msg.content,
 })),
 ];

 const response = await this.anthropic.messages.create({
 model: this.config.model.id,
 max_tokens: this.config.model.maxTokens,
 temperature: this.config.model.temperature,
 system: this.config.systemPrompt,
 messages,
 });

 const textContent = response.content.find((block) => block.type === "text");
 if (!textContent || textContent.type !== "text") {
 throw new Error("No text content in Claude response");
 }

 return textContent.text;
}

private buildConversationContext: string {
 let context = `[CONVERSATION CONTEXT]\n`;
 context += `Session ID: ${this.sessionId}\n`;
 context += `Current Phase: ${this.state.phase}\n`;
 context += `Questions Asked in Phase: ${this.state.questionCount}\n`;
 context += `Overall Confidence: ${(this.state.confidenceScore * 100).toFixed(0)}%\n\n`;

 context += `[EXTRACTED METRICS]\n`;
 context += JSON.stringify(this.state.extractedMetrics, null, 2) + "\n\n";

 context += `[CONVERSATION FLAGS]\n`;
 context += JSON.stringify(this.state.flags, null, 2) + "\n\n";

 context += `[PHASE GUIDANCE]\n`;
 context += this.getPhaseGuidance + "\n\n`;

 return context;
}
```

**Why this works:**

- Claude maintains awareness of conversation stage
- Extracted metrics guide follow-up questions
- Flags prevent asking redundant questions
- Phase guidance keeps conversation on track

---

## Message Persistence with Prisma

**Pattern**: Store conversation state in database after each message exchange.

**Location**: `lib/melissa/agent.ts`

```typescript
private async saveProgress: Promise<void> {
 try {
 await prisma.session.update({
 where: { id: this.sessionId },
 data: {
 status: this.state.phase === "reporting" ? "completed": "active",
 transcript: JSON.stringify(this.state.transcript),
 metadata: JSON.stringify({
 phase: this.state.phase,
 questionCount: this.state.questionCount,
 extractedMetrics: this.state.extractedMetrics,
 flags: this.state.flags,
 confidenceScore: this.state.confidenceScore,
 }),
 completedAt: this.state.phase === "reporting" ? new Date: null,
 },
 });
 } catch (error) {
 console.error("Error saving session progress:", error);
 // Don't throw - progress save failure shouldn't break the conversation
 }
}
```

**Hydrating state on resume:**

```typescript
private hydrateState(partialState: Partial<ConversationState>): ConversationState {
 return {
...this.initializeState,
...partialState,
 startedAt: partialState.startedAt ? new Date(partialState.startedAt): new Date,
 lastActivityAt: partialState.lastActivityAt ? new Date(partialState.lastActivityAt): new Date,
 };
}

// Usage when agent is created
const existingTranscript = session.transcript ? JSON.parse(session.transcript as string): [];
const existingMetadata = session.metadata ? JSON.parse(session.metadata as string): {};

const agent = await MelissaAgent.create({
 sessionId,
 existingState: {
 transcript: existingTranscript,
 phase: existingMetadata.phase || "greeting",
 questionCount: existingMetadata.questionCount || 0,
 extractedMetrics: existingMetadata.extractedMetrics || {},
 flags: existingMetadata.flags || defaultFlags,
 confidenceScore: existingMetadata.confidenceScore || 0,
 },
});
```

---

## Type-Safe API Route Handler

**Pattern**: Use Zod validation, custom error types, and proper Next.js response handling.

**Location**: `app/api/melissa/chat/route.ts`

```typescript
import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { logger } from "@/lib/logger";

// Custom error types
class ConfigurationError extends Error {
 constructor(message: string) {
 super(message);
 this.name = "ConfigurationError";
 }
}

class DatabaseError extends Error {
 constructor(message: string) {
 super(message);
 this.name = "DatabaseError";
 }
}

class AIServiceError extends Error {
 constructor(message: string) {
 super(message);
 this.name = "AIServiceError";
 }
}

// Request validation schema
const chatRequestSchema = z.object({
 sessionId: z.string.min(1),
 message: z.string.min(1),
});

export async function POST(request: NextRequest) {
 try {
 // 1. Validate environment
 if (!process.env.ANTHROPIC_API_KEY) {
 throw new ConfigurationError(
 "AI service not configured. Please contact support.",
 );
 }

 // 2. Parse and validate request
 const body = await request.json;
 const { sessionId, message } = chatRequestSchema.parse(body);

 // 3. Get or create session
 let session;
 try {
 session = await prisma.session.findUnique({
 where: { id: sessionId },
 include: { responses: true },
 });

 if (!session) {
 session = await prisma.session.create({
 data: {
 id: sessionId,
 status: "active",
 transcript: JSON.stringify([]),
 metadata: JSON.stringify({}),
 },
 });
 }
 } catch (error) {
 throw new DatabaseError(
 "Unable to access session data. Please try again.",
 );
 }

 // 4. Initialize agent
 let agent;
 try {
 agent = await MelissaAgent.create({
 sessionId,
 existingState: { /*... */ },
 });
 } catch (error) {
 throw new AIServiceError(
 "Failed to initialize AI assistant. Please try again.",
 );
 }

 // 5. Process message
 let response;
 try {
 response = await agent.processMessage(message);
 } catch (error) {
 logger.error("AI message processing failed", "api", { sessionId, error });
 throw new AIServiceError(
 "AI assistant is temporarily unavailable. Please try again in a moment.",
 );
 }

 return NextResponse.json(response);
 } catch (error) {
 // Error handling by type
 if (error instanceof z.ZodError) {
 return NextResponse.json(
 {
 error: "Invalid request data",
 details: error.errors,
 retryable: false,
 },
 { status: 400 },
 );
 }

 if (error instanceof ConfigurationError) {
 return NextResponse.json(
 { error: "Configuration Error", message: error.message, retryable: false },
 { status: 503 },
 );
 }

 if (error instanceof DatabaseError) {
 return NextResponse.json(
 { error: "Database Error", message: error.message, retryable: true },
 { status: 503 },
 );
 }

 if (error instanceof AIServiceError) {
 return NextResponse.json(
 { error: "AI Service Error", message: error.message, retryable: true },
 { status: 503 },
 );
 }

 return NextResponse.json(
 { error: "Unexpected Error", retryable: true },
 { status: 500 },
 );
 }
}
```

---

## File Attachments (PDF Documents)

**Pattern**: Support PDF document uploads in conversation (experimental feature).

**Location**: `lib/melissa/agent.ts`

```typescript
// Message type with optional attachments
interface Message {
 id: string;
 role: "user" | "assistant" | "system";
 content: string;
 timestamp: Date;
 attachments?: FileAttachment[];
 metadata?: Record<string, unknown>;
}

interface FileAttachment {
 filename: string;
 mimeType: string;
 size: number;
 base64Data?: string;
}

// Building messages with document blocks
const messages: Anthropic.MessageParam[] = [
...this.state.transcript.map((msg) => {
 // Check if message has file attachments
 if (msg.attachments && msg.attachments.length > 0) {
 // Construct multi-part content with text + documents
 const contentBlocks: Array<
 | Anthropic.TextBlockParam
 | {
 type: "document";
 source: {
 type: "base64";
 media_type: "application/pdf";
 data: string;
 };
 }
 > = [
 {
 type: "text",
 text: msg.content,
 },
 ];

 // Add document blocks for each attachment
 for (const attachment of msg.attachments) {
 if (attachment.base64Data) {
 contentBlocks.push({
 type: "document",
 source: {
 type: "base64",
 media_type: "application/pdf" as const,
 data: attachment.base64Data,
 },
 });
 }
 }

 return {
 role: msg.role === "user" ? ("user" as const): ("assistant" as const),
 content: contentBlocks as any, // Cast for SDK compatibility
 };
 }

 // Text-only message (no attachments)
 return {
 role: msg.role === "user" ? ("user" as const): ("assistant" as const),
 content: msg.content,
 };
 }),
];
```

**Note**: Document support requires `@anthropic-ai/sdk` version with PDF support. this project uses version 0.27.3.

---

## Error Handling Strategy

**Pattern**: Three-tier error handling with specific error types, logging, and user-friendly messages.

```typescript
// 1. Throw specific error types
try {
 const response = await this.anthropic.messages.create({
 /*... */
 });
} catch (error) {
 console.error("Error generating AI response:", error);
 throw new Error("Failed to generate AI response");
}

// 2. Catch and categorize in API route
catch (error) {
 logger.error('Melissa chat request failed', 'api', {
 endpoint: '/api/melissa/chat',
 error: error instanceof Error ? error.message: String(error),
 name: error instanceof Error ? error.name: 'Unknown',
 stack: error instanceof Error ? error.stack: undefined,
 });

 if (error instanceof ConfigurationError) {
 return NextResponse.json(
 { error: "Configuration Error", message: error.message, retryable: false },
 { status: 503 },
 );
 }

 //... other error types
}

// 3. Frontend displays user-friendly message
{response.error && (
 <Alert variant="destructive">
 <AlertDescription>{response.message}</AlertDescription>
 {response.retryable && <Button onClick={retry}>Retry</Button>}
 </Alert>
)}
```

---

## Logging Integration

**Pattern**: Structured logging at key points in the conversation lifecycle.

**Location**: Uses `lib/logger` (debug package + file logging)

```typescript
import { logger } from "@/lib/logger";

// Log file attachments processed
if (fileAttachments.length > 0) {
 logger.info("File attachments processed", "melissa", {
 sessionId,
 fileCount: fileAttachments.length,
 files: fileAttachments.map((f) => ({ name: f.filename, size: f.size })),
 });
}

// Log processing failures
catch (error) {
 logger.error('AI message processing failed', 'api', {
 endpoint: '/api/melissa/chat',
 sessionId,
 error: error instanceof Error ? error.message: String(error),
 stack: error instanceof Error ? error.stack: undefined,
 });
}

// Log database save warnings (non-fatal)
catch (error) {
 logger.warn('Failed to save response to database', 'database', {
 sessionId,
 error: error instanceof Error ? error.message: String(error),
 note: 'Conversation continues despite save failure',
 });
}
```

---

## Metrics Extraction

**Pattern**: Extract business metrics from user messages using a dedicated processor.

**Location**: `lib/melissa/processors/metricsExtractor.ts`

```typescript
export class MetricsExtractor {
 async extract(
 userMessage: string,
 existingMetrics: ExtractedMetrics,
 phase: ConversationPhase,
 ): Promise<ExtractionResult> {
 // Use regex, NLP, or Claude to extract structured data
 const extractionResult = {
 extractedMetrics: {},
 flags: {},
 uncertainties: [],
 };

 // Example: Extract time investment
 const timeMatch = userMessage.match(/(\d+)\s*(hours?|hrs?)/i);
 if (timeMatch) {
 extractionResult.extractedMetrics.timeInvestmentHoursPerWeek =
 parseInt(timeMatch[1]);
 extractionResult.flags.hasTimeInvestment = true;
 }

 // Example: Extract team size
 const teamMatch = userMessage.match(/(\d+)\s*(people|team|members)/i);
 if (teamMatch) {
 extractionResult.extractedMetrics.teamSize = parseInt(teamMatch[1]);
 extractionResult.flags.hasTeamSize = true;
 }

 return extractionResult;
 }
}

// Usage in agent
const extractionResult = await this.metricsExtractor.extract(
 userMessage,
 this.state.extractedMetrics,
 this.state.phase,
);

this.state.extractedMetrics = {
...this.state.extractedMetrics,
...extractionResult.extractedMetrics,
};
```

---

## Progress Tracking

**Pattern**: Calculate progress based on conversation phase and questions asked.

```typescript
private calculateProgress: number {
 const phases = this.config.conversationFlow.phases;
 const currentIndex = phases.indexOf(this.state.phase);
 const phaseProgress = currentIndex / phases.length;
 const withinPhaseProgress =
 this.state.questionCount /
 (this.config.conversationFlow.maxQuestionsPerPhase[this.state.phase] || 5);

 return Math.min(
 100,
 Math.round((phaseProgress + withinPhaseProgress / phases.length) * 100),
 );
}

// Phase transition logic
private shouldTransitionPhase: PhaseTransitionResult {
 const maxQuestions =
 this.config.conversationFlow.maxQuestionsPerPhase[this.state.phase] || 5;

 // Transition if max questions reached
 if (this.state.questionCount >= maxQuestions) {
 const phaseIndex = this.config.conversationFlow.phases.indexOf(this.state.phase);
 const nextPhase = this.config.conversationFlow.phases[phaseIndex + 1];
 if (nextPhase) {
 return {
 shouldTransition: true,
 nextPhase: nextPhase as ConversationPhase,
 reason: "Max questions reached for phase",
 };
 }
 }

 // Phase-specific completion criteria
 switch (this.state.phase) {
 case "greeting":
 if (this.state.flags.hasGreeted && this.state.flags.hasProcessName) {
 return {
 shouldTransition: true,
 nextPhase: "discovery",
 reason: "Initial process identified",
 };
 }
 break;

 case "discovery":
 if (
 this.state.extractedMetrics.processName &&
 this.state.extractedMetrics.processDescription
 ) {
 return {
 shouldTransition: true,
 nextPhase: "metrics",
 reason: "Process understood",
 };
 }
 break;

 //... other phases
 }

 return { shouldTransition: false };
}
```

---

## Testing Patterns

**Pattern**: Mock Anthropic responses in tests to ensure predictable behavior.

```typescript
// __tests__/lib/melissa/agent.test.ts
import { MelissaAgent } from "@/lib/melissa/agent";

jest.mock("@anthropic-ai/sdk", => {
 return {
 __esModule: true,
 default: jest.fn.mockImplementation( => ({
 messages: {
 create: jest.fn.mockResolvedValue({
 content: [
 {
 type: "text",
 text: "Mocked Claude response",
 },
 ],
 usage: {
 input_tokens: 100,
 output_tokens: 50,
 },
 }),
 },
 })),
 };
});

describe("MelissaAgent", => {
 it("should process user message and return response", async => {
 const agent = await MelissaAgent.create({
 sessionId: "test-session",
 });

 const response = await agent.processMessage("I want to optimize invoicing");

 expect(response.message).toBe("Mocked Claude response");
 expect(response.phase).toBe("greeting");
 });
});
```

---

## See Also

- [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) - Fast lookup patterns
- [02-MESSAGES-API.md](./02-MESSAGES-API.md) - Complete Messages API reference
- [/docs/ARCHITECTURE.md](/path/to/project/docs/ARCHITECTURE.md) - System architecture
- [/lib/melissa/agent.ts](/path/to/project/lib/melissa/agent.ts) - Full implementation
