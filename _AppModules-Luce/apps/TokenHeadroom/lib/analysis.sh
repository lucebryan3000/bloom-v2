#!/usr/bin/env bash
# lib/analysis.sh — TokenHeadroom context analysis engine

# Run analysis and output JSON
analysis_run_json() {
  local root="${CONTEXT_ROOT:-.}"
  local budget="${CONTEXT_BUDGET:-200000}"

  python3 - "$root" "$budget" <<'PY'
import json
import os
import sys
from pathlib import Path

root = sys.argv[1] if len(sys.argv) > 1 else '.'
budget = int(sys.argv[2]) if len(sys.argv) > 2 else 200000

def estimate_tokens(path):
    """Rough token estimate: ~4 chars per token"""
    try:
        size = os.path.getsize(path)
        return size // 4
    except:
        return 0

def is_ignored(path, ignore_patterns):
    """Check if path matches any ignore pattern"""
    for pat in ignore_patterns:
        pat = pat.strip()
        if not pat or pat.startswith('#'):
            continue
        if pat.endswith('/'):
            if pat[:-1] in path:
                return True
        elif pat in path:
            return True
    return False

# Load .claudeignore patterns
ignore_file = os.path.join(root, '.claudeignore')
ignore_patterns = []
if os.path.exists(ignore_file):
    with open(ignore_file, 'r', encoding='utf-8', errors='ignore') as f:
        ignore_patterns = f.read().splitlines()

# Load settings
settings_file = os.path.join(root, '.claude', 'settings.json')
settings = {}
if os.path.exists(settings_file):
    try:
        with open(settings_file, 'r', encoding='utf-8') as f:
            settings = json.load(f)
    except:
        pass

# Analyze unignored paths
unignored_paths = []
total_tokens = 0
for dirpath, dirnames, filenames in os.walk(root):
    # Skip hidden and common large dirs
    dirnames[:] = [d for d in dirnames if not d.startswith('.') and d not in ('node_modules', '.next', 'dist', 'build', '__pycache__')]

    for fname in filenames:
        if fname.startswith('.'):
            continue
        fpath = os.path.join(dirpath, fname)
        relpath = os.path.relpath(fpath, root)

        if is_ignored(relpath, ignore_patterns):
            continue

        tokens = estimate_tokens(fpath)
        if tokens > 0:
            unignored_paths.append({
                'path': relpath,
                'token_cost': tokens
            })
            total_tokens += tokens

# Sort by token cost descending
unignored_paths.sort(key=lambda x: -x['token_cost'])

# Get auto-include patterns
auto_include = (settings.get('context', {}) or {}).get('autoIncludePatterns', []) or []

# Find large commands (placeholder)
large_commands = []

# Find large docs
large_docs = [p for p in unignored_paths if any(x in p['path'].lower() for x in ('readme', 'doc', 'wiki', 'report', '.md')) and p['token_cost'] > 500]

result = {
    'root': root,
    'targets': ['.claudeignore', '.claude/settings.json'],
    'budget': budget,
    'total_estimated_tokens': total_tokens,
    'headroom': budget - total_tokens,
    'analysis_data': {
        'unignored_paths': unignored_paths[:100],  # Top 100
        'ignore_pattern_count': len([p for p in ignore_patterns if p.strip() and not p.startswith('#')])
    },
    'autoInclude': auto_include,
    'largeCommands': large_commands,
    'largeDocs': large_docs[:20]
}

print(json.dumps(result, indent=2))
PY
}
