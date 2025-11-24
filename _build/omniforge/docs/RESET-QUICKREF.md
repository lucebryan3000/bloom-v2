# OmniForge Reset - Quick Reference

**Purpose**: Reset last deployment while preserving OmniForge system improvements

---

## Commands

| Command | Description |
|---------|-------------|
| `omni reset` | Interactive reset (confirm before delete) |
| `omni reset --yes` | Non-interactive reset (auto-confirm) |
| `omni reset --help` | Show reset help |

---

## What Gets Deleted

### Root Configuration Files
- `docker-compose.yml`
- `drizzle.config.ts`
- `next.config.ts`
- `package.json`
- `playwright.config.ts`
- `tsconfig.json`
- `vitest.config.ts`
- `.env.example`

### State Files
- `.bootstrap_state`
- `tsconfig.tsbuildinfo`
- `next-env.d.ts`
- `pnpm-lock.yaml`

### Directories
- `src/` (all source files)
- `e2e/` (E2E tests)
- `public/` (public assets)
- `.next/` (Next.js build cache)
- `node_modules/` (NPM packages)
- `logs/` (build logs)
- `test-results/` (Playwright results)
- `playwright-report/` (Playwright reports)

---

## What Gets Preserved

### OmniForge System
- `_build/omniforge/` (entire OmniForge system)
  - All scripts and libraries
  - All improvements and enhancements
  - Configuration files

### Project Files
- `.claude/` (Claude Code configuration)
- `docs/` (documentation)
- `.git/` (git repository)
- `_backup/` (previous backups)

---

## Backup Location

Backups are automatically created at:
```
_backup/deployment-YYYYMMDD-HHMMSS/
├── manual-fixes/           # Manually created files
│   ├── confidence.ts
│   ├── sessionState.ts
│   └── narrative.ts
├── package.json            # Package manifest
├── tsconfig.json           # TypeScript config
├── deployment-manifest.log # Deployment manifest
└── .bootstrap_state        # Bootstrap state
```

---

## Full Deployment Cycle

### 1. Reset Current Deployment
```bash
omni reset
# or
omni reset --yes   # Skip confirmation
```

### 2. Initialize New Deployment
```bash
omni run
```

### 3. Verify Build
```bash
omni build
```

### 4. Test Application
```bash
pnpm dev
```

---

## Restoring from Backup

If you need to restore manually created files after a failed deployment:

```bash
# Find latest backup
ls -lt _backup/

# Restore manual fixes
cp _backup/deployment-YYYYMMDD-HHMMSS/manual-fixes/*.ts src/lib/

# Restore package.json (if needed)
cp _backup/deployment-YYYYMMDD-HHMMSS/package.json .

# Restore TypeScript config (if needed)
cp _backup/deployment-YYYYMMDD-HHMMSS/tsconfig.json .
```

---

## Safety Features

### Automatic Backup
- Every reset creates a timestamped backup
- Includes all manually created files
- Includes configuration files

### Interactive Confirmation
- Default mode asks for confirmation
- Shows what will be deleted
- Shows what will be preserved

### Preserve OmniForge
- Never deletes `_build/omniforge/`
- Verifies critical files after reset
- Fails safely if verification fails

---

## Common Scenarios

### Scenario 1: Test Different Configuration
```bash
# 1. Reset current deployment
omni reset --yes

# 2. Modify bootstrap.conf
vim _build/omniforge/bootstrap.conf

# 3. Deploy with new config
omni run

# 4. Verify
omni build
```

### Scenario 2: Fix Build Errors
```bash
# 1. Reset failed deployment
omni reset --yes

# 2. Redeploy
omni run

# 3. If same error occurs, restore fixes
cp _backup/deployment-*/manual-fixes/*.ts src/lib/

# 4. Build
omni build
```

### Scenario 3: Clean Slate
```bash
# 1. Reset everything
omni reset --yes

# 2. Fresh deployment
omni run

# 3. Fresh build
omni build
```

---

## Troubleshooting

### Reset Shows "No deployment to reset"
**Solution**: Nothing to reset - you're already at a clean state

### Reset Fails with "OmniForge missing"
**Solution**: Critical OmniForge files were deleted. Restore from git:
```bash
git restore _build/omniforge/
```

### Manual fixes not backed up
**Solution**: Files didn't exist at time of reset. Check previous backups:
```bash
ls -la _backup/deployment-*/manual-fixes/
```

### Can't find backup
**Solution**: Backups are in `_backup/` with timestamps:
```bash
ls -lt _backup/ | head -5
```

---

## Advanced Usage

### Custom Backup Location
```bash
# Before reset, manually backup to custom location
cp -r src/lib/manual-fixes ~/my-custom-backup/

# After reset and redeploy
cp ~/my-custom-backup/*.ts src/lib/
```

### Selective Reset
```bash
# Delete only source files (keep configs)
rm -rf src/ e2e/ public/

# Keep state file
rm .next/ node_modules/

# Redeploy
omni run
```

---

## Comparison with Clean Command

| Feature | `omni reset` | `omni clean` |
|---------|--------------|--------------|
| Target | Current deployment | Specified path |
| Backup | Automatic | Manual |
| Scope | Root directory | Configurable |
| Use Case | Redeploy | Test deployments |

---

## Quick Tips

1. **Always use `omni reset`** instead of manual `rm -rf`
2. **Backups are cheap** - don't skip them
3. **Check backups** before running long operations
4. **Use `--yes` in scripts** for automation
5. **Test in `test/` first** using `test-deploy.sh`

---

## Related Commands

- `omni run` - Initialize deployment
- `omni build` - Verify build
- `omni clean` - Clean test installations
- `omni status` - Show deployment status

---

**Last Updated**: 2025-11-24
**Version**: OmniForge 1.1.0
