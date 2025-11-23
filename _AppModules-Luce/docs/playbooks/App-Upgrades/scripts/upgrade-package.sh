#!/bin/bash
# upgrade-package.sh - Interactive package upgrade with package.json tracking
# Usage: ./upgrade-package.sh <package-name> [version]
#        ./upgrade-package.sh @anthropic-ai/sdk latest
#        ./upgrade-package.sh next 16.0.3

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check arguments
if [ -z "$1" ]; then
  echo -e "${RED}Error: Package name required${NC}"
  echo "Usage: $0 <package-name> [version]"
  echo "Examples:"
  echo "  $0 @anthropic-ai/sdk latest"
  echo "  $0 next 16.0.3"
  echo "  $0 bcryptjs"
  exit 1
fi

PACKAGE=$1
VERSION=${2:-latest}

echo -e "${BLUE}=== Package Upgrade Tracker ===${NC}"
echo -e "Package: ${YELLOW}$PACKAGE${NC}"
echo -e "Target version: ${YELLOW}$VERSION${NC}"
echo ""

# Create upgrade tracking directory
mkdir -p _build/upgrade-tracking
TRACKING_DIR="_build/upgrade-tracking"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)
TRACKING_FILE="${TRACKING_DIR}/upgrade-${PACKAGE//\//-}-${TIMESTAMP}.json"

# Step 1: Capture current state from package.json
echo -e "${BLUE}[1/6] Reading current package.json...${NC}"

CURRENT_VERSION=$(cat package.json | jq -r ".dependencies.\"$PACKAGE\" // .devDependencies.\"$PACKAGE\" // \"not installed\"" | sed 's/[\^~]//g')
IS_DEV_DEP=$(cat package.json | jq -r "if .devDependencies.\"$PACKAGE\" then \"true\" else \"false\" end")

if [ "$CURRENT_VERSION" = "not installed" ] || [ "$CURRENT_VERSION" = "null" ]; then
  echo -e "${YELLOW}⚠️  Package not found in package.json${NC}"
  echo -e "Will install as new dependency"
  CURRENT_VERSION="0.0.0"
  IS_NEW_INSTALL="true"
else
  echo -e "${GREEN}Current version: $CURRENT_VERSION${NC}"
  IS_NEW_INSTALL="false"
fi

# Step 2: Save package.json snapshot
echo -e "\n${BLUE}[2/6] Saving package.json snapshot...${NC}"
cp package.json "${TRACKING_DIR}/package.json.before-${TIMESTAMP}"
echo -e "${GREEN}✅ Snapshot saved${NC}"

# Step 3: Check what version will be installed
echo -e "\n${BLUE}[3/6] Resolving target version...${NC}"
if [ "$VERSION" = "latest" ]; then
  TARGET_VERSION=$(npm view "$PACKAGE" version 2>/dev/null || echo "unknown")
else
  TARGET_VERSION="$VERSION"
fi

echo -e "${GREEN}Target version: $TARGET_VERSION${NC}"

# Step 4: Install/upgrade package
echo -e "\n${BLUE}[4/6] Installing package...${NC}"

if [ "$IS_NEW_INSTALL" = "true" ]; then
  echo -e "${YELLOW}Installing new package...${NC}"
  if [ "$IS_DEV_DEP" = "true" ]; then
    npm install --save-dev "$PACKAGE@$VERSION"
  else
    npm install "$PACKAGE@$VERSION"
  fi
else
  echo -e "${YELLOW}Upgrading existing package...${NC}"
  if [ "$IS_DEV_DEP" = "true" ]; then
    npm install --save-dev "$PACKAGE@$VERSION"
  else
    npm install "$PACKAGE@$VERSION"
  fi
fi

# Step 5: Capture new state from package.json
echo -e "\n${BLUE}[5/6] Reading updated package.json...${NC}"

NEW_VERSION=$(cat package.json | jq -r ".dependencies.\"$PACKAGE\" // .devDependencies.\"$PACKAGE\"" | sed 's/[\^~]//g')
cp package.json "${TRACKING_DIR}/package.json.after-${TIMESTAMP}"

echo -e "${GREEN}New version: $NEW_VERSION${NC}"

# Step 6: Create tracking record
echo -e "\n${BLUE}[6/6] Creating tracking record...${NC}"

cat > "$TRACKING_FILE" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "package": "$PACKAGE",
  "type": "$([ "$IS_DEV_DEP" = "true" ] && echo "devDependencies" || echo "dependencies")",
  "versions": {
    "before": "$CURRENT_VERSION",
    "after": "$NEW_VERSION",
    "target": "$TARGET_VERSION"
  },
  "action": "$([ "$IS_NEW_INSTALL" = "true" ] && echo "install" || echo "upgrade")",
  "files": {
    "before": "package.json.before-${TIMESTAMP}",
    "after": "package.json.after-${TIMESTAMP}",
    "tracking": "$(basename $TRACKING_FILE)"
  },
  "git": {
    "branch": "$(git branch --show-current 2>/dev/null || echo "unknown")",
    "commit": "$(git rev-parse HEAD 2>/dev/null || echo "unknown")"
  },
  "system": {
    "node": "$(node --version)",
    "npm": "$(npm --version)"
  }
}
EOF

echo -e "${GREEN}✅ Tracking record saved to: $TRACKING_FILE${NC}"

# Display summary
echo ""
echo -e "${BLUE}=== Upgrade Summary ===${NC}"
echo -e "Package: ${YELLOW}$PACKAGE${NC}"
echo -e "Before: ${RED}$CURRENT_VERSION${NC}"
echo -e "After:  ${GREEN}$NEW_VERSION${NC}"
echo -e "Type:   $([ "$IS_DEV_DEP" = "true" ] && echo "devDependency" || echo "dependency")"
echo ""
echo -e "${BLUE}Files saved:${NC}"
echo "  Before: ${TRACKING_DIR}/package.json.before-${TIMESTAMP}"
echo "  After:  ${TRACKING_DIR}/package.json.after-${TIMESTAMP}"
echo "  Tracking: $TRACKING_FILE"
echo ""
echo -e "${BLUE}View diff:${NC}"
echo "  diff ${TRACKING_DIR}/package.json.before-${TIMESTAMP} ${TRACKING_DIR}/package.json.after-${TIMESTAMP}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review changes: git diff package.json package-lock.json"
echo "2. Run validation: ./scripts/upgrade-validate.sh"
echo "3. Run tests: npm test"
echo "4. Commit: git add . && git commit -m 'feat: upgrade $PACKAGE $CURRENT_VERSION → $NEW_VERSION'"
