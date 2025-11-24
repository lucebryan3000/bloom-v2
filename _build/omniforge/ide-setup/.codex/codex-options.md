# Codex options to stage in new projects

Working notes for bootstrapping a `.codex/` folder when you spin up a new repo. Source of truth: `codex --help`, `codex exec --help`, `codex features list`, and the existing `kb` command pattern (see `/home/luce/apps/bloom/.codex/commands/kb-codex.md`).

## Minimal layout to copy

```
.codex/
  codex-options.md        # keep this guide in-repo
  commands/               # each Markdown file = one codex command contract
    kb-codex.md           # example command; clone/tweak for others
    # review.md           # optional: PR/code review protocol
    # ship.md             # optional: release/merge checklist
    # test.md             # optional: test runner protocol
    # lint.md             # optional: lint/format protocol
    # incident.md         # optional: oncall/mitigation steps
```

Delete or comment any optional lines you do not want; keep the rest as your starter kit.

## How command files work

- Place command definitions under `.codex/commands/<name>.md`; the file name becomes the command (e.g., `kb-codex.md` → `kb`).
- Good structure: title, purpose, invocation examples, strict execution protocol (steps, safety rules), and expected outputs.
- Copy patterns from `kb-codex.md`: clear protocol, guardrails (don’t touch unrelated files), and explicit success criteria.
- Keep commands idempotent and repo-scoped; avoid instructions that mutate global state.

### Command template (copy/paste)

```markdown
# <Command Name>

Purpose: <what this command covers>

## Invocation
<command> [args...]

## Protocol
1. <step 1>
2. <step 2>
3. <step 3>

## Outputs to surface
- <what to report back>
```

## Suggested commands to stage (comment out what you don't need)

- [ ] `kb` – knowledge-base generator (reuse `/home/luce/apps/bloom/.codex/commands/kb-codex.md`).
- [ ] `review` – PR/code review rubric (severity-first findings, testing asks).
- [ ] `ship` – release/merge checklist (tests, changelog, versioning, git add/commit boundaries).
- [ ] `test` – project-specific test matrix (unit/integration/e2e commands, coverage expectations).
- [ ] `lint` – lint/format commands, autofix policy.
- [ ] `incident` – mitigation/runbook steps for urgent fixes.
- [ ] `plan` – when to build a plan vs. execute directly (tie to repo risk level).

Uncheck or delete anything you do not want in the default scaffold.

## Runtime defaults (from `~/.codex/config.toml`)

Use `~/.codex/config.toml` for per-user defaults; override per-run with `-c key=value`. Example baseline for new projects:

```toml
model = "gpt-5.1-codex-max"
# model_reasoning_effort = "xhigh"          # uncomment for deeper chains
sandbox_mode = "workspace-write"            # safer than danger-full-access for new repos
approval_policy = "on-request"              # ask on risky commands
# features.apply_patch_freeform = true      # optional beta
# features.web_search_request = true        # optional web search tool
# sandbox_permissions = ["disk-full-read-access"]  # optional, expands sandbox
# shell_environment_policy.inherit = "all"  # optional, inherit env vars

[projects."/abs/path/to/repo"]
trust_level = "trusted"
```

## Flags you can set at invocation time (from `codex --help`/`codex exec --help`)

- `-m, --model <name>` to swap models; `--oss` + `--local-provider <lmstudio|ollama>` for local.
- `-s, --sandbox <read-only|workspace-write|danger-full-access>` to pick sandbox.
- `-a, --ask-for-approval <untrusted|on-failure|on-request|never>` to control approvals.
- `--full-auto` = `-a on-request` + `--sandbox workspace-write`.
- `--search` to enable web search tool.
- `-C, --cd <DIR>` to pin working root; `--add-dir <DIR>` to grant extra write dirs.
- `--output-schema <FILE>` for structured final responses; `--json` for JSONL event stream.

## Feature flags available here (`codex features list`)

Name | Stage | Enabled
---- | ----- | -------
undo | stable | true
view_image_tool | stable | true
unified_exec | experimental | false
rmcp_client | experimental | false
apply_patch_freeform | beta | false
web_search_request | stable | false
exec_policy | experimental | true
experimental_sandbox_command_assessment | experimental | false
enable_experimental_windows_sandbox | experimental | false
remote_compaction | experimental | true
parallel | experimental | false
shell_tool | stable | true

Toggle via `~/.codex/config.toml` (`features.<name> = true/false`) or `codex --enable/--disable <name>`.

## MCP (Model Context Protocol) hooks (optional)

- `codex mcp add|get|remove|list` to manage global MCP servers (experimental).
- Requires enabling the experimental client for OAuth flows when needed (`experimental_use_rmcp_client` in config).
- Keep server configs outside the repo; reference them in docs if a project depends on them.

## New-repo checklist (edit/comment to taste)

- [ ] Copy this `codex-options.md` into `.codex/` of the new repo.
- [ ] Decide which commands to keep; duplicate `kb-codex.md` as a template for each.
- [ ] Set project trust level in `~/.codex/config.toml` with the repo’s absolute path.
- [ ] Pick sandbox + approval defaults (prefer `workspace-write` + `on-request` unless locked down).
- [ ] Enable only the feature flags you trust; avoid beta/experimental by default.
- [ ] Document test/lint commands inside the matching command files.
- [ ] Add any MCP servers the project requires (if any), but do not store secrets in-repo.
