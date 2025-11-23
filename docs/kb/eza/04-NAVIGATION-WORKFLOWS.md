---
id: eza-04-navigation-workflows
topic: eza
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals', 'eza-02-output-customization']
related_topics: ['terminal-ux', 'productivity']
embedding_keywords: [eza, navigation, list-directories, workflow]
last_reviewed: 2025-02-14
---

# 04 – Navigation Workflows

## 1. Purpose

Describe repeatable listings that help engineers orient themselves inside complex repositories: top-level overviews, service-focused scans, monorepo package navigation, and focus lists for daily work.

## 2. Mental Model / Problem Statement

Navigation tasks answer "Where am I?" and "What matters next?" `eza` excels here when you standardize a handful of curated commands and bind them to shell aliases or fzf workflows. Treat each workflow as a question + answer pair documented for humans and AI.

## 3. Golden Path

1. **Top-level map** – `eza --only-dirs --level=1 --group-directories-first --icons` bound to `ldirs` alias.
2. **Service deep dive** – `eza --tree --level=2 services/api` to visualize submodules quickly.
3. **Focus files** – `eza --long --glob="*.ts" --sort=changed --reverse src/<feature>` when triaging features.
4. **Trash + temp cleanup** – `eza --only-dirs --glob="*tmp*" --sort=changed` to find stale temp directories.
5. **Binary hunt** – `eza --long --sort=size --reverse --glob="*.bin" build` before shipping artifacts.

## 4. Variations & Trade-Offs

- **Aliases vs. scripts** – simple workflows can be aliases; more complex ones should be functions or scripts that check prerequisites (fonts, Git status, etc.).
- **fzf integration** – piping `eza --oneline` into `fzf` gives interactive navigation but loses metadata; decide based on user preference.
- **Remote sessions** – disable icons and color scales to speed up navigation on high latency SSH connections.

## 5. Examples

### Example 1 – Pedagogical: Quick directory switcher

```sh
ldirs() {
  eza --only-dirs --level=1 --group-directories-first "$@"
}

cd "$(ldirs | fzf)"
```
Lists first-level directories and piped into `fzf` for quick `cd` operations.

### Example 2 – Realistic Synthetic: Monorepo package radar

```
eza --tree --level=2 packages \
    --group-directories-first \
    --glob="package.json" \
    --ignore-glob="**/node_modules"
```
Shows package directories with their manifest locations to quickly inspect dependency boundaries.

### Example 3 – Framework Integration: tmux status script

```sh
#!/usr/bin/env bash
service=$(eza --only-dirs --level=1 services | head -n 1)
tmux set-option -g status-right "Svc: $service $(date +%H:%M)"
```
Uses `eza` to detect the freshest service directory and surfaces it in the tmux bar.

## 6. Common Pitfalls

1. Forgetting to limit depth in monorepos, flooding the terminal.
2. Using `--tree` when a flat list plus fzf would be faster for navigation.
3. Not excluding `node_modules`/`dist` directories, which slows down command completion.
4. Hardcoding directories in scripts without verifying they exist; prefer `if [ -d services ]; then ...` checks.
5. Running navigation helpers in directories without Git repos when they assume `--git` output.

## 7. AI Pair Programming Notes

- Provide the navigation question up front: e.g., "Need to inspect all services under `services/` sorted by recent changes." AI will map to the right command.
- Ask AI to output alias/function definitions with guardrails (directory existence checks, icon toggles).
- Encourage prompts referencing `[EZA-NAV-01]` style IDs for each workflow documented, aiding retrieval.

