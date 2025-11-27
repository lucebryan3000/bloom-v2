#!/usr/bin/env bash
# Project-local environment helper
# Usage: source ./env.sh

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export PATH="${PROJECT_ROOT}:${PATH}"
echo "PATH updated for project: ${PROJECT_ROOT}"
echo "Current PATH:"
echo "${PATH}" | tr ':' '\n'
