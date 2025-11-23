---
id: eza-06-scripting-automation
topic: eza
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals', 'eza-03-filtering-selection']
related_topics: ['shell-automation', 'ci-cd']
embedding_keywords: [eza, scripting, automation, ci, json]
last_reviewed: 2025-02-14
---

# 06 – Scripting & Automation

## 1. Purpose

Demonstrate reliable ways to embed `eza` inside shell scripts, CI pipelines, pre-commit hooks, and diagnostics tooling without breaking due to formatting or environment drift.

## 2. Mental Model / Problem Statement

Automation requires **stable output** and **predictable exit codes**. `eza` exits 0 on success, >0 on errors (missing paths, invalid flags). Focus on:

- Deterministic formatting: disable color/icons, fix time/size units.
- Machine parsing: prefer `--json`, `--oneline`, `--record-separator`.
- Performance: restrict recursion and Git lookups.
- Portability: guard commands behind `command -v eza` checks.

## 3. Golden Path

1. **Feature-detect** – `if command -v eza >/dev/null; then ... fi`
2. **Lock formatting** – `--color=never --no-icons --time-style=long-iso --binary`
3. **Prefer JSON** – `eza --json --long --git > listing.json`
4. **Use `--oneline` + NUL separator** when feeding file paths to other tools: `eza --oneline --record-separator="\0" ... | xargs -0 <cmd>`
5. **Document exit behavior** – treat missing path as failure, capture stderr for debugging.

## 4. Variations & Trade-Offs

- JSON vs. parsing columns: JSON is easiest but not available on very old eza builds; fallback to `--oneline` with delimiters.
- Running in CI containers vs. developer laptops: container paths may lack fonts; keep automation commands icon-free.
- `--hyperlink` is useless in automation; disable to avoid escape codes.

## 5. Examples

### Example 1 – Pedagogical: Guarded script snippet

```sh
if ! command -v eza >/dev/null; then
  echo "eza missing" >&2
  exit 1
fi

eza --long --header --color=never --no-icons "$@"
```
Ensures scripts fail fast if eza is absent.

### Example 2 – Realistic Synthetic: Generate JSON manifest for deploy artifact

```sh
eza --json --long --binary --time-style=long-iso build \
  | jq 'map({name: .name, size: .size, modified: .modified})' > build_manifest.json
```
Produces structured metadata ready for further automation.

### Example 3 – Framework Integration: CI step that lists large files before upload

```yaml
- name: List large artifacts
  run: |
    eza --long --sort=size --reverse --bytes --only-files dist \
        --glob="*.zip" \
        --color=never --no-icons | tee large_artifacts.txt
```
Captures deterministic output for pipeline logs.

## 6. Common Pitfalls

1. Forgetting to disable colors/icons, making logs unreadable.
2. Assuming JSON output order is stable; always treat as data, not sorted list, or sort via `jq`.
3. Not escaping globs in YAML or JSON contexts (use single quotes in shell script blocks).
4. Parsing whitespace-delimited columns when filenames contain spaces; use `--oneline --record-separator='\0'`.
5. Running `eza` before building artifacts; script should `set -e` and fail gracefully if directories don't exist.

## 7. AI Pair Programming Notes

- Provide context (CI runner OS, shell) when asking AI to embed `eza` in automation.
- Ask AI to include fallback instructions for environments lacking `eza`, such as `ls` alternative or installation steps.
- Encourage AI to cite `[EZA-AUTO-JSON]` guidelines when providing JSON parsing recipes.

