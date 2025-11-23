---
id: eza-02-output-customization
topic: eza
file_role: core
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals']
related_topics: ['terminal-ux', 'shell-automation']
embedding_keywords: [eza, output, customization, icons, columns, color]
last_reviewed: 2025-02-14
---

# 02 – Output Customization

## 1. Purpose

Teach how to control layout, colors, icons, headers, and column selection so that `eza` outputs exactly the visual information humans need without clutter. Applies to developer tooling, onboarding docs, and AI prompt design.

## 2. Mental Model / Problem Statement

`eza` renders directory data into a table whose axes you can choose. Every customization flag toggles one axis:

- **Layout axis** – grid, long list, tree, oneline.
- **Column axis** – permissions, user/group, size, time, Git.
- **Styling axis** – headers, colors, icons, hyperlinks.

Treat each axis independently and compose them explicitly to avoid hidden defaults. When documenting commands, list axes in this order for readability.

## 3. Golden Path

1. **Start from `--long --header`** ([EZA-OC-01]) to ensure columns are labeled.
2. **Add grouping** ([EZA-OC-02]) – `--group` for owner column, `--group-directories-first` to keep directories on top.
3. **Select icons intentionally** ([EZA-OC-03]) – `--icons` when fonts support them, `--no-icons` otherwise.
4. **Tune colors** ([EZA-OC-04]) – leverage `EZA_COLORS` or `--color-scale` for readability; disable in logs.
5. **Pin time and size formats** ([EZA-OC-05]) – `--time-style=long-iso` and `--binary` for deterministic outputs.

## 4. Variations & Trade-Offs

- **Grid vs. long** – grid is dense but lacks metadata; long is verbose but precise.
- **Icons** – helpful locally, but remote terminals might not support fonts; consider environment detection.
- **Hyperlinks** – enable with `--hyperlink` for modern terminals; older clients might display escape sequences.
- **Headers** – `--header` clarifies columns but adds a line; disable when embedding in limited height UIs.

## 5. Examples

### Example 1 – Pedagogical: Clean long listing baseline

```
eza --long --header --group --group-directories-first --icons
```
This is the baseline "readable long listing" recommended for day-to-day use.

### Example 2 – Realistic Synthetic: Color-safe CI output

```
eza --long \
    --header \
    --group \
    --no-icons \
    --time-style=long-iso \
    --color=never \
    --binary \
    build > build_listing.txt
```
Forces deterministic formatting suitable for diffing in CI artifacts.

### Example 3 – Framework Integration: Nerd Font aware shell function

```sh
lsf() {
  if [[ $TERM_PROGRAM == "WezTerm" ]]; then
    eza --grid --icons --color-scale "$@"
  else
    eza --grid --color=never "$@"
  fi
}
```
Adapts styling to the terminal program.

## 6. Common Pitfalls

1. Using `--grid` with wide filenames causing wrap; prefer `--long --truncate-owner` in narrow terminals.
2. Forgetting to disable icons on shared servers lacking Nerd Fonts.
3. Combining `--color=never` with `--color-scale`; the scale flag is ignored but may confuse readers.
4. Relying on locale-specific time formats leading to inconsistent logs across machines.
5. Misordering flags; while eza accepts any order, documenting them haphazardly hurts reproducibility.

## 7. AI Pair Programming Notes

- When describing desired output to AI, specify axes (layout/columns/styling). Example: "Need grid layout, no icons, directories first."
- Ask AI to emit commands that include `--header` in long listings unless there is a deliberate reason not to.
- Encourage AI to include `EZA_COLORS` examples using safe ANSI codes for colorblind-friendly schemes.
- For automation, remind AI to reference `EZA-OC-05` to output deterministic timestamps and sizes.

