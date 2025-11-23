# Melissa Playbook System - Full Implementation Plan

## Executive Summary

**Status:** Ready for implementation (Bug #8 completed November 14, 2025)
**Total Estimated Time:** 6-8 hours
**Prerequisites:**
- ✅ Foundation installed (see **INSTALLATION-GUIDE.md** for scripts 1-10)
- ✅ Bug #8 (IFL phase progression) completed
**Goal:** Full end-to-end Melissa Playbook system with tests and sample data

## Bug Status Review

| Bug # | Description | Status | Notes |
|-------|-------------|--------|-------|
| Bug #1 | Installation script path resolution | ✅ FIXED | Commit e88d7c3 |
| Bug #2 | Hard-coded Organization relation | ✅ N/A | Organization model exists in schema.prisma:13 |
| Bug #3 | Missing `prisma generate` | ✅ FIXED | Commit e88d7c3 |
| Bug #4 | Database seeding logic | ⚠️ IN PROGRESS | See Phase 1 below |
| Bug #5 | Service modules ignore tenant scoping | ✅ FIXED | Singleton PrismaClient (commit e88d7c3) |
| Bug #6 | Compiler returns empty data | ✅ FIXED | 200+ line parser (commit e88d7c3) |
| Bug #7 | Prompt builder ignores context | ✅ FIXED | 148-line builder (commit e88d7c3) |
| Bug #8 | IFL engine no phase advancement | 🔄 IMPLEMENTING | Local Claude Code running now |

**Current Completion:** ~65% (was 10%, now with Bugs #5-7 fixed + #8 in progress)

---

## Implementation Phases

### Phase 1: Fix Bug #4 - Database Seeding (1 hour)

**Goal:** Create proper seed script for Melissa Playbook test data

**Current State:**
- `prisma/seed.ts` exists but doesn't populate Melissa tables
- Missing seed data for: `MelissaPersona`, `ChatProtocol`, `PlaybookSource`, `PlaybookCompiled`

**Tasks:**

1. **Add Melissa Persona Seed Data** (15 mins)
   ```typescript
   // Add to prisma/seed.ts
   const defaultPersona = await prisma.melissaPersona.create({
     data: {
       slug: 'melissa-default',
       name: 'Melissa (Default)',
       description: 'Friendly, inquisitive AI facilitator for ROI discovery workshops',
       baseTone: 'professional-warm',
       explorationTone: 'curious',
       synthesisTone: 'analytical',
       cognitionPrimary: 'analytical',
       cognitionSecondary: 'empathetic',
       cognitionTertiary: 'creative',
       curiosityModes: ['exploratory', 'clarifying', 'validating'],
       explorationLevel: 70,
       structureLevel: 60,
       isDefault: true,
       organizationId: defaultOrg.id,
     },
   });
   ```

2. **Add Chat Protocol Seed Data** (15 mins)
   ```typescript
   const defaultProtocol = await prisma.chatProtocol.create({
     data: {
       slug: 'standard-discovery',
       name: 'Standard Discovery Protocol',
       description: '15-minute guided discovery with structured phases',
       oneQuestionMode: true,
       maxQuestions: 25,
       maxFollowups: 3,
       allowQuestionMerging: false,
       allowQuestionSkipping: false,
       driftSoftLimit: 3,
       driftHardLimit: 5,
       phases: ['greet_frame', 'discover_probe', 'validate_quantify', 'synthesize_reflect', 'advance_close'],
       strictPhases: true,
       isDefault: true,
       organizationId: defaultOrg.id,
     },
   });
   ```

3. **Add Minimal Playbook Source** (15 mins)
   ```typescript
   const bottleneckPlaybook = await prisma.playbookSource.create({
     data: {
       slug: 'bottleneck-minimal-v1',
       name: 'Bottleneck Discovery (Minimal)',
       category: 'process-optimization',
       objective: 'Identify process bottlenecks and estimate ROI potential',
       version: '1.0.0',
       personaId: defaultPersona.id,
       protocolId: defaultProtocol.id,
       markdown: `<!-- See bottleneck_minimal_v1.md for full content -->`,
       organizationId: defaultOrg.id,
     },
   });
   ```

4. **Add Compiled Playbook** (15 mins)
   ```typescript
   // Compile the playbook and mark it active
   import { compilePlaybookSource } from '@/lib/melissa/playbookCompiler';

   const compiled = await compilePlaybookSource(bottleneckPlaybook.id, { activate: true });
   console.log(`✓ Compiled playbook: ${compiled.slug} (${compiled.questions.length} questions)`);
   ```

**Verification:**
```bash
npx prisma db seed
# Should output:
# ✓ Created default MelissaPersona: melissa-default
# ✓ Created default ChatProtocol: standard-discovery
# ✓ Created PlaybookSource: bottleneck-minimal-v1
# ✓ Compiled playbook: bottleneck-minimal-v1 (5 questions)
```

---

### Phase 2: Write Compiler Unit Tests (2 hours)

**Goal:** Test all 5 extraction functions + edge cases

**File:** `lib/melissa/__tests__/playbookCompiler.test.ts`

**Test Coverage:**

1. **extractPhases()** (30 mins)
   - Valid phases list
   - Missing ## Phases section (should return default 5 phases)
   - Empty phases section
   - Malformed phase names

2. **extractQuestions()** (30 mins)
   - Valid question blocks (all fields)
   - Missing optional fields (type, options)
   - Quoted vs unquoted text
   - Array options with various formats
   - Empty questions section

3. **extractRules()** (20 mins)
   - Valid key:value pairs
   - Boolean parsing (true/false)
   - Number parsing
   - String values
   - Missing ## Rules section

4. **extractScoring()** (15 mins)
   - Valid scoring section
   - Missing section (returns null)
   - Raw text extraction

5. **extractReport()** (15 mins)
   - Valid report section
   - Missing section (returns null)
   - Raw text extraction

6. **parseMarkdownToPlaybookDTO() Integration** (30 mins)
   - Full valid playbook
   - Minimal playbook (only required sections)
   - PhaseMap grouping correctness
   - CompileInfo metadata

**Example Test:**
```typescript
import { describe, it, expect } from '@jest/globals';
import { parseMarkdownToPlaybookDTO } from '../playbookCompiler';
import type { PlaybookSource } from '@prisma/client';

describe('Playbook Compiler', () => {
  describe('extractPhases', () => {
    it('should extract valid phases list', () => {
      const source: PlaybookSource = {
        id: 'test-1',
        slug: 'test',
        name: 'Test',
        category: 'test',
        objective: null,
        version: '1.0.0',
        personaId: 'persona-1',
        protocolId: 'protocol-1',
        markdown: `
## Phases
- greet_frame
- discover_probe
        `,
        organizationId: 'org-1',
        createdAt: new Date(),
        updatedAt: new Date(),
      };

      const dto = parseMarkdownToPlaybookDTO(source);

      expect(dto.phaseMap).toHaveProperty('greet_frame');
      expect(dto.phaseMap).toHaveProperty('discover_probe');
      expect(dto.compileInfo.phaseCount).toBe(2);
    });

    it('should return default phases when ## Phases missing', () => {
      const source: PlaybookSource = {
        /* minimal source without ## Phases */
      };

      const dto = parseMarkdownToPlaybookDTO(source);

      expect(dto.compileInfo.phaseCount).toBe(5);
      expect(dto.phaseMap).toHaveProperty('greet_frame');
      expect(dto.phaseMap).toHaveProperty('advance_close');
    });
  });

  describe('extractQuestions', () => {
    it('should parse question with all fields', () => {
      const source: PlaybookSource = {
        markdown: `
## Questions
- id: q_test
  phase: greet_frame
  type: multiple_choice
  text: "What is your role?"
  options: ["Manager", "Engineer", "Executive"]
        `,
      };

      const dto = parseMarkdownToPlaybookDTO(source);

      expect(dto.questions).toHaveLength(1);
      expect(dto.questions[0].id).toBe('q_test');
      expect(dto.questions[0].phase).toBe('greet_frame');
      expect(dto.questions[0].type).toBe('multiple_choice');
      expect(dto.questions[0].text).toBe('What is your role?');
      expect(dto.questions[0].options).toEqual(['Manager', 'Engineer', 'Executive']);
    });
  });

  // ... more tests
});
```

**Run tests:**
```bash
npm test -- lib/melissa/__tests__/playbookCompiler.test.ts
```

---

### Phase 3: Write IFL Engine Unit Tests (1 hour)

**Goal:** Test phase progression scenarios

**File:** `lib/melissa/__tests__/iflEngine.test.ts`

**Test Coverage:**

1. **getNextQuestion()** (15 mins)
   - Returns first unanswered question
   - Returns null when all answered
   - Respects phase order

2. **applyAnswer() - Phase Progression** (30 mins)
   - Sets currentPhase from first question
   - Does NOT advance until phase complete
   - Advances to next phase when current phase complete
   - Resets totalQuestionsAsked on phase transition
   - Stays in final phase (no next phase)

3. **recordAnswer()** (15 mins)
   - Increments totalQuestionsAsked
   - Stores answer in ctx.answers
   - Preserves existing answers

**Example Test (from BUG-8 doc):**
```typescript
it('should advance to next phase when current phase complete', () => {
  const ctx: SessionContext = {
    sessionId: 'test-session',
    currentPhase: 'greet_frame',
    totalQuestionsAsked: 2,
    followupCount: 0,
    answers: { q1: 'answer1', q2: 'answer2' }, // greet_frame complete
  };

  const mockPlaybook: PlaybookCompiled = {
    phaseMap: {
      greet_frame: [
        { id: 'q1', phase: 'greet_frame', type: 'free_text', text: 'Q1' },
        { id: 'q2', phase: 'greet_frame', type: 'free_text', text: 'Q2' },
      ],
      discover_probe: [
        { id: 'q3', phase: 'discover_probe', type: 'free_text', text: 'Q3' },
      ],
    },
    questions: [/* all questions */],
  };

  const mockProtocol = {
    phases: ['greet_frame', 'discover_probe', 'validate_quantify'],
    strictPhases: true,
  };

  // Answering q3 should trigger phase advancement
  const updated = applyAnswer(ctx, 'q3', 'answer3', mockPlaybook, mockProtocol);

  expect(updated.currentPhase).toBe('discover_probe');
  expect(updated.totalQuestionsAsked).toBe(0); // Reset for new phase
  expect(updated.answers).toHaveProperty('q3');
});
```

**Run tests:**
```bash
npm test -- lib/melissa/__tests__/iflEngine.test.ts
```

---

### Phase 4: Generate SQL Migration (30 mins)

**Goal:** Create Prisma migration for Melissa tables

**Tables to Create:**
- `MelissaPersona` (persona configurations)
- `ChatProtocol` (conversation rules)
- `PlaybookSource` (human-authored Markdown)
- `PlaybookCompiled` (compiled JSON structures)

**NOTE:** These models already exist in `prisma/schema.prisma` (lines 857-1000+). We just need to run the migration.

**Check Current Schema:**
```bash
grep -n "model MelissaPersona" prisma/schema.prisma
grep -n "model ChatProtocol" prisma/schema.prisma
grep -n "model PlaybookSource" prisma/schema.prisma
grep -n "model PlaybookCompiled" prisma/schema.prisma
```

**If models exist (they should):**
```bash
# Generate migration
npx prisma migrate dev --name add_melissa_playbook_tables

# Expected output:
# Applying migration `20241115_add_melissa_playbook_tables`
# ✔ Generated Prisma Client
```

**If models don't exist (unlikely):**
- Models should have been added by installation scripts
- Check `_build-prompts/Melissa-Playbooks/1_schema_and_migrate.sh`
- Run the script or manually add models from script

**Verification:**
```bash
# Check database
npx prisma studio
# Navigate to MelissaPersona table - should exist
```

---

### Phase 5: Create Minimal Test Playbook (1 hour)

**Goal:** Write `bottleneck_minimal_v1.md` playbook

**File:** `data/playbooks/bottleneck_minimal_v1.md`

**Spec:** 5 questions, 2 phases, follows PLAYBOOK_SPEC_V1.md format

**Content:**
```markdown
---
slug: bottleneck-minimal-v1
category: process-optimization
objective: "Identify process bottlenecks and estimate automation ROI"
protocol: standard-discovery
persona: melissa-default
version: 1.0.0
---

# Bottleneck Discovery Workshop (Minimal)

A streamlined 5-question discovery to identify workflow bottlenecks and estimate ROI potential.

## Phases
- greet_frame
- discover_probe

## Questions

- id: q_intro_name
  phase: greet_frame
  type: free_text
  text: "Let's start with your name. What should I call you?"

- id: q_intro_role
  phase: greet_frame
  type: free_text
  text: "What's your role in the organization?"

- id: q_intro_process
  phase: greet_frame
  type: free_text
  text: "Which process or workflow would you like to optimize?"

- id: q_discover_time
  phase: discover_probe
  type: free_text
  text: "Approximately how many hours per week does your team spend on this process?"

- id: q_discover_pain
  phase: discover_probe
  type: free_text
  text: "What's the biggest frustration or bottleneck in this process?"

## Rules
oneQuestionMode: true
maxFollowups: 2

## Scoring
(Not implemented in v1.0.0 - placeholder for future)

## Report
(Not implemented in v1.0.0 - placeholder for future)
```

**Test Compilation:**
```typescript
// scripts/test-playbook-compilation.ts
import { prisma } from '@/lib/db/client';
import { compilePlaybookSource } from '@/lib/melissa/playbookCompiler';
import fs from 'fs';

async function testCompilation() {
  // Read playbook markdown
  const markdown = fs.readFileSync('data/playbooks/bottleneck_minimal_v1.md', 'utf-8');

  // Create PlaybookSource
  const source = await prisma.playbookSource.create({
    data: {
      slug: 'bottleneck-minimal-v1',
      name: 'Bottleneck Discovery (Minimal)',
      category: 'process-optimization',
      objective: 'Identify process bottlenecks and estimate automation ROI',
      version: '1.0.0',
      personaId: 'default-persona-id', // Get from seed
      protocolId: 'default-protocol-id', // Get from seed
      markdown,
      organizationId: 'default-org-id',
    },
  });

  // Compile it
  const compiled = await compilePlaybookSource(source.id, { activate: true });

  console.log('✓ Compilation successful!');
  console.log(`  - Questions extracted: ${compiled.questions.length}`);
  console.log(`  - Phases: ${Object.keys(compiled.phaseMap).join(', ')}`);
  console.log(`  - Status: ${compiled.status}`);
  console.log(`  - Active: ${compiled.isActive}`);
}

testCompilation();
```

**Run:**
```bash
npx ts-node scripts/test-playbook-compilation.ts
```

---

### Phase 6: Create Seed Script Enhancement (30 mins)

**Goal:** Update `prisma/seed.ts` to populate Melissa tables

**Add to existing seed.ts:**
```typescript
// After Organization and User creation...

console.log('🧠 Seeding Melissa Playbook data...');

// 1. Create default persona
const defaultPersona = await prisma.melissaPersona.create({
  data: {
    slug: 'melissa-default',
    name: 'Melissa (Default)',
    description: 'Friendly, inquisitive AI facilitator for ROI discovery workshops',
    baseTone: 'professional-warm',
    explorationTone: 'curious',
    synthesisTone: 'analytical',
    cognitionPrimary: 'analytical',
    cognitionSecondary: 'empathetic',
    cognitionTertiary: 'creative',
    curiosityModes: ['exploratory', 'clarifying', 'validating'],
    explorationLevel: 70,
    structureLevel: 60,
    isDefault: true,
    organizationId: org.id,
  },
});
console.log(`  ✓ Created MelissaPersona: ${defaultPersona.slug}`);

// 2. Create default protocol
const defaultProtocol = await prisma.chatProtocol.create({
  data: {
    slug: 'standard-discovery',
    name: 'Standard Discovery Protocol',
    description: '15-minute guided discovery with structured phases',
    oneQuestionMode: true,
    maxQuestions: 25,
    maxFollowups: 3,
    allowQuestionMerging: false,
    allowQuestionSkipping: false,
    driftSoftLimit: 3,
    driftHardLimit: 5,
    phases: ['greet_frame', 'discover_probe', 'validate_quantify', 'synthesize_reflect', 'advance_close'],
    strictPhases: true,
    isDefault: true,
    organizationId: org.id,
  },
});
console.log(`  ✓ Created ChatProtocol: ${defaultProtocol.slug}`);

// 3. Create playbook source (read from file)
const playbookMarkdown = fs.readFileSync('data/playbooks/bottleneck_minimal_v1.md', 'utf-8');

const playbookSource = await prisma.playbookSource.create({
  data: {
    slug: 'bottleneck-minimal-v1',
    name: 'Bottleneck Discovery (Minimal)',
    category: 'process-optimization',
    objective: 'Identify process bottlenecks and estimate automation ROI',
    version: '1.0.0',
    personaId: defaultPersona.id,
    protocolId: defaultProtocol.id,
    markdown: playbookMarkdown,
    organizationId: org.id,
  },
});
console.log(`  ✓ Created PlaybookSource: ${playbookSource.slug}`);

// 4. Compile the playbook
import { compilePlaybookSource } from '@/lib/melissa/playbookCompiler';

const compiledPlaybook = await compilePlaybookSource(playbookSource.id, { activate: true });
console.log(`  ✓ Compiled PlaybookCompiled: ${compiledPlaybook.slug} (${(compiledPlaybook.questions as any[]).length} questions)`);

console.log('✅ Melissa Playbook seed complete!\n');
```

**Run seed:**
```bash
npx prisma db seed

# Expected output:
# 🧠 Seeding Melissa Playbook data...
#   ✓ Created MelissaPersona: melissa-default
#   ✓ Created ChatProtocol: standard-discovery
#   ✓ Created PlaybookSource: bottleneck-minimal-v1
#   ✓ Compiled PlaybookCompiled: bottleneck-minimal-v1 (5 questions)
# ✅ Melissa Playbook seed complete!
```

---

### Phase 7: End-to-End Verification (30 mins)

**Goal:** Test full pipeline: Markdown → Parser → Compiled → IFL Engine

**Verification Script:** `scripts/verify-melissa-pipeline.ts`

```typescript
import { prisma } from '@/lib/db/client';
import { getActiveCompiledBySlug } from '@/lib/melissa/playbookService';
import { getDefaultPersona } from '@/lib/melissa/personaService';
import { getDefaultProtocol } from '@/lib/melissa/protocolService';
import { buildInitialSessionContext } from '@/lib/melissa/sessionContext';
import { extractQuestions, getNextQuestion, applyAnswer } from '@/lib/melissa/iflEngine';
import { buildPrompt } from '@/lib/melissa/promptBuilder';

async function verifyPipeline() {
  console.log('='.repeat(60));
  console.log('Melissa Playbook Pipeline Verification');
  console.log('='.repeat(60));
  console.log('');

  // Step 1: Load playbook
  console.log('1. Loading compiled playbook...');
  const playbook = await getActiveCompiledBySlug('bottleneck-minimal-v1');
  if (!playbook) throw new Error('Playbook not found');
  console.log(`   ✓ Loaded: ${playbook.name}`);
  console.log(`   ✓ Questions: ${(playbook.questions as any[]).length}`);
  console.log('');

  // Step 2: Load persona and protocol
  console.log('2. Loading persona and protocol...');
  const persona = await getDefaultPersona();
  const protocol = await getDefaultProtocol();
  if (!persona || !protocol) throw new Error('Persona or protocol not found');
  console.log(`   ✓ Persona: ${persona.name}`);
  console.log(`   ✓ Protocol: ${protocol.name}`);
  console.log('');

  // Step 3: Initialize session
  console.log('3. Initializing session context...');
  let ctx = buildInitialSessionContext('verify-session', 'default-org');
  console.log(`   ✓ Session ID: ${ctx.sessionId}`);
  console.log(`   ✓ Total questions asked: ${ctx.totalQuestionsAsked}`);
  console.log('');

  // Step 4: Get first question
  console.log('4. Getting first question...');
  const questions = extractQuestions(playbook);
  const firstQuestion = getNextQuestion(ctx, playbook);
  if (!firstQuestion) throw new Error('No questions found');
  console.log(`   ✓ Question ID: ${firstQuestion.id}`);
  console.log(`   ✓ Phase: ${firstQuestion.phase}`);
  console.log(`   ✓ Text: ${firstQuestion.text}`);
  console.log('');

  // Step 5: Build prompt
  console.log('5. Building LLM prompt...');
  const prompt = buildPrompt({
    persona,
    protocol,
    playbook,
    ctx,
    question: firstQuestion,
  });
  console.log(`   ✓ Prompt length: ${prompt.length} chars`);
  console.log(`   ✓ Contains persona: ${prompt.includes(persona.name)}`);
  console.log(`   ✓ Contains protocol: ${prompt.includes(protocol.name)}`);
  console.log('');

  // Step 6: Apply answer and test phase progression
  console.log('6. Testing phase progression...');
  ctx = applyAnswer(ctx, firstQuestion.id, 'Test answer', playbook, {
    phases: protocol.phases as string[],
    strictPhases: protocol.strictPhases,
  });
  console.log(`   ✓ Answer recorded: ${ctx.answers[firstQuestion.id]}`);
  console.log(`   ✓ Current phase: ${ctx.currentPhase}`);
  console.log(`   ✓ Questions asked: ${ctx.totalQuestionsAsked}`);
  console.log('');

  // Step 7: Answer all greet_frame questions
  console.log('7. Completing greet_frame phase...');
  const greetQuestions = questions.filter(q => q.phase === 'greet_frame');
  console.log(`   - Found ${greetQuestions.length} questions in greet_frame`);

  for (let i = 1; i < greetQuestions.length; i++) {
    const q = greetQuestions[i];
    ctx = applyAnswer(ctx, q.id, `Test answer ${i + 1}`, playbook, {
      phases: protocol.phases as string[],
      strictPhases: protocol.strictPhases,
    });
  }
  console.log(`   ✓ Answered ${greetQuestions.length} questions`);
  console.log(`   ✓ Current phase: ${ctx.currentPhase}`);
  console.log('');

  // Step 8: Get next question (should be from discover_probe)
  console.log('8. Testing phase transition...');
  const nextQuestion = getNextQuestion(ctx, playbook);
  if (!nextQuestion) throw new Error('No next question found');
  console.log(`   ✓ Next question ID: ${nextQuestion.id}`);
  console.log(`   ✓ Next question phase: ${nextQuestion.phase}`);
  console.log(`   ✓ Phase advanced: ${nextQuestion.phase === 'discover_probe'}`);
  console.log('');

  console.log('='.repeat(60));
  console.log('✅ All verification checks passed!');
  console.log('='.repeat(60));
}

verifyPipeline().catch(console.error);
```

**Run verification:**
```bash
npx ts-node scripts/verify-melissa-pipeline.ts

# Expected output:
# ============================================================
# Melissa Playbook Pipeline Verification
# ============================================================
#
# 1. Loading compiled playbook...
#    ✓ Loaded: Bottleneck Discovery (Minimal)
#    ✓ Questions: 5
#
# 2. Loading persona and protocol...
#    ✓ Persona: Melissa (Default)
#    ✓ Protocol: Standard Discovery Protocol
#
# ... (all steps pass)
#
# ============================================================
# ✅ All verification checks passed!
# ============================================================
```

---

## Final Checklist

Before considering Melissa Playbook system complete, verify:

- [ ] All 8 bugs fixed (Bugs #1-8)
- [ ] Bug #8 (IFL phase progression) completed by local Claude Code
- [ ] Database migration applied successfully
- [ ] Seed script creates: Persona, Protocol, PlaybookSource, PlaybookCompiled
- [ ] Compiler unit tests pass (all 5 extraction functions)
- [ ] IFL engine unit tests pass (phase progression)
- [ ] End-to-end verification script passes
- [ ] Type checking passes: `npx tsc --noEmit`
- [ ] Build succeeds: `npm run build`
- [ ] All tests pass: `npm test`

---

## Post-Implementation: Next Steps

After this implementation completes, you'll have:

✅ **Core Engine:** Fully functional IFL engine with phase progression
✅ **Compiler:** Markdown → JSON parser with test coverage
✅ **Data Layer:** Seeded database with sample playbook
✅ **Service Layer:** Persona, Protocol, Playbook services
✅ **Prompt Builder:** Context-aware LLM prompt composition

**What's still needed (out of scope for now):**

1. **API Endpoint:** `/api/melissa/playbook/chat` (new endpoint for IFL-based chat)
2. **Frontend Integration:** UI components for playbook-driven conversations
3. **ROI Calculation:** Connect session data to ROI engine
4. **Report Generation:** Generate reports from completed sessions
5. **Additional Playbooks:** More sophisticated playbooks (10-15 questions, 4-5 phases)

**Estimated time for full production readiness:** +10-15 hours

---

## Questions or Issues?

**Reference Documentation:**
- Playbook Format: `docs/playbooks/PLAYBOOK_SPEC_V1.md`
- Bug #8 Implementation: `_build-prompts/Melissa-Playbooks/BUG-8-IFL-PHASE-PROGRESSION-FIX.md`
- Codex Review: `_build-prompts/Melissa-Playbooks/MelissaPlaybookClaude-review.md`
- FRD Spec: `docs/playbooks/PLAYBOOK_SPEC_V1.md`

**Contact:** Refer to original implementation prompts or run Codex scan for validation

---

*Generated: 2025-11-15*
*Status: Ready for implementation*
*Total Estimated Time: 6-8 hours*
