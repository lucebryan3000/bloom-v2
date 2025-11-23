---
id: eza-05-scm-aware
topic: eza
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals', 'eza-03-filtering-selection']
related_topics: ['git', 'code-review']
embedding_keywords: [eza, git, scm, status, listings]
last_reviewed: 2025-02-14
---

# 05 – SCM-Aware Listings

## 1. Purpose

Enable Git-centric workflows: reviewing changes, surfacing ignored files, summarizing untracked assets, or visualizing submodules. `eza` can display git status per file and respect ignore rules, making it ideal for quick pre-commit scans.

## 2. Mental Model / Problem Statement

`eza` shells out to Git when `--git` or related flags are used. The extra column uses short status codes similar to `git status --short`. Combine this with filtering/sorting to target review tasks.

## 3. Golden Path

1. **Status column** – `eza --long --git` adds `??`, `M`, `A`, etc. Keep `--header` for clarity.
2. **Ignore awareness** – `--git-ignore` hides ignored files; `--git-ignore-only` shows only ignored items (useful for verifying `.gitignore`).
3. **Repo summaries** – `--git-repos` run in a directory of repos to summarize each one's branch and clean/dirty status.
4. **Change-focused sorts** – pair `--sort=changed --reverse` with `--git` to bubble recent modifications.
5. **Pre-commit alias** – `alias gstatus='eza --long --git --sort=changed --reverse --color=always'` for quick scans before committing.

## 4. Variations & Trade-Offs

- `--git` requires executing from within a repo or a subdirectory; otherwise `eza` falls back silently.
- On repos with 100k+ tracked files, Git status can lag; consider `git status --short` for canonical output and `eza` for visualization only.
- Git submodules show aggregated status; use `--git-repos` in the parent directory to view submodule statuses clearly.

## 5. Examples

### Example 1 – Pedagogical: Show tracked/untracked files

```
eza --long --git
```
Displays Git codes next to each entry.

### Example 2 – Realistic Synthetic: Focus on ignored build artifacts

```
eza --long --git-ignore-only --sort=size --reverse dist
```
Surfaces files that are ignored but still large, helpful before cleaning caches.

### Example 3 – Framework Integration: Repo dashboard script

```sh
#!/usr/bin/env bash
cd ~/code
printf "Repo\tBranch\tStatus\n"
eza --git-repos --long --header --only-dirs projects |
  awk '{printf "%s\t%s\t%s\n", $1, $2, $3}'
```
Lists each repo directory with branch and dirty/clean status.

## 6. Common Pitfalls

1. Running `--git` in directories with many untracked files (e.g., build artifacts) causing slowdowns.
2. Assuming `--git-ignore` respects `.git/info/exclude`; depending on version it may not—test before relying on it.
3. Interpreting git status codes incorrectly; consult Git docs for multi-letter states (e.g., `AD`).
4. Forgetting that `--git` uses HEAD; stashing or detached HEAD states may hide certain changes.
5. Logging `--git` output to CI without `--color=never`, leading to unreadable escape sequences.

## 7. AI Pair Programming Notes

- Tell AI whether you want to see ignored files, tracked files, or repo rollups; it will choose `--git`, `--git-ignore`, or `--git-repos` accordingly.
- Request commands with timeouts or fallback suggestions for extremely large repos.
- When automating, ensure AI includes guardrails (e.g., detecting `.git` presence) to avoid wasted Git invocations.

