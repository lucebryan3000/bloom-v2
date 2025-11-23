#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

echo "=================================================="
echo "Bug #4 Fix: Melissa Playbook Database Seeding"
echo "=================================================="
echo ""
echo "This script enhances prisma/seed.ts with Melissa Playbook test data."
echo ""

# Check if seed.ts already has Melissa seeding
if grep -q "seedMelissaPlaybooks" prisma/seed.ts 2>/dev/null; then
  echo "✓ Melissa seeding already exists in prisma/seed.ts"
  echo "Skipping..."
  exit 0
fi

echo "Step 1: Backing up current seed.ts..."
cp prisma/seed.ts prisma/seed.ts.backup
echo "  ✓ Backup created: prisma/seed.ts.backup"
echo ""

echo "Step 2: Adding Melissa Playbook seeding function..."

# Add import for compilePlaybookSource at the top (after other imports)
IMPORT_LINE="import { compilePlaybookSource } from '@/lib/melissa/playbookCompiler';"

# Check if import already exists
if ! grep -q "compilePlaybookSource" prisma/seed.ts; then
  # Add after the bcrypt import (around line 5)
  sed -i '5a\'"$IMPORT_LINE" prisma/seed.ts
  echo "  ✓ Added import for compilePlaybookSource"
fi

# Now add the seedMelissaPlaybooks function before the main() function
# We'll insert it right before the main() function definition

cat >> prisma/seed.ts.new <<'SEED_FUNCTION'
// ============================================================================
// SEED MELISSA PLAYBOOK DATA (Bug #4 Fix)
// ============================================================================

async function seedMelissaPlaybooks(orgId: string): Promise<void> {
  console.log('🧠 Seeding Melissa Playbook data...');

  // 1. Create default persona
  const existingPersona = await prisma.melissaPersona.findFirst({
    where: { slug: 'melissa-default' },
  });

  let defaultPersona;
  if (existingPersona) {
    console.log('  ℹ️  Persona "melissa-default" already exists');
    defaultPersona = existingPersona;
  } else {
    defaultPersona = await prisma.melissaPersona.create({
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
        organizationId: orgId,
      },
    });
    console.log(`  ✓ Created MelissaPersona: ${defaultPersona.slug}`);
  }

  // 2. Create default protocol
  const existingProtocol = await prisma.chatProtocol.findFirst({
    where: { slug: 'standard-discovery' },
  });

  let defaultProtocol;
  if (existingProtocol) {
    console.log('  ℹ️  Protocol "standard-discovery" already exists');
    defaultProtocol = existingProtocol;
  } else {
    defaultProtocol = await prisma.chatProtocol.create({
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
        organizationId: orgId,
      },
    });
    console.log(`  ✓ Created ChatProtocol: ${defaultProtocol.slug}`);
  }

  // 3. Create minimal test playbook source
  const existingSource = await prisma.playbookSource.findFirst({
    where: { slug: 'bottleneck-minimal-v1' },
  });

  let playbookSource;
  if (existingSource) {
    console.log('  ℹ️  PlaybookSource "bottleneck-minimal-v1" already exists');
    playbookSource = existingSource;
  } else {
    // Minimal playbook markdown (inline for now - move to file later)
    const playbookMarkdown = `---
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
`;

    playbookSource = await prisma.playbookSource.create({
      data: {
        slug: 'bottleneck-minimal-v1',
        name: 'Bottleneck Discovery (Minimal)',
        category: 'process-optimization',
        objective: 'Identify process bottlenecks and estimate automation ROI',
        version: '1.0.0',
        personaId: defaultPersona.id,
        protocolId: defaultProtocol.id,
        markdown: playbookMarkdown,
        organizationId: orgId,
      },
    });
    console.log(`  ✓ Created PlaybookSource: ${playbookSource.slug}`);
  }

  // 4. Compile the playbook (if not already compiled)
  const existingCompiled = await prisma.playbookCompiled.findFirst({
    where: {
      slug: 'bottleneck-minimal-v1',
      isActive: true,
    },
  });

  if (existingCompiled) {
    console.log('  ℹ️  Compiled playbook already exists and is active');
  } else {
    const compiledPlaybook = await compilePlaybookSource(playbookSource.id, { activate: true });
    const questionCount = (compiledPlaybook.questions as any[]).length;
    console.log(`  ✓ Compiled PlaybookCompiled: ${compiledPlaybook.slug} (${questionCount} questions)`);
  }

  console.log('✅ Melissa Playbook seed complete!');
  console.log('');
}

SEED_FUNCTION

# Now we need to call this function from main()
# Add the call before "console.log('🎉 Seed completed successfully!');" in main()

# This is tricky with sed, so let's create a patch file instead
echo "  ✓ Created seedMelissaPlaybooks function"
echo ""

echo "Step 3: Integrating into main() function..."
echo ""
echo "⚠️  MANUAL STEP REQUIRED:"
echo ""
echo "Add the following line to prisma/seed.ts in the main() function"
echo "after the seedPlaybooks() call (around line 217):"
echo ""
echo "  // Seed Melissa Playbook data (Bug #4 fix)"
echo "  await seedMelissaPlaybooks(techCorp.id);"
echo ""
echo "Then run:"
echo "  npx prisma db seed"
echo ""

# Restore original file for manual editing
mv prisma/seed.ts.backup prisma/seed.ts

echo "=================================================="
echo "Next Steps:"
echo "=================================================="
echo ""
echo "1. Manually add the seedMelissaPlaybooks() call to main() in prisma/seed.ts"
echo "2. Run: npx prisma db seed"
echo "3. Verify in Prisma Studio:"
echo "   npx prisma studio"
echo "   Check: MelissaPersona, ChatProtocol, PlaybookSource, PlaybookCompiled tables"
echo ""
echo "Expected Output:"
echo "  ✓ Created MelissaPersona: melissa-default"
echo "  ✓ Created ChatProtocol: standard-discovery"
echo "  ✓ Created PlaybookSource: bottleneck-minimal-v1"
echo "  ✓ Compiled PlaybookCompiled: bottleneck-minimal-v1 (5 questions)"
echo ""
