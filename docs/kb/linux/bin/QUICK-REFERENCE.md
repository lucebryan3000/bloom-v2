---
id: linux-quick-reference
topic: linux
file_role: quickref
profile: full
difficulty_level: all-levels
kb_version: 3.1
prerequisites: []
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux, quick-reference, cheat-sheet, syntax]
last_reviewed: 2025-11-13
---

# Linux Bin Directories - Quick Reference Guide

Copy-paste ready commands and snippets for working with Linux bin directories, PATH management, and executable scripts.

---

## 1. Finding Commands

### Check if a command exists

```bash
# Using which (shows first match in PATH)
which python3
```

**What it does**: Shows the full path to the executable that would run
**When to use**: Quick check if command is in PATH

### Find all instances of a command

```bash
# Using type -a
type -a python
```

**What it does**: Lists all locations where command is found (aliases, functions, executables)
**When to use**: Debug conflicts or find all versions

### Get detailed command information

```bash
# Using whereis
whereis python3
```

**What it does**: Shows binary, source, and man page locations
**When to use**: Find related files (docs, sources)

### Check if command is alias, function, or binary

```bash
# Using type without -a
type python3
```

**What it does**: Shows what kind of command it is
**When to use**: Understand command resolution order

### Find commands by pattern

```bash
# Find all python-related commands
compgen -c | grep python
```

**What it does**: Lists all commands matching pattern
**When to use**: Discover available related commands

### Search for executable files

```bash
# Find executable files in current directory
find. -maxdepth 1 -type f -executable
```

**What it does**: Lists executable files
**When to use**: Audit scripts in a directory

### Check command availability without running it

```bash
# Using command -v
command -v docker >/dev/null 2>&1 && echo "Docker installed" || echo "Docker not found"
```

**What it does**: Checks existence, safe for scripts
**When to use**: Dependency checking in scripts

### Find commands in specific directory

```bash
# List all executables in /usr/local/bin
ls -lh /usr/local/bin | grep '^-rwx'
```

**What it does**: Shows executables with permissions
**When to use**: Audit specific bin directory

### Get hash of command location

```bash
# Show hash table entry
hash python3
```

**What it does**: Shows cached command location
**When to use**: Check if shell has cached the command

### Find recently modified commands

```bash
# Find commands modified in last 7 days
find /usr/local/bin -type f -mtime -7 -executable
```

**What it does**: Lists recently changed executables
**When to use**: Track recent installations

### Check command with full path

```bash
# Bypass PATH and use absolute path
/usr/bin/python3 --version
```

**What it does**: Runs specific version directly
**When to use**: Avoid PATH conflicts

### Find broken symlinks in bin directories

```bash
# Find broken symlinks
find /usr/local/bin -type l ! -exec test -e {} \; -print
```

**What it does**: Lists symlinks pointing to non-existent files
**When to use**: Clean up dead links

---

## 2. Checking PATH

### Display current PATH

```bash
# Show PATH on separate lines
echo "$PATH" | tr ':' '\n'
```

**What it does**: Shows each PATH directory on new line
**When to use**: Readable PATH inspection

### Display PATH with line numbers

```bash
# Number each PATH entry
echo "$PATH" | tr ':' '\n' | nl
```

**What it does**: Numbers each directory
**When to use**: Reference specific PATH positions

### Check if directory is in PATH

```bash
# Test for specific directory
echo "$PATH" | grep -q "/usr/local/bin" && echo "In PATH" || echo "Not in PATH"
```

**What it does**: Boolean check for directory
**When to use**: Verify PATH contains directory

### Show PATH directories that exist

```bash
# Only show existing directories
echo "$PATH" | tr ':' '\n' | while read d; do [ -d "$d" ] && echo "$d"; done
```

**What it does**: Filters out non-existent directories
**When to use**: Find invalid PATH entries

### Show PATH directories that don't exist

```bash
# Find missing directories
echo "$PATH" | tr ':' '\n' | while read d; do [ ! -d "$d" ] && echo "$d"; done
```

**What it does**: Shows broken PATH entries
**When to use**: Debug PATH issues

### Count directories in PATH

```bash
# Count PATH entries
echo "$PATH" | tr ':' '\n' | wc -l
```

**What it does**: Returns number of directories
**When to use**: Monitor PATH complexity

### Show duplicate directories in PATH

```bash
# Find duplicates
echo "$PATH" | tr ':' '\n' | sort | uniq -d
```

**What it does**: Lists directories appearing multiple times
**When to use**: Clean up redundant PATH entries

### Show PATH with descriptions

```bash
# Annotate PATH entries
echo "$PATH" | tr ':' '\n' | while read d; do
 echo "$d ($(ls "$d" 2>/dev/null | wc -l) files)"
done
```

**What it does**: Shows directory with file count
**When to use**: Understand PATH composition

### Compare PATH across shells

```bash
# Check PATH in different shell
bash -c 'echo $PATH' > /tmp/bash_path
zsh -c 'echo $PATH' > /tmp/zsh_path
diff /tmp/bash_path /tmp/zsh_path
```

**What it does**: Shows PATH differences between shells
**When to use**: Debug shell-specific issues

### Show PATH inheritance

```bash
# Show original PATH before modifications
env -i bash -c 'echo $PATH'
```

**What it does**: Shows minimal system PATH
**When to use**: See base PATH without user customizations

### Validate PATH security

```bash
# Check for world-writable directories in PATH
echo "$PATH" | tr ':' '\n' | while read d; do
 [ -d "$d" ] && [ -w "$d" ] && ls -ld "$d"
done
```

**What it does**: Finds insecure PATH directories
**When to use**: Security audit

### Search PATH for specific file

```bash
# Find file in PATH directories
IFS=: read -ra DIRS <<< "$PATH"
for dir in "${DIRS[@]}"; do
 [ -f "$dir/mycommand" ] && echo "Found in: $dir"
done
```

**What it does**: Searches all PATH dirs for file
**When to use**: Find command location manually

---

## 3. Modifying PATH

### Add directory to PATH (temporary, session only)

```bash
# Prepend to PATH
export PATH="/opt/myapp/bin:$PATH"
```

**What it does**: Adds directory to front of PATH
**When to use**: Test new binaries without permanent change

### Add directory to end of PATH (temporary)

```bash
# Append to PATH
export PATH="$PATH:/opt/myapp/bin"
```

**What it does**: Adds directory to end of PATH
**When to use**: Lower priority additions

### Add to PATH permanently (bash)

```bash
# Add to ~/.bashrc
echo 'export PATH="/opt/myapp/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**What it does**: Persists PATH change for bash
**When to use**: Permanent bash configuration

### Add to PATH permanently (zsh)

```bash
# Add to ~/.zshrc
echo 'export PATH="/opt/myapp/bin:$PATH"' >> ~/.zshrc
source ~/.zshrc
```

**What it does**: Persists PATH change for zsh
**When to use**: Permanent zsh configuration

### Add to PATH for all users

```bash
# Add to /etc/environment (requires sudo)
sudo bash -c 'echo "PATH=\"/opt/myapp/bin:$PATH\"" >> /etc/environment'
```

**What it does**: System-wide PATH modification
**When to use**: Install for all users

### Remove directory from PATH

```bash
# Remove specific directory
export PATH=$(echo "$PATH" | tr ':' '\n' | grep -v "/opt/myapp/bin" | tr '\n' ':' | sed 's/:$//')
```

**What it does**: Filters out directory from PATH
**When to use**: Remove unwanted PATH entry

### Reset PATH to default

```bash
# Restore system default PATH
export PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
```

**What it does**: Sets minimal system PATH
**When to use**: Fix corrupted PATH

### Add multiple directories to PATH

```bash
# Add several directories at once
export PATH="/opt/app1/bin:/opt/app2/bin:/opt/app3/bin:$PATH"
```

**What it does**: Prepends multiple directories
**When to use**: Bulk PATH updates

### Add directory only if it exists

```bash
# Conditional PATH addition
[ -d "/opt/myapp/bin" ] && export PATH="/opt/myapp/bin:$PATH"
```

**What it does**: Safe PATH modification
**When to use**: Prevent PATH pollution

### Add directory only if not already in PATH

```bash
# Avoid duplicates
if [[ ":$PATH:" != *":/opt/myapp/bin:"* ]]; then
 export PATH="/opt/myapp/bin:$PATH"
fi
```

**What it does**: Prevents duplicate entries
**When to use**: Idempotent PATH updates

### Create PATH setup script

```bash
# Create reusable PATH configuration
cat > ~/setup_path.sh << 'EOF'
#!/bin/bash
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"
EOF
chmod +x ~/setup_path.sh
source ~/setup_path.sh
```

**What it does**: Centralizes PATH configuration
**When to use**: Portable PATH setup

### Set PATH in cron jobs

```bash
# Cron doesn't inherit PATH
# Add to crontab
0 * * * * PATH=/usr/local/bin:/usr/bin:/bin /path/to/script.sh
```

**What it does**: Ensures cron has correct PATH
**When to use**: Fix cron command not found errors

---

## 4. Creating Scripts

### Basic bash script template

```bash
#!/bin/bash
# Script: script_name.sh
# Description: What this script does
# Usage:./script_name.sh [args]

set -euo pipefail # Exit on error, undefined vars, pipe failures

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

# Functions
error {
 echo -e "${RED}Error: $1${NC}" >&2
 exit 1
}

success {
 echo -e "${GREEN}$1${NC}"
}

# Main logic
main {
 echo "Script starting..."
 # Your code here
 success "Script completed successfully"
}

main "$@"
```

**What it does**: Provides robust bash script foundation
**When to use**: Starting any new bash script

### Python script template for ~/bin

```bash
#!/usr/bin/env python3
"""
Script: script_name.py
Description: What this script does
Usage: script_name.py [args]
"""

import sys
import argparse

def main:
 parser = argparse.ArgumentParser(description="Script description")
 parser.add_argument('input', help='Input parameter')
 parser.add_argument('-v', '--verbose', action='store_true', help='Verbose output')

 args = parser.parse_args

 # Your logic here
 print(f"Processing: {args.input}")

 return 0

if __name__ == "__main__":
 sys.exit(main)
```

**What it does**: Standard Python script template
**When to use**: Creating Python command-line tools

### Node.js script template

```bash
#!/usr/bin/env node
/**
 * Script: script_name.js
 * Description: What this script does
 * Usage: script_name.js [args]
 */

const args = process.argv.slice(2);

function main {
 if (args.length === 0) {
 console.error('Usage: script_name.js <argument>');
 process.exit(1);
 }

 console.log('Processing:', args[0]);

 // Your logic here

 process.exit(0);
}

main;
```

**What it does**: Node.js executable script template
**When to use**: Creating Node command-line tools

### Shell script with option parsing

```bash
#!/bin/bash

# Default values
VERBOSE=0
OUTPUT_FILE=""

# Parse options
while getopts "vo:h" opt; do
 case $opt in
 v) VERBOSE=1;;
 o) OUTPUT_FILE="$OPTARG";;
 h) echo "Usage: $0 [-v] [-o output_file] input_file"
 exit 0;;
 \?) echo "Invalid option: -$OPTARG" >&2
 exit 1;;
 esac
done

shift $((OPTIND-1))

# Remaining args
INPUT_FILE="$1"

[ $VERBOSE -eq 1 ] && echo "Verbose mode enabled"
[ -n "$OUTPUT_FILE" ] && echo "Output: $OUTPUT_FILE"
```

**What it does**: Handles command-line options
**When to use**: Scripts needing flags/options

### Script with logging

```bash
#!/bin/bash

LOG_FILE="/tmp/$(basename "$0".sh).log"

log {
 echo "[$(date +'%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "Script started"
# Your code here
log "Script completed"
```

**What it does**: Adds timestamped logging
**When to use**: Production scripts needing audit trail

### Script with dependency checking

```bash
#!/bin/bash

# Check required commands
REQUIRED_CMDS="jq curl wget"

for cmd in $REQUIRED_CMDS; do
 if ! command -v "$cmd" &>/dev/null; then
 echo "Error: Required command '$cmd' not found" >&2
 exit 1
 fi
done

echo "All dependencies satisfied"
```

**What it does**: Validates dependencies before execution
**When to use**: Scripts with external tool dependencies

### Script with configuration file

```bash
#!/bin/bash

CONFIG_FILE="${HOME}/.config/myscript.conf"

# Create default config if missing
if [ ! -f "$CONFIG_FILE" ]; then
 cat > "$CONFIG_FILE" << EOF
API_KEY=your_key_here
API_URL=https://api.example.com
TIMEOUT=30
EOF
fi

# Source config
source "$CONFIG_FILE"

echo "Using API: $API_URL"
```

**What it does**: Loads configuration from file
**When to use**: Scripts needing persistent settings

### Script with dry-run mode

```bash
#!/bin/bash

DRY_RUN=0

# Parse --dry-run flag
for arg in "$@"; do
 [ "$arg" = "--dry-run" ] && DRY_RUN=1
done

run_cmd {
 if [ $DRY_RUN -eq 1 ]; then
 echo "[DRY RUN] Would execute: $*"
 else
 "$@"
 fi
}

run_cmd rm -rf /tmp/data
```

**What it does**: Allows testing without side effects
**When to use**: Destructive operations

### Script with progress indicator

```bash
#!/bin/bash

total=100
for i in $(seq 1 $total); do
 echo -ne "Progress: $i/$total\r"
 sleep 0.1
done
echo -e "\nComplete!"
```

**What it does**: Shows real-time progress
**When to use**: Long-running operations

### Script with trap for cleanup

```bash
#!/bin/bash

TEMP_DIR=$(mktemp -d)

cleanup {
 echo "Cleaning up..."
 rm -rf "$TEMP_DIR"
}

trap cleanup EXIT INT TERM

# Your code here using $TEMP_DIR
```

**What it does**: Ensures cleanup on exit/interrupt
**When to use**: Scripts creating temp files

---

## 5. Making Executable

### Make file executable for owner only

```bash
chmod u+x script.sh
```

**What it does**: Adds execute permission for user
**When to use**: Personal scripts

### Make executable for everyone

```bash
chmod +x script.sh
```

**What it does**: Adds execute for user, group, others
**When to use**: Shared scripts

### Make executable with specific permissions

```bash
chmod 755 script.sh
```

**What it does**: rwxr-xr-x (owner: all, others: read+execute)
**When to use**: Standard script permissions

### Make executable and readable by all

```bash
chmod a+rx script.sh
```

**What it does**: Adds read+execute for all
**When to use**: Public scripts

### Remove execute permission

```bash
chmod -x script.sh
```

**What it does**: Removes execute permission
**When to use**: Prevent accidental execution

### Make all scripts in directory executable

```bash
find. -name "*.sh" -exec chmod +x {} \;
```

**What it does**: Bulk permission update
**When to use**: Initialize script directory

### Make executable only if file has shebang

```bash
# Check for shebang and make executable
if head -n 1 script.sh | grep -q '^#!'; then
 chmod +x script.sh
fi
```

**What it does**: Conditional execution permission
**When to use**: Safe bulk updates

### Set execute permission recursively

```bash
chmod -R +x scripts/
```

**What it does**: Makes all files executable
**When to use**: Script directories (use with caution)

### Copy file and make executable in one command

```bash
install -m 755 script.sh /usr/local/bin/script
```

**What it does**: Copies with permissions set
**When to use**: Install scripts efficiently

### Check if file is executable

```bash
if [ -x script.sh ]; then
 echo "Executable"
else
 echo "Not executable"
fi
```

**What it does**: Tests execute permission
**When to use**: Validation scripts

---

## 6. Installing Scripts

### Install to ~/bin (user-local)

```bash
# Create ~/bin if needed
mkdir -p ~/bin

# Copy script
cp myscript.sh ~/bin/myscript

# Make executable
chmod +x ~/bin/myscript

# Ensure ~/bin is in PATH (add to ~/.bashrc if not)
echo 'export PATH="$HOME/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**What it does**: Installs script for current user
**When to use**: Personal tools

### Install to /usr/local/bin (system-wide)

```bash
sudo cp myscript.sh /usr/local/bin/myscript
sudo chmod 755 /usr/local/bin/myscript
```

**What it does**: Installs for all users
**When to use**: Shared utilities

### Install with install command

```bash
# install command sets permissions and ownership
sudo install -m 755 -o root -g root myscript.sh /usr/local/bin/myscript
```

**What it does**: Professional installation with permissions
**When to use**: Production deployments

### Install script with man page

```bash
# Install script
sudo install -m 755 myscript.sh /usr/local/bin/myscript

# Install man page
sudo install -m 644 myscript.1 /usr/local/share/man/man1/myscript.1
sudo mandb
```

**What it does**: Installs with documentation
**When to use**: Polished tools

### Install Python package as command

```bash
# For Python scripts with setup.py
pip install --user.

# Or using pip directly
pip install --user -e.
```

**What it does**: Installs Python package as command
**When to use**: Python CLI tools

### Install Node.js package globally

```bash
npm install -g.
```

**What it does**: Installs Node package as command
**When to use**: Node.js CLI tools

### Create wrapper script for complex installation

```bash
# install.sh
#!/bin/bash
set -e

INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="myscript"

echo "Installing $SCRIPT_NAME..."

# Copy main script
sudo install -m 755 src/main.sh "$INSTALL_DIR/$SCRIPT_NAME"

# Copy dependencies
sudo mkdir -p /usr/local/lib/$SCRIPT_NAME
sudo cp -r lib/* /usr/local/lib/$SCRIPT_NAME/

# Create config directory
sudo mkdir -p /etc/$SCRIPT_NAME
sudo cp config/default.conf /etc/$SCRIPT_NAME/

echo "Installation complete!"
```

**What it does**: Automated installation with dependencies
**When to use**: Complex multi-file tools

### Uninstall script

```bash
# Uninstall from /usr/local/bin
sudo rm -f /usr/local/bin/myscript

# Remove config
sudo rm -rf /etc/myscript

# Remove libraries
sudo rm -rf /usr/local/lib/myscript
```

**What it does**: Clean removal
**When to use**: Uninstalling tools

### Install to ~/.local/bin (XDG standard)

```bash
mkdir -p ~/.local/bin
install -m 755 myscript.sh ~/.local/bin/myscript

# Ensure in PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

**What it does**: Follows XDG base directory spec
**When to use**: Modern Linux installations

### Verify installation

```bash
# Check if command is found
which myscript

# Check permissions
ls -l $(which myscript)

# Test execution
myscript --version
```

**What it does**: Validates successful installation
**When to use**: After installing scripts

---

## 7. Symlink Management

### Create symlink in ~/bin

```bash
ln -s /opt/myapp/bin/myapp ~/bin/myapp
```

**What it does**: Creates symbolic link
**When to use**: Link to installed programs

### Create symlink with different name

```bash
ln -s /usr/bin/python3.11 ~/bin/python
```

**What it does**: Links with custom name
**When to use**: Version aliasing

### Force create symlink (overwrite existing)

```bash
ln -sf /opt/myapp/bin/myapp ~/bin/myapp
```

**What it does**: Overwrites existing link
**When to use**: Update links

### Check if file is a symlink

```bash
if [ -L ~/bin/myapp ]; then
 echo "Is a symlink"
fi
```

**What it does**: Tests for symlink
**When to use**: Validation scripts

### Show symlink target

```bash
readlink ~/bin/myapp
```

**What it does**: Shows where link points
**When to use**: Debugging links

### Show canonical path of symlink

```bash
readlink -f ~/bin/myapp
```

**What it does**: Resolves full path
**When to use**: Find actual file location

### List all symlinks in directory

```bash
find ~/bin -type l -ls
```

**What it does**: Shows all symbolic links
**When to use**: Audit links

### Find broken symlinks

```bash
find ~/bin -type l ! -exec test -e {} \; -print
```

**What it does**: Lists dead links
**When to use**: Clean up old links

### Remove symlink

```bash
rm ~/bin/myapp
# OR
unlink ~/bin/myapp
```

**What it does**: Deletes symbolic link (not target)
**When to use**: Remove outdated links

### Update symlink to new target

```bash
ln -sf /opt/newapp/bin/app ~/bin/app
```

**What it does**: Points link to new location
**When to use**: Switch versions

### Create relative symlink

```bash
ln -s../share/myapp/script.sh ~/bin/myapp
```

**What it does**: Uses relative path
**When to use**: Portable setups

### Bulk create symlinks

```bash
# Link all executables from directory
for f in /opt/myapp/bin/*; do
 ln -s "$f" ~/bin/$(basename "$f")
done
```

**What it does**: Creates multiple links
**When to use**: Link entire bin directory

---

## 8. Troubleshooting

### Fix "command not found"

```bash
# 1. Check if command exists
which mycommand

# 2. Check PATH
echo "$PATH" | tr ':' '\n'

# 3. Find where command actually is
find /usr -name mycommand 2>/dev/null

# 4. Add directory to PATH or create symlink
export PATH="/path/to/command:$PATH"
# OR
ln -s /path/to/mycommand ~/bin/mycommand
```

**What it does**: Diagnoses and fixes missing commands
**When to use**: Command not found errors

### Fix "permission denied"

```bash
# 1. Check permissions
ls -l script.sh

# 2. Make executable
chmod +x script.sh

# 3. Check if file is on noexec filesystem
mount | grep noexec

# 4. If noexec, copy to different location
cp script.sh ~/bin/script.sh
chmod +x ~/bin/script.sh
```

**What it does**: Fixes permission issues
**When to use**: Cannot execute file errors

### Fix "bad interpreter"

```bash
# 1. Check shebang
head -n 1 script.sh

# 2. Check if interpreter exists
which python3

# 3. Fix shebang to correct path
sed -i '1s|.*|#!/usr/bin/env python3|' script.sh

# 4. Or use env for portability
sed -i '1s|.*|#!/usr/bin/env bash|' script.sh
```

**What it does**: Fixes interpreter issues
**When to use**: Bad interpreter errors

### Clear command hash cache

```bash
# Shell caches command locations
hash -r

# Or for specific command
hash -d mycommand
```

**What it does**: Forces shell to re-find commands
**When to use**: Command updated but shell uses old version

### Fix "text file busy"

```bash
# 1. Check what's using the file
lsof script.sh

# 2. Kill processes using it
fuser -k script.sh

# 3. Or wait for processes to finish
```

**What it does**: Resolves file lock issues
**When to use**: Cannot modify running script

### Debug script execution

```bash
# Run with bash debugging
bash -x script.sh

# Or add to script
set -x # Enable debugging
#... code...
set +x # Disable debugging
```

**What it does**: Shows each command as executed
**When to use**: Script behaving unexpectedly

### Fix line ending issues (Windows to Linux)

```bash
# Remove carriage returns
dos2unix script.sh

# Or with sed
sed -i 's/\r$//' script.sh
```

**What it does**: Converts line endings
**When to use**: Scripts from Windows

### Check script syntax without running

```bash
# For bash scripts
bash -n script.sh

# For Python scripts
python3 -m py_compile script.py
```

**What it does**: Validates syntax
**When to use**: Before deploying scripts

### Fix "no such file or directory" for existing file

```bash
# 1. Check for hidden characters
cat -A script.sh | head -n 1

# 2. Check interpreter exists
head -n 1 script.sh
which <interpreter>

# 3. Fix with correct shebang
sed -i '1s|.*|#!/usr/bin/env bash|' script.sh
```

**What it does**: Fixes invisible character issues
**When to use**: File exists but "not found"

### Diagnose PATH issues

```bash
# Compare different shell PATHs
echo "Current shell: $PATH" > /tmp/path1
bash -l -c 'echo $PATH' > /tmp/path2
diff /tmp/path1 /tmp/path2

# Check PATH order
echo "$PATH" | tr ':' '\n' | nl

# Find duplicate entries
echo "$PATH" | tr ':' '\n' | sort | uniq -d
```

**What it does**: Identifies PATH configuration issues
**When to use**: Command resolution problems

---

## 9. Version Management

### Switch between Python versions

```bash
# Using update-alternatives (Debian/Ubuntu)
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.10 1
sudo update-alternatives --install /usr/bin/python python /usr/bin/python3.11 2
sudo update-alternatives --config python

# Using symlinks
ln -sf /usr/bin/python3.11 ~/bin/python
```

**What it does**: Manages multiple Python versions
**When to use**: Need different Python versions

### Switch between Node versions (with nvm)

```bash
# List installed versions
nvm list

# Install version
nvm install 18

# Use version
nvm use 18

# Set default
nvm alias default 18
```

**What it does**: Manages Node.js versions
**When to use**: Project-specific Node versions

### Create version-specific commands

```bash
# Link specific versions with version suffix
ln -s /usr/bin/python3.10 ~/bin/python3.10
ln -s /usr/bin/python3.11 ~/bin/python3.11

# Default python points to preferred version
ln -s ~/bin/python3.11 ~/bin/python
```

**What it does**: Allows explicit version selection
**When to use**: Multiple versions needed

### Use alternatives system (Debian/Ubuntu)

```bash
# Configure alternatives
sudo update-alternatives --config editor
sudo update-alternatives --config java

# Display current alternative
update-alternatives --display python
```

**What it does**: System-wide version management
**When to use**: System tool versions

### Project-specific version with.envrc (direnv)

```bash
# Install direnv
# Add to ~/.bashrc: eval "$(direnv hook bash)"

# Create.envrc in project
echo 'export PATH=/opt/python3.10/bin:$PATH' >.envrc
direnv allow
```

**What it does**: Auto-switches versions per directory
**When to use**: Per-project environments

### Check all installed versions

```bash
# Find all Python versions
ls -l /usr/bin/python*

# Find all Node versions
ls -ld ~/.nvm/versions/node/*

# Find all Ruby versions
ls -ld ~/.rbenv/versions/*
```

**What it does**: Lists available versions
**When to use**: Audit installed versions

---

## 10. Shell Configuration

### Minimal.bashrc template

```bash
# ~/.bashrc

# If not running interactively, don't do anything
[[ $- != *i* ]] && return

# PATH configuration
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# Aliases
alias ll='ls -lah'
alias grep='grep --color=auto'

# History settings
HISTSIZE=10000
HISTFILESIZE=20000
HISTCONTROL=ignoredups:erasedups

# Prompt
PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ '
```

**What it does**: Basic bash configuration
**When to use**: New user setup

###.bash_profile vs.bashrc

```bash
# ~/.bash_profile (login shells)
if [ -f ~/.bashrc ]; then
 source ~/.bashrc
fi

# User-specific environment
export PATH="$HOME/bin:$PATH"
```

**What it does**: Ensures.bashrc is sourced
**When to use**: Login shell configuration

### Load additional config files

```bash
# ~/.bashrc

# Load custom configs
for file in ~/.config/bash/*.sh; do
 [ -r "$file" ] && source "$file"
done
```

**What it does**: Modular configuration
**When to use**: Organize complex configs

### Zsh configuration template

```bash
# ~/.zshrc

# PATH
export PATH="$HOME/bin:$PATH"
export PATH="$HOME/.local/bin:$PATH"

# History
HISTSIZE=10000
SAVEHIST=10000
HISTFILE=~/.zsh_history
setopt SHARE_HISTORY

# Aliases
alias ll='ls -lah'

# Completion
autoload -Uz compinit
compinit
```

**What it does**: Basic zsh setup
**When to use**: Zsh users

### Conditional PATH additions

```bash
# ~/.bashrc

# Add to PATH only if directory exists and not already in PATH
add_to_path {
 if [ -d "$1" ] && [[ ":$PATH:" != *":$1:"* ]]; then
 export PATH="$1:$PATH"
 fi
}

add_to_path "$HOME/bin"
add_to_path "$HOME/.local/bin"
add_to_path "/usr/local/go/bin"
```

**What it does**: Safe PATH management
**When to use**: Prevent PATH pollution

### Shell-specific configuration

```bash
# Detect shell and configure accordingly
if [ -n "$BASH_VERSION" ]; then
 # Bash-specific config
 shopt -s histappend
elif [ -n "$ZSH_VERSION" ]; then
 # Zsh-specific config
 setopt SHARE_HISTORY
fi
```

**What it does**: Portable shell config
**When to use**: Multi-shell environments

---

## 11. Security Checks

### Audit PATH for security

```bash
#!/bin/bash
# Check for insecure PATH directories

echo "=== PATH Security Audit ==="
echo "$PATH" | tr ':' '\n' | while read dir; do
 if [ ! -d "$dir" ]; then
 echo "[WARN] Missing directory: $dir"
 elif [ -w "$dir" ] && [ "$(stat -c %a "$dir")" -gt 755 ]; then
 echo "[CRIT] World-writable: $dir"
 elif [ "$(stat -c %U "$dir")" != "root" ] && [ "$(stat -c %U "$dir")" != "$USER" ]; then
 echo "[WARN] Owned by other user: $dir ($(stat -c %U "$dir"))"
 else
 echo "[OK] $dir"
 fi
done
```

**What it does**: Identifies security risks in PATH
**When to use**: Security audits

### Check for malicious commands

```bash
# Verify command checksums
sha256sum $(which ssh) > /tmp/ssh.sum
# Compare with known good checksum

# Check for suspicious modifications
find /usr/bin -type f -mtime -7 -ls
```

**What it does**: Detects tampered binaries
**When to use**: Security investigations

### Audit executable permissions

```bash
# Find world-writable executables (bad!)
find /usr/local/bin -type f -perm -002 -ls

# Find executables owned by unexpected users
find /usr/local/bin -type f ! -user root -ls
```

**What it does**: Finds permission issues
**When to use**: Security hardening

### Check script security

```bash
# Ensure script doesn't have SUID/SGID
find ~/bin -type f \( -perm -4000 -o -perm -2000 \) -ls

# Check for scripts with dangerous permissions
find ~/bin -type f -perm -022 -ls
```

**What it does**: Identifies risky permissions
**When to use**: Script security review

---

## 12. One-Liners

### Find largest executables

```bash
find /usr/bin -type f -executable -exec du -h {} + | sort -rh | head -20
```

**What it does**: Lists biggest binaries
**When to use**: Disk space analysis

### Count commands in PATH

```bash
echo "$PATH" | tr ':' '\n' | xargs -I {} find {} -maxdepth 1 -type f -executable 2>/dev/null | wc -l
```

**What it does**: Counts available commands
**When to use**: System inventory

### Find commands installed today

```bash
find /usr/local/bin -type f -executable -mtime 0
```

**What it does**: Lists recent installations
**When to use**: Track new tools

### Find Python scripts without shebang

```bash
find ~/bin -name "*.py" ! -exec head -n 1 {} \; -exec grep -q '^#!' \; -print
```

**What it does**: Finds scripts missing shebang
**When to use**: Script quality check

### Show command origins

```bash
which -a python | while read cmd; do echo "$cmd: $(file $cmd)"; done
```

**What it does**: Shows file type of each command
**When to use**: Understand command types

### Find recently executed commands

```bash
history | tail -50 | awk '{print $2}' | sort | uniq -c | sort -rn
```

**What it does**: Most used recent commands
**When to use**: Identify frequently used tools

### Clean up broken symlinks

```bash
find ~/bin -type l ! -exec test -e {} \; -delete
```

**What it does**: Removes dead links
**When to use**: Housekeeping

### Backup bin directory

```bash
tar czf ~/bin-backup-$(date +%Y%m%d).tar.gz ~/bin
```

**What it does**: Creates timestamped backup
**When to use**: Before major changes

### Find shell scripts by content

```bash
find /usr/local/bin -type f -exec grep -l '^#!/bin/bash' {} \;
```

**What it does**: Lists bash scripts
**When to use**: Script inventory

### Show command execution time

```bash
time mycommand
# Or for more detail
/usr/bin/time -v mycommand
```

**What it does**: Measures execution time
**When to use**: Performance testing

### Find commands with man pages

```bash
for cmd in /usr/bin/*; do
 man -w $(basename $cmd) &>/dev/null && echo $(basename $cmd)
done
```

**What it does**: Lists documented commands
**When to use**: Find documented tools

### Create command inventory

```bash
{
 echo "Command,Path,Size,Modified"
 find /usr/local/bin -type f -executable -printf '%f,%p,%s,%TY-%Tm-%Td\n'
} > command-inventory.csv
```

**What it does**: CSV inventory of commands
**When to use**: Documentation

### Find duplicate command names in PATH

```bash
echo "$PATH" | tr ':' '\n' | while read dir; do
 find "$dir" -maxdepth 1 -type f -executable 2>/dev/null
done | xargs -n1 basename | sort | uniq -d
```

**What it does**: Finds name conflicts
**When to use**: Resolve PATH conflicts

### Show commands by language

```bash
# Count by interpreter
find /usr/local/bin -type f -exec head -n 1 {} \; | grep '^#!' | sort | uniq -c
```

**What it does**: Statistics by script type
**When to use**: Codebase analysis

### Quick command wrapper

```bash
# Create wrapper that logs all executions
echo '#!/bin/bash
echo "$(date): $0 $@" >> ~/command.log
exec /usr/bin/original_command "$@"
' > ~/bin/wrapped_command && chmod +x ~/bin/wrapped_command
```

**What it does**: Wraps command with logging
**When to use**: Audit command usage

---

## Additional Quick Tips

### Make script reload-friendly

```bash
# In your script, use this pattern to allow re-sourcing
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
 # Script is being executed
 main "$@"
else
 # Script is being sourced
 echo "Script sourced, functions available"
fi
```

### Create command with here-document

```bash
cat > ~/bin/mycommand << 'EOF'
#!/bin/bash
echo "Hello from mycommand"
EOF
chmod +x ~/bin/mycommand
```

**What it does**: Inline script creation
**When to use**: Quick command creation

### Test script in isolated PATH

```bash
env -i PATH=/usr/bin:/bin bash script.sh
```

**What it does**: Runs with minimal PATH
**When to use**: Test script portability

### Create self-updating script

```bash
#!/bin/bash
SCRIPT_URL="https://example.com/script.sh"
SCRIPT_PATH="$(readlink -f "$0")"

update {
 curl -fsSL "$SCRIPT_URL" -o "$SCRIPT_PATH.new"
 chmod +x "$SCRIPT_PATH.new"
 mv "$SCRIPT_PATH.new" "$SCRIPT_PATH"
 echo "Updated successfully"
}

[ "$1" = "--update" ] && update && exit 0
```

**What it does**: Script can update itself
**When to use**: Distributed scripts

### Find commands using specific libraries

```bash
for cmd in /usr/bin/*; do
 ldd "$cmd" 2>/dev/null | grep -q "libssl" && echo "$cmd"
done
```

**What it does**: Finds commands with dependency
**When to use**: Security audits (e.g., OpenSSL)

---

**Total Lines: 900+** - This reference provides comprehensive, copy-paste ready examples for all common bin directory operations, PATH management, and script development tasks.