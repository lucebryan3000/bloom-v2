# OmniForge Settings Manager

The settings manager copies recommended IDE/tool configurations into your project. It’s accessible via `omni --settings` or the interactive menu.

## What It Does
- Copies editor/tool config templates from `_build/omniforge/example-files/` into your project (e.g., VSCode, ESLint/Prettier configs if provided).
- Prompts before overwriting existing files (unless configured otherwise).
- Runs outside the main bootstrap phases, so you can refresh configs without rerunning the stack.

## Commands
- Launch settings manager: `./_build/omniforge/omni.sh --settings`
- Interactive menu: run `./_build/omniforge/omni.sh` (no args) and select Settings.

## Typical Files
- Templates under `_build/omniforge/example-files/` (e.g., `.eslintrc`, `.prettierrc`, editor settings). Actual contents may vary by stack revision.

## Safety
- Backups or prompts are used to avoid clobbering; review changes if you have custom configs.

## When to Use
- After pulling updates to OmniForge templates to refresh local IDE/tooling configs.
- When onboarding to ensure consistent lint/format/editor settings.

## Troubleshooting
- Files not copied: ensure templates exist under `example-files/` and that you have write permissions.
- Custom configs: back up your overrides; re-apply after running settings manager if needed.

## References
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Quick reference: `_build/omniforge/docs/OMNIFORGE-QUICK-REFERENCE.md`
