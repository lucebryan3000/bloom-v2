#!/usr/bin/env bash
# Project-local environment helper
# Usage: source ./env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ADDED="false"
case ":${PATH}:" in
  *":${PROJECT_ROOT}:"*) ;; # already present
  *) export PATH="${PROJECT_ROOT}:${PATH}"; ADDED="true" ;;
esac
echo "PATH updated by env.sh"
echo "  Project root added: ${PROJECT_ROOT} (${ADDED})"
echo "  PATH entries:"
echo "${PATH}" | tr ':' '\n' | sed 's/^/    - /'
