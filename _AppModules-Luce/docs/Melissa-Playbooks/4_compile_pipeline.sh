#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

TARGET_DIR="lib/melissa"
mkdir -p "${TARGET_DIR}"

COMPILER_FILE="${TARGET_DIR}/playbookCompiler.ts"

if [[ -f "${COMPILER_FILE}" ]]; then
  echo "${COMPILER_FILE} already exists, skipping."
  exit 0
fi

cat > "${COMPILER_FILE}" <<'EOF'
import { PlaybookSource, PlaybookCompiled } from '@prisma/client';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * DTO for compiled playbook content.
 */
export interface CompiledPlaybookDTO {
  name: string;
  slug: string;
  category: string;
  objective?: string | null;
  version: string;
  phaseMap: any;
  questions: any;
  scoringModel?: any;
  reportSpec?: any;
  rulesOverrides?: any;
  compileInfo?: any;
}

/**
 * Parse a PlaybookSource.markdown into a structured DTO.
 * For v1, this is a placeholder that expects the Markdown to roughly
 * follow docs/playbooks/PLAYBOOK_SPEC_V1.md and can be gradually
 * improved or LLM-assisted.
 */
export function parseMarkdownToPlaybookDTO(source: PlaybookSource): CompiledPlaybookDTO {
  // TODO: Implement real parsing logic.
  // For now, return a trivial DTO using defaults, so you can wire through the plumbing
  // and write tests. Use the spec in docs/playbooks/PLAYBOOK_SPEC_V1.md as your guide.
  return {
    name: source.name,
    slug: source.slug,
    category: source.category,
    objective: source.objective,
    version: source.version,
    phaseMap: {
      greet_frame: [],
      discover_probe: [],
      validate_quantify: [],
      synthesize_reflect: [],
      advance_close: [],
    },
    questions: [],
    scoringModel: null,
    reportSpec: null,
    rulesOverrides: null,
    compileInfo: {
      notes: 'parseMarkdownToPlaybookDTO is using a placeholder implementation.',
      sourceId: source.id,
    },
  };
}

/**
 * Compile a PlaybookSource into a PlaybookCompiled row.
 * Optionally mark it active.
 */
export async function compilePlaybookSource(sourceId: string, options?: { activate?: boolean }): Promise<PlaybookCompiled> {
  const source = await prisma.playbookSource.findUnique({
    where: { id: sourceId },
  });

  if (!source) {
    throw new Error(`PlaybookSource not found for id=${sourceId}`);
  }

  const dto = parseMarkdownToPlaybookDTO(source);

  // Deactivate existing compiled variants for this slug if we're activating this one.
  if (options?.activate) {
    await prisma.playbookCompiled.updateMany({
      where: { slug: dto.slug },
      data: { isActive: false },
    });
  }

  const compiled = await prisma.playbookCompiled.create({
    data: {
      sourceId: source.id,
      name: dto.name,
      slug: dto.slug,
      category: dto.category,
      objective: dto.objective ?? null,
      version: dto.version,
      status: 'compiled_ok',
      isActive: options?.activate ?? false,
      personaId: source.personaId,
      protocolId: source.protocolId,
      phaseMap: dto.phaseMap,
      questions: dto.questions,
      scoringModel: dto.scoringModel,
      reportSpec: dto.reportSpec,
      rulesOverrides: dto.rulesOverrides,
      compileInfo: dto.compileInfo,
    },
  });

  return compiled;
}
EOF

echo "Compile pipeline stub created at ${COMPILER_FILE}"
