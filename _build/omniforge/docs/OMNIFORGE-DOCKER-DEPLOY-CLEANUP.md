# OmniForge Docker Deploy Scan & Wipe

How to inventory and wipe host artifacts tied to a container deployment using the deploy scan + cleanup pair, plus the Omni menu shortcut.

## Components
- Scan (read-only): `_build/omniforge/scripts/docker-deploy-scan.sh <container>`
  - Waits for Docker daemon, then for the container to be stable/healthy (default 5 minutes) before scanning.
  - Reports host mount paths (binds + volume mountpoints) and lists files with mtime >= container creation time.
  - Writes reports to `_build/docker-deploy/<container>/files-created-<timestamp>.txt`.
- Cleanup (dry-run by default): `_build/scripts/docker-deploy-clean.sh [--force] [--remove-docker] [--remove-networks] [--remove-report] <container>`
  - Reads the latest `files-created-*.txt` for the container and uses it as the source of truth for host file deletion.
  - Prompts if the container or image is older than 1 hour (`MAX_AGE_SECONDS` overrideable) before proceeding.
  - `--force` to actually delete files (otherwise prints them).
  - `--remove-docker` stops/removes the container and its named volumes; `--remove-networks` drops non-default networks; `--remove-report` deletes the report folder (requires `--force`).
- Menu shortcut: Omni main menu option “Wipe/Erase Docker Bootstrap” (option 8) discovers report folders, shows latest report per container, confirms, then runs the full wipe command.

## Typical Flow
1) After deploy, generate a report (host-level):
```bash
./_build/omniforge/scripts/docker-deploy-scan.sh bloom2_app
```
2) Inspect the report:
```bash
cat _build/docker-deploy/bloom2_app/files-created-*.txt | tail
```
3) Dry-run cleanup (see what would be removed):
```bash
./_build/scripts/docker-deploy-clean.sh bloom2_app
```
4) Full wipe (host files + container + volumes + networks + report):
```bash
./_build/scripts/docker-deploy-clean.sh --force --remove-docker --remove-networks --remove-report bloom2_app
```
5) Omni CLI wrapper (non-interactive, full wipe): 
```bash
./_build/omniforge/omni.sh docker-wipe --container bloom2_app --force
```
   - Defaults to full wipe (files + container + volumes + networks + report); omit `--force` for dry-run.
6) Via menu: run `./_build/omniforge/omni.sh`, choose “Maintenance / Cleanup” → “Wipe/Erase Docker Bootstrap”, pick the container, confirm.

## Safety Notes
- Cleanup is dry-run until `--force` is provided.
- File deletions are limited to paths listed in the latest scan report (host-side artifacts only).
- Age guard prompts if the target container/image is older than 1 hour; override with `MAX_AGE_SECONDS=<seconds>`.
- Networks: only non-default networks are removed when `--remove-networks` is set.
- Report deletion (`--remove-report`) also respects dry-run; requires `--force` to remove the directory.

## Locations
- Scan script: `_build/omniforge/scripts/docker-deploy-scan.sh`
- Cleanup script: `_build/scripts/docker-deploy-clean.sh`
- Reports: `_build/docker-deploy/<container>/files-created-<timestamp>.txt`
- Menu entry: `_build/omniforge/lib/menu.sh` (option 8), wrapper: `_build/omniforge/omni.sh`
