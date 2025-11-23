---
id: eza-07-cross-platform
topic: eza
file_role: practical
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-01-fundamentals', 'eza-02-output-customization']
related_topics: ['linux', 'terminal-ux']
embedding_keywords: [eza, windows, macos, wsl, ssh, remote]
last_reviewed: 2025-02-14
---

# 07 – Cross-Platform & Remote Usage

## 1. Purpose

Outline the differences and guardrails when using `eza` on macOS, Linux, WSL, remote SSH sessions, and containers. Helps teams ship consistent dotfiles and avoid broken glyphs or missing packages.

## 2. Mental Model / Problem Statement

`eza` itself is portable, but its dependencies (fonts, locale, package managers) are not. Define environment profiles:

- **Local rich terminals** – icons, hyperlinks, colors safe.
- **Remote/headless** – colorless, icon-free, often older glibc.
- **Windows via WSL** – Linux binaries but Windows fonts.
- **Containers** – minimal packages; install via package manager or copy binary.

## 3. Golden Path

1. **Detect environment**
   - `if [[ -n $SSH_CONNECTION ]]; then export EZA_STYLE="plain"; fi`
2. **Provide fallback alias**
   - `alias ls='ls --color=auto'` when `eza` unavailable.
3. **Manage fonts**
   - On macOS install Nerd Fonts via Homebrew casks; on Windows install manually and configure Windows Terminal profile.
4. **Package sources**
   - WSL/Ubuntu: `sudo add-apt-repository ppa:determinant/eza && sudo apt install eza`
   - Alpine containers: `apk add eza` (available in community repo).
5. **Sync configs**
   - Use platform-specific config fragments (e.g., `.config/zsh/eza-linux.zsh`).

## 4. Variations & Trade-Offs

- Some remote hosts forbid custom package installs; ship a statically linked binary in your dotfiles.
- On Windows PowerShell, `eza` works via `scoop` but certain options (e.g., `--hyperlink`) may not be supported.
- Containers might lack locales; set `LC_ALL=C.UTF-8` to avoid encoding warnings.

## 5. Examples

### Example 1 – Pedagogical: Environment-aware alias

```sh
if [[ -n "$SSH_CONNECTION" ]]; then
  alias ls='eza --long --color=never --no-icons --group-directories-first'
else
  alias ls='eza --long --icons --color-scale'
fi
```
Switches styling based on remote vs. local usage.

### Example 2 – Realistic Synthetic: Installing in a Debian-based container

```Dockerfile
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends eza fonts-nerd-font-mono && rm -rf /var/lib/apt/lists/*
```
Ensures CI containers have the same toolchain as local dev.

### Example 3 – Framework Integration: Windows Terminal profile snippet

```json
{
  "commandline": "wsl ~ -c 'eza --grid --icons'",
  "font": { "face": "FiraCode Nerd Font" }
}
```
Launches WSL with `eza` grid listing and proper font.

## 6. Common Pitfalls

1. Assuming fonts exist on servers; they usually do not.
2. Forgetting to install `libgit2` dependencies on musl-based distros—use package manager builds.
3. Using `--color-scale` in terminals that only support 8 colors, resulting in unreadable output.
4. Hardcoding Linux-specific options in PowerShell scripts (e.g., relying on `grep`), causing cross-platform failures.
5. Not handling older glibc versions; prefer static builds when distributing binaries widely.

## 7. AI Pair Programming Notes

- When creating dotfiles or container images, tell AI the exact platform so it picks supported package commands.
- Ask AI to include fallbacks for when `eza` is missing or fonts not installed.
- Encourage prompts referencing `[EZA-XPLAT]` guidelines when bridging Windows/WSL.

