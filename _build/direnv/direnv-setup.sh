#!/usr/bin/env bash
# =============================================================================
# direnv-setup.sh - helper to install/configure direnv for this project
# =============================================================================
# Menu options:
#   1) Install direnv (best-effort via common package managers)
#   2) Create .envrc for this project with PATH export
#   3) Help / usage tips
#   4) Quit
#
# The generated .envrc will:
#   - add a chosen PATH entry (validated to exist)
#   - include clear comments on how to use direnv
# =============================================================================

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ENVRC_PATH="${PROJECT_ROOT}/.envrc"
ENV_HELPER_PATH="${PROJECT_ROOT}/env.sh"

confirm() {
  local prompt="${1:-Proceed? [y/N]} "
  read -r -p "$prompt" ans
  [[ "${ans,,}" == "y" ]]
}

install_direnv() {
  if command -v direnv >/dev/null 2>&1; then
    echo "direnv already installed: $(command -v direnv)"
    return 0
  fi

  echo "direnv not found. Attempt install?"
  if ! confirm "Install direnv now? [y/N] "; then
    echo "Skipping install."
    return 0
  fi

  if command -v apt-get >/dev/null 2>&1; then
    sudo apt-get update && sudo apt-get install -y direnv
  elif command -v brew >/dev/null 2>&1; then
    brew install direnv
  elif command -v pacman >/dev/null 2>&1; then
    sudo pacman -S --noconfirm direnv
  else
    echo "No supported package manager detected. Install manually from https://direnv.net/#install"
    return 1
  fi

  echo "direnv install attempted. Ensure your shell is hooked:"
  echo "  eval \"\$(direnv hook $(basename \"$SHELL\"))\""
}

create_envrc() {
  local add_path=""
  while [[ -z "$add_path" ]]; do
    read -r -p "Enter a PATH directory to add (must exist): " add_path
    if [[ -z "$add_path" || ! -d "$add_path" ]]; then
      echo "Path is empty or does not exist. Try again."
      add_path=""
    fi
  done

  cat > "${ENVRC_PATH}" <<EOF
# direnv configuration for $(basename "${PROJECT_ROOT}")
# To enable: run 'direnv allow' in the project root after editing.

# Add project-specific PATH entry (dir must exist)
export PATH=${add_path}:\$PATH

# Notes:
# - direnv will load this file when you 'cd' into the project root.
# - Edit this file as needed, then run 'direnv allow' again.
# - To hook your shell: eval "\$(direnv hook $(basename "$SHELL"))"
EOF

  echo ".envrc written to ${ENVRC_PATH}"
  echo "Run 'direnv allow' in ${PROJECT_ROOT} to activate."
}

create_env_helper() {
  cat > "${ENV_HELPER_PATH}" <<'EOF'
#!/usr/bin/env bash
# Project-local environment helper
# Usage: source ./env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Dedup PATH (preserve order)
deduped_path=""
seen=""
IFS=':' read -r -a path_parts <<< "${PATH}"
for part in "${path_parts[@]}"; do
  case ":${seen}:" in
    *":${part}:"*) ;; # already seen
    *)
      seen="${seen}:${part}"
      if [[ -z "${deduped_path}" ]]; then
        deduped_path="${part}"
      else
        deduped_path="${deduped_path}:${part}"
      fi
      ;;
  esac
done

# Add project root if missing
ADDED="false"
case ":${deduped_path}:" in
  *":${PROJECT_ROOT}:"*) ;;
  *) deduped_path="${PROJECT_ROOT}:${deduped_path}"; ADDED="true" ;;
esac

export PATH="${deduped_path}"

echo "PATH updated by env.sh"
echo "  Project root added: ${PROJECT_ROOT} (${ADDED})"
echo "  PATH entries:"
echo "${PATH}" | tr ':' '\n' | sed 's/^/    - /'
EOF

  chmod +x "${ENV_HELPER_PATH}" || true
  echo "env.sh helper written to ${ENV_HELPER_PATH}"
  echo "Run 'source ./env.sh' in ${PROJECT_ROOT} to update PATH for the session."
}

show_help() {
  cat <<EOF
direnv setup helper:
1) Install direnv (best-effort) if missing.
2) Create .envrc with a validated PATH entry; remember to run 'direnv allow'.
3) Create env.sh helper to prepend project root to PATH (per-session, manual source).
Hook your shell:
  eval "\$(direnv hook $(basename "$SHELL"))"
EOF
}

menu() {
  while true; do
    echo "========================================"
    echo "direnv setup for $(basename "${PROJECT_ROOT}")"
    echo "1) Install direnv"
    echo "2) Create/overwrite .envrc (add PATH)"
    echo "3) Create/overwrite env.sh helper (per-session PATH)"
    echo "4) Help"
    echo "5) Quit"
    read -r -p "Choose an option: " choice
    case "$choice" in
      1) install_direnv ;;
      2) create_envrc ;;
      3) create_env_helper ;;
      4) show_help ;;
      5) exit 0 ;;
      *) echo "Invalid choice." ;;
    esac
  done
}

menu
