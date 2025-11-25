# Local Ignored Files

This page makes ChatGPT/GitHub and Claude Code aware of files that exist locally but are excluded from version control or Claude context.

## How to refresh
- Requirements: `python3` with the `pathspec` package available.
- Run `./scripts/list-ignored-files.sh` from the repo root to re-list current items.
- Update this file whenever a new persistent local artifact should stay out of GitHub and Claude context.

## Git-ignored items present
- .bootstrap_state
- .claude/archive/
- .claude/logs/
- .claude/scripts/playbook/core/
- .claude/scripts/playbook/lib/
- .tools/
- .toolsrc.example
- _AppModules-Luce/GitHub-Scripts/GitHub-Scripts-old.zip
- _AppModules-Luce/GitHub-Scripts/lib/
- _AppModules-Luce/GitHub-Scripts/logs/
- _AppModules-Luce/_bootstrap/root/.env
- _AppModules-Luce/apps/GitHub-Scripts/GitHub-Scripts-old.zip
- _AppModules-Luce/apps/GitHub-Scripts/lib/
- _AppModules-Luce/apps/GitHub-Scripts/logs/
- _AppModules-Luce/apps/context-opt/
- _AppModules-Luce/backup/
- _build/omniforge/.download-cache/
- _build/omniforge/docs/bootstrap.conf.backup
- scripts/bootstrap/

## Untracked (not ignored)
- none (once this file and `scripts/list-ignored-files.sh` are checked in)

## Claude soft-blocked items present (.claude/.claudeignore)
- .DS_Store
- .tools/node/
- .tools/pnpm/
- _AppModules-Luce/.DS_Store
- _AppModules-Luce/GitHub-Scripts-old.zip
- _AppModules-Luce/docs/
- _build/

Notes:
- The Claude list is summarized; it collapses deeper `dist/` and build caches (mostly under `.tools/`) to keep the output readable.
- Claude hard-blocks (defined in `.claude/settings.json`) are not listed here; see that file for the deny list.
