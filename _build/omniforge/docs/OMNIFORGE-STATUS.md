# OmniForge Status & State Management

`omni status` (backed by `_build/omniforge/bin/status`) shows bootstrap progress, lists phases/scripts, displays configuration, and lets you clear state for reruns. This guide covers commands, state files, and common flows.

## Quick Commands
- Show completion state: `./_build/omniforge/omni.sh --status`
- List phases and scripts: `./_build/omniforge/omni.sh --list`
- Show configuration summary: `./_build/omniforge/omni.sh --config`
- Clear all state: `./_build/omniforge/omni.sh status --clear`
- Clear one script: `./_build/omniforge/omni.sh status --clear "foundation/init-nextjs.sh"`
- JSON output: `LOG_FORMAT=json ./_build/omniforge/omni.sh --status`

## Modes
| Option | Description |
| --- | --- |
| `--state` (default) | Show script completion state. |
| `--list` | List all phases and their scripts. |
| `--config` | Print resolved configuration and flags. |
| `--clear [key]` | Clear state for a script, or all if no key is provided. |

## State Files
- `.omniforge_state`: Tracks per-script completion so reruns can skip finished steps unless `--force` is provided.
- `.omniforge_index`: Index of tech_stack scripts and required variables. Regenerated during runs; referenced by status and validation.

## Behavior & Flags
- `LOG_FORMAT=json` switches status output to JSON (useful for CI).
- `VERBOSE=true` enables verbose logging. 
- `--force` (on `omni --run` / `--phase`) reruns scripts even if state says they are complete.
- `omni status --clear` removes state entries; use to rerun selected scripts without forcing everything.

## Best Practices
- Check `--status` after a run to confirm phase completion before proceeding to build/verify.
- Use `--list` before a targeted `--phase` run to confirm the scripts you expect are present.
- In CI, `LOG_FORMAT=json omni --status` provides machine-readable progress snapshots.

## Troubleshooting
- Missing state file: it will be recreated on the next run; if phases show incomplete unexpectedly, confirm git cleanliness and rerun with `--force` if needed.
- Stuck scripts marked complete: clear specific entries via `omni status --clear "<script-path>"` and rerun the relevant phase.
- Index mismatch: regenerate by running `omni --run` (or `--phase`) to rebuild `.omniforge_index` before inspecting status.
