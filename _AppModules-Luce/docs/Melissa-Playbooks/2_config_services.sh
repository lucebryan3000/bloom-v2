#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "${ROOT_DIR}"

TARGET_DIR="lib/melissa"
mkdir -p "${TARGET_DIR}"

PERSONA_SERVICE="${TARGET_DIR}/personaService.ts"
PROTOCOL_SERVICE="${TARGET_DIR}/protocolService.ts"
PLAYBOOK_SERVICE="${TARGET_DIR}/playbookService.ts"

if [[ ! -f "${PERSONA_SERVICE}" ]]; then
  cat > "${PERSONA_SERVICE}" <<'EOF'
import { PrismaClient, MelissaPersona } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Service functions for loading Melissa persona configuration.
 */
export async function getDefaultPersona(organizationId?: string): Promise<MelissaPersona | null> {
  if (organizationId) {
    const scoped = await prisma.melissaPersona.findFirst({
      where: { organizationId, isDefault: true },
    });
    if (scoped) return scoped;
  }
  return prisma.melissaPersona.findFirst({
    where: { isDefault: true },
  });
}

export async function getPersonaBySlug(slug: string, organizationId?: string): Promise<MelissaPersona | null> {
  if (organizationId) {
    const scoped = await prisma.melissaPersona.findFirst({
      where: { slug, organizationId },
    });
    if (scoped) return scoped;
  }
  return prisma.melissaPersona.findUnique({
    where: { slug },
  });
}
EOF
  echo "Created ${PERSONA_SERVICE}"
else
  echo "Persona service already exists at ${PERSONA_SERVICE}, skipping."
fi

if [[ ! -f "${PROTOCOL_SERVICE}" ]]; then
  cat > "${PROTOCOL_SERVICE}" <<'EOF'
import { PrismaClient, ChatProtocol } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Service functions for loading ChatProtocol configuration.
 */
export async function getDefaultProtocol(organizationId?: string): Promise<ChatProtocol | null> {
  if (organizationId) {
    const scoped = await prisma.chatProtocol.findFirst({
      where: { organizationId, isDefault: true },
    });
    if (scoped) return scoped;
  }
  return prisma.chatProtocol.findFirst({
    where: { isDefault: true },
  });
}

export async function getProtocolBySlug(slug: string, organizationId?: string): Promise<ChatProtocol | null> {
  if (organizationId) {
    const scoped = await prisma.chatProtocol.findFirst({
      where: { slug, organizationId },
    });
    if (scoped) return scoped;
  }
  return prisma.chatProtocol.findUnique({
    where: { slug },
  });
}
EOF
  echo "Created ${PROTOCOL_SERVICE}"
else
  echo "Protocol service already exists at ${PROTOCOL_SERVICE}, skipping."
fi

if [[ ! -f "${PLAYBOOK_SERVICE}" ]]; then
  cat > "${PLAYBOOK_SERVICE}" <<'EOF'
import { PrismaClient, PlaybookSource, PlaybookCompiled } from '@prisma/client';

const prisma = new PrismaClient();

/**
 * Get the human-authored Markdown source by slug.
 */
export async function getPlaybookSourceBySlug(slug: string): Promise<PlaybookSource | null> {
  return prisma.playbookSource.findUnique({
    where: { slug },
  });
}

/**
 * Get the active compiled playbook by slug.
 */
export async function getActiveCompiledBySlug(slug: string): Promise<PlaybookCompiled | null> {
  return prisma.playbookCompiled.findFirst({
    where: {
      slug,
      isActive: true,
      status: 'compiled_ok',
    },
    orderBy: {
      compiledAt: 'desc',
    },
  });
}
EOF
  echo "Created ${PLAYBOOK_SERVICE}"
else
  echo "Playbook service already exists at ${PLAYBOOK_SERVICE}, skipping."
fi

echo "Config services step complete."
