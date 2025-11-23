# Appmelia Bloom - Technical Architecture Report

**Document Version:** 1.0
**Last Updated:** November 16, 2025
**Status:** Comprehensive Technical Documentation

---

## Executive Summary

Appmelia Bloom is a Next.js 16 application implementing an AI-guided ROI discovery workshop. The architecture is built on modern web technologies with a focus on type safety, developer experience, and maintainability. The system uses SQLite with WAL mode for development, with a clear migration path to PostgreSQL for production.

**Tech Stack Snapshot:**
- **Framework:** Next.js 16.0.1 (App Router, React 19.2.0)
- **Language:** TypeScript 5.9.3 (strict mode)
- **Database:** SQLite (WAL mode) + Prisma 5.22.0
- **AI/ML:** Anthropic Claude Sonnet 4.5 (via Vercel AI SDK)
- **UI:** shadcn/ui + Radix UI + Tailwind CSS 3.4
- **State:** Zustand with persistence middleware
- **Testing:** Jest + Playwright 1.56.1
- **Logging:** Unified file-first logging with background database ingestion

---

## Architecture Report Summary

This document is a comprehensive technical reference (1,768 lines) covering all architectural decisions, patterns, and implementation details for Appmelia Bloom.

### 📋 Key Sections:

1. **Application Architecture** - Next.js 16 App Router structure, Server/Client components, API patterns, async params breaking change
2. **Data Layer** - Prisma schema with 40+ models (Session, Response, ROIReport, MelissaPersona, ChatProtocol, Playbooks, etc.), SQLite WAL mode for dev
3. **AI/LLM Integration** - MelissaAgent state machine, Persona-Protocol-Playbook composition system, Multi-LLM profiles (Phase 9), Tool calling (Phase 10)
4. **Business Logic** - ROI Calculator (NPV, IRR, Payback, TCO), Confidence scoring, Sensitivity analysis
5. **Caching** - Idempotency cache (in-memory), future Redis migration
6. **State Management** - Zustand stores with ephemeral→active session state machine
7. **UI Architecture** - Component organization, Dark mode (semantic vars + explicit classes), Settings tabs, Monitoring dashboard
8. **Security** - Cookie-based edit keys with JWT, Zod validation, Audit logging
9. **Logging & Monitoring** - Unified file-first logger, SSE streaming, 8 health metric cards
10. **Testing** - Jest + Playwright configurations, per-worker databases

### 🔐 6 Architecture Decision Records (ADRs):

- **ADR-001:** SQLite WAL mode for development
- **ADR-002:** Next.js 16 async params pattern
- **ADR-003:** Ephemeral→Active session state machine
- **ADR-004:** File-first logging architecture
- **ADR-005:** Multi-LLM profile system
- **ADR-006:** In-memory idempotency cache

### 📊 Document Coordination:

This architecture document is synchronized with **Bloom-PRD-v10-MVP-v1.0.md** (product requirements). When one updates, the other should be reviewed for consistency. The PRD captures **what** we're building; this document explains **how**.

---

## Table of Contents

1. [Application Architecture](#1-application-architecture)
2. [Data Layer](#2-data-layer)
3. [AI/LLM Integration](#3-aillm-integration---melissaai-architecture)
4. [Business Logic](#4-business-logic---roi-calculation-engine)
5. [Caching Architecture](#5-caching-architecture)
6. [State Management](#6-state-management)
7. [UI Architecture](#7-ui-architecture)
8. [Security & Authentication](#8-security--authentication)
9. [Logging & Monitoring](#9-logging--monitoring)
10. [Testing Infrastructure](#10-testing-infrastructure)
11. [Technical Architecture Diagrams](#11-technical-architecture-diagrams)
12. [Complete API Endpoint Specifications](#12-complete-api-endpoint-specifications)
13. [Detailed Prisma Schema](#13-detailed-prisma-schema)
14. [Melissa.ai Agent Specification](#14-melissaai-agent-specification)
15. [ROI Calculation Engine](#15-roi-calculation-engine)
16. [UI/UX Component Library](#16-uiux-component-library)
17. [Docker Configuration & Deployment](#17-docker-configuration--deployment)
18. [Security & Compliance Strategy](#18-security--compliance-strategy)
19. [Performance Requirements & Optimization](#19-performance-requirements--optimization)
20. [Summary & Key Decisions](#summary--key-architectural-decisions)

---

## 1. Application Architecture

### **Next.js 16 App Router Structure**

The application uses Next.js 16's App Router with a clear separation between routes, API endpoints, and UI components:

```
app/
├── (auth)/              # Auth-protected routes (future)
├── (demo)/              # Demo/sandbox routes
├── api/                 # API routes (70+ endpoints)
│   ├── sessions/        # Session management (CRUD + lifecycle)
│   ├── melissa/         # AI chat endpoint
│   ├── admin/           # Admin operations (tasks, backup, config)
│   ├── system/          # System health, metrics, logs
│   └── settings/        # User preferences, dashboard layout
├── workshop/            # Main workshop interface
├── settings/            # Settings UI with tabs
├── sessions/            # Session browser
├── runs/                # Playbook run viewer
└── layout.tsx           # Root layout with providers
```

### **Server vs Client Components**

**Strategic Use of Server Components (Default):**
- API routes are always server-side
- Page layouts use Server Components for initial data fetching
- Static pages (terms, privacy, help) are Server Components

**Client Components (Explicit `"use client"`):**
- Interactive UI: Chat interface, forms, modals
- State management: Zustand stores
- Real-time features: SSE log streaming
- Third-party integrations: Monaco Editor, React Query

**Example - Root Layout** (Server Component with Client Providers):

```typescript
// app/layout.tsx
export default function RootLayout({ children }) {
  return (
    <html suppressHydrationWarning>
      <body>
        <QueryProvider>              {/* Client Provider */}
          <ThemeProvider>            {/* Client Provider */}
            <BrandingProvider>       {/* Client Provider */}
              <LayoutClient>         {/* Client Component */}
                {children}
              </LayoutClient>
            </BrandingProvider>
          </ThemeProvider>
        </QueryProvider>
      </body>
    </html>
  );
}
```

### **API Route Patterns**

**Next.js 16 Breaking Change - Async Params:**

All dynamic routes must await params (breaking change from Next.js 15):

```typescript
// ✅ CORRECT (Next.js 16)
export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params; // Must await Promise
  // ...
}

// ❌ WRONG (Next.js 14/15)
export async function GET(
  request: NextRequest,
  { params }: { params: { id: string } }
) {
  const { id } = params; // Error: params is Promise
}
```

**Standard API Route Structure:**

```typescript
export async function POST(request: NextRequest) {
  try {
    // 1. Parse & validate input with Zod
    const body = await request.json();
    const data = schema.parse(body);

    // 2. Business logic
    const result = await service.process(data);

    // 3. Return response
    return NextResponse.json(result);
  } catch (error) {
    // 4. Error handling with appropriate status codes
    if (error instanceof z.ZodError) {
      return NextResponse.json({ error: "Validation failed" }, { status: 400 });
    }
    // ...
  }
}
```

### **Middleware & Instrumentation**

**No middleware.ts file** - Authentication and rate limiting are handled at the API route level rather than global middleware.

**Future Consideration:** Add middleware for:
- Global rate limiting
- CORS headers
- Request logging
- Authentication checks

---

## 2. Data Layer

### **Prisma Schema - Comprehensive Overview**

The Prisma schema contains **40+ models** organized into logical domains:

**Core Models:**
- `Organization` (1) → `User` (many) → `Session` (many)
- `Session` → `Response` (many), `ROIReport` (one), `ReportExport` (many)

**Key Schema Highlights:**

```prisma
model Session {
  id             String         @id @default(cuid())
  userId         String?
  user           User?          @relation(...)
  organizationId String?
  organization   Organization?  @relation(...)

  // Session lifecycle
  status         String         @default("active")
  startedAt      DateTime       @default(now())
  completedAt    DateTime?

  // Conversation data
  transcript     String?        // JSON conversation log
  metadata       String?        // JSON { phase, metrics, flags }
  answers        String?        // JSON { [questionId]: value }

  // Context fields (FRD v1.1)
  customerName     String?
  customerIndustry String?
  employeeCount    Int?
  problemStatement String?
  department       String?
  sessionTitle     String?
  // ... 10+ context fields

  // Browser-based authentication (POC)
  editKey      String?        // Signed UUID for PATCH auth
  lastEditedAt String?

  // Relations
  responses      Response[]
  roiReport      ROIReport?
  memory         SessionMemory?
  instructions   SessionInstructions?
  files          SessionFile[]

  @@index([userId, status])
  @@index([customerName])
  @@index([problemStatement])
}
```

**Melissa Playbook System (Phase 8):**

```prisma
model MelissaPersona {
  // Persona definition (who Melissa is)
  baseTone         String
  cognitionPrimary String
  curiosityModes   String  // CSV: "why,how,what-if"
  explorationLevel Int     @default(50)
}

model ChatProtocol {
  // Behavioral rules (how Melissa asks questions)
  oneQuestionMode Boolean @default(true)
  maxQuestions    Int     @default(25)
  driftSoftLimit  Int     @default(3)
  strictPhases    Boolean @default(false)
}

model PlaybookSource {
  // Human-authored playbook (Markdown)
  markdown    String
  personaId   String?
  protocolId  String?
}

model PlaybookCompiled {
  // Runtime-ready specification (JSON)
  runtimeSpec   String?  // MelissaPlaybookRuntimeSpec
  phaseMap      String   // Phase definitions
  questions     String   // Question bank
  scoringModel  String?  // ROI scoring logic
}

model Run {
  // Execution instance of a playbook
  playbookId String
  outcome    String?  // completed|failed|cancelled
  steps      RunStep[]
  artifacts  Artifact[]
  logs       TxLog[]
  roiReport  ROIReport?
}
```

**Security Models:**

```prisma
model AuditLog {
  userId    String
  action    String  // LOGIN, LOGOUT, CREATE, UPDATE, REPORT_GENERATED
  details   String? // JSON
  ipAddress String?
  timestamp DateTime @default(now())
}

model APIKey {
  key            String  @unique  // SHA-256 hashed
  organizationId String
  permissions    String  // JSON array
  lastUsedAt     DateTime?
  revokedAt      DateTime?
}

model EncryptedData {
  dataType       String  // pii, financial, health
  encryptedValue String  // AES-256
  iv             String  // Initialization vector
  keyVersion     Int     // For key rotation
}
```

### **Database Configuration - SQLite WAL Mode**

**Current Setup:**
```env
DATABASE_URL="file:./bloom.db?mode=wal"
```

**WAL (Write-Ahead Logging) Benefits:**
- 30-50% better concurrent read/write performance
- Atomic commits with better crash recovery
- Industry-standard SQLite configuration
- Handles concurrent session creation with retry logic

**WAL Files:**
- `bloom.db` - Main database file
- `bloom.db-wal` - Write-ahead log (temporary buffer)
- `bloom.db-shm` - Shared memory index

**Migration Path:**
- Development: SQLite WAL (current)
- Production: PostgreSQL 16 (planned for >1000 concurrent users)

**Architecture Decision Record (ADR-001):**
- **Decision:** Use SQLite WAL mode for development
- **Rationale:** Simplicity, zero configuration, sufficient for POC
- **Consequences:** Single-instance deployment, migrate to PostgreSQL for scale
- **Status:** Accepted

### **Data Access Patterns**

**Prisma Client Usage:**

```typescript
// Always use Prisma - NO raw SQL
import { prisma } from "@/lib/db/client";

// Standard pattern: Select only needed fields
const session = await prisma.session.findUnique({
  where: { id },
  select: {
    id: true,
    status: true,
    transcript: true,
    // Don't select unused fields
  },
});

// Transactions for multi-table operations
await prisma.$transaction(async (tx) => {
  const session = await tx.session.create({ /* ... */ });
  await tx.response.create({ /* ... */ });
  await tx.roiReport.create({ /* ... */ });
});

// Pagination with cursor
const sessions = await prisma.session.findMany({
  take: 20,
  skip: 0,
  orderBy: { startedAt: 'desc' },
  cursor: lastId ? { id: lastId } : undefined,
});
```

---

## 3. AI/LLM Integration - Melissa.ai Architecture

### **Agent Core - Multi-Phase Conversation State Machine**

The `MelissaAgent` class orchestrates the AI-guided ROI discovery conversation:

```typescript
// lib/melissa/agent.ts
export class MelissaAgent {
  private state: ConversationState;
  private runtimeSpec?: MelissaPlaybookRuntimeSpec;

  // Phase 9: Multi-LLM Profile System
  static async create(options: MelissaAgentOptions): Promise<MelissaAgent> {
    const config = await getMelissaConfig(organizationId);
    const agent = new MelissaAgent(options, config);

    // Phase 2: Load runtime spec (spec-driven behavior)
    if (process.env.ENABLE_MELISSA_RUNTIME_SPEC === 'true' && options.playbookSlug) {
      agent.runtimeSpec = await loadRuntimeSpecBySlug(options.playbookSlug);
    }

    return agent;
  }

  async processMessage(userMessage: string, attachments?: FileAttachment[]): Promise<ResponseData> {
    // 1. Extract metrics from user message
    const extractionResult = await this.metricsExtractor.extract(userMessage, ...);

    // 2. Update conversation state
    this.state.extractedMetrics = { ...this.state.extractedMetrics, ...extractionResult };

    // 3. Generate AI response (via LLM profile system)
    const aiResponse = await this.generateAIResponse(userMessage);

    // 4. Check for phase transition (spec-driven or hardcoded)
    const transition = this.shouldTransitionPhase();
    if (transition.shouldTransition) {
      this.state.phase = transition.nextPhase;
    }

    // 5. Calculate ROI if ready
    if (this.state.phase === "calculation" && this.state.flags.hasAutomationEstimate) {
      await this.calculateROI();
    }

    // 6. Save progress to database
    await this.saveProgress();

    return { message: aiResponse, phase, progress, confidence, ... };
  }
}
```

**Conversation Phases:**

```typescript
type ConversationPhase =
  | "greeting"       // Welcome, explain process
  | "discovery"      // Understand business process
  | "metrics"        // Gather quantitative data
  | "validation"     // Validate assumptions
  | "calculation"    // Compute ROI
  | "reporting";     // Present results
```

### **Prompt Building System**

**Persona-Protocol-Playbook Composition:**

```typescript
// lib/melissa/promptBuilder.ts
export function buildPrompt(params: {
  persona: MelissaPersona;     // Who Melissa is
  protocol: ChatProtocol;      // How she behaves
  playbook: PlaybookCompiled;  // What she asks
  ctx: SessionContext;         // Conversation state
  question: { id, text, phase };
}): string {
  return `
=================================================================
SYSTEM CONTEXT
=================================================================

# Persona: ${persona.name}
- Base Tone: ${persona.baseTone}
- Cognition: ${persona.cognitionPrimary}
- Curiosity: ${deserializeCuriosityModes(persona.curiosityModes).join(', ')}
- Exploration Level: ${persona.explorationLevel}/100

# Protocol: ${protocol.name}
- One Question Mode: ${protocol.oneQuestionMode ? 'ENABLED' : 'disabled'}
- Max Questions: ${protocol.maxQuestions}
- Drift Limits: ${protocol.driftSoftLimit}/${protocol.driftHardLimit}

=================================================================
PLAYBOOK CONTEXT
=================================================================

# Playbook: ${playbook.name}
Category: ${playbook.category}
Objective: ${playbook.objective}

=================================================================
SESSION STATE
=================================================================

Current Phase: ${ctx.currentPhase}
Questions Asked: ${ctx.totalQuestionsAsked}/${protocol.maxQuestions}
Drift Counter: ${ctx.driftCount || 0}

=================================================================
CURRENT TASK
=================================================================

Question to Ask: "${question.text}"
Phase: ${question.phase}
Type: ${question.type || 'free_text'}

⚠️ ONE QUESTION MODE ACTIVE:
- Ask ONLY the question above
- Do NOT ask multiple questions
- Wait for user response
  `;
}
```

### **Multi-LLM Profile System (Phase 9)**

**Flexible Provider/Model Routing:**

```typescript
// lib/melissa/llm.ts
export async function callMelissaLLM(options: {
  profileId: string;         // 'melissa-default', 'melissa-sonnet-4', etc.
  systemPrompt: string;
  messages: MelissaLLMMessage[];
  temperature?: number;
  maxTokens?: number;
  tools?: ToolDefinition[]; // Phase 10: Tool calling
  toolContext?: any;
}): Promise<{ content: string; toolCalls?: ToolCall[] }> {
  const profile = getProfileById(options.profileId);

  // Build Anthropic messages format
  const anthropicMessages = options.messages.map(msg => {
    if (msg.content is Array) {
      // Multi-part content (text + documents)
      return {
        role: msg.role,
        content: msg.content.map(block => {
          if (block.type === 'document') {
            return {
              type: 'document',
              source: {
                type: 'base64',
                media_type: 'application/pdf',
                data: block.source.data,
              },
            };
          }
          return { type: 'text', text: block.text };
        }),
      };
    }
    return { role: msg.role, content: msg.content };
  });

  // Call Anthropic API with tool support
  const response = await anthropic.messages.create({
    model: profile.model,
    max_tokens: options.maxTokens || profile.maxTokens,
    temperature: options.temperature ?? profile.temperature,
    system: options.systemPrompt,
    messages: anthropicMessages,
    tools: options.tools || [],
  });

  // Extract tool calls if present
  const toolCalls = extractToolCalls(response);

  return {
    content: extractTextContent(response),
    toolCalls,
  };
}
```

**Profile Configuration:**

```typescript
const LLM_PROFILES: Record<string, LLMProfile> = {
  'melissa-default': {
    provider: 'anthropic',
    model: 'claude-sonnet-4-5-20250929',
    temperature: 0.7,
    maxTokens: 1000,
    description: 'Balanced conversational agent',
  },
  'melissa-analytical': {
    provider: 'anthropic',
    model: 'claude-opus-4-20250514',
    temperature: 0.3,
    maxTokens: 2000,
    description: 'Deep analysis and data extraction',
  },
};
```

### **Tool Calling Integration (Phase 10)**

**Tool Definition & Execution:**

```typescript
// lib/melissa/tools.ts
export function getToolsForPhase(phase: ConversationPhase): ToolDefinition[] {
  if (phase === 'calculation' || phase === 'reporting') {
    return [
      {
        name: 'calculate_roi',
        description: 'Calculate ROI metrics from extracted data',
        input_schema: {
          type: 'object',
          properties: {
            totalBenefit: { type: 'number' },
            totalCost: { type: 'number' },
            timeframe: { type: 'number' },
          },
          required: ['totalBenefit', 'totalCost', 'timeframe'],
        },
      },
      {
        name: 'generate_report',
        description: 'Generate executive ROI report',
        input_schema: { /* ... */ },
      },
    ];
  }
  return [];
}

// Tool execution
export async function executeToolCall(
  toolName: string,
  toolInput: any,
  context: ToolContext
): Promise<ToolResult> {
  const handler = toolHandlers[toolName];
  if (!handler) {
    throw new Error(`Unknown tool: ${toolName}`);
  }

  return await handler(toolInput, context);
}
```

### **Context Management**

**Session Context Loading:**

```typescript
// lib/melissa/context-loader.ts
export async function loadBloomContext(
  sessionId: string,
  organizationId?: string
): Promise<BloomContext | null> {
  // Load session-specific context (Memory, Instructions, Files)
  const [memory, instructions, files] = await Promise.all([
    prisma.sessionMemory.findUnique({ where: { sessionId } }),
    prisma.sessionInstructions.findUnique({ where: { sessionId } }),
    prisma.sessionFile.findMany({ where: { sessionId } }),
  ]);

  // Load organization context (future: org-wide settings)
  const orgContext = organizationId
    ? await loadOrganizationContext(organizationId)
    : null;

  return {
    memory: memory?.content,
    instructions: instructions?.content,
    files: files.map(f => ({
      id: f.id,
      filename: f.filename,
      fileType: f.fileType,
      path: f.storagePath,
    })),
    organization: orgContext,
  };
}
```

**File Attachment Processing:**

```typescript
// lib/utils/fileProcessor.ts
export async function processMessageWithAttachments(message: string): Promise<{
  cleanContent: string;
  attachments: FileAttachment[];
}> {
  // Extract file references from message (e.g., "[FILE:path/to/file.pdf]")
  const fileRefs = extractFileReferences(message);

  // Load files and encode to base64
  const attachments = await Promise.all(
    fileRefs.map(async (ref) => {
      const fileData = await fs.readFile(ref.path);
      return {
        path: ref.path,
        filename: path.basename(ref.path),
        mediaType: mime.lookup(ref.path) || 'application/octet-stream',
        size: fileData.length,
        base64Data: fileData.toString('base64'),
      };
    })
  );

  // Remove file references from message
  const cleanContent = message.replace(/\[FILE:[^\]]+\]/g, '').trim();

  return { cleanContent, attachments };
}
```

---

## 4. Business Logic - ROI Calculation Engine

### **ROI Calculator Architecture**

The `ROICalculator` class provides comprehensive financial analysis:

```typescript
// lib/roi/calculator.ts
export class ROICalculator {
  private assumptions: ROIAssumptions;
  private discountRate: number;

  /**
   * Main calculation entry point - comprehensive ROI analysis
   */
  calculate(inputs: ROIInputs, options: CalculationOptions = {}): ROIResult {
    // 1. Normalize inputs (handle missing data, apply defaults)
    const normalized = this.normalizeInputs(inputs);

    // 2. Calculate annual benefit
    const annualBenefit = this.calculateAnnualBenefit(normalized);

    // 3. Determine total investment
    const totalInvestment = this.calculateTotalInvestment(normalized);

    // 4. Generate cash flow schedule (monthly projections)
    const cashFlows = this.generateCashFlows(normalized, annualBenefit, totalInvestment);

    // 5. Calculate primary metrics
    const npv = this.calculateNPV(cashFlows);
    const irr = this.calculateIRR(cashFlows);
    const paybackPeriod = this.calculatePaybackPeriod(cashFlows);
    const tco = this.calculateTCO(normalized, totalInvestment);

    // 6. Calculate financial ratios
    const profitabilityIndex = this.calculateProfitabilityIndex(cashFlows, totalInvestment);
    const benefitCostRatio = normalized.totalBenefit / normalized.totalCost;

    // 7. Calculate time-based analysis
    const monthlyROI = this.calculateMonthlyROI(normalized, annualBenefit, totalInvestment);
    const quarterlyROI = this.aggregateByQuarter(monthlyROI);
    const annualROI = this.aggregateByYear(monthlyROI);

    // 8. Risk-adjusted metrics
    const riskAdjustedReturn = irr / (inputs.riskFactor || 1.0);

    return {
      netPresentValue: npv,
      internalRateReturn: irr,
      paybackPeriod,
      totalCostOwnership: tco,
      returnOnInvestment: this.calculateROIPercentage(totalBenefit, totalCost),
      breakEvenPoint: this.calculateBreakEvenPoint(normalized, annualBenefit),
      monthlyROI,
      quarterlyROI,
      annualROI,
      profitabilityIndex,
      benefitCostRatio,
      riskAdjustedReturn,
      cashFlowSchedule: cashFlows,
      assumptionsUsed: { /* ... */ },
      methodology: 'comprehensive',
      confidence: 85,
      reliabilityLevel: 'excellent',
      warnings: this.generateWarnings(normalized, npv, irr),
      limitations: this.generateLimitations(normalized),
    };
  }

  /**
   * Calculate Net Present Value (NPV)
   * NPV = Σ(Ct / (1 + r)^t) - C0
   */
  private calculateNPV(cashFlows: CashFlow[]): number {
    return cashFlows.reduce((sum, cf) => sum + cf.presentValue, 0);
  }

  /**
   * Calculate Internal Rate of Return (IRR)
   * Using Newton-Raphson method for precision
   */
  private calculateIRR(cashFlows: CashFlow[]): number {
    const maxIterations = 100;
    const tolerance = 0.00001;

    // Initial guess based on simple ROI
    const totalCashFlow = cashFlows.slice(1).reduce((sum, cf) => sum + cf.netCashFlow, 0);
    const initialInvestment = Math.abs(cashFlows[0].netCashFlow);
    let irr = totalCashFlow / initialInvestment / (cashFlows.length / 12);

    for (let i = 0; i < maxIterations; i++) {
      let npv = 0;
      let dnpv = 0; // Derivative

      cashFlows.forEach((cf) => {
        const periodInYears = cf.period / 12;
        const discountFactor = Math.pow(1 + irr, periodInYears);

        npv += cf.netCashFlow / discountFactor;
        dnpv -= (cf.netCashFlow * periodInYears) / (discountFactor * (1 + irr));
      });

      if (Math.abs(npv) < tolerance) return irr;
      if (Math.abs(dnpv) < tolerance) return 0;

      const newIRR = irr - npv / dnpv;
      if (Math.abs(newIRR - irr) < tolerance) return newIRR;

      irr = newIRR;
      if (irr < -0.99 || irr > 10 || isNaN(irr)) return 0;
    }

    return irr;
  }

  /**
   * Generate cash flow schedule with inflation adjustment
   */
  private generateCashFlows(
    inputs: Required<Omit<ROIInputs, "sessionId" | "calculatedAt">>,
    annualBenefit: number,
    totalInvestment: number
  ): CashFlow[] {
    const cashFlows: CashFlow[] = [];
    const months = inputs.timeframe || 24;
    let cumulativeCashFlow = -totalInvestment;

    // Period 0: Initial investment
    cashFlows.push({
      period: 0,
      inflow: 0,
      outflow: totalInvestment,
      netCashFlow: -totalInvestment,
      cumulativeCashFlow: -totalInvestment,
      presentValue: -totalInvestment,
    });

    // Periods 1-N: Monthly benefits
    for (let month = 1; month <= months; month++) {
      const monthlyBenefit = annualBenefit / 12;

      // Inflation adjustment
      const inflationAdjustment = Math.pow(
        1 + (inputs.inflationRate || 0.03),
        month / 12
      );
      const adjustedBenefit = monthlyBenefit * inflationAdjustment;

      // Monthly maintenance costs
      const monthlyMaintenance = (inputs.maintenanceCostAnnual || 0) / 12;

      const netCashFlow = adjustedBenefit - monthlyMaintenance;
      cumulativeCashFlow += netCashFlow;

      // Present value calculation
      const periodInYears = month / 12;
      const discountFactor = Math.pow(1 + inputs.discountRate, periodInYears);
      const presentValue = netCashFlow / discountFactor;

      cashFlows.push({
        period: month,
        inflow: adjustedBenefit,
        outflow: monthlyMaintenance,
        netCashFlow,
        cumulativeCashFlow,
        presentValue,
      });
    }

    return cashFlows;
  }
}
```

### **Confidence Scoring System**

```typescript
// lib/roi/confidence.ts
export class ConfidenceEstimator {
  async calculate(
    extractedMetrics: ExtractedMetrics,
    flags: ConversationFlags,
    phase: ConversationPhase
  ): number {
    const factors = {
      dataCompleteness: this.calculateCompleteness(extractedMetrics),
      dataAccuracy: this.calculateAccuracy(extractedMetrics),
      assumptionValidity: this.calculateValidityScore(extractedMetrics),
      calculationComplexity: this.calculateComplexity(phase),
      industryAlignment: this.calculateIndustryScore(extractedMetrics.industry),
    };

    const weights = {
      dataCompleteness: 0.30,
      dataAccuracy: 0.25,
      assumptionValidity: 0.20,
      calculationComplexity: 0.15,
      industryAlignment: 0.10,
    };

    const weighted = Object.entries(factors).reduce((sum, [key, value]) => {
      return sum + value * weights[key as keyof typeof weights];
    }, 0);

    return Math.round(weighted * 100);
  }

  private calculateCompleteness(metrics: ExtractedMetrics): number {
    const requiredFields = [
      'processName', 'weeklyHours', 'teamSize', 'hourlyRate',
      'automationPercentage', 'implementationTimeline'
    ];

    const provided = requiredFields.filter(field =>
      metrics[field as keyof ExtractedMetrics] !== undefined
    ).length;

    return provided / requiredFields.length;
  }
}
```

### **Sensitivity Analysis**

```typescript
// lib/roi/sensitivityAnalysis.ts
export function performSensitivityAnalysis(
  baseInputs: ROIInputs,
  options: { range?: number } = {}
): SensitivityAnalysis {
  const range = options.range || 0.2; // ±20% default

  const variables: SensitivityVariable[] = [
    'automationPercentage',
    'hourlyRate',
    'implementationCost',
    'timeframe',
  ].map(varName => {
    const baseValue = baseInputs[varName];
    const lowValue = baseValue * (1 - range);
    const highValue = baseValue * (1 + range);

    // Calculate ROI at low and high values
    const lowROI = new ROICalculator().calculate({ ...baseInputs, [varName]: lowValue });
    const highROI = new ROICalculator().calculate({ ...baseInputs, [varName]: highValue });

    return {
      name: varName,
      baseValue,
      lowValue,
      highValue,
      lowROI: lowROI.returnOnInvestment,
      highROI: highROI.returnOnInvestment,
      impact: Math.abs(highROI.returnOnInvestment - lowROI.returnOnInvestment),
    };
  });

  // Sort by impact (tornado diagram)
  const tornado = variables
    .sort((a, b) => b.impact - a.impact)
    .map(v => ({
      variable: v.name,
      baseValue: v.baseValue,
      lowImpact: v.lowROI - baseROI,
      highImpact: v.highROI - baseROI,
      range: v.impact,
    }));

  return {
    baseCase: baseROI,
    variables,
    tornado,
    scenarios: generateScenarios(baseInputs),
  };
}
```

---

## 5. Caching Architecture

### **Idempotency Cache (In-Memory)**

**Purpose:** Prevent duplicate session creation on retry/double-submit

```typescript
// lib/cache/idempotency-cache.ts
const cache = new Map<string, CacheEntry>();
const TTL_MS = 60 * 1000; // 60 seconds

export function checkIdempotencyKey(key: string): string | null {
  const entry = cache.get(key);
  if (!entry) return null;

  // Check expiration
  if (Date.now() - entry.createdAt > TTL_MS) {
    cache.delete(key);
    return null;
  }

  return entry.sessionId;
}

export function cacheIdempotencyKey(key: string, sessionId: string): void {
  cache.set(key, { sessionId, createdAt: Date.now() });
}

// Periodic cleanup every 2 minutes
setInterval(() => {
  for (const [key, entry] of cache.entries()) {
    if (Date.now() - entry.createdAt > TTL_MS) {
      cache.delete(key);
    }
  }
}, 2 * 60 * 1000);
```

**Trade-offs:**
- ✅ Simple, fast, zero dependencies
- ✅ Sufficient for POC (single-instance)
- ⚠️ Process restart clears cache
- 🔄 Future: Migrate to Redis for multi-instance

**Usage Example:**

```typescript
// app/api/sessions/route.ts
export async function POST(request: NextRequest) {
  const idempotencyKey = request.headers.get('X-Idempotency-Key');

  if (idempotencyKey) {
    // Check for existing session
    const existingSessionId = checkIdempotencyKey(idempotencyKey);
    if (existingSessionId) {
      return NextResponse.json({ sessionId: existingSessionId, cached: true });
    }
  }

  // Create new session
  const session = await prisma.session.create({ /* ... */ });

  // Cache for future retries
  if (idempotencyKey) {
    cacheIdempotencyKey(idempotencyKey, session.id);
  }

  return NextResponse.json({ sessionId: session.id });
}
```

---

## 6. State Management

### **Zustand Stores with Persistence**

**Session Store - Ephemeral → Active State Machine:**

```typescript
// stores/sessionStore.ts
interface SessionStore {
  // State machine: ephemeral → creating → active
  sessionState: "ephemeral" | "creating" | "active";

  // Ephemeral state (client-side, no DB)
  ephemeralId: string | null;
  ephemeralMessages: Message[];
  ephemeralMetadata: SessionMetadata;

  // Active state (DB-backed)
  sessionId: string | null;       // WS-YYYYMMDD-XXX
  messages: Message[];
  currentPhase: ConversationPhase;
  progress: number;

  // Actions
  createEphemeralSession: () => void;
  commitSession: () => Promise<void>;  // Ephemeral → Active
  loadExistingSession: (id: string) => Promise<boolean>;
}

export const useSessionStore = create<SessionStore>()(
  persist(
    (set, get) => ({
      sessionState: "ephemeral",
      ephemeralId: null,
      ephemeralMessages: [],
      messages: [],

      createEphemeralSession: () => {
        const ephemeralId = `${Date.now()}-${Math.random().toString(36)}`;
        set({
          sessionState: "ephemeral",
          ephemeralId,
          ephemeralMessages: [createGreetingMessage()],
          messages: [createGreetingMessage()],
        });
      },

      commitSession: async () => {
        const state = get();

        // Guard: Already committed
        if (state.sessionState === "active") return;

        // Guard: No user messages
        const userMessages = state.ephemeralMessages.filter(m => m.role === "user");
        if (userMessages.length === 0) return;

        set({ sessionState: "creating" });

        // Create DB session
        const response = await fetch("/api/sessions", {
          method: "POST",
          headers: {
            "Content-Type": "application/json",
            "X-Idempotency-Key": `${state.ephemeralId}-${Date.now()}`,
          },
          body: JSON.stringify({
            transcript: JSON.stringify(state.ephemeralMessages),
            metadata: JSON.stringify(state.ephemeralMetadata),
          }),
        });

        const { sessionId } = await response.json();

        // Transition to active
        set({
          sessionState: "active",
          sessionId,
          messages: state.ephemeralMessages,
          ephemeralId: null,
          ephemeralMessages: [],
        });
      },

      loadExistingSession: async (sessionId: string) => {
        const response = await fetch(`/api/sessions?sessionId=${sessionId}`);
        const session = await response.json();

        const messages = JSON.parse(session.transcript || "[]");
        const metadata = JSON.parse(session.metadata || "{}");

        set({
          sessionState: "active",
          sessionId,
          messages,
          ephemeralMetadata: metadata,
          currentPhase: metadata.phase || "greeting",
          progress: metadata.progress || 0,
        });

        return true;
      },
    }),
    {
      name: "bloom-session",
      version: 2,
      partialize: (state) => ({
        sessionState: state.sessionState,
        ephemeralId: state.ephemeralId,
        ephemeralMessages: state.ephemeralMessages,
        sessionId: state.sessionId,
        messages: state.messages,
        // Do NOT persist userId/organizationId (prevent stale foreign keys)
      }),
      onRehydrateStorage: () => (state) => {
        // Auto-cleanup stale ephemeral sessions (>24h)
        if (state?.sessionState === "ephemeral") {
          const age = Date.now() - state.lastActivityAt;
          if (age > 24 * 60 * 60 * 1000) {
            state.resetSession();
          }
        }
      },
    }
  )
);
```

**Why This Pattern?**

1. **Zero Token Usage on Landing:** Greeting message is static, no API call
2. **Deferred DB Creation:** Session created only after first user message
3. **Offline Resilience:** User can start conversation without network
4. **Idempotency:** Double-submit protection via `X-Idempotency-Key` header

**Other Stores:**

```typescript
// stores/brandingStore.ts - Branding configuration
// stores/monitoringStore.ts - Real-time metrics
// stores/dashboardLayoutStore.ts - Widget visibility/order
// stores/contextPanelStore.ts - Workshop context panel state
// stores/runStore.ts - Playbook run state
```

---

## 7. UI Architecture

### **Component Organization**

```
components/
├── ui/                    # shadcn/ui primitives (headless + Radix)
│   ├── button.tsx
│   ├── card.tsx
│   ├── dialog.tsx
│   ├── select.tsx
│   └── ... (30+ components)
├── bloom/                 # Bloom-specific components
│   ├── ChatInterface.tsx
│   ├── ROIDisplay.tsx
│   └── ...
├── workshop/              # Workshop-specific features
│   ├── SessionContextPanel.tsx
│   ├── AIIntelligenceDrawer.tsx
│   └── ...
├── settings/              # Settings UI
│   ├── SettingsTabs.tsx
│   ├── MonitoringTab.tsx
│   └── ...
├── monitoring/            # Real-time monitoring widgets
│   ├── HealthMetrics.tsx
│   ├── LogViewer.tsx
│   └── ...
├── providers/             # Context providers
│   ├── ThemeProvider.tsx
│   ├── QueryProvider.tsx
│   └── BrandingProvider.tsx
└── layout/                # Layout components
    ├── Header.tsx
    └── LayoutClient.tsx
```

### **Dark Mode Implementation**

**Dual Approach: Semantic Variables + Explicit Classes**

```tsx
// Approach 1: Semantic CSS Variables (PRIMARY)
<div className="bg-background text-foreground">
<div className="bg-card text-card-foreground">
<p className="text-muted-foreground">

// CSS Variables auto-switch:
// Light: --background: 0 0% 100%; --foreground: 222.2 84% 4.9%;
// Dark:  --background: 222.2 84% 4.9%; --foreground: 210 40% 98%;

// Approach 2: Explicit dark: classes (SECONDARY)
<div className="bg-blue-50 dark:bg-blue-900/30">
<Badge className="bg-green-50 text-green-700 dark:bg-green-900/30 dark:text-green-300">
<Icon className="text-blue-600 dark:text-blue-400" />
```

**Theme Provider:**

```tsx
// components/providers/ThemeProvider.tsx
import { ThemeProvider as NextThemesProvider } from 'next-themes';

export function ThemeProvider({ children }: { children: React.ReactNode }) {
  return (
    <NextThemesProvider
      attribute="class"
      defaultTheme="dark"
      enableSystem={false}
      disableTransitionOnChange
      storageKey="theme"
    >
      {children}
    </NextThemesProvider>
  );
}
```

### **Settings System - Tab-Based UI**

**7 Main Tabs:**

```typescript
const tabs = [
  { id: 'general', label: 'General', icon: Settings },
  { id: 'branding', label: 'Branding', icon: Palette },
  { id: 'sessions', label: 'Sessions', icon: MessageSquare },
  { id: 'melissa', label: 'Melissa Config', icon: Bot },
  { id: 'monitoring', label: 'Monitoring', icon: Activity },
  { id: 'developer', label: 'Developer', icon: Code },
  { id: 'backup', label: 'Backup & Restore', icon: Database },
];
```

**Monitoring Tab - Real-Time Dashboard:**

**8 Health Metric Cards:**
1. Host System Health (CPU, memory, disk)
2. Database Health (connection, query performance)
3. API Health (endpoint uptime)
4. App Server Health (Node.js metrics)
5. Logging Status (log file size, rotation)
6. Export Metrics (PDF, Excel, JSON usage)
7. Playwright Tests (E2E test results)
8. Unit Tests (Jest coverage)

**Widget Customization:**
- Show/hide widgets via modal
- Drag-to-reorder (future)
- Persistent state in `DashboardLayout` table

---

## 8. Security & Authentication

### **Session-Based Authentication (Browser Edit Keys)**

**POC Implementation - Cookie-Based Edit Rights:**

```typescript
// lib/utils/session-auth.ts
import { SignJWT, jwtVerify } from 'jose';

const SECRET = new TextEncoder().encode(process.env.NEXTAUTH_SECRET);

/**
 * Generate signed UUID for session edit key
 */
export async function generateSignedUUID(): Promise<string> {
  const uuid = crypto.randomUUID();

  const token = await new SignJWT({ uuid })
    .setProtectedHeader({ alg: 'HS256' })
    .setIssuedAt()
    .setExpirationTime('30d')
    .sign(SECRET);

  return token;
}

/**
 * Validate signed UUID (check signature)
 */
export async function validateSignedUUID(token: string): Promise<boolean> {
  try {
    const { payload } = await jwtVerify(token, SECRET);
    return !!payload.uuid;
  } catch {
    return false;
  }
}
```

**Usage in Session Creation:**

```typescript
// app/api/sessions/route.ts
export async function POST(request: NextRequest) {
  // 1. Create edit key
  const editKey = await generateSignedUUID();

  // 2. Create session
  const session = await prisma.session.create({
    data: {
      // ... session fields
      editKey,  // Store in DB
    },
  });

  // 3. Set cookie with edit key
  const response = NextResponse.json({ sessionId: session.id });
  response.cookies.set(`session.editKey.${session.id}`, editKey, {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'strict',
    maxAge: 30 * 24 * 60 * 60, // 30 days
  });

  return response;
}
```

**Authorization in PATCH Endpoint:**

```typescript
// app/api/sessions/[id]/route.ts
export async function PATCH(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  const { id } = await params;

  // 1. Extract edit key from cookie
  const editKeyCookie = request.cookies.get(`session.editKey.${id}`)?.value;
  if (!editKeyCookie) {
    return NextResponse.json({ error: "Unauthorized" }, { status: 403 });
  }

  // 2. Validate signature
  if (!validateSignedUUID(editKeyCookie)) {
    return NextResponse.json({ error: "Invalid edit key" }, { status: 403 });
  }

  // 3. Verify edit key matches session
  const session = await prisma.session.findUnique({
    where: { id },
    select: { editKey: true },
  });

  if (session.editKey !== editKeyCookie) {
    return NextResponse.json({ error: "Edit key mismatch" }, { status: 403 });
  }

  // 4. Authorized - proceed with update
  // ...
}
```

### **Input Validation (Zod Schemas)**

**Comprehensive validation on all API endpoints:**

```typescript
// app/api/sessions/route.ts
import { z } from 'zod';

const createSessionSchema = z.object({
  userId: z.string().optional(),
  organizationId: z.string().optional(),

  // Context fields
  customerName: z.string().min(1).max(200).optional(),
  customerIndustry: z.string().optional(),
  employeeCount: z.number().int().min(1).max(100000).optional(),
  problemStatement: z.string().max(1000).optional(),
  department: z.string().max(100).optional(),
  customerContact: z.string().email().optional(),

  // Attendees validation
  attendees: z.array(z.object({
    name: z.string().min(1),
    role: z.string().optional(),
  })).max(50).optional(),

  contextComplete: z.boolean().optional(),
});

export async function POST(request: NextRequest) {
  try {
    const body = await request.json();
    const validated = createSessionSchema.parse(body);
    // ... proceed with validated data
  } catch (error) {
    if (error instanceof z.ZodError) {
      return NextResponse.json(
        { error: "Validation failed", details: error.issues },
        { status: 400 }
      );
    }
  }
}
```

### **Audit Logging**

```typescript
// Automatic audit logging for sensitive operations
await prisma.auditLog.create({
  data: {
    userId: user.id,
    sessionId: session.id,
    action: 'REPORT_GENERATED',
    details: JSON.stringify({
      format: 'pdf',
      roi: roiReport.totalROI,
      confidence: roiReport.confidenceScore,
    }),
    ipAddress: request.headers.get('x-forwarded-for'),
    userAgent: request.headers.get('user-agent'),
  },
});
```

---

## 9. Logging & Monitoring

### **Unified Logger - File-First Architecture**

**Design Principles:**

1. **File-first:** Write to NDJSON file (fast, no DB locks)
2. **Background ingestion:** Separate job reads file → writes to DB
3. **Dual-write transition:** Temporarily write to both file + DB for safety
4. **Categorized sources:** api, database, melissa, session, system, etc.

```typescript
// lib/logger/index.ts
class UnifiedLogger {
  log(
    level: LogLevel,
    message: string,
    source: LogSource,
    metadata?: Record<string, unknown>
  ): LogResult {
    const entry: LogEntry = {
      id: uuidv4(),
      timestamp: new Date().toISOString(),
      level,
      message,
      source,
      metadata,
    };

    // 1. Console (always for visibility)
    if (config.enableConsole) {
      writeToConsole(entry);
    }

    // 2. PRIMARY: Flat file (logs/app.log)
    appendToLogFile(entry, { logFilePath: "logs/app.log" });

    // 3. TEMPORARY: Database (during transition)
    if (config.enableDatabase) {
      writeToDatabase(entry);
    }

    // 4. Check log rotation
    logRotation.checkAndRotate();

    return { success: true, id: entry.id };
  }

  // Convenience methods
  debug(msg: string, source: LogSource, meta?: any) { return this.log('debug', msg, source, meta); }
  info(msg: string, source: LogSource, meta?: any) { return this.log('info', msg, source, meta); }
  warn(msg: string, source: LogSource, meta?: any) { return this.log('warn', msg, source, meta); }
  error(msg: string, source: LogSource, meta?: any) { return this.log('error', msg, source, meta); }
  critical(msg: string, source: LogSource, meta?: any) { return this.log('critical', msg, source, meta); }
}

export const logger = new UnifiedLogger();
```

**Log Sources (Categories):**

```typescript
type LogSource =
  | 'api'           // API routes
  | 'database'      // Prisma queries
  | 'melissa'       // AI agent
  | 'session'       // Session lifecycle
  | 'roi'           // ROI calculations
  | 'export'        // Report exports
  | 'scheduler'     // Task scheduler
  | 'backup'        // Backup operations
  | 'system'        // System events
  | 'security'      // Auth, rate limiting
  | 'monitoring';   // Health checks
```

### **Real-Time SSE Log Streaming**

**Server-Sent Events for live log viewing:**

```typescript
// app/api/system/logs-query/route.ts
export async function GET(request: NextRequest) {
  const searchParams = request.nextUrl.searchParams;
  const stream = searchParams.get('stream') === 'true';

  if (stream) {
    // SSE stream
    const encoder = new TextEncoder();
    const stream = new ReadableStream({
      async start(controller) {
        // Send initial batch
        const logs = await prisma.logEntry.findMany({
          take: 50,
          orderBy: { timestamp: 'desc' },
        });

        controller.enqueue(encoder.encode(`data: ${JSON.stringify(logs)}\n\n`));

        // Poll for new logs every 2 seconds
        const interval = setInterval(async () => {
          const newLogs = await prisma.logEntry.findMany({
            where: { timestamp: { gt: lastTimestamp } },
            orderBy: { timestamp: 'desc' },
          });

          if (newLogs.length > 0) {
            controller.enqueue(encoder.encode(`data: ${JSON.stringify(newLogs)}\n\n`));
            lastTimestamp = newLogs[0].timestamp;
          }
        }, 2000);

        // Cleanup on close
        request.signal.addEventListener('abort', () => {
          clearInterval(interval);
          controller.close();
        });
      },
    });

    return new Response(stream, {
      headers: {
        'Content-Type': 'text/event-stream',
        'Cache-Control': 'no-cache',
        'Connection': 'keep-alive',
      },
    });
  }

  // Regular query
  // ...
}
```

---

## 10. Testing Infrastructure

### **Jest Configuration (Unit & Integration Tests)**

```typescript
// tests/config/jest.config.ts
const customJestConfig: Config = {
  setupFilesAfterEnv: ['<rootDir>/tests/config/jest.setup.ts'],
  testEnvironment: 'jest-environment-jsdom',
  moduleNameMapper: {
    '^@/(.*)$': '<rootDir>/$1',
    '@paralleldrive/cuid2': '<rootDir>/tests/mocks/cuid2.ts',
    '^uuid$': '<rootDir>/tests/mocks/uuid.ts',
  },
  testPathIgnorePatterns: [
    '<rootDir>/.next/',
    '<rootDir>/tests/e2e/',  // Exclude Playwright E2E tests
  ],
  collectCoverageFrom: [
    'app/**/*.{js,jsx,ts,tsx}',
    'lib/**/*.{js,jsx,ts,tsx}',
    'components/**/*.{js,jsx,ts,tsx}',
    '!**/*.d.ts',
  ],
  coverageThreshold: {
    global: {
      branches: 70,
      functions: 70,
      lines: 80,
      statements: 80,
    },
  },
};
```

### **Playwright Configuration (E2E Tests)**

```typescript
// tests/config/playwright.config.ts
export default defineConfig({
  testDir: path.join(__dirname, '../e2e'),
  testMatch: '**/*.spec.ts',

  fullyParallel: true,
  retries: process.env.CI ? 2 : 0,
  workers: process.env.CI ? 1 : undefined,

  reporter: [
    ['html', { outputFolder: 'tests/reports/playwright-html' }],
    ['json', { outputFile: 'tests/reports/playwright-results.json' }],
    ['list'],
  ],

  use: {
    baseURL: 'http://localhost:3001',
    trace: 'on-first-retry',
    screenshot: 'only-on-failure',
    video: 'retain-on-failure',
  },

  projects: [
    { name: 'chromium', use: { ...devices['Desktop Chrome'] } },
    { name: 'firefox', use: { ...devices['Desktop Firefox'] } },
    { name: 'webkit', use: { ...devices['Desktop Safari'] } },
  ],

  webServer: {
    command: 'npm run dev:simple',
    url: 'http://localhost:3001',
    reuseExistingServer: !process.env.CI,
    timeout: 120_000,
  },
});
```

---

## 11. Technical Architecture Diagrams

### **System Architecture Overview**

```
┌─────────────────────────────────────────────────────────────────┐
│                         FRONTEND LAYER                          │
│  Next.js 16 App Router | React 19 | Tailwind CSS | shadcn/ui   │
├──────────────────────┬──────────────────────┬───────────────────┤
│  Workshop Pages      │  Settings Pages      │  Admin UI         │
│  - Workshop Chat     │  - General Settings  │  - Task Manager   │
│  - Session Browser   │  - Branding Config   │  - Log Viewer     │
│  - Report Viewer     │  - Session Monitor   │  - Health Metrics │
│                      │  - Log Streaming     │                   │
└──────────────────────┴──────────────────────┴───────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                         API GATEWAY LAYER                       │
│           Next.js App Router API Routes (70+ endpoints)         │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ /api/sessions│ /api/melissa │ /api/admin   │ /api/system       │
│ - CRUD       │ - Chat       │ - Tasks      │ - Health          │
│ - Export     │ - Context    │ - Backup     │ - Metrics         │
│ - Lifecycle  │ - Completion │ - Config     │ - Logs            │
└──────────────┴──────────────┴──────────────┴───────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    BUSINESS LOGIC LAYER                         │
│  AI Agent | ROI Engine | Report Generator | Cache Manager      │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ Melissa.ai   │ ROI Calc     │ Export Gen   │ Idempotency       │
│ - State Mgmt │ - NPV/IRR    │ - PDF        │ - In-Memory Cache │
│ - Routing    │ - Sensitivity│ - Excel      │ - Deduplication  │
│ - Extraction │ - Confidence │ - JSON       │                   │
└──────────────┴──────────────┴──────────────┴───────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                         DATA LAYER                              │
│            Prisma ORM | SQLite WAL (Dev) | Postgres (Prod)     │
├──────────────┬──────────────┬──────────────┬───────────────────┤
│ Sessions     │ AI Models    │ Benchmarks   │ Audit Logs        │
│ - Responses  │ - Personas   │ - Industry   │ - Actions         │
│ - Metadata   │ - Protocols  │ - Metrics    │ - Changes         │
│ - Transcript │ - Playbooks  │ - Data       │ - Governance      │
└──────────────┴──────────────┴──────────────┴───────────────────┘
                                 ↓
┌─────────────────────────────────────────────────────────────────┐
│                    EXTERNAL SERVICES                            │
│  Anthropic Claude API | Redis (optional) | File Storage        │
└─────────────────────────────────────────────────────────────────┘
```

### **Data Flow: Session Creation & ROI Discovery**

```
User starts Workshop
        ↓
Create Ephemeral Session (in-memory)
        ↓
User sends first message → Transition to Active Session (DB)
        ↓
Melissa.ai processes message:
  - Extract relevant data
  - Route to next question
  - Track confidence
        ↓
Store Response + update Session metadata
        ↓
Monitor for completion criteria (all required fields present)
        ↓
When ready → Trigger ROI Calculation
        ↓
Generate Report (PDF/Excel/JSON)
        ↓
Store ROIReport record + link to Session
        ↓
Export workflow completes
```

---

## 12. Complete API Endpoint Specifications

### **Endpoint Organization (70+ Endpoints)**

#### **Session Management API**
| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/api/sessions` | GET | List all sessions | ✅ Live |
| `/api/sessions` | POST | Create new session | ✅ Live |
| `/api/sessions/[id]` | GET | Fetch session details | ✅ Live |
| `/api/sessions/[id]` | PUT | Update session metadata | ✅ Live |
| `/api/sessions/[id]` | DELETE | Archive session | ✅ Live |
| `/api/sessions/[id]/resume` | POST | Resume paused session | ✅ Live |
| `/api/sessions/[id]/export` | POST | Export session (JSON/PDF/Excel) | ✅ Live |
| `/api/sessions/[id]/transcript` | GET | Fetch conversation transcript | ✅ Live |
| `/api/sessions/[id]/audit` | GET | Fetch audit trail | ✅ Live |

#### **Melissa.ai Chat API**
| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/api/melissa/chat` | POST | Send message, get AI response | ✅ Live |
| `/api/melissa/context` | GET | Fetch conversation context | ✅ Live |
| `/api/melissa/suggest` | POST | Get next suggested questions | ✅ Live |
| `/api/melissa/validate` | POST | Validate extracted data | ✅ Live |
| `/api/melissa/confidence` | GET | Get confidence scorecard | ✅ Live |

#### **ROI Calculation API**
| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/api/roi/calculate` | POST | Calculate ROI metrics | 🚧 Pending |
| `/api/roi/[sessionId]/report` | GET | Fetch ROI report | 🚧 Pending |
| `/api/roi/sensitivity` | POST | Run sensitivity analysis | 🚧 Pending |
| `/api/roi/benchmarks` | GET | Fetch industry benchmarks | ✅ Live |

#### **Admin & System APIs**
| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/api/admin/tasks` | GET | List background tasks | ✅ Live |
| `/api/admin/tasks` | POST | Create task | ✅ Live |
| `/api/admin/tasks/[id]` | GET | Task details | ✅ Live |
| `/api/admin/backup` | POST | Trigger database backup | ✅ Live |
| `/api/health` | GET | System health check | ✅ Live |
| `/api/health/db` | GET | Database connection status | ✅ Live |
| `/api/logs` | GET | Retrieve application logs | ✅ Live |
| `/api/logs/stream` | GET | SSE stream for real-time logs | ✅ Live |
| `/api/metrics` | GET | System performance metrics | ✅ Live |
| `/api/cache/analytics` | GET | Cache performance stats | ✅ Live |

### **Request/Response Schemas (Zod)**

**Create Session Request:**
```typescript
{
  organizationId: string;
  userId?: string;
  initiativeId?: string;
  config?: {
    timeboxMinutes: number;      // Default: 15
    locale: string;              // Default: en-US
    outputFormat: 'json' | 'pdf' | 'excel';
  }
}
```

**Chat Message Request:**
```typescript
{
  sessionId: string;
  message: string;
  attachments?: File[];           // Optional file context
  metadata?: Record<string, any>; // Custom tracking data
}
```

**ROI Calculate Request:**
```typescript
{
  sessionId: string;
  inputs: {
    processHoursPerWeek: number;
    teamSize: number;
    hourlyRate: number;
    automationPercentage: number;
    implementationCost: number;
    discountRate: number;        // Default: 10%
    yearsToAnalyze: number;      // Default: 5
  }
}
```

---

## 13. Detailed Prisma Schema

### **Core Data Models (40+ total)**

#### **Session Management**
```prisma
model Session {
  id                    String    @id @default(cuid())
  organizationId        String
  userId                String?
  initiativeId          String?

  // Session Lifecycle
  status                SessionStatus  @default(EPHEMERAL)
  startedAt             DateTime       @default(now())
  completedAt           DateTime?
  pausedAt              DateTime?

  // State Management
  currentStage          String?        // Which phase of workshop
  currentConfidence     Float?         @default(0)
  metadata              Json?          // Extensible session data
  transcript            Json?          // Full conversation history

  // Relations
  organization          Organization   @relation(fields: [organizationId], references: [id])
  responses             Response[]
  roiReport             ROIReport?
  auditLog              AuditLog[]

  @@index([organizationId, status])
  @@index([createdAt])
}

enum SessionStatus {
  EPHEMERAL    // In-memory only
  ACTIVE       // User has sent first message
  PAUSED       // Temporarily suspended
  COMPLETED    // Exported and ready
  ARCHIVED     // Historical record
}

model Response {
  id            String   @id @default(cuid())
  sessionId     String
  turn          Int      // Turn number in conversation

  // User input
  userMessage   String
  userContext   Json?    // Additional metadata from user

  // AI output
  aiMessage     String
  extractedData Json?    // Parsed ROI inputs from AI
  confidence    Float?   // Confidence in extraction

  session       Session  @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  @@index([sessionId, turn])
}
```

#### **AI Model Configuration**
```prisma
model MelissaPersona {
  id              String   @id @default(cuid())
  name            String   // "ROI Specialist", "Process Expert"
  systemPrompt    String   // Base persona definition
  tone            String   // "professional", "friendly"
  expertise       String[] // ["finance", "operations"]

  protocols       ChatProtocol[]
}

model ChatProtocol {
  id              String   @id @default(cuid())
  personaId       String
  name            String   // "Discovery Protocol", "Validation Protocol"
  description     String
  questionFlow    Json     // Ordered list of questions
  exitCriteria    Json?    // When to end this protocol

  persona         MelissaPersona @relation(fields: [personaId], references: [id])
  playbooks       Playbook[]
}

model Playbook {
  id              String   @id @default(cuid())
  protocolId      String
  name            String   // "ROI Discovery Playbook"
  version         Int      @default(1)
  rules           Json     // Conditional routing rules
  templates       Json     // Response templates

  protocol        ChatProtocol @relation(fields: [protocolId], references: [id])
}
```

#### **ROI & Financial Data**
```prisma
model ROIReport {
  id                String   @id @default(cuid())
  sessionId         String   @unique

  // Input Metrics
  inputs            Json     // Original user inputs
  assumptions       Json     // All documented assumptions

  // Financial Results
  npv               Float    // Net Present Value
  irr               Float?   // Internal Rate of Return
  paybackPeriod     Float?   // Months to break even
  tco               Float    // Total Cost of Ownership

  // Confidence & Sensitivity
  confidenceScore   Float    // 0-100, breakdown in JSON
  confidenceFactor  Json     // {completeness, quality, historical, assumptions}
  sensitivityData   Json     // Tornado diagram data

  // Honey Outcome
  honeyOutcome      Json     // 2-3 KPIs with baselines

  // Metadata
  generatedAt       DateTime @default(now())
  exportedAt        DateTime?
  exportFormat      String?  // "json" | "pdf" | "excel"

  session           Session  @relation(fields: [sessionId], references: [id], onDelete: Cascade)
}

model Benchmark {
  id              String   @id @default(cuid())
  industry        String   // "Manufacturing", "Healthcare"
  processType     String   // "AP/AR", "Sales", "HR"

  metric          String   // "hourly_rate", "automation_pct"
  avgValue        Float
  percentile25    Float
  percentile75    Float

  lastUpdated     DateTime @default(now())

  @@index([industry, processType, metric])
}
```

#### **Security & Audit**
```prisma
model AuditLog {
  id              String   @id @default(cuid())
  sessionId       String

  action          String   // "message_sent", "export_requested"
  actor           String   // User ID or "system"
  payload         Json?    // What changed

  createdAt       DateTime @default(now())

  session         Session  @relation(fields: [sessionId], references: [id], onDelete: Cascade)

  @@index([sessionId, createdAt])
}
```

---

## 14. Melissa.ai Agent Specification

### **Agent Architecture: State Machine**

**States:**
1. **GREETING** → Show intro, explain workshop
2. **DISCOVERY** → Ask about process, volume, team, costs
3. **EXTRACTION** → Validate and refine inputs
4. **VALIDATION** → Confirm assumptions, fill gaps
5. **CALCULATION** → Trigger ROI compute
6. **SUMMARY** → Show results, confidence scorecard
7. **EXPORT** → Offer PDF/Excel/JSON export

### **Question Routing Logic**

```typescript
// Pseudocode for routing
currentState = DISCOVERY

if allRequiredFieldsPresent() {
  transition(VALIDATION)
} else if lowConfidence() {
  askClarifyingQuestion()
  updateResponse.extractedData
  updateResponse.confidence
} else {
  askNextQuestion(questionRouter.next(currentState, userMessage))
}
```

### **Data Extraction Pipeline**

**Responsible for extracting:**
- Process name & description
- Hours per week (handles ranges: "10-15" → 12.5)
- Team size
- Hourly rate
- Automation percentage
- Implementation cost estimate
- Discount rate (default 10%)

**Confidence Factors:**
- Completeness: Are all required fields present?
- Quality: Are values reasonable/validated?
- Historical: Has user provided historical data?
- Assumptions: Are assumptions documented?

### **Integration with ROI Engine**

Once extraction complete → Call `/api/roi/calculate` with extracted inputs:

```typescript
await fetch('/api/roi/calculate', {
  method: 'POST',
  body: JSON.stringify({
    sessionId,
    inputs: extractedData
  })
});
```

---

## 15. ROI Calculation Engine

### **Financial Formulas**

#### **NPV (Net Present Value)**
```
NPV = Σ(Cash Flow_t / (1 + r)^t) - Initial Investment
Where:
  t = year (0 to n)
  r = discount rate
  Cash Flow_t = Annual savings in year t
```

**Implementation:** `lib/roi/calculator.ts:calculateNPV()`
- Iterates through analysis period (default 5 years)
- Applies discount rate each period
- Accounts for implementation ramp-up

#### **IRR (Internal Rate of Return)**
```
0 = NPV = Σ(Cash Flow_t / (1 + IRR)^t) - Initial Investment
```

**Algorithm:** Newton-Raphson method
**Target Precision:** ±0.001%
**Implementation:** `lib/roi/calculator.ts:calculateIRR()`

#### **Payback Period**
```
Payback = Year + (Unrecovered Cost / Year_Cash_Flow)
```

**Key Point:** When cumulative savings exceed initial investment

**Implementation:** `lib/roi/calculator.ts:calculatePaybackPeriod()`

#### **TCO (Total Cost of Ownership)**
```
TCO = Initial Investment + (Annual Costs × Years)
    - (Annual Savings × Years)
```

**Includes:**
- Automation implementation cost
- Ongoing maintenance (estimated as % of automation savings)
- License fees (if applicable)

### **Sensitivity Analysis (Tornado Diagram)**

**Variables tested:**
- Labor hourly rate (±20%)
- Automation percentage (±15%)
- Implementation cost (±25%)
- Discount rate (±3%)

**Output:** Ranking by impact on NPV

**Implementation:** `lib/roi/sensitivity.ts:generateSensitivityAnalysis()`

### **Confidence Scoring**

```typescript
ConfidenceScore = (
  Completeness(0.30) +      // All fields provided
  Quality(0.25) +           // Values within reasonable range
  Historical(0.20) +        // Based on actual data
  Industry(0.15) +          // Aligned with benchmarks
  Assumptions(0.10)         // Well-documented
) × 100
```

**Output includes factor breakdown** for transparency

---

## 16. UI/UX Component Library

### **Component Organization**

```
components/
├── ui/                              # shadcn/ui base components
│   ├── button.tsx                   # Button with 4 variants
│   ├── input.tsx                    # Text input, validated
│   ├── card.tsx                     # Card layout container
│   ├── dialog.tsx                   # Modal dialogs
│   ├── tabs.tsx                     # Tab navigation
│   ├── table.tsx                    # Data tables
│   ├── select.tsx                   # Dropdown selector
│   ├── slider.tsx                   # Range input
│   └── ... (20+ standard components)
│
├── bloom/                           # Bloom-specific components
│   ├── Workshop/
│   │   ├── ChatInterface.tsx        # Main chat UI
│   │   ├── MessageList.tsx          # Message history
│   │   ├── InputPrompt.tsx          # User input field
│   │   └── ProgressIndicator.tsx    # Workshop stage indicator
│   │
│   ├── Reports/
│   │   ├── ROIReportView.tsx        # Full report layout
│   │   ├── MetricsCard.tsx          # Individual metric display
│   │   ├── SensitivityChart.tsx     # Tornado diagram
│   │   └── ConfidenceScorecard.tsx  # Confidence breakdown
│   │
│   ├── Settings/
│   │   ├── SettingsTabs.tsx         # Tab container
│   │   ├── GeneralSettings.tsx      # Basic config
│   │   ├── BrandingPanel.tsx        # Logo & colors
│   │   ├── MonitoringTab.tsx        # Logs & metrics
│   │   └── SessionManager.tsx       # Session list
│   │
│   └── Admin/
│       ├── TaskScheduler.tsx        # Background tasks
│       ├── LogViewer.tsx            # Log streaming
│       └── HealthMetrics.tsx        # System health cards
```

### **Design System**

**Colors (Tailwind + CSS Variables):**
- Primary: `--bloom-primary: #7C3AED` (Purple)
- Secondary: `--bloom-secondary: #10B981` (Green)
- Accent: `--bloom-accent: #F59E0B` (Amber)
- Status: High `#10B981`, Medium `#F59E0B`, Low `#EF4444`

**Dark Mode:** Automatic via `class` strategy in `tailwind.config.ts`
- Light mode: Standard Tailwind colors
- Dark mode: CSS variables with darker tints
- No hardcoded light colors allowed

**Typography:**
- Headings: Inter, sans-serif (bold 600-700)
- Body: Inter, sans-serif (regular 400)
- Monospace: JetBrains Mono (code snippets)

**Spacing:** Base unit 4px (Tailwind classes: `p-4`, `space-y-4`, etc.)

---

## 17. Docker Configuration & Deployment

### **Multi-Stage Build Process**

**Stage 1: Dependencies**
```dockerfile
FROM node:20-alpine AS deps
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
RUN npm ci
RUN npx prisma generate
```

**Stage 2: Builder**
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /app
COPY --from=deps /app/node_modules ./node_modules
COPY . .
RUN npm run build
```

**Stage 3: Runner (Production)**
```dockerfile
FROM node:20-alpine AS runner
WORKDIR /app
COPY --from=builder /app/public ./public
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY package*.json ./
EXPOSE 3000
CMD ["npm", "start"]
```

### **Docker Compose Services**

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:16-alpine
    environment:
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
      POSTGRES_DB: bloom
    volumes:
      - postgres_data:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres"]
      interval: 10s
      timeout: 5s
      retries: 5

  redis:
    image: redis:7-alpine
    volumes:
      - redis_data:/data
    healthcheck:
      test: ["CMD", "redis-cli", "ping"]
      interval: 10s
      timeout: 5s
      retries: 5

  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      DATABASE_URL: postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/bloom
      REDIS_URL: redis://redis:6379
      NEXTAUTH_SECRET: ${NEXTAUTH_SECRET}
      NEXTAUTH_URL: http://app:3000
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_healthy
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:3000/api/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  postgres_data:
  redis_data:
```

### **Deployment Checklist**

- [ ] Build Docker image: `docker build -t bloom:latest .`
- [ ] Run migrations: `docker-compose run app npx prisma migrate deploy`
- [ ] Seed database: `docker-compose run app npm run db:seed`
- [ ] Health check: `curl http://localhost:3000/api/health`
- [ ] Verify logs: `docker-compose logs -f app`

---

## 18. Security & Compliance Strategy

### **Authentication & Authorization**

**NextAuth.js v4.24.13:**
- Session-based (cookies)
- JWT signing for edit operations
- Role-based access (facilitator, admin, viewer)

**Cookie-Based Edit Keys:**
```typescript
// Generate on login
editKey = jwt.sign({
  userId,
  sessionId,
  permissions: ['read', 'write']
}, NEXTAUTH_SECRET, { expiresIn: '24h' })

// Stored in secure, httpOnly cookie
// Verified on every mutation
```

### **Input Validation**

**Zod schemas on ALL endpoints:**
```typescript
const chatMessageSchema = z.object({
  sessionId: z.string().cuid(),
  message: z.string().min(1).max(5000),
  attachments: z.array(z.instanceof(File)).optional()
});

export async function POST(request: Request) {
  const body = await request.json();
  const { sessionId, message } = chatMessageSchema.parse(body);
  // Process validated input
}
```

### **Audit Logging**

**Every sensitive action logged to `AuditLog` table:**
- Session creation/deletion
- Message sent
- Export generated
- ROI report created
- Settings changed
- Admin operations

**Format:**
```json
{
  "action": "export_requested",
  "actor": "user:123",
  "sessionId": "session:456",
  "format": "pdf",
  "timestamp": "2025-11-16T10:30:00Z",
  "result": "success"
}
```

### **Data Privacy & Residency**

- ✅ Data stored in customer's tenant (Postgres instance)
- ✅ Appmelia never owns or caches customer data
- ✅ Conversation transcripts encrypted at rest (optional)
- ✅ GDPR-ready: Right to be forgotten (cascade delete)

### **Compliance Roadmap**

| Certification | Status | Target |
|---|---|---|
| WCAG 2.1 AA (Accessibility) | In Progress | v7.2 |
| SOC 2 Type II | Planned | v8.0 |
| ISO 27001 | Planned | v8.0 |
| HIPAA (if needed) | Out of scope | N/A |

---

## 19. Performance Requirements & Optimization

### **Performance SLAs**

| Metric | Target | Current | Status |
|--------|--------|---------|--------|
| API Response (p95) | < 250ms | ~150-200ms | ✅ Met |
| ROI Calculation (p95) | < 500ms | ~100-200ms | ✅ Met |
| Export Generation (p95) | < 3s | ~1-2s | ✅ Met |
| Page Load (p90) | < 2s | ~0.5-1.5s | ✅ Met |
| Chat Message Latency | < 5s | ~2-4s (with Claude) | ✅ Met |

### **Optimization Strategies**

#### **1. Caching Tier**
```
In-Memory Cache (60s TTL)
    ↓
Redis Cache (5m TTL)
    ↓
Database
```

**Cached Items:**
- Benchmark data (read-heavy)
- Industry metrics (rarely changing)
- Session metadata (after mutation)

#### **2. Database Optimization**
```sql
-- Indexes on high-query tables
CREATE INDEX idx_sessions_org_status ON sessions(organization_id, status);
CREATE INDEX idx_responses_session ON responses(session_id, turn);
CREATE INDEX idx_audit_session_created ON audit_logs(session_id, created_at);
```

#### **3. API Response Compression**
- Gzip enabled for responses > 1KB
- JSON serialization optimized (no circular refs)
- Large arrays paginated

#### **4. Frontend Optimization**
- Code splitting by route (Next.js automatic)
- Image optimization (Next Image component)
- React Query deduplication & caching
- Lazy load heavy components (Report charts)

#### **5. Monitoring & Alerting**

**Real-time metrics dashboard:**
- API latency by endpoint
- Cache hit rate
- Database connection pool usage
- Error rates
- CPU/memory utilization

**Alerts (webhook to Slack):**
- API latency > 500ms
- Error rate > 1%
- Cache hit rate < 40%
- Database connections > 80

---

## Summary & Key Architectural Decisions

### **Architecture Decision Records (ADRs)**

**ADR-001: SQLite WAL Mode for Development**
- **Decision:** Use SQLite with WAL mode
- **Rationale:** Zero config, 30-50% better performance, sufficient for POC
- **Consequences:** Single-instance only, migrate to PostgreSQL for scale
- **Status:** Accepted

**ADR-002: Next.js 16 Async Params Pattern**
- **Decision:** All dynamic routes must await params
- **Rationale:** Breaking change in Next.js 16
- **Consequences:** Updated ~15 route handlers
- **Status:** Implemented

**ADR-003: Ephemeral → Active Session State Machine**
- **Decision:** Defer DB session creation until first user message
- **Rationale:** Zero token usage on landing, offline resilience
- **Consequences:** Added complexity in state management
- **Status:** Implemented

**ADR-004: File-First Logging Architecture**
- **Decision:** Write logs to NDJSON file, background ingestion to DB
- **Rationale:** Eliminate DB lock contention during high-volume logging
- **Consequences:** Added log rotation, ingestion job
- **Status:** In transition (dual-write)

**ADR-005: Multi-LLM Profile System**
- **Decision:** Abstract LLM calls behind profile system
- **Rationale:** Flexibility to switch providers/models per use case
- **Consequences:** Added profile configuration layer
- **Status:** Implemented (Phase 9)

**ADR-006: Idempotency Cache (In-Memory)**
- **Decision:** Use in-memory cache with 60s TTL for idempotency
- **Rationale:** Simple, fast, sufficient for POC
- **Consequences:** Lost on restart (acceptable trade-off)
- **Status:** Implemented, plan to migrate to Redis

---

## Key Technical Highlights

### **1. Modern Next.js 16 Patterns**
- App Router with Server/Client Component separation
- Async params pattern for all dynamic routes
- Streaming SSR for real-time updates
- Server-Sent Events for log streaming

### **2. Type-Safe TypeScript**
- Strict mode enabled across entire codebase
- Zod schemas for runtime validation
- Prisma-generated types for database models
- Comprehensive type coverage (90%+)

### **3. AI-First Architecture**
- Multi-LLM profile system for flexible provider routing
- Persona-Protocol-Playbook composition for prompt building
- Tool calling integration for ROI calculations
- Context management with file attachments

### **4. Financial Rigor**
- Comprehensive ROI calculator (NPV, IRR, Payback, TCO)
- Newton-Raphson method for IRR precision
- Sensitivity analysis with tornado diagrams
- Confidence scoring with transparent factor breakdown

### **5. Developer Experience**
- Unified logging with categorized sources
- Real-time monitoring dashboard with SSE
- Comprehensive test coverage (Jest + Playwright)
- Per-worker databases for test isolation

### **6. Security & Governance**
- Cookie-based edit keys with JWT signing
- Zod validation on all API endpoints
- Audit logging for sensitive operations
- Rate limiting (planned: Redis-based)

---

**Document Prepared By:** Claude (Anthropic)
**Based On:** Comprehensive codebase exploration of Appmelia Bloom
**Total Models:** 40+ Prisma models
**Total API Endpoints:** 70+
**Total Components:** 100+
**Lines of Code:** ~50,000+

---

*This technical architecture report provides a comprehensive overview of how Appmelia Bloom is built, from database schema to UI components, AI integration to testing infrastructure. It serves as both documentation and a guide for future development.*
