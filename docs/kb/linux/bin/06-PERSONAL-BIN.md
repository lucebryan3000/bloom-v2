---
id: linux-06-personal-bin
topic: linux
file_role: detailed
profile: full
difficulty_level: intermediate
kb_version: 3.1
prerequisites: [linux-basics]
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux]
last_reviewed: 2025-11-13
---

# 06-PERSONAL-BIN.md - Your Personal Binary Directory

## Table of Contents
1. [Why Create ~/bin?](#why-create-bin)
2. [Setting Up ~/bin Directory](#setting-up-bin-directory)
3. [Adding to PATH](#adding-to-path)
4. [Creating Your First Script](#creating-your-first-script)
5. [~/bin vs ~/.local/bin](#bin-vs-localbin)
6. [Organizing Scripts in ~/bin](#organizing-scripts-in-bin)
7. [Naming Conventions](#naming-conventions)
8. [Project-Specific Wrappers](#project-specific-wrappers)
9. [Managing Symlinks to Project Tools](#managing-symlinks-to-project-tools)
10. [Backup and Version Control](#backup-and-version-control)
11. [Common Patterns](#common-patterns)

---

## Why Create ~/bin?

### The Problem

You write useful scripts but then:
- Can't remember where you saved them
- Have to type full paths: `~/scripts/backup/run-backup.sh`
- Scatter scripts across multiple projects
- Can't reuse them easily across different projects
- Lose them when you change projects

### The Solution: ~/bin

A **personal bin directory** gives you:

1. **Single location** for all personal tools
2. **No paths needed** - just type the command name
3. **Portable** - easy to backup and sync
4. **Discoverable** - `ls ~/bin` shows all your tools
5. **Professional** - mimics system bin directories

### ✅ Before and After

**❌ Before (scattered scripts)**:
```bash
~/projects/backup/scripts/backup.sh
~/work/scripts/deploy.sh
~/Downloads/fix-permissions.sh
~/Desktop/test.sh

# Have to remember locations:
~/projects/backup/scripts/backup.sh /data
```

**✅ After (organized ~/bin)**:
```bash
~/bin/backup
~/bin/deploy
~/bin/fix-permissions
~/bin/test-api

# Just type the name:
backup /data
```

### Real-World Benefits

**Productivity**:
- Save 30+ seconds per command (no path lookup)
- Reuse scripts across all projects
- Build personal toolkit over time

**Organization**:
- One place for all personal tools
- Easy to document and share
- Simple to backup

**Learning**:
- Practice shell scripting
- Build automation skills
- Create portfolio of tools

---

## Setting Up ~/bin Directory

### Quick Setup

```bash
# Create directory
mkdir -p ~/bin

# Add to PATH (bash)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc

# Reload shell configuration
source ~/.bashrc

# Verify it's in PATH
echo $PATH | grep -o "$HOME/bin"
```

### ✅ Step-by-Step Setup

**1. Create the directory**:
```bash
mkdir -p ~/bin
```

**2. Verify it was created**:
```bash
ls -ld ~/bin
drwxr-xr-x 2 luce luce 4096 Nov 9 10:00 /home/luce/bin
```

**3. Add to PATH in your shell config**:

**For Bash** (~/.bashrc):
```bash
# Add ~/bin to PATH
if [ -d "$HOME/bin" ]; then
 export PATH="$HOME/bin:$PATH"
fi
```

**For Zsh** (~/.zshrc):
```bash
# Add ~/bin to PATH
if [ -d "$HOME/bin" ]; then
 export PATH="$HOME/bin:$PATH"
fi
```

**For Fish** (~/.config/fish/config.fish):
```fish
# Add ~/bin to PATH
set -gx PATH $HOME/bin $PATH
```

**4. Reload your shell**:
```bash
# Bash
source ~/.bashrc

# Zsh
source ~/.zshrc

# Fish
source ~/.config/fish/config.fish

# Or just open a new terminal
```

**5. Verify PATH includes ~/bin**:
```bash
echo $PATH
# Should include /home/luce/bin

# More precise check:
echo $PATH | tr ':' '\n' | grep bin
/home/luce/bin
/usr/local/bin
/usr/bin
/bin
```

**6. Test it works**:
```bash
# Create test script
echo '#!/bin/bash' > ~/bin/hello
echo 'echo "Hello from ~/bin!"' >> ~/bin/hello
chmod +x ~/bin/hello

# Run it (no path needed!)
hello
# Output: Hello from ~/bin!
```

### ❌ Common Setup Mistakes

**1. Forgot to reload shell**:
```bash
# Added to ~/.bashrc but didn't source it
hello
# bash: hello: command not found

# Fix: source ~/.bashrc
```

**2. Wrong order in PATH**:
```bash
# ❌ Wrong - system bins have priority
export PATH="$PATH:$HOME/bin"

# ✅ Correct - your bins have priority
export PATH="$HOME/bin:$PATH"
```

**3. Didn't make script executable**:
```bash
# Created script but forgot chmod +x
hello
# bash: hello: Permission denied

# Fix:
chmod +x ~/bin/hello
```

**4. Used relative path**:
```bash
# ❌ Wrong
export PATH="~/bin:$PATH" # ~ doesn't expand in quotes

# ✅ Correct
export PATH="$HOME/bin:$PATH" # $HOME expands properly
```

---

## Adding to PATH

### Understanding PATH

**PATH** is an environment variable that tells the shell where to look for executable files:

```bash
echo $PATH
/home/luce/bin:/usr/local/bin:/usr/bin:/bin:/usr/games
```

**Structure**: Colon-separated list of directories
**Search order**: Left to right (first match wins)

### PATH Search Order Matters

```bash
# If you have:
/home/luce/bin/python
/usr/bin/python

# And PATH is:
export PATH="$HOME/bin:$PATH"

# Typing 'python' runs ~/bin/python (comes first)

# If PATH was:
export PATH="$PATH:$HOME/bin"

# Typing 'python' runs /usr/bin/python (comes first)
```

### ✅ Recommended PATH Order

```bash
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"

# Priority:
# 1. ~/bin - Your personal scripts (highest priority)
# 2. ~/.local/bin - User-installed programs
# 3. /usr/local/bin - System-wide custom installs
# 4. /usr/bin - System programs
# 5. /bin - Essential system binaries
```

### ✅ Best Practice PATH Configuration

**~/.bashrc**:
```bash
# Personal bin directories
if [ -d "$HOME/bin" ]; then
 PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
 PATH="$HOME/.local/bin:$PATH"
fi

export PATH
```

**Benefits**:
- Only adds directories that exist
- Clear and maintainable
- Explicitly exports PATH

### Checking What PATH Will Find

```bash
# Which command will run?
which python
/home/luce/bin/python

# See all matches in PATH
type -a python
python is /home/luce/bin/python
python is /usr/bin/python

# Test without running
command -v python
/home/luce/bin/python
```

### ❌ PATH Anti-Patterns

**1. Dot in PATH (security risk)**:
```bash
# ❌ NEVER DO THIS
export PATH=".:$PATH"

# Why dangerous:
cd /tmp/untrusted
# Malicious 'ls' here could run instead of /bin/ls
```

**2. Duplicate entries**:
```bash
# ❌ Inefficient
export PATH="$HOME/bin:$HOME/bin:$PATH"

# ✅ Better
if ! echo "$PATH" | grep -q "$HOME/bin"; then
 export PATH="$HOME/bin:$PATH"
fi
```

**3. Overly complex PATH**:
```bash
# ❌ Hard to debug
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/local/games:/usr/games:$HOME/bin:$HOME/.local/bin:$HOME/scripts:$HOME/tools:$HOME/utils:$HOME/.cargo/bin:$HOME/.npm/bin:..."

# ✅ Keep it simple
export PATH="$HOME/bin:$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
```

---

## Creating Your First Script

### Step-by-Step: Hello World

**1. Create the script file**:
```bash
nano ~/bin/greet
```

**2. Add shebang and code**:
```bash
#!/bin/bash
# My first ~/bin script

name="${1:-World}"
echo "Hello, $name!"
```

**3. Make it executable**:
```bash
chmod +x ~/bin/greet
```

**4. Test it**:
```bash
greet
# Output: Hello, World!

greet Alice
# Output: Hello, Alice!
```

**5. Use it from anywhere**:
```bash
cd /tmp
greet Bob
# Output: Hello, Bob!
# Works from any directory!
```

### ✅ More Useful First Scripts

**Quick note taker**:
```bash
#!/bin/bash
# File: ~/bin/note

NOTE_FILE="$HOME/notes.txt"

if [ $# -eq 0 ]; then
 # No arguments: show notes
 cat "$NOTE_FILE"
else
 # Arguments: add note with timestamp
 echo "$(date '+%Y-%m-%d %H:%M') - $*" >> "$NOTE_FILE"
 echo "Note added!"
fi
```

**Usage**:
```bash
note "Remember to buy milk"
note "Meeting at 3pm"
note
# 2025-11-09 10:30 - Remember to buy milk
# 2025-11-09 10:31 - Meeting at 3pm
```

**Quick web server**:
```bash
#!/bin/bash
# File: ~/bin/serve

port="${1:-8000}"
echo "Starting server on http://localhost:$port"
python3 -m http.server "$port"
```

**Usage**:
```bash
cd ~/projects/website
serve
# Starting server on http://localhost:8000

serve 3000
# Starting server on http://localhost:3000
```

**Git status for all repos**:
```bash
#!/bin/bash
# File: ~/bin/git-status-all

find ~/projects -name.git -type d | while read gitdir; do
 repo=$(dirname "$gitdir")
 echo "=== $repo ==="
 git -C "$repo" status -s
 echo
done
```

**Usage**:
```bash
git-status-all
# === /home/luce/projects/myapp ===
# M README.md
# ?? newfile.txt
#
# === /home/luce/projects/website ===
# [clean]
```

---

## ~/bin vs ~/.local/bin

### The XDG Base Directory Standard

The **XDG** (Cross-Desktop Group) standard defines:
- `~/.local/bin` - User-installed executables
- `~/.local/share` - User data
- `~/.config` - User configuration

### When to Use Each

| Directory | Use For | Examples |
|-----------|---------|----------|
| `~/bin` | Personal scripts you wrote | backup, deploy, git-cleanup |
| `~/.local/bin` | Programs you installed | pipx tools, cargo binaries |

### ✅ Recommended Setup: Use Both

```bash
# In ~/.bashrc

# Personal scripts (highest priority)
if [ -d "$HOME/bin" ]; then
 PATH="$HOME/bin:$PATH"
fi

# User-installed programs
if [ -d "$HOME/.local/bin" ]; then
 PATH="$HOME/.local/bin:$PATH"
fi

export PATH
```

**PATH order**: `~/bin` → `~/.local/bin` → system paths

**Why this order**:
- Your scripts override user-installed programs
- User-installed programs override system programs
- You control the entire chain

### Examples of What Goes Where

**~/bin** (your scripts):
```bash
~/bin/backup # Your backup script
~/bin/deploy # Your deployment script
~/bin/fix-perms # Your permission fixer
~/bin/clean-logs # Your log cleaner
~/bin/start-dev # Your dev environment starter
```

**~/.local/bin** (installed programs):
```bash
~/.local/bin/black # Python formatter (via pipx)
~/.local/bin/poetry # Python package manager
~/.local/bin/rustc # Rust compiler (via rustup)
~/.local/bin/gh # GitHub CLI (downloaded)
```

### ✅ Migration: From ~/bin to Both

If you only have `~/bin`, here's how to add `~/.local/bin`:

```bash
# 1. Create ~/.local/bin
mkdir -p ~/.local/bin

# 2. Move installed programs there
mv ~/bin/black ~/.local/bin/
mv ~/bin/poetry ~/.local/bin/

# 3. Keep your scripts in ~/bin
# (leave them alone)

# 4. Update PATH in ~/.bashrc
if [ -d "$HOME/bin" ]; then
 PATH="$HOME/bin:$PATH"
fi

if [ -d "$HOME/.local/bin" ]; then
 PATH="$HOME/.local/bin:$PATH"
fi

export PATH

# 5. Reload
source ~/.bashrc
```

### ❌ Common Confusion

**"Should I use ~/bin or ~/.local/bin?"**

Both! They serve different purposes:
- Write your own scripts → `~/bin`
- Install external tools → `~/.local/bin`

**"Does it really matter?"**

For personal use, not much. But:
- Following standards helps with automation
- Makes it clear what's custom vs. installed
- Easier to backup/sync appropriately
- Some installers default to `~/.local/bin`

---

## Organizing Scripts in ~/bin

### Flat Structure (Recommended for Most Users)

```bash
~/bin/
â"œâ"€â"€ backup
â"œâ"€â"€ deploy
â"œâ"€â"€ docker-cleanup
â"œâ"€â"€ git-cleanup
â"œâ"€â"€ notes
â"œâ"€â"€ serve
â""â"€â"€ todo
```

**Advantages**:
- Simple: all scripts in one place
- Fast: `ls ~/bin` shows everything
- Portable: easy to backup

**Disadvantages**:
- Can get cluttered with many scripts
- Harder to find related scripts

### ✅ Naming Prefixes (Best Practice)

Use prefixes to group related scripts:

```bash
~/bin/
â"œâ"€â"€ docker-cleanup
â"œâ"€â"€ docker-logs
â"œâ"€â"€ docker-restart
â"œâ"€â"€ git-cleanup
â"œâ"€â"€ git-recent
â"œâ"€â"€ git-status-all
â"œâ"€â"€ npm-clean
â"œâ"€â"€ npm-update-all
â""â"€â"€ system-backup
```

**Benefits**:
- Grouped alphabetically: `ls ~/bin`
- Tab completion helps: `git-<TAB>` shows all git scripts
- Clear purpose from name

### Subdirectories (Advanced)

If you have 50+ scripts:

```bash
~/bin/
â"œâ"€â"€ docker/
â"‚ â"œâ"€â"€ cleanup
â"‚ â"œâ"€â"€ logs
â"‚ â""â"€â"€ restart
â"œâ"€â"€ git/
â"‚ â"œâ"€â"€ cleanup
â"‚ â"œâ"€â"€ recent
â"‚ â""â"€â"€ status-all
â""â"€â"€ wrappers/
 â"œâ"€â"€ backup ->../backup.sh
 â""â"€â"€ deploy ->../deploy.sh
```

**To make this work**, add subdirectories to PATH:
```bash
# In ~/.bashrc
if [ -d "$HOME/bin" ]; then
 PATH="$HOME/bin:$PATH"

 # Add subdirectories
 for dir in "$HOME/bin"/*; do
 if [ -d "$dir" ]; then
 PATH="$dir:$PATH"
 fi
 done
fi
```

**Or use wrapper scripts**:
```bash
# ~/bin/docker
#!/bin/bash
# Wrapper for docker scripts

case "$1" in
 cleanup) ~/bin/docker/cleanup;;
 logs) ~/bin/docker/logs "$2";;
 restart) ~/bin/docker/restart "$2";;
 *)
 echo "Usage: docker {cleanup|logs|restart}"
 exit 1
;;
esac
```

**Usage**:
```bash
docker cleanup
docker logs mycontainer
docker restart mycontainer
```

### ❌ Anti-Pattern: Too Much Nesting

```bash
# ❌ Don't do this
~/bin/scripts/utils/docker/cleanup/run.sh

# ✅ Do this
~/bin/docker-cleanup
```

**Why**:
- Simpler is better
- Easy to find and remember
- Less to type

---

## Naming Conventions

### ✅ Good Script Names

**Characteristics**:
- Lowercase (Unix tradition)
- Hyphen-separated (kebab-case)
- Descriptive but concise
- Action-oriented (verbs)

**Examples**:
```bash
backup # Simple, clear
git-cleanup # Scoped, action-oriented
docker-logs # Category-action pattern
start-dev # Action-target pattern
fix-permissions # Problem-solution pattern
```

### ❌ Bad Script Names

```bash
script.sh # Too generic
myScript # camelCase (not Unix convention)
backup_database # Underscores less common (harder to type)
b # Too short, unclear
backup-all-databases-and-configs-to-external-drive # Too long
```

### Naming Patterns

**1. Category-Action**:
```bash
git-cleanup # Clean up git repos
docker-logs # Show docker logs
npm-update # Update npm packages
system-backup # Backup system files
```

**2. Action-Target**:
```bash
backup-db # Backup database
deploy-app # Deploy application
clean-logs # Clean log files
start-dev # Start development server
```

**3. Tool Name**:
```bash
serve # Start web server
note # Quick note taker
todo # TODO list manager
timer # Simple timer
```

**4. Description**:
```bash
fix-permissions # Fix file permissions
analyze-logs # Analyze log files
compress-images # Compress image files
```

### ✅ Extension or No Extension?

**Unix convention**: No extension for executable scripts in ~/bin

```bash
# ✅ Recommended
~/bin/backup

# ❌ Not recommended for ~/bin
~/bin/backup.sh
```

**Why no extension**:
- Commands don't have extensions (`ls`, `cp`, `git`)
- Implementation detail (could rewrite in Python later)
- Cleaner to type

**When to use extension**:
- Source files (not directly executed): `lib/utils.sh`
- Documentation: `README.md`
- Scripts not in PATH: `~/scripts/backup.sh`

### Avoiding Name Conflicts

**Check before creating**:
```bash
# Check if name already exists
which backup
type backup
command -v backup

# If exists, choose different name:
backup → my-backup
backup → backup-all
backup → do-backup
```

**Common conflicts to avoid**:
```bash
test # Shell builtin
time # System command
date # System command
cat # System command
echo # Shell builtin
cd # Shell builtin
kill # Shell builtin
```

**✅ Safe alternatives**:
```bash
test → run-test, test-all
time → timer, timeit
cat → show, display
```

---

## Project-Specific Wrappers

### The Problem

You work on multiple projects, each with their own commands:

```bash
cd ~/projects/app1
npm run dev

cd ~/projects/app2
docker-compose up

cd ~/projects/app3
./run-dev.sh
```

You have to remember:
- Which directory each project is in
- What command to run
- What arguments it needs

### The Solution: Wrapper Scripts

Create simple wrappers in `~/bin` that handle the complexity:

**✅ Project Launcher**:
```bash
#!/bin/bash
# File: ~/bin/start-myapp

cd ~/projects/myapp || exit 1
npm run dev
```

**Usage**:
```bash
start-myapp
# Automatically cds to project and runs dev server
```

### ✅ Multi-Project Wrapper

```bash
#!/bin/bash
# File: ~/bin/dev

project="$1"
shift # Remove project name from arguments

case "$project" in
 website)
 cd ~/projects/website || exit 1
 npm run dev "$@"
;;
 api)
 cd ~/projects/api || exit 1
 docker-compose up "$@"
;;
 admin)
 cd ~/projects/admin || exit 1
 python manage.py runserver "$@"
;;
 *)
 echo "Usage: dev {website|api|admin} [args]"
 echo ""
 echo "Examples:"
 echo " dev website"
 echo " dev api -d # Docker detached mode"
 echo " dev admin 0.0.0.0:8000"
 exit 1
;;
esac
```

**Usage**:
```bash
dev website
dev api -d
dev admin 0.0.0.0:8000
```

### ✅ Project-Specific Tasks

```bash
#!/bin/bash
# File: ~/bin/myapp

PROJ_DIR="$HOME/projects/myapp"
cd "$PROJ_DIR" || exit 1

case "$1" in
 dev)
 npm run dev
;;
 build)
 npm run build
;;
 test)
 npm test
;;
 deploy)
 git push origin main
 echo "Deploying..."
;;
 logs)
 tail -f logs/app.log
;;
 db)
 sqlite3 data/app.db
;;
 *)
 echo "Usage: myapp {dev|build|test|deploy|logs|db}"
 exit 1
;;
esac
```

**Usage**:
```bash
myapp dev # Start dev server
myapp test # Run tests
myapp deploy # Deploy to production
myapp logs # Tail logs
```

### ✅ Smart Project Finder

```bash
#!/bin/bash
# File: ~/bin/proj

# Find project directory
find_project {
 local name="$1"
 local search_dirs=(
 "$HOME/projects"
 "$HOME/work"
 "$HOME/src"
 )

 for dir in "${search_dirs[@]}"; do
 if [ -d "$dir/$name" ]; then
 echo "$dir/$name"
 return 0
 fi
 done

 return 1
}

project_name="$1"
shift

project_dir=$(find_project "$project_name")
if [ -z "$project_dir" ]; then
 echo "Project '$project_name' not found"
 exit 1
fi

cd "$project_dir" || exit 1

# If additional arguments, run them as a command
if [ $# -gt 0 ]; then
 "$@"
else
 # Otherwise, open a new shell in the project directory
 exec $SHELL
fi
```

**Usage**:
```bash
proj myapp # Open shell in myapp directory
proj myapp npm run dev # Run command in myapp directory
proj website git status # Run git status in website directory
```

---

## Managing Symlinks to Project Tools

### The Problem

Projects have their own tools in `node_modules/.bin`, `venv/bin`, etc., but you want to use them system-wide.

### ✅ Symlink Project Tools

**Create symlinks in ~/bin**:
```bash
# Link Node project tools
ln -s ~/projects/myapp/node_modules/.bin/eslint ~/bin/eslint-myapp
ln -s ~/projects/myapp/node_modules/.bin/prettier ~/bin/prettier-myapp

# Link Python venv tools
ln -s ~/projects/api/venv/bin/black ~/bin/black-api
ln -s ~/projects/api/venv/bin/pytest ~/bin/pytest-api
```

**Usage**:
```bash
eslint-myapp src/app.js
prettier-myapp --check.
black-api.
pytest-api tests/
```

### ✅ Script to Create Project Symlinks

```bash
#!/bin/bash
# File: ~/bin/link-project-tools

project_name="$1"
project_dir="$HOME/projects/$project_name"

if [ ! -d "$project_dir" ]; then
 echo "Project directory not found: $project_dir"
 exit 1
fi

# Link Node.js tools
if [ -d "$project_dir/node_modules/.bin" ]; then
 echo "Linking Node.js tools..."
 for tool in "$project_dir/node_modules/.bin"/*; do
 tool_name=$(basename "$tool")
 link_name="${tool_name}-${project_name}"
 ln -sf "$tool" "$HOME/bin/$link_name"
 echo " Linked: $link_name"
 done
fi

# Link Python venv tools
if [ -d "$project_dir/venv/bin" ]; then
 echo "Linking Python tools..."
 for tool in "$project_dir/venv/bin"/*; do
 tool_name=$(basename "$tool")
 # Skip python/pip (too generic)
 case "$tool_name" in
 python*|pip*|activate*) continue;;
 esac
 link_name="${tool_name}-${project_name}"
 ln -sf "$tool" "$HOME/bin/$link_name"
 echo " Linked: $link_name"
 done
fi

echo "Done!"
```

**Usage**:
```bash
link-project-tools myapp
# Linking Node.js tools...
# Linked: eslint-myapp
# Linked: prettier-myapp
# Linked: webpack-myapp
# Done!
```

### ✅ Wrapper Instead of Symlink

Sometimes symlinks don't work well (e.g., relative paths). Use wrappers:

```bash
#!/bin/bash
# File: ~/bin/myapp-eslint

cd ~/projects/myapp || exit 1
exec./node_modules/.bin/eslint "$@"
```

**Benefits**:
- Sets correct working directory
- Handles relative paths correctly
- Can add default arguments

### ❌ Symlink Pitfalls

**1. Broken symlinks when project moves**:
```bash
ln -s ~/projects/myapp/venv/bin/black ~/bin/black-myapp
mv ~/projects/myapp ~/projects/myapp-v2
black-myapp # Broken!
```

**Fix**: Use absolute paths with `$HOME`:
```bash
ln -s "$HOME/projects/myapp/venv/bin/black" ~/bin/black-myapp
```

**2. Symlink vs. copy**:
```bash
# ❌ Copy - gets out of date
cp ~/projects/myapp/node_modules/.bin/eslint ~/bin/eslint-myapp

# ✅ Symlink - always current
ln -s ~/projects/myapp/node_modules/.bin/eslint ~/bin/eslint-myapp
```

**3. Name conflicts**:
```bash
# Multiple projects with same tool
ln -s ~/projects/app1/node_modules/.bin/webpack ~/bin/webpack # App 1
ln -s ~/projects/app2/node_modules/.bin/webpack ~/bin/webpack # Overwrites!

# ✅ Use project suffixes
ln -s ~/projects/app1/node_modules/.bin/webpack ~/bin/webpack-app1
ln -s ~/projects/app2/node_modules/.bin/webpack ~/bin/webpack-app2
```

---

## Backup and Version Control

### ✅ Git Repository for ~/bin

**Setup**:
```bash
cd ~/bin
git init
git add.
git commit -m "Initial commit of personal scripts"
git remote add origin git@github.com:yourusername/bin-scripts.git
git push -u origin main
```

**Benefits**:
- Version history
- Backup to GitHub
- Sync across machines
- Collaborate and share

### ✅.gitignore for ~/bin

```bash
# File: ~/bin/.gitignore

# Ignore symlinks to project tools
*-myapp
*-website
*-api

# Ignore machine-specific scripts
*-local

# Ignore backups
*.bak
*.old

# Ignore temporary files
*.tmp
.DS_Store
```

### ✅ README for Your Scripts

```markdown
# My Personal Bin Scripts

Personal command-line tools and utilities.

## Installation

```bash
git clone git@github.com:yourusername/bin-scripts.git ~/bin
chmod +x ~/bin/*
```

Add to ~/.bashrc:
```bash
export PATH="$HOME/bin:$PATH"
```

## Scripts

- `backup` - Backup important directories
- `deploy` - Deploy current project
- `docker-cleanup` - Clean up Docker images/containers
- `git-cleanup` - Clean up merged git branches
- `serve` - Start local web server
- `todo` - Simple TODO list manager

## Usage

See individual script files for usage information.
```

### ✅ Sync Across Machines

**On first machine**:
```bash
cd ~/bin
git push origin main
```

**On second machine**:
```bash
git clone git@github.com:yourusername/bin-scripts.git ~/bin
chmod +x ~/bin/*
```

**Keep in sync**:
```bash
# First machine
cd ~/bin
git add new-script
git commit -m "Add new-script"
git push

# Second machine
cd ~/bin
git pull
chmod +x new-script
```

### ✅ Automated Backup Script

```bash
#!/bin/bash
# File: ~/bin/backup-bin

BACKUP_DIR="$HOME/backups/bin"
DATE=$(date +%Y%m%d_%H%M%S)
ARCHIVE="$BACKUP_DIR/bin_$DATE.tar.gz"

mkdir -p "$BACKUP_DIR"

tar -czf "$ARCHIVE" -C "$HOME" bin/

echo "Backed up ~/bin to $ARCHIVE"

# Keep only last 10 backups
cd "$BACKUP_DIR"
ls -t bin_*.tar.gz | tail -n +11 | xargs rm -f

echo "Cleaned up old backups"
```

**Usage**:
```bash
backup-bin
# Backed up ~/bin to /home/luce/backups/bin/bin_20251109_103045.tar.gz
# Cleaned up old backups
```

### ❌ What NOT to Commit

```bash
# Don't commit:
- API keys or secrets
- Machine-specific paths
- Generated files
- Large binaries
- Symlinks (document them instead)
```

**Use environment variables for secrets**:
```bash
#!/bin/bash
# ✅ Good
API_KEY="${MY_API_KEY:-}"
if [ -z "$API_KEY" ]; then
 echo "Set MY_API_KEY environment variable"
 exit 1
fi

# ❌ Bad
API_KEY="sk-1234567890abcdef" # Hardcoded!
```

---

## Common Patterns

### Pattern 1: Argument Parsing

```bash
#!/bin/bash
# File: ~/bin/example

# Show usage
usage {
 echo "Usage: $0 [-h] [-v] [-f FILE] ARG"
 echo ""
 echo "Options:"
 echo " -h Show this help"
 echo " -v Verbose mode"
 echo " -f FILE Input file"
 exit 1
}

# Parse options
VERBOSE=false
INPUT_FILE=""

while getopts "hvf:" opt; do
 case "$opt" in
 h) usage;;
 v) VERBOSE=true;;
 f) INPUT_FILE="$OPTARG";;
 *) usage;;
 esac
done

shift $((OPTIND-1))

# Remaining argument
ARG="$1"

if [ -z "$ARG" ]; then
 echo "Error: ARG required"
 usage
fi

# Script logic
$VERBOSE && echo "Verbose mode enabled"
$VERBOSE && echo "Input file: $INPUT_FILE"
echo "Processing: $ARG"
```

### Pattern 2: Error Handling

```bash
#!/bin/bash
# File: ~/bin/safe-script

set -euo pipefail # Exit on error, undefined vars, pipe failures

# Cleanup on exit
cleanup {
 echo "Cleaning up..."
 # Remove temporary files, etc.
}
trap cleanup EXIT

# Check dependencies
check_command {
 if ! command -v "$1" &> /dev/null; then
 echo "Error: $1 not found. Please install it."
 exit 1
 fi
}

check_command git
check_command npm

# Script logic
echo "Starting..."
#...
```

### Pattern 3: Configuration File

```bash
#!/bin/bash
# File: ~/bin/configurable-script

CONFIG_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/myscript/config"

# Load configuration if it exists
if [ -f "$CONFIG_FILE" ]; then
 source "$CONFIG_FILE"
else
 # Default configuration
 OUTPUT_DIR="$HOME/output"
 VERBOSE=false
fi

# Script can now use $OUTPUT_DIR, $VERBOSE, etc.
echo "Output directory: $OUTPUT_DIR"
```

**Config file** (~/.config/myscript/config):
```bash
OUTPUT_DIR="$HOME/Documents/output"
VERBOSE=true
```

### Pattern 4: Interactive Prompts

```bash
#!/bin/bash
# File: ~/bin/interactive

# Simple yes/no prompt
confirm {
 read -p "$1 (y/n) " -n 1 -r
 echo
 [[ $REPLY =~ ^[Yy]$ ]]
}

# Ask for confirmation
if confirm "Delete all files?"; then
 echo "Deleting..."
else
 echo "Cancelled"
 exit 0
fi

# Select from options
echo "Select environment:"
select env in "dev" "staging" "prod"; do
 case "$env" in
 dev|staging|prod)
 echo "Selected: $env"
 break
;;
 *)
 echo "Invalid selection"
;;
 esac
done
```

### Pattern 5: Logging

```bash
#!/bin/bash
# File: ~/bin/logged-script

LOG_FILE="$HOME/.logs/myscript.log"
mkdir -p "$(dirname "$LOG_FILE")"

# Logging function
log {
 echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Script started"
log "Processing files..."
log "Script completed"
```

### Pattern 6: Progress Indicator

```bash
#!/bin/bash
# File: ~/bin/progress-script

total=100
for i in $(seq 1 $total); do
 # Simulate work
 sleep 0.1

 # Show progress
 echo -ne "Progress: $i/$total\r"
done
echo -e "\nDone!"
```

### Pattern 7: Temporary Files

```bash
#!/bin/bash
# File: ~/bin/temp-file-script

# Create temp file that's automatically cleaned up
TEMP_FILE=$(mktemp)
trap "rm -f $TEMP_FILE" EXIT

# Use temp file
echo "data" > "$TEMP_FILE"
process "$TEMP_FILE"

# Automatically cleaned up on exit
```

---

## Advanced Tips

### ✅ Create Scripts Faster

**Script template**:
```bash
#!/bin/bash
# File: ~/bin/new

# Quick script creator

name="$1"
if [ -z "$name" ]; then
 echo "Usage: new SCRIPT_NAME"
 exit 1
fi

script="$HOME/bin/$name"

if [ -f "$script" ]; then
 echo "Error: $script already exists"
 exit 1
fi

cat > "$script" << 'EOF'
#!/bin/bash
# Description: TODO

set -euo pipefail

# Your code here
echo "Hello from new script!"
EOF

chmod +x "$script"
echo "Created: $script"

# Open in editor
${EDITOR:-nano} "$script"
```

**Usage**:
```bash
new my-script
# Created: /home/luce/bin/my-script
# (opens in editor)
```

### ✅ List All Your Scripts

```bash
#!/bin/bash
# File: ~/bin/list-scripts

# Show all executable scripts in ~/bin
for script in ~/bin/*; do
 if [ -f "$script" ] && [ -x "$script" ]; then
 name=$(basename "$script")
 desc=$(grep -m 1 "^# Description:" "$script" | sed 's/# Description: //')
 printf "%-20s %s\n" "$name" "$desc"
 fi
done
```

### ✅ Script Documentation

Add help to all scripts:
```bash
#!/bin/bash
# Description: Example script with help

if [ "$1" == "--help" ] || [ "$1" == "-h" ]; then
 cat << EOF
NAME
 example - Example script

SYNOPSIS
 example [OPTIONS] FILE

DESCRIPTION
 This script does something useful with FILE.

OPTIONS
 -h, --help Show this help
 -v, --verbose Verbose output

EXAMPLES
 example input.txt
 example -v input.txt
EOF
 exit 0
fi

# Script logic...
```

---

## Quick Reference

### Setup Commands

```bash
# Create ~/bin
mkdir -p ~/bin

# Add to PATH
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Create first script
cat > ~/bin/hello << 'EOF'
#!/bin/bash
echo "Hello, World!"
EOF
chmod +x ~/bin/hello

# Test
hello
```

### Common Workflows

```bash
# Create new script
nano ~/bin/myscript
chmod +x ~/bin/myscript

# Test script
~/bin/myscript
myscript

# Edit script
nano ~/bin/myscript
$EDITOR ~/bin/myscript

# Remove script
rm ~/bin/myscript

# List scripts
ls -lh ~/bin
```

---

**Next**: [07-PERMISSIONS-SECURITY.md](./07-PERMISSIONS-SECURITY.md) - Understanding permissions and security
