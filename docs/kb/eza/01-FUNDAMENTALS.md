---
id: eza-01-fundamentals
topic: eza
file_role: fundamentals
profile: full
difficulty_level: beginner-to-intermediate
kb_version: 3.1
prerequisites: ['linux']
related_topics: ['linux', 'terminal-tools']
embedding_keywords: [eza, fundamentals, install, basics, ls-replacement]
last_reviewed: 2025-02-14
---

# 01 – Fundamentals

## 1. Purpose

Explain what `eza` is, how it relates to `ls`/`exa`, how to install it on major platforms, and how to read its default output. Start here if you have never used `eza` or need to standardize a team-wide rollout.

## 2. Mental Model / Problem Statement

`eza` is the actively maintained fork of `exa`, written in Rust with async filesystem access. It treats directory listings as structured data: each column is a dimension you can toggle. The goal is deterministic, legible listings that encode metadata (Git, icons, file sizes) without ad-hoc parsing.

Key ideas:

- **Column-first design** – choose which metadata columns to show; defaults mimic `ls -l` but are more readable.
- **Sane defaults** – color scale, directory grouping, and human-readable sizes aim to eliminate alias sprawl.
- **Extensibility** – JSON, oneline, tree, hyperlink outputs cover both humans and machines.
- **Safety** – `eza` will not follow symlinks or escalate privileges beyond what the OS allows.

## 3. Golden Path

1. **Install via package manager**
   - macOS: `brew install eza`
   - Debian: `sudo apt install -y eza`
   - Fedora: `sudo dnf install -y eza`
   - Arch: `sudo pacman -S eza`
   - Alternatively `cargo install eza --locked`. Pin versions for reproducibility.
2. **Create a cautious alias**
   - `alias l='eza -l --group --header --git'`
   - Keep `ls` untouched until the team standardizes fonts and color expectations.
3. **Validate environment**
   - Run `eza --version` and `eza --long` in a repository.
   - Confirm Nerd Font available if using icons.
4. **Adopt shared defaults**
   - Document the "blessed" combination (e.g., `-l --header --group --git --icons`).
   - Encourage `EZA_DEFAULT_OPTIONS` env var to centralize flags.

## 4. Variations & Trade-Offs

- **Icons** – add clarity but require patched fonts and may confuse screen readers.
- **Hyperlink mode** – integrates with iTerm2/WezTerm to make paths clickable; disable for plain terminals.
- **Color scales** – `--color-scale` maps sizes to gradients; not ideal for colorblind accessibility without adjustments.
- **Alias vs. function** – advanced setups use shell functions to auto-disable icons on remote SSH hosts; extra complexity but safer.

## 5. Examples

### Example 1 – Pedagogical: Compare ls and eza outputs

```
ls -l
# vs
EZA_COLORS="xx=1;33" eza -l --header --icons
```
Notice eza adds headers, uses clearer colors, and displays icons; columns remain consistent.

### Example 2 – Realistic Synthetic: Install via cargo with version pin

```
cargo install eza --locked --root "$HOME/.local"
export PATH="$HOME/.local/bin:$PATH"
```
Ensures reproducible builds even when distro packages lag.

### Example 3 – Framework Integration: Terminal profile snippet

```sh
# ~/.config/zsh/eza.zsh
if command -v eza >/dev/null; then
  alias ls='eza --group-directories-first --icons'
fi
```
Integrates `eza` into zsh config while retaining fallback behavior.

## 6. Common Pitfalls

1. Installing from stale community taps leading to old `exa` builds; always confirm `eza --version`.
2. Forgetting to install Nerd Fonts; icons render as boxes.
3. Placing `cargo install` binaries outside `$PATH` causing "command not found" errors.
4. Assuming `--git` works outside Git repositories; it silently disables but still incurs checks.
5. Using `sudo` with eza to inspect root directories; `sudo eza` can leak color codes into scripts—prefer `sudo -E` or `su -` shells.

## 7. AI Pair Programming Notes

- Describe the environment (macOS, Debian, busy server) so AI picks the right install commands.
- Ask AI to verify font requirements or fallback behavior as part of onboarding tasks.
- When generating dotfiles, remind AI to source `11-CONFIG-AND-OPERATIONS.md` for alias constraints.
- Provide `EZA_DEFAULT_OPTIONS` context when seeking debugging help so AI understands baseline flags.

