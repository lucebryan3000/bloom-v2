# OmniForge Download Cache

OmniForge keeps a self-contained download cache for npm tarballs and related artifacts to speed up bootstrap and reduce network churn. This guide explains where it lives, how it’s used, and how to manage or purge it.

## Location & Contents

- Path: `_build/omniforge/.download-cache/`
- Typical contents: npm tarballs (Next.js, Drizzle, React, etc.), unpacked packages, and occasional metadata files for cached installs.
- Scope: Cache is confined to the OmniForge directory; safe to delete when you want a clean fetch.

## How It’s Used

- Tech_stack scripts and package installers check the cache before hitting the network.
- Background warmups may populate the cache during preflight to accelerate phase execution.
- Cache is reused across runs unless purged.

## Managing the Cache

- Purge via CLI: `./_build/omniforge/omni.sh --purge` (recommended)
- Manual removal: `rm -rf _build/omniforge/.download-cache/` (safe; cache will be rebuilt on next run)
- Inspect size: `du -sh _build/omniforge/.download-cache`

## Canonical Tarball Versions (current cache snapshot)

- next-15.5.6.tgz
- react-19.2.0.tgz / react-dom-19.2.0.tgz
- typescript-5.9.3.tgz
- drizzle-orm-0.44.7.tgz / drizzle-kit-0.31.7.tgz
- lucide-react-0.554.0.tgz
- tailwindcss-4.1.17.tgz / postcss-8.5.6.tgz / autoprefixer-10.4.22.tgz
- pg-boss-12.3.1.tgz
- vitest-4.0.14.tgz / playwright-test-1.57.0.tgz
- ai-sdk-openai-2.0.72.tgz / ai-sdk-anthropic-2.0.49.tgz / ai-5.0.102.tgz
- class-variance-authority-0.7.1.tgz
- zustand-5.0.8.tgz

(No duplicate versions detected in `_build/omniforge/.download-cache/npm`.)

## When to Purge

- After dependency upgrades to avoid stale tarballs.
- When disk space is constrained.
- If cached artifacts look corrupted (re-run after purge).

## Related Settings

- Cache path is derived from `OMNIFORGE_DIR` (see `omni.settings.sh`), defaulting to `_build/omniforge/.download-cache/`.
- No external/global cache is required; the project cache is self-contained.

## Troubleshooting

- “Package missing” even with cache present: purge and rerun to refresh tarballs.
- Slow installs: warmup may have been skipped; rerun with network available or pre-warm by rerunning bootstrap.
- Permission errors: ensure `_build/omniforge/.download-cache/` is writable by the current user.
