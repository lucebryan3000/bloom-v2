#!/usr/bin/env bash
#
# docker-deploy-clean.sh
#
# Clean up host artifacts created for a particular container deployment.
#
# This script:
#   - Finds the latest scan report produced by docker-deploy-scan.sh
#   - Parses the host file list from that report
#   - Deletes those files (with optional --force)
#   - Optionally stops/removes the container and associated volumes
#
# Usage:
#   ./_build/scripts/docker-deploy-clean.sh [--force] [--remove-docker] <container_name>
#
#   --force          actually delete files (otherwise dry-run)
#   --remove-docker  stop & remove the container and its named volumes
#   --remove-networks remove non-default networks attached to the container
#   --remove-report   delete the scan report directory for this container
#
# Example:
#   ./_build/scripts/docker-deploy-clean.sh bloom2_app           # dry-run
#   ./_build/scripts/docker-deploy-clean.sh --force bloom2_app   # delete files only
#   ./_build/scripts/docker-deploy-clean.sh --force --remove-docker bloom2_app
#
set -euo pipefail

FORCE=false
REMOVE_DOCKER=false
REMOVE_NETWORKS=false
REMOVE_REPORT=false
MAX_AGE_SECONDS="${MAX_AGE_SECONDS:-3600}" # prompt if container/image older than this (default 1h)

while [[ $# -gt 0 ]]; do
  case "$1" in
    --force)
      FORCE=true
      shift
      ;;
    --remove-docker)
      REMOVE_DOCKER=true
      shift
      ;;
    --remove-networks)
      REMOVE_NETWORKS=true
      shift
      ;;
    --remove-report)
      REMOVE_REPORT=true
      shift
      ;;
    -*)
      echo "Unknown option: $1"
      echo "Usage: $0 [--force] [--remove-docker] [--remove-networks] [--remove-report] <container_name>"
      exit 1
      ;;
    *)
      # first non-option is the container name
      CONTAINER="${1:-}"
      shift
      break
      ;;
  esac
done

CONTAINER="${CONTAINER:-${1:-}}"

if [ -z "${CONTAINER:-}" ]; then
  echo "Usage: $0 [--force] [--remove-docker] [--remove-networks] [--remove-report] <container_name>"
  exit 1
fi

# Helpers
parse_epoch() {
  local raw="$1"
  date -d "$raw" +%s 2>/dev/null || echo ""
}

human_age() {
  local seconds="$1"
  local h=$(( seconds / 3600 ))
  local m=$(( (seconds % 3600) / 60 ))
  local s=$(( seconds % 60 ))
  printf "%dh %02dm %02ds" "$h" "$m" "$s"
}

# Resolve project root
if git rev-parse --show-toplevel >/dev/null 2>&1; then
  PROJECT_ROOT="$(git rev-parse --show-toplevel)"
else
  PROJECT_ROOT="$(pwd)"
fi

SCAN_DIR="$PROJECT_ROOT/_build/docker-deploy/$CONTAINER"
LOG_DIR="$PROJECT_ROOT/_build/omniforge/logs"
LOG_FILE="$LOG_DIR/docker-wipe.log"

mkdir -p "$LOG_DIR" 2>/dev/null || true

FILES_LISTED=0
FILES_DELETED=0
CONTAINER_STOPPED=false
CONTAINER_REMOVED=false
VOLUMES_REMOVED=0
NETWORKS_REMOVED=0

log_summary() {
  local result="$1"
  local mode
  mode=$([[ "$FORCE" == "true" ]] && echo "DELETE" || echo "DRY-RUN")
  local ts
  ts="$(date -u +'%Y-%m-%dT%H:%M:%SZ')"
  echo "[$ts] container=${CONTAINER} mode=${mode} result=${result} report=${LATEST_REPORT} files_listed=${FILES_LISTED} files_deleted=${FILES_DELETED} remove_docker=${REMOVE_DOCKER} container_removed=${CONTAINER_REMOVED} volumes=${#CONTAINER_VOLUMES[@]} volumes_removed=${VOLUMES_REMOVED} networks=${#CONTAINER_NETWORKS[@]} networks_removed=${NETWORKS_REMOVED}" >>"$LOG_FILE"
}

if [ ! -d "$SCAN_DIR" ]; then
  echo "ERROR: No scan directory found for container '$CONTAINER' at (expected output from _build/omniforge/scripts/docker-deploy-scan.sh):"
  echo "  $SCAN_DIR"
  echo "Run docker-deploy-scan.sh for this container first."
  exit 1
fi

# Find latest report
LATEST_REPORT="$(ls -1 "$SCAN_DIR"/files-created-*.txt 2>/dev/null | sort | tail -n 1 || true)"

if [ -z "$LATEST_REPORT" ]; then
  echo "ERROR: No files-created-*.txt reports found in:"
  echo "  $SCAN_DIR"
  echo "Run docker-deploy-scan.sh for this container first."
  exit 1
fi

echo "Project root: $PROJECT_ROOT"
echo "Container:    $CONTAINER"
echo "Report:       $LATEST_REPORT"
echo "Mode:         $([[ "$FORCE" == "true" ]] && echo "DELETE" || echo "DRY-RUN")"
echo "Remove docker resources: $REMOVE_DOCKER"
echo "Remove networks:         $REMOVE_NETWORKS"
echo "Remove report folder:    $REMOVE_REPORT"
echo

# Container/image age check (warn if older than MAX_AGE_SECONDS)
DOCKER_AVAILABLE=false
CONTAINER_FOUND=false
CONTAINER_CREATED_EPOCH=""
IMAGE_CREATED_EPOCH=""
IMAGE_ID=""
CONTAINER_NETWORKS=()
CONTAINER_VOLUMES=()

if command -v docker >/dev/null 2>&1; then
  DOCKER_AVAILABLE=true
  if docker inspect "$CONTAINER" >/dev/null 2>&1; then
    CONTAINER_FOUND=true
    CONTAINER_CREATED_RAW="$(docker inspect "$CONTAINER" --format '{{.Created}}' || echo "")"
    CONTAINER_CREATED_EPOCH="$(parse_epoch "$CONTAINER_CREATED_RAW")"
    IMAGE_ID="$(docker inspect "$CONTAINER" --format '{{.Image}}' || echo "")"
    if [ -n "$IMAGE_ID" ]; then
      IMAGE_CREATED_RAW="$(docker inspect "$IMAGE_ID" --format '{{.Created}}' 2>/dev/null || echo "")"
      IMAGE_CREATED_EPOCH="$(parse_epoch "$IMAGE_CREATED_RAW")"
    fi

    # Capture networks & volumes up front (before any removals)
    if command -v jq >/dev/null 2>&1; then
      mapfile -t CONTAINER_NETWORKS < <(docker inspect "$CONTAINER" --format '{{json .NetworkSettings.Networks}}' 2>/dev/null \
        | jq -r 'keys[]' 2>/dev/null || true)
      mapfile -t CONTAINER_VOLUMES < <(docker inspect "$CONTAINER" --format '{{json .Mounts}}' 2>/dev/null \
        | jq -r '.[] | select(.Type == "volume") | .Name' 2>/dev/null || true)
    else
      while IFS= read -r net; do
        [ -n "$net" ] && CONTAINER_NETWORKS+=("$net")
      done < <(docker inspect "$CONTAINER" 2>/dev/null | grep '"NetworkID"' -B1 \
        | grep '"Name"' | sed -E 's/.*"Name": "([^"]+)".*/\1/' || true)
      while IFS= read -r vname; do
        [ -n "$vname" ] && CONTAINER_VOLUMES+=("$vname")
      done < <(docker inspect "$CONTAINER" 2>/dev/null | grep '"Type": "volume"' -A2 \
        | grep '"Name"' | sed -E 's/.*"Name": "([^"]+)".*/\1/' || true)
    fi
  fi
fi

if [ "$DOCKER_AVAILABLE" = true ] && [ "$CONTAINER_FOUND" = true ]; then
  now_epoch="$(date +%s)"
  age_messages=()
  if [ -n "$CONTAINER_CREATED_EPOCH" ]; then
    container_age=$(( now_epoch - CONTAINER_CREATED_EPOCH ))
    if (( container_age > MAX_AGE_SECONDS )); then
      age_messages+=("Container created $(human_age "$container_age") ago (raw: $(docker inspect "$CONTAINER" --format '{{.Created}}')).")
    fi
  fi
  if [ -n "$IMAGE_CREATED_EPOCH" ]; then
    image_age=$(( now_epoch - IMAGE_CREATED_EPOCH ))
    if (( image_age > MAX_AGE_SECONDS )); then
      age_messages+=("Image ($IMAGE_ID) created $(human_age "$image_age") ago (raw: $(docker inspect "$IMAGE_ID" --format '{{.Created}}')).")
    fi
  fi

  if [ "${#age_messages[@]}" -gt 0 ]; then
    echo "WARNING: Target looks older than $(human_age "$MAX_AGE_SECONDS")."
    for msg in "${age_messages[@]}"; do
      echo "  - $msg"
    done
    echo
    read -r -p "Proceed with cleanup for '$CONTAINER'? [y/N] " confirm
    case "$confirm" in
      y|Y|yes|YES) ;;
      *) echo "Aborting cleanup."; exit 1 ;;
    esac
    echo
  fi
else
  echo "Note: Unable to verify container/image age (docker available: $DOCKER_AVAILABLE, container found: $CONTAINER_FOUND)."
  echo
fi

# Parse file paths from the report.
# The scan script prints lines like:
#   <path>
#     size: ...
#     mtime: ...
# We'll grab lines that look like absolute paths (starting with /), ignoring header text.
FILE_PATHS=()
while IFS= read -r line; do
  # Trim leading spaces
  path="$(echo "$line" | sed -E 's/^[[:space:]]+//')"
  # Treat lines that start with "/" as file paths
  if [[ "$path" == /* ]] && [ -f "$path" ]; then
    FILE_PATHS+=("$path")
  fi
done <"$LATEST_REPORT"

FILES_LISTED=${#FILE_PATHS[@]}

if [ "${#FILE_PATHS[@]}" -eq 0 ]; then
  echo "No file paths detected in the latest report. Nothing to clean."
  exit 0
fi

echo "Files to consider for cleanup:"
for f in "${FILE_PATHS[@]}"; do
  echo "  $f"
done
echo

if [ "$FORCE" != "true" ]; then
  echo "Dry-run only. Pass --force to actually delete these files."
else
  echo "Deleting files..."
  for f in "${FILE_PATHS[@]}"; do
    if [ -f "$f" ]; then
      echo "  rm $f"
      if rm -f "$f"; then
        FILES_DELETED=$((FILES_DELETED + 1))
      fi
    else
      echo "  (skip, does not exist) $f"
    fi
  done
  echo "File deletion complete."
  echo
fi

# Optional Docker resource cleanup
if [ "$REMOVE_DOCKER" == "true" ]; then
  if ! command -v docker >/dev/null 2>&1; then
    echo "WARNING: docker CLI not found; cannot remove docker resources."
  else
    echo "Docker resource cleanup requested (--remove-docker)."
    echo

    # Stop container if running
    if docker ps --format '{{.Names}}' | grep -Fxq "$CONTAINER"; then
      echo "Stopping container: $CONTAINER"
      if docker stop "$CONTAINER"; then
        CONTAINER_STOPPED=true
      fi
    else
      echo "Container '$CONTAINER' not currently running."
    fi

    # Remove container if present
    if docker ps -a --format '{{.Names}}' | grep -Fxq "$CONTAINER"; then
      echo "Removing container: $CONTAINER"
      if docker rm "$CONTAINER"; then
        CONTAINER_REMOVED=true
      fi
    else
      echo "Container '$CONTAINER' not found among stopped containers."
    fi

    # Remove named volumes captured earlier
    if [ "${#CONTAINER_VOLUMES[@]}" -gt 0 ]; then
      echo
      echo "Removing named volumes associated with this container:"
      for v in "${CONTAINER_VOLUMES[@]}"; do
        echo "  docker volume rm $v"
        if docker volume rm "$v"; then
          VOLUMES_REMOVED=$((VOLUMES_REMOVED + 1))
        fi
      done
    fi

    # Remove networks (excluding defaults) if requested
    if [ "$REMOVE_NETWORKS" == "true" ] && [ "${#CONTAINER_NETWORKS[@]}" -gt 0 ]; then
      echo
      echo "Removing container-attached networks (non-default):"
      for n in "${CONTAINER_NETWORKS[@]}"; do
        case "$n" in
          bridge|host|none) echo "  Skipping default network: $n"; continue ;;
        esac
        echo "  docker network rm $n"
        if docker network rm "$n"; then
          NETWORKS_REMOVED=$((NETWORKS_REMOVED + 1))
        fi
      done
    elif [ "$REMOVE_NETWORKS" == "true" ]; then
      echo
      echo "No non-default networks captured for this container."
    fi

    echo
    echo "Docker resource cleanup done (container + volumes where possible)."
  fi
fi

# Optional report folder cleanup
if [ "$REMOVE_REPORT" == "true" ]; then
  if [ "$FORCE" != "true" ]; then
    echo "Report folder removal requested but skipped (dry-run)."
  else
    echo "Removing report directory: $SCAN_DIR"
    rm -rf "$SCAN_DIR"
  fi
fi

echo
echo "Cleanup script complete."
echo "Report used: $LATEST_REPORT"
echo "Mode: $([[ "$FORCE" == "true" ]] && echo "DELETE" || echo "DRY-RUN")"
log_summary "ok"
