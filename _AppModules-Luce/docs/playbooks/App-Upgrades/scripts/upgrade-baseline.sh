#!/bin/bash
# upgrade-baseline.sh - Save baseline state before upgrades
# Usage: ./upgrade-baseline.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Saving Upgrade Baseline ===${NC}"

# Create baseline directory
mkdir -p _build/upgrade-baseline
BASELINE_DIR="_build/upgrade-baseline"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
BASELINE_FILE="${BASELINE_DIR}/baseline-${TIMESTAMP}.txt"

echo -e "${BLUE}Creating baseline snapshot...${NC}"

# Save system info
{
  echo "=== Baseline Snapshot: $(date) ==="
  echo ""
  echo "=== Node.js Version ==="
  node --version
  echo ""
  echo "=== npm Version ==="
  npm --version
  echo ""
  echo "=== Git Status ==="
  git status --short
  echo ""
  echo "=== Git Branch ==="
  git branch --show-current
  echo ""
  echo "=== Installed Package Versions ==="
  npm list --depth=0
  echo ""
  echo "=== Outdated Packages ==="
  npm outdated || true
  echo ""
  echo "=== Dependabot PRs ==="
  gh pr list --label "dependencies" --json number,title,createdAt 2>/dev/null || echo "GitHub CLI not available or not authenticated"
  echo ""
  echo "=== Package.json Dependencies ==="
  cat package.json | jq '.dependencies'
  echo ""
  echo "=== Package.json DevDependencies ==="
  cat package.json | jq '.devDependencies'
  echo ""
  echo "=== TypeScript Version ==="
  npx tsc --version
  echo ""
  echo "=== Audit Summary ==="
  npm audit --summary || true
} > "$BASELINE_FILE"

# Create symlink to latest
ln -sf "$(basename "$BASELINE_FILE")" "${BASELINE_DIR}/latest.txt"

echo -e "${GREEN}✅ Baseline saved to: ${BASELINE_FILE}${NC}"
echo -e "${GREEN}✅ Latest baseline: ${BASELINE_DIR}/latest.txt${NC}"
echo ""
echo -e "${BLUE}To compare later, run:${NC}"
echo "  diff ${BASELINE_DIR}/latest.txt <(npm list --depth=0)"
echo ""
echo -e "${BLUE}To view baseline:${NC}"
echo "  cat ${BASELINE_DIR}/latest.txt"
