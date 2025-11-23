# Build Backlog Data Files

This folder contains the data files used by the `/build-backlog` slash command.

## Files

- **build-backlog.md** - Active backlog tasks (work in progress)
- **build-backlog-completed.md** - Archived completed tasks
- **README.md** - This file (organizational documentation)

## Organization

These files are **excluded from auto-loading** via `.claudeignore` to reduce context consumption, but the `/build-backlog` command can still access them on-demand.

### Why This Structure?

1. **Self-contained**: All backlog-related data in one location
2. **Reduced context**: Data files don't load on every message (~7KB saved)
3. **On-demand access**: `/build-backlog` command loads when needed
4. **Easy maintenance**: Related files grouped together

## Usage

### Command Location
The command wrapper is at: `.claude/commands/build-backlog.md`

### Data Location
The actual backlog data is here: `.claude/commands/build-backlog/build-backlog.md`

### How .claudeignore Works
```bash
# Exclude all files in build-backlog subfolder
.claude/commands/build-backlog/*.md

# But keep the command wrapper accessible
!.claude/commands/build-backlog.md
```

**Result:**
- ✅ `/build-backlog` command is always available
- ✅ Data files are excluded from auto-context
- ✅ Command can still read data files when invoked

## Maintenance

When updating the backlog:
- Use `/build-backlog add` to add tasks
- Use `/build-backlog update` to change completion status
- Both modes automatically save to `build-backlog.md`
- Backups are created as `build-backlog.md.bak`

## Future Enhancements

Potential additions to this folder:
- `build-backlog-templates.md` - Task templates
- `build-backlog-archive-YYYY-MM.md` - Monthly archives
- `build-backlog-metrics.json` - Completion statistics
