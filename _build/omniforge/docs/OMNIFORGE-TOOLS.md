# OmniForge Local Toolchain (Node.js & pnpm)

How OmniForge installs and activates project-local tooling so bootstrap can run without system-level Node.js/pnpm.

## What It Does
- Installs Node.js and pnpm under `.tools/` in the project when not already available on the host.
- Activates the local toolchain during runs so `node`/`pnpm` resolve from `.tools/` first.
- Skips host installs when inside the app container (assumes image already has Node.js/pnpm).

## When It Runs
- On `./_build/omniforge/omni.sh --run` / `--phase` / `--init` in host mode if Node.js or pnpm is missing.
- Uses `prereqs_local_setup_all` from `lib/prereqs.sh` and sources the activation script from `TOOLS_ACTIVATE_SCRIPT` (e.g., `_build/omniforge/.tools/activate`).

## Paths
- Base directory: `_build/omniforge/.tools/`
- Activation script: `_build/omniforge/.tools/activate` (prepends local bin to `PATH`)

## Usage
- No manual steps needed; OmniForge installs/activates automatically.
- To verify activation: run `which node` and `which pnpm` after `omni.sh` starts; should point to `.tools/` when on host.
- To force re-setup: delete `_build/omniforge/.tools/` and rerun `omni.sh` (will reinstall if needed).

## Container Mode
- If `INSIDE_OMNI_DOCKER=1`, OmniForge does not install local tools and expects the app image to provide Node.js/pnpm.

## Troubleshooting
- Tools not found after run: ensure `omni.sh` was used (wrapper sets up tools) and check permissions on `.tools/`.
- Using system Node.js instead: confirm the activation script is sourced (OmniForge does this automatically); check `PATH` for `.tools/node/bin`.
- Corrupted tools: remove `_build/omniforge/.tools/` and rerun to reinstall.

## References
- Workflow: `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
