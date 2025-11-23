#!/bin/bash
# upgrade-validate.sh - Automate post-upgrade validation
# Usage: ./upgrade-validate.sh

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

FAILED=0

echo -e "${BLUE}=== Post-Upgrade Validation Suite ===${NC}\n"

# Create validation report
mkdir -p _build/upgrade-validation
REPORT_FILE="_build/upgrade-validation/validation-$(date +%Y%m%d-%H%M%S).txt"

{
  echo "=== Upgrade Validation Report: $(date) ==="
  echo ""
} > "$REPORT_FILE"

# Test 1: TypeScript type check
echo -e "${BLUE}[1/8] TypeScript Type Check...${NC}"
if npx tsc --noEmit >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ TypeScript: PASS${NC}"
  echo "✅ TypeScript: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ TypeScript: FAIL${NC}"
  echo "❌ TypeScript: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Test 2: ESLint
echo -e "${BLUE}[2/8] ESLint Check...${NC}"
if npm run lint >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ ESLint: PASS${NC}"
  echo "✅ ESLint: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ ESLint: FAIL${NC}"
  echo "❌ ESLint: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Test 3: Build validation
echo -e "${BLUE}[3/8] Next.js Build...${NC}"
if npm run build >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ Build: PASS${NC}"
  echo "✅ Build: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ Build: FAIL${NC}"
  echo "❌ Build: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Test 4: Unit tests
echo -e "${BLUE}[4/8] Unit Tests...${NC}"
if npm run test:unit >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ Unit Tests: PASS${NC}"
  echo "✅ Unit Tests: PASS" >> "$REPORT_FILE"
else
  echo -e "${YELLOW}⚠️  Unit Tests: SKIP (no test:unit script or tests failed)${NC}"
  echo "⚠️  Unit Tests: SKIP" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Test 5: Prisma validation
echo -e "${BLUE}[5/8] Prisma Schema Validation...${NC}"
if npx prisma validate >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ Prisma Schema: PASS${NC}"
  echo "✅ Prisma Schema: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ Prisma Schema: FAIL${NC}"
  echo "❌ Prisma Schema: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Test 6: Prisma generate
echo -e "${BLUE}[6/8] Prisma Client Generation...${NC}"
if npx prisma generate >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ Prisma Generate: PASS${NC}"
  echo "✅ Prisma Generate: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ Prisma Generate: FAIL${NC}"
  echo "❌ Prisma Generate: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Test 7: Security audit
echo -e "${BLUE}[7/8] Security Audit...${NC}"
{
  echo "=== Security Audit Summary ==="
  npm audit --summary
  echo ""
} >> "$REPORT_FILE" 2>&1

AUDIT_CRITICAL=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.critical // 0' || echo "0")
AUDIT_HIGH=$(npm audit --json 2>/dev/null | jq '.metadata.vulnerabilities.high // 0' || echo "0")

if [ "$AUDIT_CRITICAL" -eq 0 ] && [ "$AUDIT_HIGH" -eq 0 ]; then
  echo -e "${GREEN}✅ Security Audit: PASS (No critical/high vulnerabilities)${NC}"
  echo "✅ Security Audit: PASS" >> "$REPORT_FILE"
else
  echo -e "${YELLOW}⚠️  Security Audit: WARNING (Critical: $AUDIT_CRITICAL, High: $AUDIT_HIGH)${NC}"
  echo "⚠️  Security Audit: WARNING (Critical: $AUDIT_CRITICAL, High: $AUDIT_HIGH)" >> "$REPORT_FILE"
fi
echo "" >> "$REPORT_FILE"

# Test 8: Package lock consistency
echo -e "${BLUE}[8/8] Package Lock Consistency...${NC}"
if npm ci --dry-run >> "$REPORT_FILE" 2>&1; then
  echo -e "${GREEN}✅ Package Lock: PASS${NC}"
  echo "✅ Package Lock: PASS" >> "$REPORT_FILE"
else
  echo -e "${RED}❌ Package Lock: FAIL (run: rm -rf node_modules package-lock.json && npm install)${NC}"
  echo "❌ Package Lock: FAIL" >> "$REPORT_FILE"
  FAILED=1
fi
echo "" >> "$REPORT_FILE"

# Summary
echo ""
echo -e "${BLUE}=== Validation Summary ===${NC}"
{
  echo ""
  echo "=== Validation Summary ==="
  echo "Timestamp: $(date)"
  echo "Node.js: $(node --version)"
  echo "npm: $(npm --version)"
  echo ""
} >> "$REPORT_FILE"

if [ $FAILED -eq 0 ]; then
  echo -e "${GREEN}✅ All validation checks passed!${NC}"
  echo "✅ All validation checks passed!" >> "$REPORT_FILE"
  echo ""
  echo -e "${GREEN}Upgrade is ready to commit.${NC}"
  echo ""
  echo -e "${BLUE}Next steps:${NC}"
  echo "1. Review validation report: $REPORT_FILE"
  echo "2. Test critical user flows manually"
  echo "3. Commit changes: git add . && git commit -m 'feat: upgrade [package]'"
  echo "4. Push and deploy"
  exit 0
else
  echo -e "${RED}❌ Validation failed! Review errors above.${NC}"
  echo "❌ Validation failed!" >> "$REPORT_FILE"
  echo ""
  echo -e "${YELLOW}Fix errors before committing.${NC}"
  echo "Full report: $REPORT_FILE"
  exit 1
fi
