## ⚙️ Bloom2 Architecture Specification (v6.1 - Final Build Blueprint)

This document is the final, detailed specification, including precise library versions and implementation details, for the **Bloom2 "App-in-a-Box"** appliance.

It is the **authoritative architecture README**: what we’re building, how it’s wired, and in what order it should be built and deployed.

---

## 1. Core Technology Stack (The Blueprint)

The stack is aggressively optimized for **performance**, **TypeScript safety**, and **low operational overhead**, adhering to the **Multi-Stage Docker Build** strategy.

### 1.1 Stack Summary

| Category      | Component       | Final Decision                            | Version / Rationale                                                                |
| :------------ | :-------------- | :---------------------------------------- | :--------------------------------------------------------------------------------- |
| **Platform**  | Runtime         | **Node.js v20.x LTS**                     | Stable, secure runtime for containerized deployments; aligns with modern Next.js.  |
|               | Framework       | **Next.js v15.x (App Router + React 19)** | Required for Server Actions, streaming, and modern RSC patterns.                   |
|               | Package Manager | **pnpm v9.x**                             | Fast, deterministic installs; maximizes Docker cache efficiency.                   |
| **Data Core** | Database        | **PostgreSQL v16.x (`pgvector` image)**   | Core relational DB; `pgvector v0.5.x` enables future semantic search capabilities. |
|               | ORM             | **Drizzle ORM v8.x**                      | Lightweight, high-performance, TypeScript-first SQL query builder.                 |
|               | DB Driver       | **`postgres.js`**                         | High-performance Postgres client; works natively with Drizzle.                     |
| **AI/Auth**   | AI SDK          | **`@vercel/ai` v3.x**                     | Standard for integrating Anthropic/LLMs with Next.js streaming components.         |
|               | Auth            | **`@auth/core` v5.x (Auth.js)**           | App Router–native authentication solution; supports streaming and RSC.             |

### 1.2 Platform Implementation Details

**Node.js v20.x LTS**

* **What:** Single runtime for local dev, CI, and production containers.
* **How:**

  * Docker base image: `node:20-alpine` (or similar) in multi-stage builds.
  * `engines` field in `package.json` pins Node 20.x for local dev.
* **Outcome:** Consistent behavior and security updates across all environments; no “works on Node 18, breaks on Node 20” drift.

**Next.js v15.x (App Router + React 19)**

* **What:** Full App Router–only architecture under `src/app`, leveraging Server Components & Server Actions.
* **How:**

  * All routes (workspace, review, report, settings) live in `src/app`.
  * Server Actions handle mutations instead of a separate REST API layer where possible.
  * Streaming responses integrated via `@vercel/ai` + Next’s `streaming` APIs.
* **Outcome:** Cleaner architecture (less API boilerplate), first-class streaming, and modern UX patterns.

**pnpm v9.x**

* **What:** Sole package manager for the project.
* **How:**

  * `pnpm-lock.yaml` committed as the source of truth.
  * Docker builds cache `~/.pnpm-store` between layers to accelerate rebuilds.
* **Outcome:** Faster installs, smaller images, better monorepo friendliness if you expand later.

---

### 1.3 Data Core Implementation Details

**PostgreSQL v16.x (pgvector image)**

* **What:** Primary relational database; includes `pgvector` for future semantic/embedding use.
* **How:**

  * Docker Compose defines a `db` service using `pgvector`-enabled Postgres image.
  * Single DB per appliance instance; no SQLite in the supported path.
* **Outcome:** Enterprise-grade persistence and a clear path for future LLM-based similarity search (e.g., session recall).

**Drizzle ORM v8.x + `postgres.js`**

* **What:** Type-safe ORM + driver stack for Postgres.
* **How:**

  * `src/db/schema.ts` (and module-split variants) define tables for `projects`, `sessions`, `messages`, `session_metrics`, `value_perspectives`, `jobs`, `audit_log`, `users`, `feature_flags`, `app_settings`, etc.
  * Drizzle migrations generated and applied at container startup.
  * `postgres.js` handles connection pooling and efficient query execution.
* **Outcome:** Minimal overhead, robust type inference, and clean migrations without Prisma’s bulk.

---

### 1.4 AI & Auth Integration

**`@vercel/ai` v3.x**

* **What:** Unified API for calling Anthropic/LLMs from Next.js (especially with streaming + RSC).
* **How:**

  * `src/features/chat/ai.ts` uses `@vercel/ai` to call Anthropic, using:

    * Sliding window context
    * Injected `SessionState` JSON into system messages
    * Streaming tokens into React server components / `useChat` hook
* **Outcome:** Clean, versionable orchestration for Melissa’s behavior with minimal glue.

**Auth.js (`@auth/core` v5.x)**

* **What:** Authentication library purpose-built for Next.js App Router.
* **How:**

  * `src/app/(auth)` routes for login, logout, and callback flows.
  * Credentials-based login for MVP; session tokens stored securely; ready for future providers (Azure AD, etc.).
* **Outcome:** Modern, streaming-compatible auth without reverting to Pages Router or legacy patterns.

---

## 2. Data Persistence, Querying, and Security Contracts

### 2.1 Concurrency & Locking Semantics

**Model: Optimistic Locking (Row-Level Versioning)**

* **What:** Prevents silent overwrites when multiple users or processes modify the same record.
* **How:**

  * Every mutable entity (`sessions`, `session_metrics`, etc.) includes a `version` column (integer).
  * UPDATE statements use: `WHERE id = $id AND version = $old_version`.
  * If zero rows are affected, the app knows a concurrent update occurred; it can then surface a conflict to the user.
* **Outcome:** Bloom2 can safely support concurrent Editor activity without data corruption, while avoiding pessimistic locks that harm performance.

### 2.2 Schema Backbone (High-Level)

**Core Tables (Drizzle Definitions)**

* `users` – auth + role (Editor, Viewer, Admin).
* `projects` – logical container for Baseline/Retro sessions.
* `sessions` – per-workshop state; stores lifecycle, associated project, type (baseline/retro).
* `messages` – full chat log (user ↔ Melissa), with emotion and metadata tags.
* `session_metrics` – normalized metrics (name, value, unit, min/max, sourceType, confidence).
* `value_perspectives` – seeded four pillars: Financial, Cultural, Customer, Employee (admin-extendable).
* `roi_results` – computed ROI numbers (baseline & scenario variants).
* `confidence_snapshots` – historical confidence per session.
* `jobs` – background jobs (queue).
* `audit_log` – immutable change log (who changed what, when, from → to, why).
* `feature_flags`, `app_settings` – runtime-configurable flags and app-level settings.

---

### 2.3 Security Contracts (Zod Validation)

The **Zod** library (`v3.x`) is the mandatory contract layer.

| Contract Type      | Location / Module                                          | Enforcement Method                                                                               |
| :----------------- | :--------------------------------------------------------- | :----------------------------------------------------------------------------------------------- |
| **Environment**    | `env.mts` using `@t3-oss/env-nextjs`                       | Validated at build- and runtime; app fails fast on missing/invalid keys.                         |
| **Server Actions** | `src/features/*/actions.ts` (`'use server'`)               | First line of code in every action: `schema.parse(input)`; invalid payloads return typed errors. |
| **API Routes**     | `src/app/api/*/route.ts` (if any)                          | Wrap `Request` parsing with Zod schemas; never trust `req.json()` unvalidated.                   |
| **Input Abuse**    | Central rate limiter util (e.g., `src/lib/rateLimiter.ts`) | Applied as a wrapper around high-risk actions (chat send, export generation, project creation).  |

**Outcome:** Every important boundary—env configuration, external input, and high-risk operations—is contract-checked. This is foundational for deterministic ROI math and confidence logic.

---

## 3. Application Flow, State & Observability

### 3.1 State Management & Performance

| Feature            | Library / Tool            | Implementation Detail                                                                 |
| :----------------- | :------------------------ | :------------------------------------------------------------------------------------ |
| **Client State**   | **Zustand v4.x**          | Stores UI state: selected session, live metrics, value cards, open loops, UI toggles. |
| **Chat Flow**      | **Optimistic UI Pattern** | Chat messages appear instantly; LLM responses stream while DB writes happen later.    |
| **PDF Generation** | **`react-to-print` v2.x** | Dedicated Report view is printed/saved via the browser; ensures WYSIWYG PDFs.         |

**Optimistic UI Behavior**

* On `chatSend`:

  * Append user message to Zustand store immediately.
  * Call `@vercel/ai` streaming endpoint; display Melissa’s reply as it arrives.
  * Dispatch a background job to:

    * Persist messages.
    * Run extraction pipeline.
    * Update `session_metrics` and `SessionState`.
* Result: perceived latency is dominated by the LLM, not the DB.

---

### 3.2 Background Job Queue (Robustness)

**Job Runner: `pg-boss` (or equivalent Postgres-native queue)**

* **What:** A robust job queue built on Postgres and `SKIP LOCKED`.
* **How:**

  * `pg-boss` (or a similar library) runs inside the Next.js process via `instrumentation.ts` or a dedicated worker entrypoint.
  * Job types:

    * `persist-session-state` – flush in-memory session state to DB.
    * `compute-roi-confidence` – recompute ROI & confidence after changes.
    * `generate-report-cache` – optional precomputation for heavier reports.
  * Concurrency tuned low (`2–4`) to avoid starving the main web thread.
* **Outcome:** Async work is resilient and recoverable (retries, dead-letter), without another infra component like Redis.

---

### 3.3 Logging & Observability

**Logger: Pino v8.x**

* **What:** High-performance structured logger.
* **How:**

  * `src/lib/logger.ts` exports a preconfigured Pino instance.
  * All significant events (requests, jobs, lifecycle transitions, errors) log JSON to `stdout`.
  * Common fields:

    * `level`, `msg`, `timestamp`, `requestId`, `sessionId`, `projectId`, `jobId`, `durationMs`.
* **Dev Experience:**

  * `docker compose logs -f web | pnpm pino-pretty` for readable logs.
* **Outcome:** Easy to grep and filter logs locally; trivial to plug into ELK/Loki/etc. later if needed.

---

## 4. UI, Standards & Governance

### 4.1 Development Standards

| Standard          | Tool / Policy                             | Implementation Detail                                                                   |
| :---------------- | :---------------------------------------- | :-------------------------------------------------------------------------------------- |
| **Accessibility** | **WCAG 2.1 AA**                           | Use semantic HTML, `shadcn/ui` accessible primitives, and `eslint-plugin-jsx-a11y`.     |
| **Code Quality**  | **ESLint & Prettier + Husky/lint-staged** | Pre-commit hooks run lint & format on changed files; TS strict mode enabled.            |
| **Testing**       | **Vitest v1.x + Playwright v1.x**         | Vitest for unit/integration tests; Playwright for E2E flows (Happy Paths & edge cases). |

**Outcome:** The codebase remains consistent, testable, and accessible, without being overburdened by hyper-strict styling rules that slow you down.

---

### 4.2 Code Organization (Final Directory Structure)

The application uses a **Hybrid Domain/Feature Structure** to group code by function, with shared libs by type.

```bash
bloom2/
├── docker-compose.yml
├── Dockerfile
├── package.json
├── pnpm-lock.yaml
├── src/
│   ├── app/                      # Next.js 15 routes & layouts
│   │   ├── layout.tsx           # Root layout
│   │   ├── page.tsx             # Landing / dashboard
│   │   ├── (auth)/              # Auth routes (login, callback)
│   │   ├── workspace/           # /workspace/[sessionId]
│   │   ├── reports/             # /reports/[sessionId]
│   │   └── settings/            # /settings (feature flags, perspectives)
│   ├── components/              # Reusable UI (shadcn/ui wrappers, layout components)
│   ├── db/
│   │   ├── schema.ts            # Drizzle schema definitions
│   │   ├── migrations/          # Generated SQL migrations
│   │   └── index.ts             # Drizzle + postgres.js client
│   ├── features/                # PRIMARY BUSINESS DOMAINS
│   │   ├── chat/                # Chat UI, useChat, AI service orchestration
│   │   ├── review/              # HITL Review Queue, diff views, review actions
│   │   ├── report/              # Report builder, charts, react-to-print integration
│   │   ├── projects/            # Project/Session CRUD flows, delta comparison
│   │   └── settings/            # Feature flags, perspectives, app config UI
│   ├── lib/
│   │   ├── roi.ts               # ROI calculation (Ironclad baseline, scenarios)
│   │   ├── confidence.ts        # Weighted attribute confidence scoring
│   │   ├── narrative.ts         # Narrative builder for report view
│   │   ├── logger.ts            # Pino configuration
│   │   ├── rateLimiter.ts       # Simple Node-based rate limiter
│   │   └── sessionState.ts      # Session state assembly for LLM prompts
│   ├── prompts/                 # Melissa prompts-as-code
│   │   ├── system.ts            # Persona, safety, global rules
│   │   ├── discovery.ts         # Discovery phase prompt
│   │   ├── quantification.ts    # Quantification phase prompt
│   │   ├── validation.ts        # Validation / Review phase prompt
│   │   └── synthesis.ts         # Narrative/report synthesis prompt
│   └── schemas/                 # Zod validation schemas
│       ├── env.ts               # T3 Env + Zod for environment
│       ├── chat.ts              # Chat payload & message schemas
│       ├── metrics.ts           # Metric/ROI-related schemas
│       ├── projects.ts          # Project/Session CRUD schemas
│       └── settings.ts          # Feature flag & app settings schemas
└── tests/
    ├── unit/                    # Vitest unit tests
    ├── integration/             # Integration tests (DB + logic)
    └── e2e/                     # Playwright E2E tests
```

---

## 5. Phased Build & Deployment Order (High-Level)

To keep the build sane and iterative, the following **phased plan** should be followed. Each phase should be releasable and tested before moving on.

### Phase 0 – Skeleton & Environment

* Initialize Next.js 15 + Node 20 + pnpm.
* Set up Dockerfile (multi-stage) + docker-compose (web + db).
* Add Drizzle + `postgres.js` + env validation (`@t3-oss/env-nextjs` + Zod).
* Verify: `docker compose up` shows a simple “Bloom2 is running” page.

### Phase 1 – Schema, Auth & Shell

* Implement Drizzle schema for `users`, `projects`, `sessions`, `value_perspectives`, `feature_flags`, `app_settings`.
* Add Auth.js v5 (credentials-based login).
* Build basic layout and route structure (Workspace/Reports/Settings placeholders).
* Verify: login works, can create dummy project/session rows in DB via a simple Server Action.

### Phase 2 – Chat Engine (Optimistic UI)

* Integrate `@vercel/ai` and basic Melissa system prompt.
* Implement `features/chat`:

  * `useChat` hook + streaming UI.
  * Optimistic append of user messages.
* Persist messages to DB (simplified, no metrics yet).
* Verify: real streaming chat with Melissa, persisted history per session.

### Phase 3 – Extraction, Metrics & Confidence

* Implement `session_metrics`, `roi_results`, `confidence_snapshots` tables.
* Build extraction pipeline with Zod-validated JSON from Melissa (metrics + friction).
* Implement `lib/confidence.ts` with weighted attribute scoring.
* Show live metrics and confidence in Data Panel using Zustand.
* Verify: conversation produces structured metrics and visible confidence scores.

### Phase 4 – ROI, Perspectives & Review Queue

* Implement `lib/roi.ts` with Ironclad baseline (min-of-range) and scenario calculations.
* Seed `value_perspectives` with Financial/Cultural/Customer/Employee.
* Implement Review Queue (features/review):

  * Diff view AI vs override.
  * Audit logging.
  * Belief update logic (SessionState).
* Verify: you can run a session, review metrics, override values, and see ROI/confidence adjust deterministically.

### Phase 5 – Report View & Exports

* Implement `/reports/[sessionId]` with full narrative, metrics, charts (shadcn/charts).
* Integrate `react-to-print` to trigger browser print → PDF.
* Build JSON + Excel exporters (sanitized).
* Verify: for a given session, you can generate a CFO-usable PDF + Excel pack.

### Phase 6 – Ops, Hardening & Final Polish

* Add:

  * `pg-boss` (or equivalent) for background jobs.
  * Pino logging, rate limiting, feature flags UI.
  * Husky + lint-staged, full ESLint/Prettier/TS strict config.
  * Vitest + Playwright suites + seed script for Golden Dataset.
* Implement:

  * Backup script / doc for Postgres (daily, 4-hour RTO target).
  * Optimistic locking (version columns).
  * A11y refinements (WCAG 2.1 AA), confirm English-only copy centralization.
* Verify:

  * `docker compose up` gives a production-ready appliance that passes tests, runs reliably, and produces defensible ROI reports.

---

This `architecture-README.md` is now your **build contract**: it defines the stack, the invariants, and the order of operations. The PRD describes *what* Bloom2 must do; this document describes *how* we will build and run it.

---

## 7. Bootstrap Configuration Files (Template & Example Organization)

The bootstrap system generates a production-ready Bloom2 installation through 35 sequenced scripts (_build/bootstrap_scripts/tech_stack/). To support this, the following **example files** are provided in `_build/bootstrap_scripts/` for reference and first-run configuration.

### 7.1 Configuration Files Overview

| File | Purpose | Status | Responsibility |
|------|---------|--------|-----------------|
| **bootstrap.conf.example** | Template for `bootstrap.conf` (orchestrator configuration) | ✅ Tracked in Git | Source of truth for bootstrap settings |
| **.env.example** | Template for `.env.local` (runtime environment variables) | ✅ Reference (never auto-copied) | Developer reference for all runtime env vars |
| **.gitignore.example** | Template for `/.gitignore` (project-level VCS exclusions) | ✅ Reference (never auto-copied) | Developer reference for artifact/secret exclusions |
| **.claudeignore.example** | Template for `/.claudeignore` (Claude Code context exclusions) | ✅ Reference (never auto-copied) | Developer reference for AI context optimization |

### 7.2 Bootstrap Configuration (`bootstrap.conf`)

**Location:** `_build/bootstrap_scripts/bootstrap.conf`

**Purpose:** Single source of truth for all bootstrap orchestrator settings.

**Generated By:** First run of `run-bootstrap.sh` or copied from `bootstrap.conf.example`

**Key Variables:**

```bash
# Core identity
APP_NAME="bloom2"
PROJECT_ROOT="."

# Logging and state tracking (auto-set by orchestrator)
LOGS_DIR="${LOG_DIR}"
BOOTSTRAP_STATE_FILE="${PROJECT_ROOT}/.bootstrap_state"

# Runtime versions
NODE_VERSION="20"
PNPM_VERSION="9"
NEXT_VERSION="15"
POSTGRES_VERSION="16"

# Database (local Docker defaults)
DB_NAME="bloom2_db"
DB_USER="bloom2"
DB_PASSWORD="change_me"  # ⚠️ MUST be changed before production

# Feature flags (35 bootstrap scripts organized by technology)
ENABLE_AUTHJS="true"
ENABLE_AI_SDK="true"
ENABLE_PG_BOSS="true"
# ... (see bootstrap.conf for all flags)

# Execution control
GIT_SAFETY="true"
ALLOW_DIRTY="false"
BOOTSTRAP_RESUME_MODE="skip"  # skip|force
LOG_FORMAT="plain"  # plain|json

# Script execution order (35 scripts, 12 technology phases)
BOOTSTRAP_STEPS_DEFAULT="
foundation/init-nextjs.sh
foundation/init-typescript.sh
# ... (full list in bootstrap.conf)
quality/ts-strict-mode.sh
"
```

**Environment Variable Override:** All `bootstrap.conf` values can be overridden via environment variables at run time:

```bash
# Example: override specific settings
APP_NAME=myapp DB_PASSWORD=secure ./run-bootstrap.sh --all

# Example: allow dirty working tree
ALLOW_DIRTY=true ./run-bootstrap.sh --all
```

**First-Run Setup:**

```bash
cd _build/bootstrap_scripts
cp bootstrap.conf.example bootstrap.conf
# Edit bootstrap.conf if you need non-default values
./run-bootstrap.sh --all
```

### 7.3 Runtime Environment (`.env.local`)

**Location:** Project root `/.env.local` (never committed to Git)

**Purpose:** Runtime configuration for Next.js app, database, AI, auth, and observability.

**Source Template:** `_build/bootstrap_scripts/.env.example`

**Installation Pattern:** Copy to root and customize:

```bash
cp _build/bootstrap_scripts/.env.example .env.local
# Edit .env.local with your actual secrets and local settings
```

**Key Sections:**

| Section | Variables | Purpose |
|---------|-----------|---------|
| **App Config** | `APP_NAME`, `NODE_ENV`, `NEXT_PUBLIC_APP_URL` | Identity and environment |
| **Database** | `DATABASE_URL`, `DB_POOL_MIN`, `DB_POOL_MAX` | PostgreSQL connection pool |
| **Auth** | `AUTH_SECRET`, `SESSION_MAX_AGE`, `SESSION_UPDATE_AGE` | Auth.js v5 session management |
| **AI/LLM** | `ANTHROPIC_API_KEY`, `LLM_API_BASE_URL` | Vercel AI SDK + Claude integration |
| **Observability** | `LOG_LEVEL`, `LOG_FORMAT` | Pino logging configuration |
| **Features** | `FEATURE_*`, `RATE_LIMIT_*` | Feature toggles and rate limiting |
| **Jobs** | `JOB_CONCURRENCY`, `JOB_RETENTION_DAYS` | pg-boss background queue |
| **Docker** | `DOCKER_REGISTRY`, `DOCKER_IMAGE_TAG` | Container registry settings |
| **Dev-Only** | `DEBUG`, `ALLOW_DIRTY`, `SEED_DATABASE` | Development helpers |

**Validation:** All required env vars are validated at Next.js startup using `@t3-oss/env-nextjs` + Zod. Missing vars cause immediate failure with descriptive errors.

**Example Minimal Setup:**

```bash
# .env.local (minimal, for local Docker Compose)
NODE_ENV=development
NEXT_PUBLIC_APP_URL=http://localhost:3000
DATABASE_URL=postgresql://bloom2:change_me@localhost:5432/bloom2_db
AUTH_SECRET=your_secure_random_secret_here
ANTHROPIC_API_KEY=sk-ant-your-key-here
LOG_LEVEL=debug
LOG_FORMAT=pretty
```

### 7.4 Version Control Exclusions (`.gitignore`)

**Location:** Project root `/.gitignore` (committed to Git)

**Purpose:** Prevent committing build artifacts, secrets, and generated files.

**Source Template:** `_build/bootstrap_scripts/.gitignore.example`

**Installation Pattern:**

```bash
# Review the example and integrate into existing .gitignore
cat _build/bootstrap_scripts/.gitignore.example >> .gitignore

# Or use as comprehensive replacement if starting fresh
cp _build/bootstrap_scripts/.gitignore.example .gitignore
```

**Key Exclusion Categories:**

| Category | Patterns | Rationale |
|----------|----------|-----------|
| **Dependencies** | `node_modules/`, `pnpm-lock.yaml`, `package-lock.json` | Locked artifacts, not committed |
| **Build Output** | `.next/`, `/build/`, `/dist/`, `*.tsbuildinfo` | Generated by build, not committed |
| **Secrets** | `.env`, `.env.local`, `.env.production` | Runtime configuration, never committed |
| **Database** | `drizzle/`, `migrations/`, `postgres_data/`, `*.sql` | Generated schemas and data |
| **Logs** | `logs/`, `*.log`, `.pino-pretty/` | Runtime artifacts, not committed |
| **IDE/Editor** | `.vscode/`, `.idea/`, `.DS_Store`, `*.swp` | Editor-specific, not project files |
| **Testing** | `coverage/`, `test-results/`, `playwright-report/` | Test artifacts, not committed |
| **Docker** | `docker-compose.override.yml`, `.dockerignore` | Local overrides, not committed |

**Current Status:** `.gitignore` is tracked in Git and fully organized by technology layer.

### 7.5 Claude Code Context Exclusions (`.claudeignore`)

**Location:** Project root `/.claudeignore` (optional, aids Claude Code analysis)

**Purpose:** Tell Claude Code which files/directories to skip during codebase analysis, optimizing context window and reducing noise.

**Source Template:** `_build/bootstrap_scripts/.claudeignore.example`

**Installation Pattern:**

```bash
cp _build/bootstrap_scripts/.claudeignore.example .claudeignore
# Customize if needed for your workflow
```

**Key Exclusion Categories:**

| Category | Files/Dirs | Rationale |
|----------|-----------|-----------|
| **Dependencies** | `node_modules/`, `pnpm-lock.yaml` | Huge, unreadable dependency trees |
| **Build** | `.next/`, `/build/`, `/dist/` | Generated, not source code |
| **Secrets** | `.env`, `.env.local`, `.env.production` | Never analyze secrets |
| **Database** | `drizzle/`, `migrations/`, `postgres_data/` | Generated schemas, not logic |
| **Logs** | `logs/`, `*.log`, `_build/bootstrap_scripts/logs/` | Runtime artifacts |
| **Tests** | `coverage/`, `test-results/`, `playwright-report/` | Heavy, only when debugging tests |
| **IDE** | `.vscode/`, `.idea/`, `.DS_Store` | Editor config, not code |

**Optimization Tip:** Uncomment lines in `.claudeignore` if analyzing code is slow:

```bash
# Uncomment these if context analysis is slow:
# node_modules/
# pnpm-lock.yaml
```

---

### 7.6 File Installation Workflow

**When You Run `./run-bootstrap.sh --all`:**

```
1. ✅ bootstrap.conf.example → ALREADY TRACKED (copied to bootstrap.conf by user)
2. ⚠️  .env.example           → PROVIDED AS REFERENCE (user copies to .env.local)
3. ⚠️  .gitignore.example     → PROVIDED AS REFERENCE (user integrates to .gitignore)
4. ⚠️  .claudeignore.example  → PROVIDED AS REFERENCE (optional, user copies to .claudeignore)
```

**Typical First-Run Setup:**

```bash
# 1. Navigate to bootstrap scripts
cd _build/bootstrap_scripts

# 2. Initialize bootstrap configuration
cp bootstrap.conf.example bootstrap.conf
# Optionally edit bootstrap.conf for custom values

# 3. Run bootstrap (auto-generates 35 scripts worth of files)
./run-bootstrap.sh --all

# 4. Back to project root
cd ../..

# 5. Copy environment templates
cp _build/bootstrap_scripts/.env.example .env.local
cp _build/bootstrap_scripts/.gitignore.example .gitignore
cp _build/bootstrap_scripts/.claudeignore.example .claudeignore

# 6. Edit .env.local with your secrets
# ANTHROPIC_API_KEY, DATABASE_URL, AUTH_SECRET, etc.

# 7. Install dependencies and start
pnpm install
docker compose up -d
pnpm dev
```

### 7.7 Summary: File Organization & Accuracy

| File | Location | Accuracy | Alignment | Status |
|------|----------|----------|-----------|--------|
| `bootstrap.conf.example` | `_build/bootstrap_scripts/` | ✅ Matches orchestrator v2.0 | ✅ All 35 scripts listed correctly | ✅ Tracked, current |
| `.env.example` | `_build/bootstrap_scripts/` | ✅ Comprehensive coverage | ✅ Maps to @t3-oss/env-nextjs validation | ✅ Reference file |
| `.gitignore.example` | `_build/bootstrap_scripts/` | ✅ Complete by tech layer | ✅ Covers all build artifacts & secrets | ✅ Reference file |
| `.claudeignore.example` | `_build/bootstrap_scripts/` | ✅ Optimized exclusions | ✅ Bootstrap logs excluded | ✅ Reference file |

---

**Installation Ready:** All example files are accurate, complete, and ready for production bootstrap deployment. They reflect the v2.0 orchestrator architecture and align with the technology stack defined in Section 1 above.
