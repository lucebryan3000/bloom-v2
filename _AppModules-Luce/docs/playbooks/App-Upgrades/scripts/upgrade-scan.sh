#!/bin/bash
# upgrade-scan.sh - Automate package upgrade discovery
# Usage: ./upgrade-scan.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Package Upgrade Scan ===${NC}\n"

# Create output directory
mkdir -p _build/upgrade-scans
SCAN_FILE="_build/upgrade-scans/scan-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "=== Package Upgrade Scan: $(date) ==="
  echo ""

  # Step 1: npm outdated
  echo "=== npm outdated (All Packages) ==="
  npm outdated || true
  echo ""

  # Step 2: Dependabot PRs
  echo "=== Dependabot Pull Requests ==="
  if command -v gh &> /dev/null; then
    gh pr list --label "dependencies" --json number,title,createdAt,headRefName 2>/dev/null || echo "GitHub CLI not authenticated or no PRs found"
  else
    echo "GitHub CLI (gh) not installed. Install with: sudo apt install gh"
  fi
  echo ""

  # Step 3: Major version upgrades available
  echo "=== Major Version Upgrades Available ==="
  npm outdated --depth=0 | awk 'NR>1 {split($3, curr, "."); split($4, want, "."); if(curr[1] != want[1]) print $1 ": " $3 " → " $4}' || echo "None found"
  echo ""

  # Step 4: Security vulnerabilities
  echo "=== Security Audit ==="
  npm audit --summary || true
  echo ""

  # Step 5: Check for deprecated packages
  echo "=== Deprecated Packages ==="
  npm ls --depth=0 2>&1 | grep -i "deprecated" || echo "None found"
  echo ""

  # Step 6: Specific critical packages
  echo "=== Critical Package Versions ==="
  echo "Checking versions of critical dependencies..."
  for pkg in "next" "@anthropic-ai/sdk" "prisma" "@prisma/client" "react" "react-dom" "typescript" "jest"; do
    CURRENT=$(npm list "$pkg" --depth=0 2>/dev/null | grep "$pkg@" | sed 's/.*@//' || echo "Not installed")
    LATEST=$(npm view "$pkg" version 2>/dev/null || echo "Unknown")
    echo "  $pkg: $CURRENT (Latest: $LATEST)"
  done
  echo ""

  # Step 7: Runtime environment check
  echo "=== Runtime Environment Verification ==="
  echo "Node.js runtime: $(node --version)"
  echo "npm runtime: $(npm --version)"
  echo ""
  echo "Installed vs package.json consistency:"
  INSTALLED_COUNT=$(npm list --depth=0 2>/dev/null | grep -c "@" || echo "0")
  echo "  Packages in node_modules: $INSTALLED_COUNT"

  # Check if package-lock.json is in sync
  if npm ci --dry-run > /dev/null 2>&1; then
    echo "  ✅ package-lock.json is in sync with package.json"
  else
    echo "  ⚠️  package-lock.json may be out of sync - run: npm install"
  fi

  # Check for running dev server
  if lsof -ti:3001 > /dev/null 2>&1; then
    DEV_PID=$(lsof -ti:3001)
    echo "  ⚠️  Dev server running on port 3001 (PID: $DEV_PID)"
    echo "     Server is using versions from current node_modules/"
  else
    echo "  ℹ️  No dev server detected on port 3001"
  fi
  echo ""

} | tee "$SCAN_FILE"

# Analysis
echo -e "${YELLOW}=== Scan Complete ===${NC}"
echo -e "Full scan saved to: ${SCAN_FILE}"
echo ""

# Count findings
MAJOR_COUNT=$(npm outdated --depth=0 2>/dev/null | awk 'NR>1 {split($3, curr, "."); split($4, want, "."); if(curr[1] != want[1]) print $1}' | wc -l || echo "0")
OUTDATED_COUNT=$(npm outdated --depth=0 2>/dev/null | wc -l || echo "0")
AUDIT_CRITICAL=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.critical // 0' || echo "0")
AUDIT_HIGH=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.high // 0' || echo "0")

echo -e "${BLUE}Summary:${NC}"
echo -e "  Outdated packages: ${OUTDATED_COUNT}"
echo -e "  Major version upgrades: ${MAJOR_COUNT}"
echo -e "  Critical vulnerabilities: ${AUDIT_CRITICAL}"
echo -e "  High vulnerabilities: ${AUDIT_HIGH}"
echo ""

# Recommendations
if [ "$MAJOR_COUNT" -gt 0 ]; then
  echo -e "${YELLOW}⚠️  Found $MAJOR_COUNT major version upgrades available${NC}"
  echo -e "   Review each upgrade for breaking changes before proceeding"
fi

if [ "$AUDIT_CRITICAL" -gt 0 ] || [ "$AUDIT_HIGH" -gt 0 ]; then
  echo -e "${RED}⚠️  Found security vulnerabilities (Critical: $AUDIT_CRITICAL, High: $AUDIT_HIGH)${NC}"
  echo -e "   Run: npm audit fix"
fi

echo ""
echo -e "${BLUE}Next steps:${NC}"
echo "1. Review scan results in: $SCAN_FILE"
echo "2. Check Dependabot PRs: gh pr list --label dependencies"
echo "3. Categorize upgrades by risk (LOW/MEDIUM/HIGH/CRITICAL)"
echo "4. Save baseline: ./upgrade-baseline.sh"
echo "5. Start with LOW risk upgrades first"
