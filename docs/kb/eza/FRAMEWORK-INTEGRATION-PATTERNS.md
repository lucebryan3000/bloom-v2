---
id: eza-framework-integration
topic: eza
file_role: framework
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: ['eza-04-navigation-workflows', 'eza-06-scripting-automation']
related_topics: ['shell-automation', 'terminal-ux', 'ci-cd']
embedding_keywords: [eza, integration, frameworks, zsh, fish, starship, fzf]
last_reviewed: 2025-02-14
---

# Framework Integration Patterns

## 1. Purpose

Show how to wire `eza` into popular shells, terminal UIs, prompts, and CI/CD pipelines so developers get consistent behavior regardless of tooling stack.

## 2. Mental Model / Problem Statement

Each framework (zsh/Oh My Zsh, fish, nushell, starship, fzf, CI pipelines) has preferred ways to expose commands. Provide small, auditable modules for each so they can be mixed and matched.

## 3. Golden Path

1. **zsh + Oh My Zsh** – create plugin `~/.oh-my-zsh/custom/plugins/eza/eza.plugin.zsh` with aliases/functions, load via `.zshrc`.
2. **fish shell** – use `~/.config/fish/functions/eza.fish` with abbreviations (`abbr`) for quick commands.
3. **nushell** – define commands via `def ls [] { eza ... }` and register in `config.nu`.
4. **Starship prompt** – enable directory listings or custom modules referencing `eza` for preview blocks.
5. **fzf integration** – pipe `eza --oneline` into `fzf` with preview windows showing `eza --long` output.
6. **CI/CD** – wrap `eza` commands inside job steps with deterministic flags.

## 4. Patterns by Framework

### zsh / Oh My Zsh

- Create plugin file:

```sh
# ~/.oh-my-zsh/custom/plugins/eza/eza.plugin.zsh
if command -v eza >/dev/null; then
  alias ls='eza --long --group --header --icons'
  alias la='eza -A --long --header --group'
  alias lt='eza --tree --level=2'
  compdef _eza eza
fi
```

- Load plugin with `plugins+=(eza)` in `.zshrc`.
- Use `zstyle ':completion:*:*:eza:*' list-colors ''` to avoid duplicate coloring.

### fish shell

```fish
function ls --wraps eza
  if command -v eza >/dev/null
    eza --group-directories-first --header --icons $argv
  else
    command ls $argv
  end
end
abbr --add lt 'eza --tree --level=2'
```

- Store in `~/.config/fish/functions/ls.fish`.
- Manage fonts via `fish_config` instructions.

### nushell

```nu
def ls [path="."] {
  if (which eza | is-empty) {
    ls $path
  } else {
    ^eza --long --group --header $path
  }
}
```

- Add to `~/.config/nushell/config.nu`.
- Use pipelines like `ls src | where size > 1mb` with nushell's tables.

### Starship Prompt

- Configure custom module to show directory size via `eza`:

```toml
[[custom.eza_tree]]
command = "eza --only-dirs --level=1"
when = "[[ ".git" ]]"
style = "bold blue"
description = "Top-level dirs"
```

- Limit updates with `shell = ["bash", "-lc"]` to avoid blocking prompt.

### fzf Integration

```sh
fzf_cd() {
  local dir
  dir=$(eza --only-dirs --oneline | fzf --preview 'eza --long --color=always {}' --preview-window=down:60%)
  [[ -n $dir ]] && cd "$dir"
}
```

- Add keybind `bindkey '^F' fzf_cd`.

### CI/CD Pipelines

```yaml
- name: List artifacts with eza
  run: |
    set -euo pipefail
    eza --long --color=never --no-icons --sort=size --reverse dist | tee artifacts.txt
```

- Pair with caching to avoid repeated expensive runs.

## 5. Examples

### Example 1 – Pedagogical: Minimal zsh plugin loader

Explain hooking into Oh My Zsh plugin system above.

### Example 2 – Realistic Synthetic: Shared fzf wrapper script committed to repo

```
# scripts/eza-fzf.sh
#!/usr/bin/env bash
set -e
EZA_DEFAULT_OPTIONS=${EZA_DEFAULT_OPTIONS:="--grid --icons"}
eza $EZA_DEFAULT_OPTIONS "$@" | fzf --ansi
```

### Example 3 – Framework Integration: GitHub Actions composite action

```yaml
runs:
  using: "composite"
  steps:
    - run: sudo apt-get update && sudo apt-get install -y eza
    - run: eza --long --sort=changed --reverse --git src
```

## 6. Common Pitfalls

1. Loading `eza` plugin before fonts are installed; ensure provisioning order.
2. Binding `ls` in shells without fallback, breaking minimal containers.
3. Running `eza` in Starship custom modules without timeout—prompt may hang.
4. Forgetting to disable colors in CI steps, polluting logs.
5. Using `fzf` previews that recursively call `eza` without guarding directories, causing loops.

## 7. AI Pair Programming Notes

- When integrating with frameworks, mention plugin directories and config formats (zsh plugin vs. fish function vs. toml) so AI emits valid syntax.
- Ask AI to provide installation checks and fallback behavior for each integration block.
- Request preview GIF or textual description when socializing new CLI experiences; AI can summarize interactions for docs.

