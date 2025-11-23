---
id: anthropic-sdk-typescript-01-installation-setup
topic: anthropic-sdk-typescript
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [anthropic-sdk-typescript-basics]
related_topics: ['anthropic-sdk-typescript']
embedding_keywords: [anthropic-sdk-typescript]
last_reviewed: 2025-11-13
---

# Anthropic SDK TypeScript - Installation & Setup

Complete guide to installing and configuring the Anthropic SDK in TypeScript projects.

---

## Table of Contents

1. [Prerequisites](#prerequisites)
2. [Installation](#installation)
3. [Environment Variables](#environment-variables)
4. [TypeScript Configuration](#typescript-configuration)
5. [Client Initialization](#client-initialization)
6. [Multiple Client Instances](#multiple-client-instances)
7. [Configuration Options](#configuration-options)
8. [Timeout Settings](#timeout-settings)
9. [Custom Headers](#custom-headers)
10. [Validation & Testing](#validation--testing)

---

## Prerequisites

**Required:**

- Node.js >= 18.0.0
- TypeScript >= 4.5.0
- npm or yarn or pnpm

**Recommended:**

- Next.js 14+ if building web applications
- Prisma for database integration

---

## Installation

### Using npm

```bash
npm install @anthropic-ai/sdk
```

### Using yarn

```bash
yarn add @anthropic-ai/sdk
```

### Using pnpm

```bash
pnpm add @anthropic-ai/sdk
```

### Current Stable Version

```json
{
 "dependencies": {
 "@anthropic-ai/sdk": "0.27.3"
 }
}
```

### Verify Installation

```bash
npm list @anthropic-ai/sdk
```

Expected output:

```
└── @anthropic-ai/sdk@0.27.3
```

---

## Environment Variables

### Required Variable

Create a `.env.local` file in your project root:

```bash
ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
```

### Getting Your API Key

1. Visit [console.anthropic.com](https://console.anthropic.com/)
2. Navigate to **API Keys** section
3. Click **Create Key**
4. Copy the key (starts with `sk-ant-api03-`)
5. Store securely in `.env.local`

**IMPORTANT**: Never commit `.env.local` to version control.

### Environment File Structure

```bash
#.env.local (local development - never commit)
ANTHROPIC_API_KEY="sk-ant-api03-actual-key-here"

#.env.example (template - safe to commit)
ANTHROPIC_API_KEY="sk-ant-api03-your-key-here"
```

### Example Full Application Setup

```bash
#.env.local
# AI/ML
ANTHROPIC_API_KEY="sk-ant-api03-xxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# Application
NEXTAUTH_SECRET="your-secret-here"
NEXTAUTH_URL="http://localhost:3000"

# Database
DATABASE_URL="file:./dev.db?mode=wal"

# Logging
LOG_LEVEL="info"
DEBUG="app:*"
NODE_OPTIONS="--max-old-space-size=4096 --enable-source-maps"
```

---

## TypeScript Configuration

### Recommended `tsconfig.json`

```json
{
 "compilerOptions": {
 "target": "ES2020",
 "lib": ["ES2020", "DOM", "DOM.Iterable"],
 "module": "esnext",
 "moduleResolution": "bundler",
 "strict": true,
 "noImplicitAny": true,
 "strictNullChecks": true,
 "esModuleInterop": true,
 "skipLibCheck": true,
 "forceConsistentCasingInFileNames": true,
 "resolveJsonModule": true,
 "isolatedModules": true,
 "jsx": "preserve",
 "incremental": true,
 "paths": {
 "@/*": ["./*"]
 }
 },
 "include": ["**/*.ts", "**/*.tsx"],
 "exclude": ["node_modules"]
}
```

### Type Imports

The SDK provides full TypeScript types:

```typescript
import Anthropic from "@anthropic-ai/sdk";
import type {
 Message,
 MessageParam,
 ContentBlock,
 TextBlock,
 MessageCreateParams,
 MessageStreamEvent,
} from "@anthropic-ai/sdk/resources/messages";
```

### Type Checking

```bash
# Run TypeScript compiler without emitting files
npx tsc --noEmit
```

This catches type errors before runtime.

---

## Client Initialization

### Basic Initialization

```typescript
import Anthropic from "@anthropic-ai/sdk";

const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
});
```

### With Validation (Recommended)

```typescript
import Anthropic from "@anthropic-ai/sdk";

const apiKey = process.env.ANTHROPIC_API_KEY;
if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY environment variable is required");
}

const anthropic = new Anthropic({ apiKey });
```

### Class-Based Initialization Pattern

```typescript
// lib/ai/agent.ts
export class AIAgent {
 private anthropic: Anthropic;

 private constructor(options: AgentOptions) {
 const apiKey = process.env.ANTHROPIC_API_KEY;
 if (!apiKey) {
 throw new Error("ANTHROPIC_API_KEY environment variable is required");
 }

 this.anthropic = new Anthropic({ apiKey });
 }
}
```

### Next.js API Route Initialization

```typescript
// app/api/chat/route.ts
import { NextRequest, NextResponse } from "next/server";
import Anthropic from "@anthropic-ai/sdk";

export async function POST(request: NextRequest) {
 // Validate environment
 if (!process.env.ANTHROPIC_API_KEY) {
 return NextResponse.json(
 { error: "AI service not configured" },
 { status: 503 },
 );
 }

 const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 });

 //... rest of handler
}
```

---

## Multiple Client Instances

### Scenario: Different Configurations per Use Case

```typescript
import Anthropic from "@anthropic-ai/sdk";

// High-temperature creative client
const creativeClient = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 defaultHeaders: { "X-Context": "creative" },
});

// Low-temperature analytical client
const analyticalClient = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 defaultHeaders: { "X-Context": "analytical" },
});

// Usage
const creativeResponse = await creativeClient.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.9,
 messages: [{ role: "user", content: "Write a poem" }],
});

const analyticalResponse = await analyticalClient.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 temperature: 0.2,
 messages: [{ role: "user", content: "Analyze this data" }],
});
```

### Scenario: Multi-Tenant Application

```typescript
class AIService {
 private clients: Map<string, Anthropic> = new Map;

 getClient(organizationId: string): Anthropic {
 if (!this.clients.has(organizationId)) {
 const apiKey = this.getOrgAPIKey(organizationId);
 this.clients.set(organizationId, new Anthropic({ apiKey }));
 }
 return this.clients.get(organizationId)!;
 }

 private getOrgAPIKey(organizationId: string): string {
 // Fetch from database or secrets manager
 return process.env.ANTHROPIC_API_KEY!;
 }
}
```

---

## Configuration Options

### Complete Configuration Object

```typescript
const anthropic = new Anthropic({
 // Required
 apiKey: process.env.ANTHROPIC_API_KEY,

 // Optional
 baseURL: "https://api.anthropic.com", // Custom base URL (rarely needed)
 timeout: 60000, // Request timeout in milliseconds (default: 60000)
 maxRetries: 2, // Number of retries on failure (default: 2)
 defaultHeaders: {
 "X-Custom-Header": "value",
 },
 defaultQuery: {
 // Custom query parameters (advanced use)
 },
});
```

### Configuration Reference Table

| Option | Type | Default | Description |
| ---------------- | -------------------- | ----------------------------- | ----------------------------------------- |
| `apiKey` | `string` | **Required** | Your Anthropic API key |
| `baseURL` | `string` | `https://api.anthropic.com` | Base URL for API requests |
| `timeout` | `number` | `600000` (10 minutes) | Request timeout in milliseconds |
| `maxRetries` | `number` | `2` | Max retry attempts for failed requests |
| `defaultHeaders` | `Record<string, string>` | `{}` | Headers sent with every request |
| `defaultQuery` | `Record<string, string>` | `{}` | Query params sent with every request |

---

## Timeout Settings

### Default Timeout

The SDK uses a 10-minute default timeout (600,000ms).

### Custom Timeout

```typescript
// 30-second timeout
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 timeout: 30000,
});
```

### Per-Request Timeout

```typescript
// Override timeout for specific request
const response = await anthropic.messages.create(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 },
 {
 timeout: 15000, // 15 seconds for this request only
 },
);
```

### Handling Timeout Errors

```typescript
import Anthropic from "@anthropic-ai/sdk";

try {
 const response = await anthropic.messages.create({
 /*... */
 });
} catch (error) {
 if (error instanceof Anthropic.APIConnectionTimeoutError) {
 console.error("Request timed out:", error.message);
 // Retry or return user-friendly error
 }
}
```

---

## Custom Headers

### Authentication Headers

The API key is automatically added via `x-api-key` header. You don't need to add it manually.

### Custom Metadata Headers

```typescript
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 defaultHeaders: {
 "X-User-ID": "user-123",
 "X-Organization-ID": "org-456",
 "X-Environment": "production",
 },
});
```

### Per-Request Headers

```typescript
const response = await anthropic.messages.create(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: [{ role: "user", content: "Hello" }],
 },
 {
 headers: {
 "X-Request-ID": "req-789",
 },
 },
);
```

### Example: Session Tracking

```typescript
const response = await anthropic.messages.create(
 {
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 1000,
 messages: messages,
 },
 {
 headers: {
 "X-Session-ID": sessionId,
 "X-Organization-ID": organizationId,
 "X-User-ID": userId,
 },
 },
);
```

---

## Validation & Testing

### Test Connection

```typescript
// test-connection.ts
import Anthropic from "@anthropic-ai/sdk";

async function testConnection {
 try {
 const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 });

 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 100,
 messages: [{ role: "user", content: "Say hello" }],
 });

 console.log("✅ Connection successful!");
 console.log("Response:", response.content[0]);
 console.log("Token usage:", response.usage);
 } catch (error) {
 console.error("❌ Connection failed:", error);
 throw error;
 }
}

testConnection;
```

Run:

```bash
npx tsx test-connection.ts
```

### Validate Environment

```typescript
// validate-env.ts
function validateEnvironment {
 const required = ["ANTHROPIC_API_KEY"];

 const missing = required.filter((key) => !process.env[key]);

 if (missing.length > 0) {
 console.error("❌ Missing required environment variables:");
 missing.forEach((key) => console.error(` - ${key}`));
 process.exit(1);
 }

 console.log("✅ All required environment variables are set");
}

validateEnvironment;
```

### Mock Client for Tests

```typescript
// __tests__/setup.ts
jest.mock("@anthropic-ai/sdk", => {
 return {
 __esModule: true,
 default: jest.fn.mockImplementation( => ({
 messages: {
 create: jest.fn.mockResolvedValue({
 content: [{ type: "text", text: "Mocked response" }],
 usage: { input_tokens: 10, output_tokens: 5 },
 }),
 },
 })),
 };
});
```

### Integration Test

```typescript
// __tests__/integration/anthropic.test.ts
import Anthropic from "@anthropic-ai/sdk";

describe("Anthropic Integration", => {
 it("should create message successfully", async => {
 const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 });

 const response = await anthropic.messages.create({
 model: "claude-sonnet-4-5-20250929",
 max_tokens: 100,
 messages: [{ role: "user", content: "Test message" }],
 });

 expect(response.content[0].type).toBe("text");
 expect(response.usage.input_tokens).toBeGreaterThan(0);
 });
});
```

---

## Common Setup Issues

### Issue: "ANTHROPIC_API_KEY is not defined"

**Solution**:

1. Verify `.env.local` exists in project root
2. Restart dev server after adding environment variables
3. Check variable name spelling (case-sensitive)

### Issue: "Invalid API key"

**Solution**:

1. Verify key starts with `sk-ant-api03-`
2. Check for trailing spaces in `.env.local`
3. Regenerate key in console.anthropic.com if needed

### Issue: TypeScript errors "Cannot find module '@anthropic-ai/sdk'"

**Solution**:

```bash
# Regenerate node_modules and types
rm -rf node_modules package-lock.json
npm install
```

### Issue: Network timeouts in development

**Solution**:

```typescript
// Increase timeout for development
const anthropic = new Anthropic({
 apiKey: process.env.ANTHROPIC_API_KEY,
 timeout: 120000, // 2 minutes
});
```

---

## Next Steps

Once setup is complete:

1. **Learn the Messages API**: [02-MESSAGES-API.md](./02-MESSAGES-API.md)
2. **See Integration Patterns**: [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md)
3. **Quick Reference**: [QUICK-REFERENCE.md](./QUICK-REFERENCE.md)

---

## See Also

- [Official SDK Documentation](https://github.com/anthropics/anthropic-sdk-typescript)
- [Anthropic API Reference](https://docs.anthropic.com/claude/reference)
