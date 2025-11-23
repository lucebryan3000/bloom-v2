#!/usr/bin/env bash
set -euo pipefail

# Basic validator for docs/kb tech knowledge bases.
# - Checks required structure
# - Ensures llms.md index coverage
# - Runs primitive secret / project-name scans
# - Designed to be run from the repo root.

KB_ROOT="docs/kb"
FAILURES=0

if [[ ! -d "$KB_ROOT" ]]; then
  echo "KB root '$KB_ROOT' not found. Run this from the repo root."
  exit 1
fi

echo "==> Validating tech KB under $KB_ROOT"

# Allow caller to configure known project/client names to block
FORBIDDEN_NAMES_DEFAULT="Bloom Appmelia Gallant"
FORBIDDEN_NAMES="${FORBIDDEN_NAMES:-$FORBIDDEN_NAMES_DEFAULT}"

# Profiles and line targets are advisory. This script does not enforce line counts strictly.

# 1) Check llms.md exists
if [[ ! -f "$KB_ROOT/llms.md" ]]; then
  echo "  ❌ Missing $KB_ROOT/llms.md (AI navigation index)"
  FAILURES=$((FAILURES + 1))
else
  echo "  ✅ Found $KB_ROOT/llms.md"
fi

# 2) Iterate topic folders
TOPIC_DIRS=()
while IFS= read -r -d '' dir; do
  name=$(basename "$dir")
  # Skip meta folders
  if [[ "$name" == ".codex" || "$name" == "templates" ]]; then
    continue
  fi
  TOPIC_DIRS+=("$dir")
done < <(find "$KB_ROOT" -maxdepth 1 -mindepth 1 -type d -print0)

if [[ ${#TOPIC_DIRS[@]} -eq 0 ]]; then
  echo "  ❌ No topic directories found under $KB_ROOT"
  FAILURES=$((FAILURES + 1))
fi

# Required core filenames (technology KBs may add more)
CORE_FILES=("README.md" "INDEX.md" "QUICK-REFERENCE.md" "FRAMEWORK-INTEGRATION-PATTERNS.md")

for dir in "${TOPIC_DIRS[@]}"; do
  topic=$(basename "$dir")
  echo "  -> Checking topic '$topic'"

  for f in "${CORE_FILES[@]}"; do
    if [[ ! -f "$dir/$f" ]]; then
      echo "     ❌ Missing $f"
      FAILURES=$((FAILURES + 1))
    fi
  done

  # 3) Front-matter presence check (very loose)
  for md in "$dir"/*.md; do
    if [[ ! -f "$md" ]]; then
      continue
    fi
    if ! head -n 1 "$md" | grep -q "^---"; then
      echo "     ❌ $md missing front-matter header"
      FAILURES=$((FAILURES + 1))
    fi
  done

  # 4) Secret / forbidden name scan
  # Simple heuristics: obvious key headers, common patterns, plus configured names.
  if grep -E -n "BEGIN (RSA|OPENSSH) PRIVATE KEY|AKIA[0-9A-Z]{16}|xox[baprs]-[0-9A-Za-z-]{10,48}" "$dir"/*.md 2>/dev/null; then
    echo "     ❌ Potential secrets found in $topic KB"
    FAILURES=$((FAILURES + 1))
  fi

  for name in $FORBIDDEN_NAMES; do
    if grep -qi "$name" "$dir"/*.md 2>/dev/null; then
      echo "     ❌ Forbidden project/client name '$name' found in $topic KB"
      FAILURES=$((FAILURES + 1))
    fi
  done

done

# 5) Link integrity check (internal links only, simple heuristic)
echo "==> Checking internal markdown links"
BROKEN_LINKS=0
while IFS= read -r -d '' md; do
  while IFS= read -r link; do
    # extract target path before any '#'
    target=$(printf "%s" "$link" | sed -E 's/^[^)]*\(([^)#]+)(#[^)]+)?\).*/\1/')
    # only check relative links
    if [[ "$target" == .* ]]; then
      base_dir=$(dirname "$md")
      full_target="$base_dir/$target"
      if [[ ! -e "$full_target" ]]; then
        echo "  ❌ Broken link in $md -> $target"
        BROKEN_LINKS=$((BROKEN_LINKS + 1))
      fi
    fi
  done < <(grep -oE "\[[^]]+\]\([^)]+\)" "$md" || true)
done < <(find "$KB_ROOT" -name "*.md" -print0)

if [[ $BROKEN_LINKS -gt 0 ]]; then
  FAILURES=$((FAILURES + 1))
fi

echo "==> Validation complete"

if [[ $FAILURES -gt 0 ]]; then
  echo "Result: ❌ $FAILURES issue(s) found"
  exit 1
else
  echo "Result: ✅ No blocking issues found"
fi
