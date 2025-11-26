# OmniForge Reset & Cleanup Tools

How to clean artifacts, purge caches, and reset OmniForge state/system files.

## Commands
- Reset OmniForge system files: `./_build/omniforge/omni.sh reset [--yes]`
  - Preserves non-OmniForge project files; removes OmniForge system files and state.
  - Prompts unless `--yes` is provided.
- Cleanup artifacts: `./_build/omniforge/omni.sh clean --path <dir> [--level 1-4]`
  - Deletes generated artifacts under a path with optional severity level.
  - No args to `clean` opens menu for interactive cleanup.
- Purge download cache: `./_build/omniforge/omni.sh --purge`
  - Removes `_build/omniforge/.download-cache/` (safe to rebuild on next run).
- Manual log cleanup: delete files under `_build/omniforge/logs/` (logs are safe to remove).

## When to Use
- Before re-running bootstrap from scratch or after major template updates (reset).
- Free disk space or remove generated outputs (clean).
- Force fresh package fetches (purge cache).

## Safety Notes
- `reset` targets OmniForge system paths and state; non-OmniForge project files are left intact.
- `clean` with higher levels removes more aggressively—confirm paths/levels before running.
- Always ensure you have backups/commits for important project files before aggressive cleanup.

## Related Files & Scripts
- Reset entry: `_build/omniforge/bin/reset`
- Cleanup scripts: `_build/omniforge/scripts/cleanup-bootstrap.sh`, `_build/omniforge/scripts/cleanup-run-artifacts.sh`
- State files: `.omniforge_state`, `.omniforge_index` (regenerated on runs)
- Cache: `_build/omniforge/.download-cache/`
- Logs: `_build/omniforge/logs/`

## Troubleshooting
- Missing state after reset: rerun `omni --run` to regenerate configs and state.
- Clean didn’t remove expected files: check the path/level arguments; run with `--level` bumped up if appropriate.
- Cache still present after purge: ensure you’re running the wrapper (`omni.sh --purge`) and that no process is holding files open.

## References
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Logging: `_build/omniforge/docs/OMNIFORGE-LOGGING.md`
- Download cache: `_build/omniforge/docs/OMNIFORGE-CACHE.md`
