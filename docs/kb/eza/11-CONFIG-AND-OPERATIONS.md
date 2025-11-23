---
id: eza-11-config-operations
topic: eza
file_role: config
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals']
related_topics: ['devops', 'cli-tooling']
embedding_keywords: [eza, configuration, installation, operations, alias]
last_reviewed: 2025-02-14
---

# 11 – Config & Operations

## 1. Purpose

Centralize operational standards for installing, configuring, upgrading, and auditing `eza` across developer machines, CI agents, and containers.

## 2. Mental Model / Problem Statement

Treat `eza` like any other CLI dependency: track versions, manage configuration fragments, and ensure reproducibility. Provide guardrails for aliasing, fonts, environment variables, and fallback strategies.

## 3. Golden Path

1. **Version management** – Pin versions in package manifests (e.g., Homebrew Brewfile, apt pin) or ship static binary checksums.
2. **Configuration layout** – Use `.config/eza/aliases.zsh`, `.config/eza/config.fish`, etc., to keep logic modular.
3. **Environment variables** – Document `EZA_COLORS`, `EZA_DEFAULT_OPTIONS`, `NO_COLOR`, `TERM`. Example: `export EZA_DEFAULT_OPTIONS="--long --header --group --git"`.
4. **Fonts** – Provide install scripts for Nerd Fonts plus fallback monospace fonts.
5. **Monitoring** – add `eza --version` to onboarding diagnostics and CI preflight logs to detect drift.

## 4. Variations & Trade-Offs

- Central alias vs. per-shell config: unify by sourcing a shared script (`$XDG_CONFIG_HOME/eza/init.sh`).
- Rolling vs. pinned versions: bleeding-edge features require newer releases; weigh stability against features like `--json` improvements.
- Enterprise hosts may forbid `cargo install`; rely on vendor packages or bring-your-own static binaries.

## 5. Examples

### Example 1 – Pedagogical: Shared alias file

```sh
# ~/.config/eza/aliases.zsh
export EZA_DEFAULT_OPTIONS="--long --header --group --group-directories-first"
if command -v eza >/dev/null; then
  alias ls="eza $EZA_DEFAULT_OPTIONS"
  alias lt='eza --tree --level=2'
fi
```
Centralizes alias definitions.

### Example 2 – Realistic Synthetic: Homebrew Brewfile entry

```
brew "eza", args: ["HEAD"]
cask "font-hack-nerd-font"
```
Ensures onboarding script installs both CLI and font.

### Example 3 – Framework Integration: CI setup script

```sh
#!/usr/bin/env bash
set -euo pipefail
if ! command -v eza >/dev/null; then
  curl -fsSL https://github.com/eza-community/eza/releases/download/v0.18.16/eza_x86_64-unknown-linux-gnu.tar.gz \
    | tar -xz -C /usr/local/bin eza
fi
printf "eza version %s\n" "$(eza --version)"
```
Downloads a pinned binary when packages are unavailable.

## 6. Common Pitfalls

1. Forgetting to update fonts when `eza` introduces new icons; document font upgrade steps.
2. Allowing `alias ls='eza'` without fallback; if `eza` fails, core shell workflows break.
3. Not clearing `EZA_DEFAULT_OPTIONS` in scripts that require different flags.
4. Skipping checksum verification when downloading binaries; include `sha256sum` checks.
5. Hardcoding install paths inconsistent across OSes; use `$HOME/.local/bin` or `/usr/local/bin` depending on privileges.

## 7. AI Pair Programming Notes

- When requesting install scripts, include OS/package manager plus whether fonts are needed.
- Ask AI to output idempotent scripts (safe to re-run) with version pinning and checksum verification where possible.
- Encourage referencing `[EZA-CONFIG]` when standardizing alias files or environment variables.

