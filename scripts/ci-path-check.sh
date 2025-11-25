#!/usr/bin/env bash
set -euo pipefail
IFS=$'\n\t'

# Ensure we stay in host mode for CI to avoid Docker re-exec
export DOCKER_EXEC_MODE="${DOCKER_EXEC_MODE:-host}"
export DOCKER_REQUIRED="${DOCKER_REQUIRED:-true}"
export INSIDE_OMNI_DOCKER="${INSIDE_OMNI_DOCKER:-}"

echo "[ci-path] DOCKER_EXEC_MODE=${DOCKER_EXEC_MODE} (expected: host)"
echo "[ci-path] INSIDE_OMNI_DOCKER=${INSIDE_OMNI_DOCKER:-<empty>}"

# Basic CLI smoke checks that should not trigger Docker or tool installs
./_build/omniforge/omni.sh --help > /dev/null
./_build/omniforge/omni.sh status --list

echo "[ci-path] Host-mode CLI path validated"
