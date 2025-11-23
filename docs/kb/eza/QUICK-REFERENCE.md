---
id: eza-quick-reference
topic: eza
file_role: quickref
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: ['linux']
related_topics: ['linux', 'terminal-tools', 'shell-automation']
embedding_keywords: [eza, quick-reference, flags, cheat-sheet, list-files]
last_reviewed: 2025-02-14
---

# eza Quick Reference

## 1. Purpose

Fast lookup for command forms, flags, and ready-made snippets covering human-friendly and machine-friendly listings. Use this file when you already know what you want to list and simply need the right incantation.

## 2. Flag Matrix & Mental Model

| Dimension | Flags | Notes |
| --- | --- | --- |
| Visibility | `-a/--all`, `-A/--almost-all`, `--only-dirs`, `--only-files` | `-A` keeps `.` and `..` hidden, good default for dotfile-aware lists. |
| Layout | `-l/--long`, `--grid`, `--oneline`, `--tree`, `--level=N` | Combine `--grid` for small directories, `--tree` for nested; always pin level. |
| Metadata Columns | `--header`, `--group`, `--group-directories-first`, `--no-permissions`, `--no-time`, `--no-user`, `--extended` | Trim noisy columns in CI by removing time/user. |
| Styling | `--color=[auto|always|never]`, `--color-scale`, `--icons`, `--no-icons`, `--smart-group` | Icons require Nerd Fonts; disable for headless logs. |
| Git | `--git`, `--git-ignore`, `--git-repos` | `--git` adds status column; pair with `--git-ignore` to hide ignored files. |
| Sorting | `--sort=name|size|time|changed|accessed|extension|type`, `--reverse`, `--natural`, `--group-directories-first` | Use `--sort=changed` for review, `--sort=size --reverse` to find large binaries. |
| Size Units | `-h/--human-readable`, `--binary`, `--bytes`, `--si` | Prefer `--binary` to align with OS disk usage. |
| Filtering | `--glob="*.ts"`, `--glob-case-insensitive`, `--exclude="node_modules"` | Pair with `--recurse` for targeted fetches. |
| Recursion | `-R/--recurse`, `--tree`, `--level=N` | Use `--tree --level=2` for architecture overviews. |
| Machine Output | `--json`, `--oneline`, `--time-style=long-iso`, `--record-separator` | `--json` is stable; `--oneline` suits `fzf`. |

## 3. Golden Path Snippets

| Task | Command |
| --- | --- |
| Daily long listing with Git | `eza -l --header --group --git --icons` |
| Focus on directories first | `eza --long --group-directories-first --only-dirs --level=1` |
| Show hidden files except . and .. | `eza -A --group --icons` |
| Tree of src up to depth 2 | `eza --tree --level=2 src` |
| Recently changed files | `eza --long --sort=changed --reverse --git --only-files` |
| Large assets with binary sizes | `eza --long --sort=size --reverse --binary public/assets` |
| Git ignored files only | `eza --long --git-ignore-only` |
| JSON for automation | `eza --json --long --git --sort=changed > listing.json` |

## 4. Variations & Trade-Offs

- Prefer `--color=never --icons=never` for log capture or when the environment lacks Nerd Fonts.
- Use `--time-style="%Y-%m-%dT%H:%M:%S"` to keep deterministic timestamps.
- Replace `--tree` with `--recurse` when you need machine-friendly flat output.
- Combine `--glob` filters with `--only-files` or `--only-dirs` to cut noise.
- On slow network drives disable `--git` and `--color-scale` to reduce system calls.

## 5. Examples

### Example 1 – Pedagogical: All files with hidden ones grouped

```
eza -Al --group --header --smart-group
```
Shows almost all files (`-A`), long format, grouped by owner and type.

### Example 2 – Realistic Synthetic: Release artifact validation

```
eza --long --group --no-user --no-time --sort=size --reverse --only-files dist --glob="*.tar.gz" --color=never
```
Curates release archives sorted by size without volatile metadata so CI comparisons stay stable.

### Example 3 – Framework Integration: TUI-friendly pipeline

```
EZA_COLORS="da=1;34:sb=1;36" eza --grid --icons --hyperlink | fzf --ansi
```
Feeds hyperlinked, colored entries into `fzf` for interactive navigation.

## 6. Common Pitfalls

1. Forgetting `--header` and misreading columns when piping to `less`.
2. Using `--git` inside directories without a `.git` ancestor; eza emits blank git column and wastes cycles.
3. Applying `--glob` without quoting; shells expand globs before eza sees them. Always wrap patterns in quotes.
4. Emitting Unicode icons to logs consumed by ASCII-only parsers.
5. Mixing `--tree` with `--oneline`; tree wants multi-line output—prefer `--tree --grid` or `--recurse --oneline`.

## 7. AI Pair Programming Notes

- When you need a command quickly, tell the AI "Reference `EZA-QR` table"; it will answer with a single snippet plus variant.
- Provide folder size, recursion depth, and Git awareness requirements; AI can map to the right column combination.
- Ask AI to emit commands with `\` line continuations for readability when copying into scripts.
- Encourage AI to cite color/formatting toggles explicitly to avoid relying on environment defaults.

