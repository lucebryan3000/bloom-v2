---
id: eza-index
topic: eza
file_role: index
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: ['linux']
related_topics: ['linux', 'terminal-tools']
embedding_keywords: [eza, index, table-of-contents, navigation]
last_reviewed: 2025-02-14
---

# eza KB Index

## 1. Purpose

Provide a navigable map of every eza KB file, how they interlink, and which questions each file answers. Use this index inside `llms.txt` bundles or when asking AI copilots for specific recipes.

## 2. Topic Graph

| Anchor | File | Key Questions |
| --- | --- | --- |
| [EZA-01](./01-FUNDAMENTALS.md) | Fundamentals | What is eza? How does it differ from ls/exa? How do I install it? |
| [EZA-02](./02-OUTPUT-CUSTOMIZATION.md) | Output Customization | How do I control columns, headers, icons, colors? |
| [EZA-03](./03-FILTERING-AND-SELECTION.md) | Filtering & Selection | How do I sort, recurse, or focus on hidden, binary, or globbed files? |
| [EZA-04](./04-NAVIGATION-WORKFLOWS.md) | Navigation Workflows | Which listings help me traverse monorepos quickly? |
| [EZA-05](./05-SCM-AWARE-LISTINGS.md) | SCM-Aware Listings | How do I blend Git status, ignore rules, or review checklists? |
| [EZA-06](./06-SCRIPTING-AND-AUTOMATION.md) | Scripting & Automation | How do I embed eza safely in shell scripts, CI, or task runners? |
| [EZA-07](./07-CROSS-PLATFORM-REMOTE.md) | Cross-Platform & Remote | What differs on macOS, Linux, WSL, SSH, containers? |
| [EZA-08](./08-TREE-AND-HIERARCHY-STRATEGIES.md) | Tree & Hierarchies | Best ways to visualize nested structures without noise? |
| [EZA-09](./09-HIGH-PERFORMANCE-LISTINGS.md) | High Performance | How to keep eza responsive in huge repos or network mounts? |
| [EZA-10](./10-STRUCTURED-OUTPUT-PIPELINES.md) | Structured Output | How to use JSON, TSV, or parse-once outputs? |
| [EZA-11](./11-CONFIG-AND-OPERATIONS.md) | Config & Operations | Install, upgrade, aliasing guardrails, enterprise rollouts. |
| [EZA-QR](./QUICK-REFERENCE.md) | Quick Reference | Flag matrix, oneliners, cheat snippets. |
| [EZA-FW](./FRAMEWORK-INTEGRATION-PATTERNS.md) | Framework Integration | Shell frameworks, terminal UI, CI/CD toolchains. |

## 3. Navigation Patterns

- **By Task Type** – Use fundamentals + quick reference for onboarding, practical files 04–07 for day-to-day, advanced 08–10 for troubleshooting.
- **By Dimension** – Each numbered file tags sections like `[EZA-SORT-01]`, `[EZA-TREE-02]`. Use those IDs inside prompts when combining sections.
- **By Output Style** – Visual output topics live in `02`, `08`, `09`. Machine-friendly output topics live in `06`, `10`, `11`.

## 4. Retrieval Bundles

| Bundle | Files | Use Case |
| --- | --- | --- |
| Base Listing | `QUICK-REFERENCE`, `01-FUNDAMENTALS` | Introduce eza or remind flag semantics. |
| Review-Prep | `05-SCM-AWARE-LISTINGS`, `04-NAVIGATION-WORKFLOWS`, `09-HIGH-PERFORMANCE-LISTINGS` | Inspect repo changes, discuss cost of `--git`. |
| Automation | `06-SCRIPTING-AND-AUTOMATION`, `10-STRUCTURED-OUTPUT-PIPELINES`, `11-CONFIG-AND-OPERATIONS` | Building scripts, CI, telemetry. |
| Visualization | `02-OUTPUT-CUSTOMIZATION`, `08-TREE-AND-HIERARCHY-STRATEGIES`, `07-CROSS-PLATFORM-REMOTE` | Terminal UX, icons, fonts, remote compatibility. |

## 5. Examples

### Example – Query Routing

- Scenario: "List directories first, hide node_modules, show git status."
- Load `QUICK-REFERENCE` (flag matrix) + `05-SCM-AWARE-LISTINGS` (git) + `03-FILTERING` (globs) for a targeted AI prompt.

## 6. Common Pitfalls

1. Loading a single file (e.g., Quick Reference) and expecting deep explanations; pair with fundamentals for context.
2. Asking AI about automation without including `10-STRUCTURED-OUTPUT-PIPELINES`, resulting in fragile parsing suggestions.
3. Mixing cross-platform guidance—`EZA-07` should accompany remote/Windows prompts.

## 7. AI Pair Programming Notes

- Reference table anchors (EZA-xx) to scope prompts. Example: "Summarize `EZA-05` guidance for CI review output."
- Encourage AI to cite sections rather than entire files to minimize context windows.
- When in doubt, load `INDEX` + the target file so AI understands relationships and prerequisites.

