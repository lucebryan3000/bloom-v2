# OmniForge Package Groups

This document defines the package groups installed by OmniForge and maps them to cached packages in `.download-cache/npm/`.

## Package Groups by Profile

| Profile    | Groups Installed                                    |
|------------|-----------------------------------------------------|
| minimal    | core                                                |
| starter    | core, auth, ui                                      |
| standard   | core, auth, ui, state, testing                      |
| advanced   | core, auth, ui, state, testing, ai                  |
| enterprise | core, auth, ui, state, testing, ai, export, quality |

---

## Group 1: Core Framework (`core/00-nextjs.sh`)

**Purpose**: Foundation - Next.js + React + TypeScript

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| next          | dep  | next-16.0.3.tgz            | React framework    |
| react         | dep  | react/                     | UI library         |
| react-dom     | dep  | react-dom/                 | DOM bindings       |
| typescript    | dev  | (network)                  | Type checking      |
| @types/node   | dev  | node/                      | Node.js types      |
| @types/react  | dev  | (network)                  | React types        |

**Install Command**:
```bash
pnpm add next react react-dom
pnpm add -D typescript @types/node @types/react @types/react-dom
```

---

## Group 2: Database (`core/01-database.sh`)

**Purpose**: PostgreSQL + Drizzle ORM

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| drizzle-orm   | dep  | drizzle-orm-0.44.7.tgz     | TypeScript ORM     |
| drizzle-kit   | dev  | (network)                  | Migration CLI      |
| postgres      | dep  | (network)                  | PG client          |

**Install Command**:
```bash
pnpm add drizzle-orm postgres
pnpm add -D drizzle-kit
```

---

## Group 3: Authentication (`core/02-auth.sh`)

**Purpose**: Auth.js (NextAuth) setup

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| next-auth     | dep  | (network)                  | Authentication     |
| @auth/core    | dep  | (network)                  | Auth core          |
| @auth/drizzle | dep  | (network)                  | Drizzle adapter    |

**Install Command**:
```bash
pnpm add next-auth @auth/core @auth/drizzle-adapter
```

---

## Group 4: UI Framework (`core/03-ui.sh`)

**Purpose**: shadcn/ui + Tailwind CSS

| Package          | Type | Cached File                | Notes              |
|------------------|------|----------------------------|--------------------|
| tailwindcss      | dev  | (network)                  | CSS framework      |
| postcss          | dev  | (network)                  | CSS processing     |
| autoprefixer     | dev  | (network)                  | CSS prefixes       |
| lucide-react     | dep  | lucide-react-0.554.0.tgz   | Icons              |
| class-variance-authority | dep | (network)           | Variant styles     |
| clsx             | dep  | (network)                  | Class names        |
| tailwind-merge   | dep  | (network)                  | Class merging      |

**Install Command**:
```bash
pnpm add lucide-react class-variance-authority clsx tailwind-merge
pnpm add -D tailwindcss postcss autoprefixer
npx tailwindcss init -p
```

---

## Group 5: State Management (`features/state.sh`)

**Purpose**: Zustand for client state

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| zustand       | dep  | (network)                  | State management   |

**Install Command**:
```bash
pnpm add zustand
```

---

## Group 6: Testing (`features/testing.sh`)

**Purpose**: Vitest + Playwright

| Package          | Type | Cached File                | Notes              |
|------------------|------|----------------------------|--------------------|
| vitest           | dev  | (network)                  | Unit testing       |
| @testing-library/react | dev | (network)            | React testing      |
| playwright       | dev  | (network)                  | E2E testing        |
| @playwright/test | dev  | (network)                  | Playwright runner  |

**Install Command**:
```bash
pnpm add -D vitest @testing-library/react @playwright/test playwright
```

---

## Group 7: AI/LLM (`features/ai-sdk.sh`)

**Purpose**: Vercel AI SDK

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| ai            | dep  | (network)                  | AI SDK core        |
| @ai-sdk/openai | dep | (network)                  | OpenAI provider    |
| @ai-sdk/anthropic | dep | (network)               | Claude provider    |

**Install Command**:
```bash
pnpm add ai @ai-sdk/openai @ai-sdk/anthropic
```

---

## Group 8: Export System (`features/export.sh`)

**Purpose**: PDF, Excel, JSON exports

| Package       | Type | Cached File                | Notes              |
|---------------|------|----------------------------|--------------------|
| jspdf         | dep  | (network)                  | PDF generation     |
| xlsx          | dep  | (network)                  | Excel exports      |

**Install Command**:
```bash
pnpm add jspdf xlsx
```

---

## Group 9: Code Quality (`features/code-quality.sh`)

**Purpose**: ESLint + Prettier + Lint-staged

| Package          | Type | Cached File                | Notes              |
|------------------|------|----------------------------|--------------------|
| eslint           | dev  | (network)                  | Linting            |
| prettier         | dev  | (network)                  | Formatting         |
| lint-staged      | dev  | (network)                  | Pre-commit         |
| husky            | dev  | (network)                  | Git hooks          |
| @typescript-eslint/eslint-plugin | dev | package/ | TS linting        |

**Install Command**:
```bash
pnpm add -D eslint prettier lint-staged husky @typescript-eslint/eslint-plugin @typescript-eslint/parser
```

---

## Cache Directory Structure

```
.download-cache/npm/
├── next-16.0.3.tgz           # Tarball (install with pnpm add ./path.tgz)
├── drizzle-orm-0.44.7.tgz    # Tarball
├── lucide-react-0.554.0.tgz  # Tarball
├── react/                     # Unpacked @types/react
├── react-dom/                 # Unpacked @types/react-dom
├── node/                      # Unpacked @types/node
└── package/                   # Unpacked @typescript-eslint/eslint-plugin
```

## Installation Priority

1. **Check cache first** - Look for `.tgz` files or unpacked directories
2. **Install from cache** - `pnpm add ./path/to/package.tgz`
3. **Fall back to network** - `pnpm add package-name`
4. **Verify installation** - Check `node_modules/package` exists
