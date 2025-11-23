---
id: eza-08-tree-hierarchy
topic: eza
file_role: advanced
profile: full
difficulty_level: intermediate-to-advanced
kb_version: 3.1
prerequisites: ['eza-03-filtering-selection']
related_topics: ['architecture-mapping']
embedding_keywords: [eza, tree, hierarchy, visualization]
last_reviewed: 2025-02-14
---

# 08 – Tree & Hierarchy Strategies

## 1. Purpose

Provide advanced recipes for `--tree`, `--level`, and recursive listings to visualize architecture without overwhelming the terminal.

## 2. Mental Model / Problem Statement

Tree views expose topology but become noisy quickly. Think in terms of **branch budgets** (max nodes per branch) and **annotation density** (what metadata to show per node). Limit both to maintain signal.

## 3. Golden Path

1. **Always cap depth** – `--tree --level=2` by default.
2. **Use include/exclude filters** – combine `--glob` and `--ignore-glob` to hide `node_modules`, `dist`, etc.
3. **Annotate sparingly** – pair tree output with `--long` only when necessary; otherwise rely on icons/indentation.
4. **Alias specialized trees** – e.g., `alias treepkg='eza --tree --level=3 --glob="package.json"'`.
5. **Export to files** – redirect tree outputs to Markdown or docs for sharing.

## 4. Variations & Trade-Offs

- `--tree` with `--long` doubles indentation, making wrap more likely; consider `--grid` for compactness.
- Instead of full trees, run multiple targeted partial trees (per service) to avoid noise.
- For docs, set `--color=never --no-icons` and wrap output in code fences.

## 5. Examples

### Example 1 – Pedagogical: Tree limited to directories

```
eza --tree --level=2 --only-dirs
```
Shows hierarchical directories only, perfect for architecture sketches.

### Example 2 – Realistic Synthetic: Feature-focused tree

```
eza --tree --level=3 --glob="*.ts" --ignore-glob="**/*.spec.ts" src/features/payments
```
Highlights TypeScript files relevant to the payments feature while skipping tests.

### Example 3 – Framework Integration: Generating Markdown diagrams

```sh
cat <<'OUT' > docs/structure.md
## Repo Outline

eza --tree --level=2 --no-icons --color=never
OUT
```
Embeds deterministic tree output into documentation.

## 6. Common Pitfalls

1. Forgetting to exclude heavy directories; `--tree` will descend into `node_modules` otherwise.
2. Expecting Git annotations to remain aligned when using `--tree --long`—indentation shifts columns.
3. Using `--tree` for automation; prefer `--recurse` with `--json` for machine consumption.
4. Allowing `--tree` to run at repo root of huge monorepos, freezing terminals.
5. Not warning collaborators about tree command runtime; include comments in scripts.

## 7. AI Pair Programming Notes

- Provide branch budget (max depth) and targeted directories when asking AI for tree commands.
- Request colorless, icon-free trees for documentation contexts.
- Ask AI to explain runtime implications when suggesting deep trees.

