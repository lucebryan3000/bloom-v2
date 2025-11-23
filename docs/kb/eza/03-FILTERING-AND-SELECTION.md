---
id: eza-03-filtering-selection
topic: eza
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals']
related_topics: ['shell-automation']
embedding_keywords: [eza, filtering, sorting, glob, recurse, list-directories]
last_reviewed: 2025-02-14
---

# 03 – Filtering & Selection

## 1. Purpose

Show how to focus listings on the files you care about: include/exclude globs, sorting, recursion depth, and metadata filters (size, type, Git status). Essential when exploring large codebases or building scripts that need deterministic subsets.

## 2. Mental Model / Problem Statement

Treat filtering as layered predicates applied before rendering. Compose them in this order:

1. **Scope** – pick directories or files to inspect.
2. **Recursion** – decide if you need nested data (`--recurse`, `--tree`, `--level`).
3. **Include/exclude** – globs, `--only-dirs`, `--only-files`, `--ignore-glob`.
4. **Metadata filters** – `--modified-after`, Git-aware flags.
5. **Sorting** – `--sort` and `--reverse` finalize ordering.

## 3. Golden Path

1. **Target directories** ([EZA-FLT-01]) – Pass explicit paths to avoid `.` when not needed.
2. **Use `--glob`** ([EZA-FLT-02]) – Always quote patterns: `--glob "*.ts"`.
3. **Limit recursion** ([EZA-FLT-03]) – `--recurse --level=2` or `--tree --level=1` instead of unlimited traversal.
4. **Combine metadata filters** ([EZA-FLT-04]) – Example: `--only-files --sort=changed --reverse` highlights recent file edits.
5. **Deterministic sorting** ([EZA-FLT-05]) – Use `--natural` for human sort, `--sort=extension` for bundling file types.

## 4. Variations & Trade-Offs

- `--tree` vs. `--recurse`: tree displays hierarchy; recurse returns flat list (better for piping to `rg`).
- `--glob` vs. shell globbing: eza can handle case-insensitive globs and multiple patterns; shell globs expand before eza sees them.
- Filtering by Git status uses `--git` plus `--git-ignore-only`; more precise but slower on huge repos.

## 5. Examples

### Example 1 – Pedagogical: Only directories at depth 1

```
eza --only-dirs --level=1 --group-directories-first
```
Lists immediate subdirectories, perfect for overview of repo structure.

### Example 2 – Realistic Synthetic: TypeScript files touched recently

```
eza --long \
    --only-files \
    --glob="*.ts" \
    --sort=changed \
    --reverse \
    --git \
    --color=always \
    src
```
Combines glob filtering, sort by modification, and Git status to target review areas.

### Example 3 – Framework Integration: Feed filtered list into testing tool

```
TEST_FILES=$(eza --oneline --glob="*.spec.ts" --recurse --level=2 tests)
npx vitest run $TEST_FILES
```
Uses `--oneline` to avoid whitespace issues, enabling shell substitution for test runners.

## 6. Common Pitfalls

1. Forgetting quotes around globs causing the shell to expand patterns prematurely.
2. Using `--tree` without `--level` and producing massive output.
3. Expecting `--glob` to match directories by default; you still need `--only-dirs` for folder-only views.
4. Sorting by `size` without `--long`; size column is missing, causing confusion.
5. Piping to `xargs` without `-0` when filenames contain spaces; prefer `--record-separator='\0'` in automation contexts.

## 7. AI Pair Programming Notes

- When requesting filtered listings, state the predicate order (scope → recursion → glob → sort) to help AI craft deterministic commands.
- Ask AI to include quoting and `--record-separator` guidance for commands that feed into scripts.
- Encourage referencing `[EZA-FLT-03]` before suggesting recursive listings in large repos to avoid runaway output.

