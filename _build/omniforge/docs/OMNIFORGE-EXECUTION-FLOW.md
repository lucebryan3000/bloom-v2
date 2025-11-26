# OmniForge Execution Flow (Host → Container → Phases)

Use this as the concise map of what happens on every run, regardless of mode (menu, `--run`, `--phase`). Pair it with the CLI/Workflow docs for flags and examples.

## End-to-End Flow (One Run)
1) **Entry & flags**: `./_build/omniforge/omni.sh …` parses CLI/env, applies profile-driven dry-run defaults (tech_stack defaults to dry-run), and may re-exec inside the app container when `DOCKER_EXEC_MODE=container`.
2) **Load & validate**: Source `omni.config`, `omni.settings.sh`, `omni.profiles.sh`, `omni.phases.sh`; resolve profile aliases/defaults; validate config/profile consistency; apply profile defaults while respecting user overrides; init logging.
3) **Tooling & setup**: Ensure project-local Node.js/pnpm on host (or use container tools), deploy OmniForge templates/settings, run first-run auto-detection if needed.
4) **Background prep**: Start prereq remediation/download warmup and build the tech_stack index; show banner/plan while these run.
5) **Preflight**: Check dependencies, required vars (via indexer), disk/writeability, and git safety (host only; relaxed in container).
6) **Execute phases**: Run all enabled phases (or a selected phase) honoring state/resume/force and dry-run; log successes/failures/skips; apply profile resource hints in container mode.
7) **Recap & next steps**: Report stats and failures (if any), tail logs in dry-run, and suggest next actions; state can be viewed/cleared via `omni --status`.

## Modes & Inputs
- **Modes**: Menu (`omni.sh`), direct `--run`/`--phase`, or `--init` (guided bootstrap). All share the same core flow; menu collects profile/feature/config via prompts.
- **Inputs**: Profile (`STACK_PROFILE`, `omni.profiles.sh`), config (`omni.config`), settings (`omni.settings.sh`), phases (`omni.phases.sh`), and env/CLI overrides.
- **Outputs**: Project files/templates, logs (`_build/omniforge/logs/`), state (`.bootstrap_state`), index (`.omniforge_index`), optional download cache (`.download-cache`).

## Behaviors to Remember
- **DRY_RUN**: Wrapper/bin defaults apply (PROFILE_DRY_RUN + tech_stack); `--dry-run`/`DRY_RUN=false` can override. Dry-run marks scripts as succeeded without executing.
- **Resume/force**: State file skips completed scripts; use `--force` or `omni status --clear` to rerun.
- **Docker split**: Host handles git safety, local toolchain, and starting services; container mode re-execs inside the app container after starting compose services.
- **Profile influence**: Profiles set feature flags, dry-run defaults, and resource hints (container mode only); user overrides win over profile defaults.

## Related References
- CLI: `_build/omniforge/docs/OMNIFORGE-CLI.md`
- Workflow (step-by-step): `_build/omniforge/docs/OMNIFORGE-WORKFLOW.md`
- Architecture: `_build/omniforge/docs/OMNIFORGE-ARCHITECTURE.md`
- Phases: `_build/omniforge/docs/OMNIFORGE-PHASES.md`
- Docker behavior: `_build/omniforge/docs/OMNIFORGE-DOCKER.md`
- Status/state: `_build/omniforge/docs/OMNIFORGE-STATUS.md`
