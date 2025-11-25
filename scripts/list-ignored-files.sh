#!/usr/bin/env bash
set -euo pipefail

# Lists files/directories that exist locally but are excluded from either Git
# (.gitignore + global excludes) or Claude context filtering (.claude/.claudeignore).
# This helps keep AI assistants aware of local-only artifacts that should never
# be uploaded.

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$REPO_ROOT"
export REPO_ROOT

if ! command -v git >/dev/null 2>&1; then
  echo "git is required to run this script" >&2
  exit 1
fi

if ! command -v python3 >/dev/null 2>&1; then
  echo "python3 is required to run this script" >&2
  exit 1
fi

echo "Repo root: $REPO_ROOT"
echo

# ---------------------------------------------------------------------------
# Git-ignored (including globally ignored) items that currently exist
# ---------------------------------------------------------------------------
echo "Git-ignored items (present on disk):"
mapfile -t git_ignored < <(git status --ignored --short | sed -n 's/^!! //p')
if ((${#git_ignored[@]} == 0)); then
  echo "  - none"
else
  for path in "${git_ignored[@]}"; do
    echo "  - $path"
  done
fi
echo

# ---------------------------------------------------------------------------
# Untracked (not ignored) items, just in case something was created locally
# ---------------------------------------------------------------------------
echo "Untracked items (not ignored):"
mapfile -t git_untracked < <(git ls-files --others --exclude-standard)
if ((${#git_untracked[@]} == 0)); then
  echo "  - none"
else
  for path in "${git_untracked[@]}"; do
    echo "  - $path"
  done
fi
echo

# ---------------------------------------------------------------------------
# Claude soft-blocked items that currently exist (.claude/.claudeignore)
# ---------------------------------------------------------------------------
echo "Claude soft-blocked items (from .claude/.claudeignore):"

python3 - <<'PY'
import os
import sys
from pathlib import Path

try:
    import pathspec  # type: ignore
except ImportError:
    print("  - pathspec Python package is required", file=sys.stderr)
    sys.exit(1)

root_env = os.environ.get("REPO_ROOT")
if not root_env:
    print("  - unable to determine repository root from REPO_ROOT", file=sys.stderr)
    sys.exit(1)

root = Path(root_env).resolve()
ignore_file = root / ".claude" / ".claudeignore"

if not ignore_file.exists():
    print("  - none (no .claude/.claudeignore file found)")
    sys.exit(0)

patterns = []
for raw_line in ignore_file.read_text().splitlines():
    stripped = raw_line.strip()
    if not stripped or stripped.startswith("#"):
        continue
    # Remove inline comments so gitwildmatch patterns work as expected
    cleaned = stripped.split("#", 1)[0].rstrip()
    if cleaned:
        patterns.append(cleaned)

if not patterns:
    print("  - none (.claude/.claudeignore is empty)")
    sys.exit(0)

spec = pathspec.PathSpec.from_lines("gitwildmatch", patterns)
matches = set()

for current, dirs, files in os.walk(root):
    rel_dir = Path(current).relative_to(root)

    # Prune .git to keep the scan fast and avoid noise
    dirs[:] = [d for d in dirs if d != ".git"]

    # If an entire directory is ignored, record it once and skip its children
    keep_dirs = []
    for d in dirs:
        rel_path = (rel_dir / d).as_posix()
        if spec.match_file(rel_path + "/"):
            matches.add(rel_path + "/")
        else:
            keep_dirs.append(d)
    dirs[:] = keep_dirs

    for f in files:
        rel_file = (rel_dir / f).as_posix()
        if spec.match_file(rel_file):
            matches.add(rel_file)

if not matches:
    print("  - none (no existing files match .claude/.claudeignore)")
    sys.exit(0)

# Summarize long nested paths so the output stays readable (e.g., dist/ folders)
SUMMARY_DEPTH = 2

def summarize(path: str) -> str:
    is_dir = path.endswith("/")
    parts = path.rstrip("/").split("/")
    if is_dir:
        if len(parts) > SUMMARY_DEPTH:
            parts = parts[:SUMMARY_DEPTH]
        summary = "/".join(parts) + "/"
        return summary

    # For files, keep the filename and the first (SUMMARY_DEPTH-1) directories
    if len(parts) > SUMMARY_DEPTH:
        parts = parts[: max(1, SUMMARY_DEPTH - 1)] + [parts[-1]]
    return "/".join(parts)

summaries = {summarize(path) for path in matches}

# Collapse redundant children so we only show the highest-level ignored path
collapsed = []
for path in sorted(summaries):
    if any(path == parent or path.startswith(parent.rstrip("/") + "/") for parent in collapsed):
        continue
    collapsed.append(path)

for path in collapsed:
    print(f"  - {path}")
PY
