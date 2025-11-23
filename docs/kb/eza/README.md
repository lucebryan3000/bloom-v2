---
id: eza-readme
topic: eza
file_role: overview
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: ['linux']
related_topics: ['linux', 'terminal-tools']
embedding_keywords: [eza, exa, modern-ls, file-listing, overview]
last_reviewed: 2025-02-14
---

# eza Knowledge Base

## 1. Purpose

Provide a project-agnostic field guide to `eza`, the actively maintained fork of `exa` that modernizes the classic `ls` workflow with colorized output, Git awareness, icons, and structured data modes. Use this KB whenever you need deterministic directory listings, reproducible automation scripts, or AI prompts about file-inspection tasks.

## 2. Mental Model / Problem Statement

`eza` treats directory listings as data visualization. Instead of memorizing dozens of `ls` flags, you compose views with predictable sections—columns, grouping, icons, git indicators, tree rendering, or JSON. Think of `eza` as a query engine for the filesystem where every flag toggles a dimension (metadata, layout, recursion depth). Mastering it means understanding how to combine dimensions for the exact question you are answering ("what changed in this repo?", "how large is this subtree?", "which files are executable?").

## 3. Golden Path

1. **Install once, alias carefully** – install from package manager or `cargo`, alias `ls='eza'` only after you are confident with defaults.
2. **Use profiles** – start with `eza -l --group --icons --git` for most work. Add `--smart-group` and `--binary` when needed.
3. **Stay consistent** – share canonical flag sets (`--long --header --git --no-permissions`) in scripts/team docs so humans and AI get the same view.
4. **Prefer structured output for automation** – rely on `--json` or `--oneline` before parsing columns manually.
5. **Annotate commands** – comment shell snippets with the intent ("show tree with depth 2 and sizes"), so AI copilots can map tasks back to KB recipes.

## 4. Variations & Trade-Offs

- **Compatibility vs. features** – plain `ls` is everywhere; `eza` requires installation. Production scripts that must run on BusyBox hosts should feature-detect.
- **Color vs. parsability** – disable colors (`--color=never`) or icons when capturing output for logs to avoid ANSI artifacts.
- **Git integration** – `--git` adds latency on huge repos because it shells out to Git. Use `--git-ignore` without status when speed matters.
- **Tree view vs. flat filters** – `--tree` is intuitive but noisy; prefer `--recurse --level` with targeted globs for automation.
- **JSON vs. column mode** – JSON adds escaping overhead but enables jq/Node parsing; choose based on downstream tooling.

## 5. Examples

### Example 1 – Pedagogical

```
eza -l --header --icons
```
Shows a long listing with headers and Nerd Font icons for quick discrimination of file types.

### Example 2 – Realistic Synthetic

```
eza --long --group --git --sort=changed --only-files src
```
Lists files in `src/`, grouped by owner, sorted by modification time, and annotated with short Git status.

### Example 3 – Framework Integration (CI log artifact)

```
eza --long --color=never --group-directories-first --no-user --no-time --total-size build > build_listing.txt
```
Generates a deterministic artifact for CI triage where ANSI codes and volatile timestamps are stripped.

## 6. Common Pitfalls

1. **Blind aliasing** – replacing `ls` globally without exporting Nerd Fonts causes garbled glyphs. Keep a fallback alias or guard on `$TERM`.
2. **Expecting hidden files by default** – `eza` excludes dotfiles unless `-a`/`--all` is used. Scripts that assumed `ls` default behavior might miss config files.
3. **Parsing colored output** – piping colored output into `awk` leads to invisible escape codes. Use `--color=never` before parsing.
4. **Git status mismatches** – on detached HEAD states `--git` can show stale info if executed outside repo root. Use `--git-ignore` or `git status --porcelain` for authoritative data.
5. **Tree depth explosions** – forgetting `--level` on `--tree` in large monorepos can freeze terminals. Always set a depth limiter.

## 7. AI Pair Programming Notes

- Load this `README` with `INDEX.md` to orient AI copilots on naming conventions and file map before requesting specific recipes.
- Reference section anchors like `[EZA-GP-01]` (Golden Path) when prompting: "Follow EZA-GP-01 to list release artifacts".
- Encourage AI suggestions to cite flag combinations rather than prose; e.g., "Use `eza --long --sort=size --bytes`".
- Remind models to prefer structured outputs (`--json`, `--oneline`) for automation tasks discussed with other KB files.
- When AI proposes aliasing, verify against rules in `11-CONFIG-AND-OPERATIONS.md`.

---

## File Map

| File | Focus |
| --- | --- |
| [INDEX.md](./INDEX.md) | Topic graph and retrieval guide |
| [QUICK-REFERENCE.md](./QUICK-REFERENCE.md) | Commands, flags, ready-made snippets |
| [01-FUNDAMENTALS.md](./01-FUNDAMENTALS.md) | Mental models, installation basics |
| [02-OUTPUT-CUSTOMIZATION.md](./02-OUTPUT-CUSTOMIZATION.md) | Layouts, icons, column control |
| [03-FILTERING-AND-SELECTION.md](./03-FILTERING-AND-SELECTION.md) | Sorting, globbing, include/exclude |
| [04-NAVIGATION-WORKFLOWS.md](./04-NAVIGATION-WORKFLOWS.md) | Daily directory traversal patterns |
| [05-SCM-AWARE-LISTINGS.md](./05-SCM-AWARE-LISTINGS.md) | Git-aware and review-centric listings |
| [06-SCRIPTING-AND-AUTOMATION.md](./06-SCRIPTING-AND-AUTOMATION.md) | Using eza inside scripts, CI, tooling |
| [07-CROSS-PLATFORM-REMOTE.md](./07-CROSS-PLATFORM-REMOTE.md) | WSL, container, remote shell nuances |
| [08-TREE-AND-HIERARCHY-STRATEGIES.md](./08-TREE-AND-HIERARCHY-STRATEGIES.md) | Visualizing hierarchies |
| [09-HIGH-PERFORMANCE-LISTINGS.md](./09-HIGH-PERFORMANCE-LISTINGS.md) | Scaling to large repos |
| [10-STRUCTURED-OUTPUT-PIPELINES.md](./10-STRUCTURED-OUTPUT-PIPELINES.md) | JSON/oneline for tooling |
| [11-CONFIG-AND-OPERATIONS.md](./11-CONFIG-AND-OPERATIONS.md) | Install, upgrades, guardrails |
| [FRAMEWORK-INTEGRATION-PATTERNS.md](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Shell, Starship, CI/CD recipes |

## Context Bundles

1. **Daily Navigation** – `QUICK-REFERENCE`, `01-FUNDAMENTALS`, `04-NAVIGATION-WORKFLOWS`.
2. **Code Review & Git** – `QUICK-REFERENCE`, `05-SCM-AWARE-LISTINGS`, `06-SCRIPTING-AND-AUTOMATION`.
3. **Automation / CI** – `06-SCRIPTING-AND-AUTOMATION`, `10-STRUCTURED-OUTPUT-PIPELINES`, `11-CONFIG-AND-OPERATIONS`.
4. **Customization / Shell Setup** – `02-OUTPUT-CUSTOMIZATION`, `07-CROSS-PLATFORM-REMOTE`, `FRAMEWORK-INTEGRATION-PATTERNS`.

