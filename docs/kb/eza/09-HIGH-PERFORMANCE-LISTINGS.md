---
id: eza-09-high-performance
topic: eza
file_role: advanced
profile: full
difficulty_level: advanced
kb_version: 3.1
prerequisites: ['eza-03-filtering-selection', 'eza-05-scm-aware']
related_topics: ['performance', 'large-repos']
embedding_keywords: [eza, performance, large-repos, optimization]
last_reviewed: 2025-02-14
---

# 09 – High-Performance Listings

## 1. Purpose

Keep `eza` responsive on massive directories, network filesystems, or CI agents under load by tuning flags, caching, and fallbacks.

## 2. Mental Model / Problem Statement

I/O and Git checks dominate runtime. Optimize by reducing syscalls (fewer directories, disable Git), limiting metadata (no icons/colors), and caching expensive operations. Always measure with `/usr/bin/time -f '%E %M' eza ...` to validate improvements.

## 3. Golden Path

1. **Disable Git** when not needed: avoid `--git`, or run `git status` separately.
2. **Limit stat calls** – skip user/time columns via `--no-user --no-time`.
3. **Avoid icons/colors** – `--color=never --no-icons` reduces Unicode work.
4. **Filter aggressively** – `--only-dirs`, `--glob`, `--level` to reduce entries.
5. **Cache directories** – for repeated runs, stage data via `find`/`fd` piped into `eza --stdin` (experimental) or use `xargs` to chunk.

## 4. Variations & Trade-Offs

- On network mounts, even metadata access is slow; run `eza` against local caches or clones.
- CI logs should avoid heavy columns; consider summarizing via `du -sh` first, then targeted `eza` runs.
- For >100k files, `fd` or `ripgrep --files` may outperform `eza`; use `eza` only for final presentation of filtered subsets.

## 5. Examples

### Example 1 – Pedagogical: Performance-friendly listing

```
eza --long --no-user --no-time --color=never --no-icons --only-dirs --level=1
```
Cuts many metadata calls while still giving structural overview.

### Example 2 – Realistic Synthetic: Two-stage pipeline for huge repos

```
fd --type f --extension rs --max-depth 3 src \
  | head -n 200 \
  | xargs -r eza --long --color=never --oneline
```
Uses `fd` to gather candidate files, then `eza` for presentation.

### Example 3 – Framework Integration: CI step with timeout

```yaml
- name: List heavy assets fast
  run: |
    timeout 5s eza --long --sort=size --reverse --bytes --only-files dist || \
      ls -lh dist
```
Provides fallback to `ls` if `eza` exceeds timeout.

## 6. Common Pitfalls

1. Forgetting to disable Git in automation, leading to second-long latency per run.
2. Running `--tree` accidentally in repo root; prefer targeted scope.
3. Using icons over SSH sessions with poor bandwidth causing slow rendering.
4. Expecting `eza` to replace `du` for total size calculations; it lists entries, it doesn't aggregate unless `--total-size` is used.
5. Ignoring error output when `eza` hits unreadable directories; check return codes and fallback gracefully.

## 7. AI Pair Programming Notes

- Request performance budgets when asking AI for commands (e.g., "must finish < 3s on 100k files").
- Ask AI to propose fallback strategies (e.g., revert to `ls`) when `eza` is unavailable or times out.
- Encourage references to `[EZA-PERF-01]` guidelines when optimizing CI logs.

