#!/usr/bin/env bash
#
# docker-deploy-scan.sh
#
# After a Docker deployment, scan host paths associated with a container
# and list files that were created or modified on the host during that
# deployment window.
#
# It does NOT look inside the image filesystem. It only cares about host
# paths that are mounted into the container (bind mounts + volume mountpoints).
#
# Usage:
#   ./_build/scripts/docker-deploy-scan.sh <container_name_or_id>
#
# Example:
#   ./_build/scripts/docker-deploy-scan.sh bloom2_app
#
# Environment knobs:
#   MIN_STABLE_SECONDS (default 300)    wait time the container must be stable/running before scan
#   MAX_WAIT_SECONDS (default 1200)     max time to wait for stability before failing
#   POLL_INTERVAL_SECONDS (default 10)  poll cadence while waiting
#   REQUIRE_HEALTHY (default 1)         require Health=healthy when healthchecks exist
#   SKIP_STABLE_WAIT (default 0)        set to 1 to skip stability wait
#   DOCKER_DAEMON_TIMEOUT (default 120) timeout for docker daemon readiness
#

set -euo pipefail

# Timing knobs for post-deploy stability checks (override via env vars)
MIN_STABLE_SECONDS="${MIN_STABLE_SECONDS:-300}"       # require container stable this long before scan
MAX_WAIT_SECONDS="${MAX_WAIT_SECONDS:-1200}"          # give up waiting after this many seconds
POLL_INTERVAL_SECONDS="${POLL_INTERVAL_SECONDS:-10}"  # poll interval while waiting
REQUIRE_HEALTHY="${REQUIRE_HEALTHY:-1}"               # require Health=healthy when present
SKIP_STABLE_WAIT="${SKIP_STABLE_WAIT:-0}"             # set to 1 to skip stability wait
DOCKER_DAEMON_TIMEOUT="${DOCKER_DAEMON_TIMEOUT:-120}" # wait for docker daemon to be ready

if [ "${1:-}" = "" ]; then
  echo "Usage: $0 <container_name_or_id>"
  exit 1
fi

CONTAINER="$1"

# Ensure docker exists
if ! command -v docker >/dev/null 2>&1; then
  echo "ERROR: docker CLI not found in PATH."
  exit 1
fi

# Wait for docker daemon to be reachable (handles cases where service is still starting)
wait_for_docker_daemon() {
  local timeout="$1"
  local interval="$2"
  local start_ts
  start_ts="$(date +%s)"
  while true; do
    if docker info >/dev/null 2>&1; then
      return 0
    fi
    local now
    now="$(date +%s)"
    if (( now - start_ts >= timeout )); then
      echo "ERROR: docker daemon not reachable after ${timeout}s."
      exit 1
    fi
    sleep "$interval"
  done
}

parse_epoch() {
  local raw="$1"
  date -d "$raw" +%s 2>/dev/null || echo ""
}

# Wait until the container is running and stable (no restarts) for MIN_STABLE_SECONDS
wait_for_container_stable() {
  local container="$1"
  local min_stable="$2"
  local max_wait="$3"
  local interval="$4"

  local wait_start
  wait_start="$(date +%s)"
  local stable_since=""
  local last_restart_count=""
  local last_started_epoch=""

  echo "Waiting for container '$container' to be running and stable for at least ${min_stable}s (max wait ${max_wait}s)..."

  while true; do
    local now
    now="$(date +%s)"
    if (( now - wait_start >= max_wait )); then
      echo "ERROR: Timed out waiting for container '$container' to stabilize."
      exit 1
    fi

    local inspect_line
    inspect_line="$(docker inspect "$container" --format '{{.State.Status}} {{.State.Running}} {{.State.Restarting}} {{.State.StartedAt}} {{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}} {{.RestartCount}}' 2>/dev/null || true)"

    if [ -z "$inspect_line" ]; then
      echo "  Container not found yet; waiting..."
      sleep "$interval"
      continue
    fi

    local status running restarting started_at health restart_count
    read -r status running restarting started_at health restart_count <<<"$inspect_line"

    if [ "$status" != "running" ] || [ "$running" != "true" ] || [ "$restarting" = "true" ]; then
      echo "  Status: $status (restarting=$restarting); waiting..."
      sleep "$interval"
      continue
    fi

    if [ "$REQUIRE_HEALTHY" = "1" ] && [ "$health" != "none" ] && [ "$health" != "healthy" ]; then
      echo "  Health: $health; waiting for healthy..."
      sleep "$interval"
      continue
    fi

    local start_epoch
    start_epoch="$(parse_epoch "$started_at")"
    if [ -z "$start_epoch" ]; then
      echo "  Could not parse container start time; waiting..."
      sleep "$interval"
      continue
    fi

    if [ "$restart_count" != "$last_restart_count" ] || [ "$start_epoch" != "$last_started_epoch" ] || [ -z "$stable_since" ]; then
      stable_since="$start_epoch"
      last_restart_count="$restart_count"
      last_started_epoch="$start_epoch"
      echo "  Detected (re)start. restart_count=$restart_count; resetting stability timer."
    fi

    local stable_elapsed
    stable_elapsed=$(( now - stable_since ))
    local uptime
    uptime=$(( now - start_epoch ))

    if (( stable_elapsed >= min_stable )); then
      echo "  Container stable: uptime=${uptime}s, restart_count=${restart_count}. Proceeding."
      break
    fi

    echo "  Running; uptime=${uptime}s; stable=${stable_elapsed}s/${min_stable}s; restart_count=${restart_count}. Waiting..."
    sleep "$interval"
  done
}

# Ensure docker daemon is ready before proceeding
wait_for_docker_daemon "$DOCKER_DAEMON_TIMEOUT" "$POLL_INTERVAL_SECONDS"

# Resolve project root (if git repo)
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

TIMESTAMP="$(date +'%Y%m%dT%H%M%S')"
TIMESTAMP_HUMAN="$(date +'%Y-%m-%d %I:%M:%S %p %Z')"
OUT_DIR="$PROJECT_ROOT/_build/docker-deploy/$CONTAINER"
mkdir -p "$OUT_DIR"
REPORT="$OUT_DIR/files-created-${TIMESTAMP}.txt"

echo "Scanning host-side artifacts for container: $CONTAINER"
echo "Project root: $PROJECT_ROOT"
echo "Report will be written to: $REPORT"
echo

{
  echo "============================================================"
  echo "Docker Deployment Host File Scan"
  echo "Container: $CONTAINER"
  echo "Project root: $PROJECT_ROOT"
  echo "Scan timestamp: $TIMESTAMP_HUMAN"
  echo "============================================================"
  echo

  # 0) Container readiness (wait until stable for post-deploy scan)
  echo "0) Container readiness"
  echo "----------------------"
  if [ "$SKIP_STABLE_WAIT" = "1" ]; then
    echo "Skipping container stability wait (SKIP_STABLE_WAIT=1)."
  else
    wait_for_container_stable "$CONTAINER" "$MIN_STABLE_SECONDS" "$MAX_WAIT_SECONDS" "$POLL_INTERVAL_SECONDS"
  fi
  echo

  # 1) Container metadata
  echo "1) Container metadata"
  echo "---------------------"

  if ! docker inspect "$CONTAINER" >/dev/null 2>&1; then
    echo "ERROR: container '$CONTAINER' not found."
    exit 1
  fi

  CREATED_RAW="$(docker inspect "$CONTAINER" --format '{{.Created}}' || echo '')"
  CONTAINER_ID="$(docker inspect "$CONTAINER" --format '{{.Id}}' || echo '')"
  IMAGE_ID="$(docker inspect "$CONTAINER" --format '{{.Image}}' || echo '')"
  STARTED_RAW="$(docker inspect "$CONTAINER" --format '{{.State.StartedAt}}' || echo '')"
  RESTART_COUNT="$(docker inspect "$CONTAINER" --format '{{.RestartCount}}' || echo '')"
  HEALTH_STATUS="$(docker inspect "$CONTAINER" --format '{{if .State.Health}}{{.State.Health.Status}}{{else}}n/a{{end}}' || echo '')"

  echo "  Container ID: $CONTAINER_ID"
  echo "  Image ID:     $IMAGE_ID"
  echo "  Created (raw): $CREATED_RAW"
  echo "  Started (raw): $STARTED_RAW"
  echo "  Restart count: $RESTART_COUNT"
  echo "  Health:        $HEALTH_STATUS"

  if [ -z "$CREATED_RAW" ]; then
    echo "  WARNING: Could not determine container creation time; skipping time-based filtering."
    DEPLOY_START_EPOCH=""
  else
    # Convert to epoch seconds; requires GNU date
    DEPLOY_START_EPOCH="$(parse_epoch "$CREATED_RAW")"
    if [ -z "$DEPLOY_START_EPOCH" ]; then
      echo "  WARNING: Unable to parse container creation time; skipping time-based filtering."
    else
      echo "  Parsed creation time (epoch): $DEPLOY_START_EPOCH"
    fi
  fi

  echo

  # 2) Mounts and host paths
  echo "2) Mounts and host paths"
  echo "------------------------"

  HOST_PATHS=()

  if command -v jq >/dev/null 2>&1; then
    MOUNTS_JSON="$(docker inspect "$CONTAINER" --format '{{json .Mounts}}')"
    echo "  Mounts:"
    echo "$MOUNTS_JSON" | jq -r '.[] | "    - Type: \(.Type)  Source: \(.Source)  Destination: \(.Destination)"'
    echo

    # Bind mounts
    while IFS= read -r src; do
      [ -n "$src" ] && HOST_PATHS+=("$src")
    done < <(echo "$MOUNTS_JSON" | jq -r '.[] | select(.Type == "bind") | .Source')

    # Volume mounts -> resolve Mountpoints via docker volume inspect
    while IFS= read -r vname; do
      if [ -n "$vname" ]; then
        MP="$(docker volume inspect "$vname" --format '{{.Mountpoint}}' 2>/dev/null || true)"
        if [ -n "$MP" ]; then
          HOST_PATHS+=("$MP")
        fi
      fi
    done < <(echo "$MOUNTS_JSON" | jq -r '.[] | select(.Type == "volume") | .Name')
  else
    echo "  Note: jq not installed; using simple grep-based mount scan."
    echo
    docker inspect "$CONTAINER" | sed 's/^/    /' | grep -n '"Mounts"' -A 10 || true
    echo

    # Best-effort source extraction
    while IFS= read -r src; do
      [ -n "$src" ] && HOST_PATHS+=("$src")
    done < <(docker inspect "$CONTAINER" \
      | grep '"Source":' \
      | sed -E 's/.*"Source": "([^"]+)".*/\1/' || true)
  fi

  if [ "${#HOST_PATHS[@]}" -eq 0 ]; then
    echo "  No host mount paths detected from the container."
    echo
    echo "============================================================"
    echo "No host paths associated with this container. Nothing to scan."
    echo "============================================================"
    exit 0
  fi

  # Deduplicate host paths
  mapfile -t HOST_PATHS_UNIQ < <(printf "%s\n" "${HOST_PATHS[@]}" | sort -u)

  echo "  Host paths associated with this container:"
  for p in "${HOST_PATHS_UNIQ[@]}"; do
    marker=""
    if [[ "$p" == "$PROJECT_ROOT"* ]]; then
      marker=" (inside project root)"
    fi
    echo "    - $p$marker"
  done
  echo

  # 3) Files created/modified on host during deployment
  echo "3) Host files created/modified during deployment"
  echo "-----------------------------------------------"
  echo "Listing files under host mount paths whose mtime is >= container creation time."
  echo "Note: This is an approximation based on file modification times."
  echo

  TOTAL_FOUND=0

  for p in "${HOST_PATHS_UNIQ[@]}"; do
    if [ ! -e "$p" ]; then
      echo "  Skipping missing host path: $p"
      echo
      continue
    fi

    # Avoid scanning Docker's own storage; focus on app/project mounts
    case "$p" in
      /var/lib/docker/*)
        echo "  Skipping internal Docker path: $p"
        echo
        continue
        ;;
    esac

    echo "  Host path: $p"
    echo "  -------------------------------------"

    if [ -z "${DEPLOY_START_EPOCH:-}" ]; then
      echo "    WARNING: No valid creation time; listing ALL files under this path."
      FIND_EXPR=(find "$p" -type f)
    else
      FIND_EXPR=(find "$p" -type f)
    fi

    # Iterate files and filter by mtime >= deploy start
    while IFS= read -r f; do
      # stat -c %Y = epoch mtime
      mtime_epoch="$(stat -c '%Y' "$f" 2>/dev/null || echo '')"
      if [ -n "${DEPLOY_START_EPOCH:-}" ] && [ -n "$mtime_epoch" ]; then
        if [ "$mtime_epoch" -lt "$DEPLOY_START_EPOCH" ]; then
          continue
        fi
      fi

      mtime_human="$(stat -c '%y' "$f" 2>/dev/null || echo '?')"
      size_bytes="$(stat -c '%s' "$f" 2>/dev/null || echo '?')"

      echo "    $f"
      echo "      size:  $size_bytes bytes"
      echo "      mtime: $mtime_human"
      TOTAL_FOUND=$((TOTAL_FOUND + 1))
    done < <("${FIND_EXPR[@]}" 2>/dev/null)

    echo
  done

  echo "Total files reported: $TOTAL_FOUND"
  echo
  echo "============================================================"
  echo "End of host file scan for container: $CONTAINER"
  echo "Report written to: $REPORT"
  echo "============================================================"
} | tee "$REPORT"
