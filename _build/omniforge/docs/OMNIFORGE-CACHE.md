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
