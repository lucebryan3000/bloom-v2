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
end

export PATH="${deduped_path}"

echo "PATH updated by env.sh"
echo "  Project root added: ${PROJECT_ROOT} (${ADDED})"
echo "  PATH entries:"
echo "${PATH}" | tr ':' '\n' | sed 's/^/    - /'
