---
id: eza-10-structured-output
topic: eza
file_role: advanced
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: ['eza-06-scripting-automation']
related_topics: ['data-pipelines']
embedding_keywords: [eza, json, structured-output, automation, pipelines]
last_reviewed: 2025-02-14
---

# 10 – Structured Output & Pipelines

## 1. Purpose

Document how to leverage `eza` outputs beyond human-readable terminals: JSON streams, oneline formats with record separators, hyperlinks, and integration with data-processing tools (`jq`, `Python`, `Node`, `PowerShell`).

## 2. Mental Model / Problem Statement

Structured outputs treat `eza` as a data export tool. Choose the right format per downstream consumer:

- **JSON** – best for pipelines, includes metadata fields (name, path, size, owner, permissions, times, Git status).
- **Oneline** – newline-delimited names; pair with null separators for safe piping.
- **Hyperlink** – adds OSC 8 sequences for clickable files in supported terminals.

## 3. Golden Path

1. **JSON everything** – `eza --json --long --git > files.json`
2. **Process via jq** – filter keys and convert to other formats.
3. **Use `--record-separator`** – `--record-separator="\0"` when feeding into `xargs -0`.
4. **Annotate outputs** – include metadata (size, modified) even if not displayed by default, so pipelines remain future-proof.
5. **Log version** – embed `eza --version` output in automation logs for reproducibility.

## 4. Variations & Trade-Offs

- JSON files can be large; filter with `jq 'map(select(.name|endswith(".log")))'` before storing.
- On older eza builds without JSON support, consider `--long --color=never` and parse columns cautiously.
- Hyperlink sequences break tools that do not understand OSC 8; restrict to developer terminals.

## 5. Examples

### Example 1 – Pedagogical: JSON to CSV via jq

```
eza --json --long --only-files src \
  | jq -r '.[] | [.name, .size, .modified] | @csv'
```
Exports name/size/modified as CSV.

### Example 2 – Realistic Synthetic: Generate SBOM-like summary

```sh
eza --json --long --recurse --level=2 src \
  | jq 'map(select(.name | test("package\\.json$")))' \
  > manifests.json
```
Filters JSON for manifest files to feed into dependency scanners.

### Example 3 – Framework Integration: Node.js script consumption

```js
import { execSync } from 'node:child_process';
const data = JSON.parse(execSync('eza --json --long --git src'));
const stale = data.filter(entry => entry.git?.status === 'M' && entry.size > 1024);
console.log(stale.map(e => e.name));
```
Uses Node to process `eza` JSON and highlight large modified files.

## 6. Common Pitfalls

1. Forgetting to disable color output even when using `--json`; always add `--color=never` to avoid stray ANSI codes if terminal enforces colors.
2. Assuming JSON order; treat arrays as unordered and sort downstream.
3. Using `xargs` with spaces in filenames; rely on null separators.
4. Mixing `--json` with `--tree`; tree layout is ignored but command still recurses—explicit is better.
5. Not handling command failures; wrap in `set -euo pipefail` when chaining with `jq`.

## 7. AI Pair Programming Notes

- Ask AI to emit both producer (`eza`) and consumer (`jq`, script) snippets so context stays synchronized.
- Provide schema expectations so AI picks correct JSON keys (`.name`, `.path`, `.size`, `.git.status`).
- Encourage AI to include validation steps (e.g., `jq empty` to verify JSON integrity) before acting on data.

