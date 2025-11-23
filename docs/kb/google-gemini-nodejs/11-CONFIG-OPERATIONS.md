---
id: google-gemini-nodejs-11-config-operations
topic: google-gemini-nodejs
file_role: config
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: [google-gemini-fundamentals, google-gemini-performance]
related_topics: [google-gemini, deployment, configuration, monitoring, operations]
embedding_keywords: [google-gemini, deployment, configuration, monitoring, operations, production, security, rate-limits]
last_reviewed: 2025-11-13
---

# Gemini Configuration & Operations

**Purpose**: Production deployment, configuration, monitoring, and operational best practices.

---

## 1. Environment Configuration

### Development Setup

```bash
# .env.local
GOOGLE_AI_API_KEY=your_api_key_here
NODE_ENV=development
LOG_LEVEL=debug
```

```typescript
// lib/config/gemini.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

export const genAI = new GoogleGenerativeAI(
  process.env.GOOGLE_AI_API_KEY || ''
);

export const config = {
  defaultModel: 'gemini-1.5-flash-latest',
  maxTokens: 8192,
  temperature: 0.7,
  topP: 0.95,
  topK: 40,
};
```

---

### Production Setup

```bash
# .env.production
GOOGLE_AI_API_KEY=your_production_key
NODE_ENV=production
LOG_LEVEL=info

# Rate limiting
RATE_LIMIT_RPM=60
RATE_LIMIT_TPM=1000000

# Monitoring
SENTRY_DSN=your_sentry_dsn
DATADOG_API_KEY=your_datadog_key
```

```typescript
// lib/config/gemini.production.ts
export const productionConfig = {
  // Use Flash by default for cost savings
  defaultModel: 'gemini-1.5-flash-latest',

  // Limit output to control costs
  maxOutputTokens: 4096,

  // Retry configuration
  maxRetries: 3,
  retryDelay: 1000,

  // Timeout settings
  timeout: 30000, // 30 seconds

  // Rate limits (adjust based on tier)
  rateLimit: {
    requestsPerMinute: 60,
    tokensPerMinute: 1000000,
  },

  // Monitoring
  enableMetrics: true,
  enableLogging: true,
};
```

---

## 2. Deployment Patterns

### Next.js API Route (Recommended)

```typescript
// app/api/ai/chat/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';
import { NextRequest, NextResponse } from 'next/server';
import { z } from 'zod';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

const RequestSchema = z.object({
  message: z.string().min(1).max(10000),
  model: z.enum(['gemini-1.5-pro-latest', 'gemini-1.5-flash-latest']).optional(),
});

export async function POST(req: NextRequest) {
  try {
    // 1. Validate input
    const body = await req.json();
    const { message, model = 'gemini-1.5-flash-latest' } = RequestSchema.parse(body);

    // 2. Generate response
    const aiModel = genAI.getGenerativeModel({ model });
    const result = await aiModel.generateContent(message);

    // 3. Track usage
    const usage = result.response.usageMetadata;
    console.log('[Gemini]', {
      model,
      inputTokens: usage?.promptTokenCount,
      outputTokens: usage?.candidatesTokenCount,
    });

    return NextResponse.json({
      text: result.response.text(),
      usage,
    });
  } catch (error) {
    console.error('[Gemini Error]', error);
    return NextResponse.json(
      { error: 'Failed to generate response' },
      { status: 500 }
    );
  }
}
```

---

### Serverless (Vercel/Netlify)

```typescript
// api/chat.ts (Vercel Serverless Function)
import { GoogleGenerativeAI } from '@google/generative-ai';

const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);

export default async function handler(req: any, res: any) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    const { message } = req.body;

    const model = genAI.getGenerativeModel({
      model: 'gemini-1.5-flash-latest',
      generationConfig: {
        maxOutputTokens: 2048, // Limit for serverless
      },
    });

    const result = await model.generateContent(message);

    return res.status(200).json({
      text: result.response.text(),
    });
  } catch (error) {
    console.error(error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}
```

---

### Docker Container

```dockerfile
# Dockerfile
FROM node:20-alpine

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm ci --only=production

# Copy application
COPY . .

# Build
RUN npm run build

# Environment variables
ENV NODE_ENV=production
ENV GOOGLE_AI_API_KEY=""

EXPOSE 3000

CMD ["npm", "start"]
```

```yaml
# docker-compose.yml
version: '3.8'
services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - GOOGLE_AI_API_KEY=${GOOGLE_AI_API_KEY}
      - NODE_ENV=production
    restart: unless-stopped
```

---

## 3. API Key Management

### Using Google Cloud Secret Manager

```typescript
import { SecretManagerServiceClient } from '@google-cloud/secret-manager';

const client = new SecretManagerServiceClient();

async function getApiKey(): Promise<string> {
  const [version] = await client.accessSecretVersion({
    name: 'projects/YOUR_PROJECT/secrets/gemini-api-key/versions/latest',
  });

  const apiKey = version.payload?.data?.toString() || '';
  return apiKey;
}

// Cache the key
let cachedApiKey: string | null = null;

export async function getGeminiClient() {
  if (!cachedApiKey) {
    cachedApiKey = await getApiKey();
  }
  return new GoogleGenerativeAI(cachedApiKey);
}
```

---

### Key Rotation Strategy

```typescript
// lib/config/key-rotation.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

class ApiKeyManager {
  private keys: string[] = [];
  private currentIndex = 0;

  constructor(keys: string[]) {
    this.keys = keys;
  }

  // Round-robin key selection
  getClient(): GoogleGenerativeAI {
    const key = this.keys[this.currentIndex];
    this.currentIndex = (this.currentIndex + 1) % this.keys.length;
    return new GoogleGenerativeAI(key);
  }

  // Mark key as invalid
  invalidateKey(key: string) {
    this.keys = this.keys.filter((k) => k !== key);
    if (this.keys.length === 0) {
      throw new Error('No valid API keys remaining');
    }
  }
}

export const keyManager = new ApiKeyManager([
  process.env.GOOGLE_AI_API_KEY_1!,
  process.env.GOOGLE_AI_API_KEY_2!,
  process.env.GOOGLE_AI_API_KEY_3!,
]);
```

---

## 4. Rate Limit Management

### Quota Monitoring

```typescript
// lib/monitoring/quota-tracker.ts
class QuotaTracker {
  private requestCount = 0;
  private tokenCount = 0;
  private windowStart = Date.now();

  private readonly limits = {
    requestsPerMinute: 60, // Adjust based on your tier
    tokensPerMinute: 1000000,
  };

  async checkQuota(): Promise<boolean> {
    const now = Date.now();
    const elapsed = now - this.windowStart;

    // Reset window every minute
    if (elapsed > 60000) {
      this.requestCount = 0;
      this.tokenCount = 0;
      this.windowStart = now;
      return true;
    }

    // Check limits
    if (this.requestCount >= this.limits.requestsPerMinute) {
      console.warn('[Quota] Request limit reached');
      return false;
    }

    if (this.tokenCount >= this.limits.tokensPerMinute) {
      console.warn('[Quota] Token limit reached');
      return false;
    }

    return true;
  }

  trackRequest(tokens: number) {
    this.requestCount++;
    this.tokenCount += tokens;
  }

  getStatus() {
    return {
      requests: {
        used: this.requestCount,
        limit: this.limits.requestsPerMinute,
        percentage: (this.requestCount / this.limits.requestsPerMinute) * 100,
      },
      tokens: {
        used: this.tokenCount,
        limit: this.limits.tokensPerMinute,
        percentage: (this.tokenCount / this.limits.tokensPerMinute) * 100,
      },
    };
  }
}

export const quotaTracker = new QuotaTracker();
```

---

### Usage with API Route

```typescript
// app/api/ai/chat/route.ts
import { quotaTracker } from '@/lib/monitoring/quota-tracker';

export async function POST(req: NextRequest) {
  // Check quota before processing
  if (!(await quotaTracker.checkQuota())) {
    return NextResponse.json(
      { error: 'Rate limit exceeded. Please try again later.' },
      { status: 429 }
    );
  }

  try {
    const result = await model.generateContent(message);
    const usage = result.response.usageMetadata;

    // Track usage
    const totalTokens =
      (usage?.promptTokenCount || 0) +
      (usage?.candidatesTokenCount || 0);

    quotaTracker.trackRequest(totalTokens);

    return NextResponse.json({ text: result.response.text() });
  } catch (error) {
    // Handle error
  }
}
```

---

## 5. Cost Monitoring

### Token Cost Calculator

```typescript
// lib/monitoring/cost-calculator.ts
export const PRICING = {
  'gemini-1.5-pro-latest': {
    input: 1.25 / 1000000,  // $1.25 per 1M tokens
    output: 5.0 / 1000000,   // $5.00 per 1M tokens
  },
  'gemini-1.5-flash-latest': {
    input: 0.075 / 1000000,  // $0.075 per 1M tokens
    output: 0.30 / 1000000,   // $0.30 per 1M tokens
  },
  'text-embedding-004': {
    input: 0.00001 / 1000,   // $0.00001 per 1K tokens
    output: 0,
  },
};

export function calculateCost(
  model: keyof typeof PRICING,
  inputTokens: number,
  outputTokens: number
): number {
  const pricing = PRICING[model];
  return inputTokens * pricing.input + outputTokens * pricing.output;
}

class CostTracker {
  private totalCost = 0;
  private costs: Array<{ timestamp: number; cost: number; model: string }> = [];

  trackUsage(model: keyof typeof PRICING, inputTokens: number, outputTokens: number) {
    const cost = calculateCost(model, inputTokens, outputTokens);
    this.totalCost += cost;
    this.costs.push({ timestamp: Date.now(), cost, model });

    // Log if cost exceeds threshold
    if (this.totalCost > 10) {
      console.warn(`[Cost Alert] Total cost: $${this.totalCost.toFixed(4)}`);
    }
  }

  getTotalCost(): number {
    return this.totalCost;
  }

  getCostBreakdown() {
    const breakdown: Record<string, number> = {};
    this.costs.forEach(({ model, cost }) => {
      breakdown[model] = (breakdown[model] || 0) + cost;
    });
    return breakdown;
  }

  getDailyCost(): number {
    const oneDayAgo = Date.now() - 86400000;
    return this.costs
      .filter((c) => c.timestamp > oneDayAgo)
      .reduce((sum, c) => sum + c.cost, 0);
  }
}

export const costTracker = new CostTracker();
```

---

### Cost Alerting

```typescript
// lib/monitoring/cost-alerts.ts
import { costTracker } from './cost-calculator';

interface AlertConfig {
  dailyLimit: number;
  monthlyLimit: number;
  webhookUrl?: string;
}

export class CostAlerter {
  private config: AlertConfig;
  private alertSent = false;

  constructor(config: AlertConfig) {
    this.config = config;
  }

  async checkLimits() {
    const dailyCost = costTracker.getDailyCost();
    const totalCost = costTracker.getTotalCost();

    if (dailyCost > this.config.dailyLimit && !this.alertSent) {
      await this.sendAlert(`Daily cost limit exceeded: $${dailyCost.toFixed(2)}`);
      this.alertSent = true;
    }

    if (totalCost > this.config.monthlyLimit) {
      await this.sendAlert(`Monthly cost limit exceeded: $${totalCost.toFixed(2)}`);
      // Implement circuit breaker here
    }
  }

  private async sendAlert(message: string) {
    console.error('[Cost Alert]', message);

    if (this.config.webhookUrl) {
      await fetch(this.config.webhookUrl, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text: message }),
      });
    }
  }
}

export const costAlerter = new CostAlerter({
  dailyLimit: 50,
  monthlyLimit: 1000,
  webhookUrl: process.env.SLACK_WEBHOOK_URL,
});
```

---

## 6. Monitoring & Logging

### Structured Logging

```typescript
// lib/monitoring/logger.ts
import pino from 'pino';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: {
    target: 'pino-pretty',
    options: {
      colorize: true,
    },
  },
});

export function logGeminiRequest(data: {
  model: string;
  inputTokens: number;
  outputTokens: number;
  latency: number;
  cost: number;
}) {
  logger.info({
    type: 'gemini_request',
    ...data,
  });
}

export function logGeminiError(error: any, context: Record<string, any>) {
  logger.error({
    type: 'gemini_error',
    error: error.message,
    stack: error.stack,
    ...context,
  });
}
```

---

### Metrics Collection

```typescript
// lib/monitoring/metrics.ts
interface Metric {
  name: string;
  value: number;
  timestamp: number;
  tags: Record<string, string>;
}

class MetricsCollector {
  private metrics: Metric[] = [];

  record(name: string, value: number, tags: Record<string, string> = {}) {
    this.metrics.push({
      name,
      value,
      timestamp: Date.now(),
      tags,
    });
  }

  // Send to monitoring service (Datadog, CloudWatch, etc.)
  async flush() {
    if (this.metrics.length === 0) return;

    try {
      await fetch(process.env.METRICS_ENDPOINT!, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify(this.metrics),
      });

      this.metrics = [];
    } catch (error) {
      console.error('[Metrics] Failed to flush:', error);
    }
  }

  getMetrics() {
    return this.metrics;
  }
}

export const metrics = new MetricsCollector();

// Auto-flush every 60 seconds
setInterval(() => metrics.flush(), 60000);
```

---

### Usage Example

```typescript
import { logger, logGeminiRequest } from '@/lib/monitoring/logger';
import { metrics } from '@/lib/monitoring/metrics';
import { costTracker } from '@/lib/monitoring/cost-calculator';

export async function POST(req: NextRequest) {
  const startTime = Date.now();

  try {
    const result = await model.generateContent(message);
    const usage = result.response.usageMetadata;

    const latency = Date.now() - startTime;
    const cost = costTracker.calculateCost(
      'gemini-1.5-flash-latest',
      usage?.promptTokenCount || 0,
      usage?.candidatesTokenCount || 0
    );

    // Log
    logGeminiRequest({
      model: 'gemini-1.5-flash-latest',
      inputTokens: usage?.promptTokenCount || 0,
      outputTokens: usage?.candidatesTokenCount || 0,
      latency,
      cost,
    });

    // Record metrics
    metrics.record('gemini.request.latency', latency, { model: 'flash' });
    metrics.record('gemini.request.cost', cost, { model: 'flash' });
    metrics.record('gemini.tokens.input', usage?.promptTokenCount || 0);
    metrics.record('gemini.tokens.output', usage?.candidatesTokenCount || 0);

    return NextResponse.json({ text: result.response.text() });
  } catch (error) {
    logGeminiError(error, { message });
    metrics.record('gemini.error', 1, { type: error.constructor.name });
    throw error;
  }
}
```

---

## 7. Health Checks

```typescript
// app/api/health/route.ts
import { GoogleGenerativeAI } from '@google/generative-ai';

export async function GET() {
  const checks = {
    timestamp: new Date().toISOString(),
    status: 'healthy',
    checks: {
      api_key: 'unknown',
      gemini_api: 'unknown',
    },
  };

  try {
    // Check API key
    if (process.env.GOOGLE_AI_API_KEY) {
      checks.checks.api_key = 'ok';
    } else {
      checks.checks.api_key = 'missing';
      checks.status = 'unhealthy';
    }

    // Check Gemini API connectivity
    const genAI = new GoogleGenerativeAI(process.env.GOOGLE_AI_API_KEY!);
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash-latest' });

    await model.generateContent('ping');
    checks.checks.gemini_api = 'ok';
  } catch (error) {
    checks.checks.gemini_api = 'error';
    checks.status = 'unhealthy';
  }

  const statusCode = checks.status === 'healthy' ? 200 : 503;
  return Response.json(checks, { status: statusCode });
}
```

---

## 8. Production Checklist

### Pre-Deployment

- [ ] API keys configured in environment variables
- [ ] API keys stored in secret manager (not hardcoded)
- [ ] Rate limiting implemented
- [ ] Error handling with retries
- [ ] Timeout configuration set
- [ ] Input validation with Zod
- [ ] Cost tracking enabled
- [ ] Logging configured
- [ ] Metrics collection setup
- [ ] Health check endpoint implemented

---

### Security

- [ ] API keys never logged
- [ ] API keys never exposed to client
- [ ] HTTPS enforced
- [ ] CORS configured properly
- [ ] Rate limiting per user/IP
- [ ] Input sanitization
- [ ] Output validation
- [ ] SQL injection prevention (use Prisma)
- [ ] XSS prevention

---

### Performance

- [ ] Default to Flash model (cheaper)
- [ ] Set maxOutputTokens limit
- [ ] Enable caching for embeddings
- [ ] Implement conversation trimming
- [ ] Use streaming for long responses
- [ ] Parallel requests where possible
- [ ] Monitor token usage

---

### Monitoring

- [ ] Error tracking (Sentry, Datadog)
- [ ] Usage metrics collection
- [ ] Cost alerts configured
- [ ] Latency monitoring
- [ ] Health check monitoring
- [ ] Log aggregation setup
- [ ] Quota monitoring

---

## 9. Best Practices

### ✅ DO

- Use environment variables for API keys
- Implement comprehensive error handling
- Monitor costs and set alerts
- Use Flash model by default
- Cache embeddings and responses
- Log all errors with context
- Set timeouts on all requests
- Validate all inputs
- Use structured logging
- Implement health checks

### ❌ DON'T

- Don't hardcode API keys
- Don't log API keys or sensitive data
- Don't use Pro when Flash suffices
- Don't ignore rate limits
- Don't skip input validation
- Don't expose raw errors to users
- Don't deploy without monitoring
- Don't forget to set maxOutputTokens

---

## AI Pair Programming Notes

**Key Takeaways**:
1. Always use environment variables for API keys
2. Implement cost tracking and alerts
3. Monitor rate limits and quotas
4. Use structured logging and metrics
5. Default to Flash model for cost savings
6. Set maxOutputTokens to prevent runaway costs
7. Implement health checks for production
8. Use secret managers for key storage

---

**This completes the Gemini Knowledge Base. See [INDEX.md](INDEX.md) for navigation.**
