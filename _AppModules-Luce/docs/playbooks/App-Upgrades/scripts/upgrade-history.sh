#!/bin/bash
# upgrade-history.sh - View package upgrade history from tracking records
# Usage: ./upgrade-history.sh [package-name]

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

TRACKING_DIR="_build/upgrade-tracking"

echo -e "${BLUE}=== Package Upgrade History ===${NC}\n"

# Check if tracking directory exists
if [ ! -d "$TRACKING_DIR" ]; then
  echo -e "${YELLOW}No upgrade history found${NC}"
  echo "Tracking directory does not exist: $TRACKING_DIR"
  exit 0
fi

# Filter by package if specified
PACKAGE_FILTER=$1

if [ -n "$PACKAGE_FILTER" ]; then
  echo -e "${BLUE}Filtering by package: ${YELLOW}$PACKAGE_FILTER${NC}\n"
fi

# Find all tracking files
TRACKING_FILES=$(find "$TRACKING_DIR" -name "upgrade-*.json" -type f | sort -r)

if [ -z "$TRACKING_FILES" ]; then
  echo -e "${YELLOW}No upgrade records found${NC}"
  exit 0
fi

# Display records
COUNT=0
while IFS= read -r file; do
  # Read tracking data
  PACKAGE=$(cat "$file" | jq -r '.package')

  # Skip if filtering and doesn't match
  if [ -n "$PACKAGE_FILTER" ] && [ "$PACKAGE" != "$PACKAGE_FILTER" ]; then
    continue
  fi

  COUNT=$((COUNT + 1))

  TIMESTAMP=$(cat "$file" | jq -r '.timestamp')
  VERSION_BEFORE=$(cat "$file" | jq -r '.versions.before')
  VERSION_AFTER=$(cat "$file" | jq -r '.versions.after')
  ACTION=$(cat "$file" | jq -r '.action')
  TYPE=$(cat "$file" | jq -r '.type')
  GIT_BRANCH=$(cat "$file" | jq -r '.git.branch')
  GIT_COMMIT=$(cat "$file" | jq -r '.git.commit' | cut -c1-8)

  # Color code the action
  if [ "$ACTION" = "install" ]; then
    ACTION_COLOR="${GREEN}"
    ACTION_LABEL="INSTALL"
  else
    ACTION_COLOR="${BLUE}"
    ACTION_LABEL="UPGRADE"
  fi

  echo -e "${ACTION_COLOR}[$ACTION_LABEL]${NC} ${YELLOW}$PACKAGE${NC}"
  echo -e "  Time:    $TIMESTAMP"
  echo -e "  Versions: ${RED}$VERSION_BEFORE${NC} → ${GREEN}$VERSION_AFTER${NC}"
  echo -e "  Type:     $TYPE"
  echo -e "  Git:      $GIT_BRANCH @ $GIT_COMMIT"
  echo -e "  Record:   $(basename $file)"
  echo ""
done <<< "$TRACKING_FILES"

if [ $COUNT -eq 0 ]; then
  echo -e "${YELLOW}No upgrades found matching filter${NC}"
else
  echo -e "${BLUE}Total upgrades: $COUNT${NC}"
fi

echo ""
echo -e "${BLUE}Commands:${NC}"
echo "  View details: cat $TRACKING_DIR/upgrade-<package>-<timestamp>.json | jq"
echo "  Compare before/after: diff $TRACKING_DIR/package.json.before-<timestamp> $TRACKING_DIR/package.json.after-<timestamp>"
echo "  Filter by package: $0 <package-name>"
