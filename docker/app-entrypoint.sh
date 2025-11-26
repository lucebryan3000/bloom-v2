#!/usr/bin/env sh
# Safe entrypoint for the app container.
# Keeps the container alive when package.json is missing (fresh bootstrap),
# and optionally starts pnpm dev once the manifest exists.

set -eu

WAIT_TIMEOUT="${APP_WAIT_TIMEOUT:-300}"   # seconds
WAIT_INTERVAL="${APP_WAIT_INTERVAL:-5}"   # seconds
APP_AUTO_START="${APP_AUTO_START:-true}"

start_ts="$(date +%s)"

if [ ! -f package.json ]; then
  echo "[entrypoint] package.json not found; waiting up to ${WAIT_TIMEOUT}s for bootstrap to generate it..."
fi

while [ ! -f package.json ]; do
  now_ts="$(date +%s)"
  elapsed=$((now_ts - start_ts))
  if [ "$elapsed" -ge "$WAIT_TIMEOUT" ]; then
    echo "[entrypoint] package.json still missing after ${WAIT_TIMEOUT}s. Staying idle (tail -f /dev/null)."
    exec tail -f /dev/null
  fi
  sleep "$WAIT_INTERVAL"
done

echo "[entrypoint] package.json detected."

if [ "$APP_AUTO_START" = "true" ]; then
  echo "[entrypoint] Starting pnpm dev..."
  exec pnpm dev
else
  echo "[entrypoint] APP_AUTO_START=false; staying idle (tail -f /dev/null)."
  exec tail -f /dev/null
fi
