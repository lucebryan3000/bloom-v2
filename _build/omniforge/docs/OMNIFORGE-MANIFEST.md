# OmniForge Manifest

Single source of truth emitted after a successful `omni run`. Consumed by the branded landing page (Next.js) and any future tooling.

## Path & lifecycle
- Written to `PROJECT_ROOT/omni.manifest.json`.
- Written once after all phases succeed.
- Skipped when: run fails, `DRY_RUN=true`, or a single-phase run is requested (unless explicitly enabled later).
- Overwrites previous manifest on success.

## Schema (initial)
```jsonc
{
  "deployedBy": "OmniForge",
  "omniVersion": "3.0.0",
  "generatedAt": "2025-01-01T12:34:56Z",
  "profile": {
    "key": "tech_stack",
    "name": "TECH_STACK",
    "tagline": "Full Tech Stack Coverage",
    "description": "...",
    "mode": "dev",
    "dryRunDefault": true,
    "resources": "memory=6g cpu=2"
  },
  "features": [
    { "key": "ENABLE_AUTHJS", "enabled": true },
    { "key": "ENABLE_AI_SDK", "enabled": false }
  ],
  "stack": {
    "runtime": "Next.js 15 · Node 20 · pnpm 9",
    "database": "Postgres/Drizzle",
    "auth": "NextAuth",
    "ai": "ai-sdk/openai, ai-sdk/anthropic",
    "jobs": "pg-boss",
    "logging": "pino",
    "ui": "App Router, shadcn/ui",
    "state": "zustand",
    "exports": "pdf, excel, markdown, json",
    "testing": "vitest, playwright",
    "quality": "eslint, prettier, husky, lint-staged"
  },
  "devQuickStart": {
    "localUrl": "http://localhost:3000",
    "containerUrl": "http://<container-ip>:3000",
    "envFiles": [".env", ".env.local"],
    "commands": ["pnpm dev", "pnpm build", "pnpm lint", "pnpm typecheck", "pnpm test", "pnpm test:e2e"],
    "endpoints": [
      { "label": "Health", "path": "/api/monitoring/health" },
      { "label": "Metrics", "path": "/api/monitoring/metrics" },
      { "label": "Chat", "path": "/chat" }
    ],
    "nextStepsUrl": ""
  },
  "logPath": "_build/omniforge/logs/omniforge_20250101_123456.log",
  "logLines": ["...deployment log lines..."],
  "container": {
    "id": "abc123",
    "name": "omniforge-dev",
    "image": "node:22-alpine",
    "network": "bridge",
    "platform": "linux/amd64",
    "status": "running",
    "uptime": "2h 10m",
    "ports": ["3000:3000"],
    "restartPolicy": "unless-stopped"
  }
}
```

## Field sources
- `deployedBy`, `omniVersion`: `OMNI_VERSION` and constants from `omni.settings.sh`.
- `generatedAt`: UTC timestamp at write time.
- `profile.*`: `STACK_PROFILE` and metadata from `omni.profiles.sh` (`name`, `tagline`, `description`, `mode`, `PROFILE_DRY_RUN`, `PROFILE_RESOURCES`).
- `features`: all `ENABLE_*` env vars after profile application.
- `stack`: derived from config + flags (package versions, enabled components).
- `devQuickStart`: URLs from settings (`DEV_SERVER_URL`), env files defaults (`.env`, `.env.local`), standard pnpm commands, endpoints from monitoring/export defaults, optional `nextStepsUrl`.
- `logPath`/`logLines`: deployment log location (if inside PROJECT_ROOT) and up to ~200 lines from the bootstrap log (when available).
- `container`: optional; may be left empty if not available.

## Compatibility
- Adding new fields is non-breaking.
- Renaming/removing existing top-level keys or `profile.key|profile.name|devQuickStart.localUrl` is breaking for the landing page template.
- Consumers must tolerate missing/empty fields and malformed manifests by falling back to defaults or a minimal welcome view.
