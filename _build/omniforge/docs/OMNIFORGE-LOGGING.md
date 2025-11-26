# OmniForge Logging

Concise guide to where OmniForge logs live, how rotation works, and how to inspect them during bootstrap and build flows.

## Locations
- Directory: `_build/omniforge/logs/`
- Files: `omniforge_YYYYMMDD_HHMMSS.log` (normal runs) and `dry-run_YYYYMMDD_HHMMSS.log` (dry runs)
- Archives: `_build/omniforge/logs/archive/` (older logs)
- Config: `LOG_DIR` is defined in `omni.settings.sh` (defaults to the path above).

## Modes & Output
- Console modes: default (info/steps), `--verbose` (adds debug), `--quiet` (errors only).
- Files always capture full detail with timestamps regardless of console mode.
- Dry-run: still writes logs; tail the latest file for previewed actions.

## Rotation & Cleanup
- Log directory is auto-created on first run.
- Rotation and cleanup are handled by the logging library on startup of `omni.sh`.
- To purge manually: remove old files under `_build/omniforge/logs/` or `archive/` (safe to delete).

## Common Commands
- List logs: `ls -lt _build/omniforge/logs`
- Tail latest: `tail -f _build/omniforge/logs/omniforge_*.log`
- Tail with filter: `tail -f _build/omniforge/logs/omniforge_*.log | grep -E "STEP|ERROR|OK"`
- Compare runs: `diff <(grep "STEP\|OK\|ERROR" log1) <(grep "STEP\|OK\|ERROR" log2)`

## Troubleshooting
- No logs written: ensure `_build/omniforge/logs/` is writable and `LOG_DIR` is not overridden incorrectly.
- Missing expected steps: check for `--quiet` usage; review the file log for full detail.
- Large log set: prune old files in `_build/omniforge/logs/` and `_build/omniforge/logs/archive/` (safe to delete).

## Related Docs
- Quick reference: `_build/omniforge/docs/OMNIFORGE-QUICK-REFERENCE.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
