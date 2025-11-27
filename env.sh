#!/usr/bin/env bash
# Project-local environment helper
# Usage: source ./env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
case ":${PATH}:" in
  *":${PROJECT_ROOT}:"*) ;; # already present
  *) export PATH="${PROJECT_ROOT}:${PATH}" ;;
esac
echo "PATH updated for project: ${PROJECT_ROOT}"
echo "Current PATH:"
echo "${PATH}" | tr ':' '\n' | awk '!seen[$0]++'
