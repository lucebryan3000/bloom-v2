#!/usr/bin/env bash
# Start the app dev server inside the Docker container (forces pnpm dev)
# Usage: ./scripts/start-dev.sh

set -euo pipefail

# Ensure the app container is up
docker compose up -d app

# Start Next.js dev in the background inside the container
docker compose exec app sh -c "pnpm dev --port 3000 >/tmp/dev.log 2>&1 & echo \$! > /tmp/dev.pid"

echo "Dev server started in container on port 3000."
echo "Logs: docker compose exec app tail -f /tmp/dev.log"
