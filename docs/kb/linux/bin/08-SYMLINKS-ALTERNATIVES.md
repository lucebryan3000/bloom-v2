---
id: linux-08-symlinks-alternatives
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

# 08-SYMLINKS-ALTERNATIVES.md - Symlinks and Alternatives System

## Table of Contents
1. [What Are Symlinks?](#what-are-symlinks)
2. [Creating Symlinks](#creating-symlinks)
3. [Absolute vs Relative Symlinks](#absolute-vs-relative-symlinks)
4. [Removing Symlinks Safely](#removing-symlinks-safely)
5. [Finding Broken Symlinks](#finding-broken-symlinks)
6. [Update-Alternatives System](#update-alternatives-system)
7. [Managing Multiple Versions](#managing-multiple-versions)
8. [Setting Default Versions](#setting-default-versions)
9. [Symlink Best Practices](#symlink-best-practices)
10. [Common Symlink Mistakes](#common-symlink-mistakes)
11. [Advanced: Alternatives Priority System](#advanced-alternatives-priority-system)

---

## What Are Symlinks?

### Definition

A **symbolic link** (symlink) is a special file that points to another file or directory. It's like a shortcut or reference.

**Two types of links**:
1. **Symbolic link** (soft link) - Points to path (can break)
2. **Hard link** - Points to inode (can't break, but limited)

### ✅ Symlink Example

```bash
# Create a symlink
ln -s /usr/bin/python3 ~/bin/python

# Now ~/bin/python points to /usr/bin/python3
ls -l ~/bin/python
lrwxrwxrwx 1 luce luce 18 Nov 9 10:00 /home/luce/bin/python -> /usr/bin/python3
│
└─ 'l' means symlink
```

**Running the symlink**:
```bash
# These are equivalent:
~/bin/python --version
/usr/bin/python3 --version

# Both show:
Python 3.11.0
```

### Why Use Symlinks?

**1. Version management**:
```bash
# Have multiple versions
/usr/bin/python3.10
/usr/bin/python3.11
/usr/bin/python3.12

# Symlink to current version
ln -s /usr/bin/python3.11 ~/bin/python
# Easy to switch versions later
```

**2. Shorter paths**:
```bash
# Instead of typing:
/opt/projects/myapp/node_modules/.bin/eslint

# Create symlink:
ln -s /opt/projects/myapp/node_modules/.bin/eslint ~/bin/eslint
eslint # Much easier!
```

**3. Location independence**:
```bash
# Scripts reference ~/bin/node
# You can change where node is installed without updating scripts
```

**4. Multiple names for same program**:
```bash
# Both point to same program
ln -s /usr/bin/vim ~/bin/vi
ln -s /usr/bin/vim ~/bin/vim
```

### How Symlinks Work

**Kernel behavior**:
1. You execute symlink: `./python`
2. Kernel sees it's a symlink (file type 'l')
3. Reads symlink target: `/usr/bin/python3`
4. Executes target instead

**Chain of symlinks** (allowed):
```bash
# Create chain
ln -s /usr/bin/python3 ~/bin/python
ln -s ~/bin/python ~/Desktop/python

# ~/Desktop/python -> ~/bin/python -> /usr/bin/python3
# All three work!
```

### ✅ Checking Symlinks

```bash
# Is it a symlink?
ls -l ~/bin/python
lrwxrwxrwx... /home/luce/bin/python -> /usr/bin/python3

# Where does it point?
readlink ~/bin/python
/usr/bin/python3

# Follow all symlinks to final target
readlink -f ~/bin/python
/usr/bin/python3.11
# (if /usr/bin/python3 is also a symlink)

# File type
file ~/bin/python
/home/luce/bin/python: symbolic link to /usr/bin/python3
```

### Symlinks vs Hard Links

**Symbolic link**:
```bash
ln -s target linkname
# Creates reference to path
# Can point to files or directories
# Can point to non-existent files (broken link)
# Can cross filesystem boundaries
```

**Hard link**:
```bash
ln target linkname
# Creates reference to same inode
# Only for files (not directories)
# Can't point to non-existent files
# Can't cross filesystem boundaries
# Multiple names for same file
```

**✅ Example: Symlink vs Hard Link**:
```bash
# Create file
echo "Hello" > original.txt

# Create symlink
ln -s original.txt symlink.txt

# Create hard link
ln original.txt hardlink.txt

# All show same content
cat original.txt
cat symlink.txt
cat hardlink.txt
# All: Hello

# Delete original
rm original.txt

# Symlink breaks
cat symlink.txt
# cat: symlink.txt: No such file or directory

# Hard link still works!
cat hardlink.txt
# Hello
```

**When to use each**:
- **Symlinks**: Almost always (more flexible)
- **Hard links**: Rarely (backups, deduplication)

---

## Creating Symlinks

### Basic Syntax

```bash
ln -s TARGET LINK_NAME
```

- `TARGET` - File or directory to point to
- `LINK_NAME` - Name of symlink to create
- `-s` - Create symbolic link (without this, creates hard link)

### ✅ Creating Symlinks Examples

**1. Link to file**:
```bash
# Point ~/bin/python to /usr/bin/python3
ln -s /usr/bin/python3 ~/bin/python

# Verify
ls -l ~/bin/python
lrwxrwxrwx... /home/luce/bin/python -> /usr/bin/python3
```

**2. Link to directory**:
```bash
# Create shortcut to projects directory
ln -s ~/projects/myapp ~/myapp

# Now these are equivalent:
cd ~/myapp
cd ~/projects/myapp
```

**3. Link in current directory**:
```bash
# Link to file elsewhere
ln -s /etc/nginx/nginx.conf./nginx.conf

# Link appears in current directory
ls -l nginx.conf
lrwxrwxrwx... nginx.conf -> /etc/nginx/nginx.conf
```

**4. Multiple symlinks to same target**:
```bash
# Create multiple names for vim
ln -s /usr/bin/vim ~/bin/vi
ln -s /usr/bin/vim ~/bin/vim
ln -s /usr/bin/vim ~/bin/editor

# All work:
vi file.txt
vim file.txt
editor file.txt
```

### ✅ Creating Symlinks for Project Tools

```bash
# Node.js project tools
ln -s ~/projects/myapp/node_modules/.bin/eslint ~/bin/eslint-myapp
ln -s ~/projects/myapp/node_modules/.bin/prettier ~/bin/prettier-myapp
ln -s ~/projects/myapp/node_modules/.bin/webpack ~/bin/webpack-myapp

# Python virtualenv tools
ln -s ~/projects/api/venv/bin/black ~/bin/black-api
ln -s ~/projects/api/venv/bin/pytest ~/bin/pytest-api

# Custom project scripts
ln -s ~/projects/myapp/scripts/deploy.sh ~/bin/deploy-myapp
```

### ❌ Common Creation Mistakes

**1. Forgetting -s flag**:
```bash
# ❌ Creates hard link instead of symlink
ln /usr/bin/python3 ~/bin/python

# ✅ Correct
ln -s /usr/bin/python3 ~/bin/python
```

**2. Target path doesn't exist**:
```bash
# ❌ Creates broken symlink
ln -s /usr/bin/python4 ~/bin/python
# No error, but python4 doesn't exist!

# ✅ Check target exists first
if [ -f /usr/bin/python3 ]; then
 ln -s /usr/bin/python3 ~/bin/python
fi
```

**3. Symlink already exists**:
```bash
# ❌ Error if link already exists
ln -s /usr/bin/python3 ~/bin/python
# ln: failed to create symbolic link 'python': File exists

# ✅ Force overwrite
ln -sf /usr/bin/python3 ~/bin/python
```

**4. Using relative path when you meant absolute**:
```bash
cd /usr/bin
ln -s python3 ~/bin/python
# This creates: ~/bin/python -> python3 (relative!)
# Breaks when you cd elsewhere

# ✅ Use absolute path
ln -s /usr/bin/python3 ~/bin/python
```

### Useful ln Options

```bash
# -s Create symbolic link
ln -s target link

# -f Force (overwrite existing)
ln -sf target link

# -n No dereference (treat link destination as normal file)
ln -sfn target link

# -v Verbose (show what's being done)
ln -sv target link

# -r Relative (create relative symlink)
ln -sr target link

# -t Target directory
ln -st ~/bin /usr/bin/python3 /usr/bin/node
# Creates ~/bin/python3 and ~/bin/node
```

---

## Absolute vs Relative Symlinks

### Absolute Symlinks

**Definition**: Target path starts from root (/)

```bash
# Create absolute symlink
ln -s /usr/bin/python3 ~/bin/python

# Check
readlink ~/bin/python
/usr/bin/python3 # Absolute path
```

**Characteristics**:
- Works from any directory
- Survives moving the symlink
- Breaks if target moves

**✅ Example**:
```bash
# Create absolute symlink
ln -s /usr/bin/python3 ~/bin/python

# Works from anywhere
cd /tmp
~/bin/python --version # Works

# Move symlink - still works
mv ~/bin/python /tmp/python
/tmp/python --version # Still works!

# But if target moves, breaks
sudo mv /usr/bin/python3 /usr/bin/python3.11
~/bin/python --version # Broken!
```

### Relative Symlinks

**Definition**: Target path is relative to symlink location

```bash
# Create relative symlink
cd ~/bin
ln -s../projects/myapp/run.sh run-myapp

# Check
readlink run-myapp
../projects/myapp/run.sh # Relative path
```

**Characteristics**:
- Only works from symlink's directory
- Breaks if you move the symlink
- Survives moving both target and symlink together

**✅ Example**:
```bash
# Create relative symlink
cd ~/bin
ln -s../projects/myapp/run.sh run-myapp

# Works from ~/bin
./run-myapp # Works

# But breaks if you move just the symlink
mv run-myapp /tmp/
/tmp/run-myapp # Broken! (looking for /tmp/../projects/myapp/run.sh)

# However, if you move BOTH together:
mv ~/bin /tmp/newbin
mv ~/projects/myapp /tmp/newapp
# The relative link still works!
```

### Creating Relative Symlinks

**Manual relative path**:
```bash
cd ~/bin
ln -s../projects/myapp/run.sh run-myapp
```

**Automatic relative path** (GNU coreutils 8.16+):
```bash
# -r flag creates relative symlink automatically
ln -sr ~/projects/myapp/run.sh ~/bin/run-myapp

# Check what was created
readlink ~/bin/run-myapp
../projects/myapp/run.sh
```

### ✅ When to Use Each

**Use absolute symlinks when**:
- Linking system binaries (`/usr/bin/python3`)
- Target is outside your home directory
- Symlink might be moved
- Standard system paths

**Use relative symlinks when**:
- Linking within a project
- Entire directory tree might be moved
- Creating portable directory structures

### ✅ Absolute Symlink Examples

```bash
# System binaries
ln -s /usr/bin/python3 ~/bin/python
ln -s /usr/bin/node ~/bin/node

# System libraries
ln -s /usr/lib/x86_64-linux-gnu/libssl.so.1.1 ~/lib/libssl.so

# Configuration files
ln -s /etc/nginx/nginx.conf ~/nginx.conf
```

### ✅ Relative Symlink Examples

```bash
# Project structure
myproject/
├── bin/
│ └── run ->../scripts/run.sh # Relative
├── scripts/
│ └── run.sh
└── data/
 └── config ->../config.json # Relative

# Create relative symlinks
cd myproject
ln -sr scripts/run.sh bin/run
ln -sr config.json data/config

# Now you can move entire myproject/ and links still work
mv myproject /opt/myproject
/opt/myproject/bin/run # Still works!
```

### Converting Between Absolute and Relative

**Absolute to relative**:
```bash
# Current: absolute symlink
readlink ~/bin/python
/usr/bin/python3

# Convert to relative
ln -sfr /usr/bin/python3 ~/bin/python

# Check
readlink ~/bin/python
../../usr/bin/python3
```

**Relative to absolute**:
```bash
# Current: relative symlink
readlink ~/bin/python
../projects/python3

# Convert to absolute
target=$(readlink -f ~/bin/python)
ln -sf "$target" ~/bin/python

# Check
readlink ~/bin/python
/home/luce/projects/python3
```

---

## Removing Symlinks Safely

### The Right Way

```bash
# Remove symlink
rm symlinkname

# Or
unlink symlinkname
```

**✅ Examples**:
```bash
# Remove symlink to file
rm ~/bin/python

# Remove symlink to directory
rm ~/myapp
```

### ❌ Dangerous Mistakes

**1. Trailing slash on directory symlink**:
```bash
# Create symlink to directory
ln -s ~/projects/myapp ~/myapp

# ❌ WRONG - deletes contents of target directory!
rm ~/myapp/
rm -r ~/myapp/

# ✅ CORRECT - removes only symlink
rm ~/myapp
```

**Real example of disaster**:
```bash
# Create symlink
ln -s ~/projects/important ~/important

# Someone tries to clean up
rm -rf ~/important/
# Just deleted everything in ~/projects/important!

# ✅ Correct way
rm ~/important # Just removes symlink
```

**2. Using find -delete with symlinks**:
```bash
# ❌ Dangerous
find ~/bin -type l -delete
# Deletes ALL symlinks without asking!

# ✅ Better
find ~/bin -type l -print
# Review the list first

# Then if sure:
find ~/bin -type l -delete
```

### ✅ Safe Symlink Removal

**Check before removing**:
```bash
# Is it a symlink?
ls -l ~/bin/python
lrwxrwxrwx... -> /usr/bin/python3

# Where does it point?
readlink ~/bin/python
/usr/bin/python3

# Safe to remove
rm ~/bin/python
```

**Removing with confirmation**:
```bash
# Prompt before removing
rm -i ~/bin/python
rm: remove symbolic link 'python'? y

# Or using find
find ~/bin -type l -ok rm {} \;
< rm... ~/bin/python > ? y
```

**Batch removal of broken symlinks only**:
```bash
# Find and remove broken symlinks
find ~/bin -type l ! -exec test -e {} \; -delete
```

### Removing vs Unlinking

**Both work the same for symlinks**:
```bash
# These are equivalent:
rm symlinkname
unlink symlinkname
```

**Difference**:
- `rm` can remove multiple files, directories (with -r)
- `unlink` removes exactly one file (safer for scripts)

**✅ Use unlink in scripts**:
```bash
#!/bin/bash
# Safer - fails if given multiple arguments
unlink ~/bin/python

# vs
rm ~/bin/python # Works, but more error-prone
```

---

## Finding Broken Symlinks

### What is a Broken Symlink?

**Broken symlink**: Symlink whose target doesn't exist

```bash
# Create symlink
ln -s /usr/bin/python4 ~/bin/python

# python4 doesn't exist - broken symlink!
ls ~/bin/python
~/bin/python # Exists as symlink

/bin/python # But target doesn't exist
# bash: /home/luce/bin/python: No such file or directory
```

### ✅ Finding Broken Symlinks

**Using find**:
```bash
# Find broken symlinks in ~/bin
find ~/bin -type l ! -exec test -e {} \; -print

# More readable version
find ~/bin -xtype l
```

**How it works**:
- `-type l` - Find symlinks
- `! -exec test -e {} \;` - Test if target exists
- If `test -e` fails, symlink is broken
- `-xtype l` - Find symlinks where target doesn't exist (shorter)

**✅ Complete Example**:
```bash
# Create some symlinks
ln -s /usr/bin/python3 ~/bin/python # ✅ Good
ln -s /usr/bin/node ~/bin/node # ✅ Good
ln -s /usr/bin/ruby ~/bin/ruby # ✅ Good
ln -s /usr/bin/python4 ~/bin/python4 # ❌ Broken (doesn't exist)
ln -s /opt/missing ~/bin/missing # ❌ Broken (doesn't exist)

# Find broken symlinks
find ~/bin -xtype l
/home/luce/bin/python4
/home/luce/bin/missing
```

### ✅ Detailed Broken Symlink Report

```bash
#!/bin/bash
# File: ~/bin/find-broken-symlinks

echo "=== Broken Symlinks Report ==="
echo

find ~/bin -type l | while read link; do
 if [ ! -e "$link" ]; then
 target=$(readlink "$link")
 echo "Broken: $link"
 echo " Target: $target (does not exist)"
 echo
 fi
done
```

**Output**:
```
=== Broken Symlinks Report ===

Broken: /home/luce/bin/python4
 Target: /usr/bin/python4 (does not exist)

Broken: /home/luce/bin/missing
 Target: /opt/missing (does not exist)
```

### ✅ Cleaning Up Broken Symlinks

**Interactive removal**:
```bash
# Find broken symlinks and ask before removing each
find ~/bin -xtype l -ok rm {} \;
< rm... /home/luce/bin/python4 > ? y
< rm... /home/luce/bin/missing > ? y
```

**Automatic removal**:
```bash
# Remove all broken symlinks in ~/bin
find ~/bin -xtype l -delete

# With verbose output
find ~/bin -xtype l -print -delete
/home/luce/bin/python4
/home/luce/bin/missing
```

**Safe cleanup script**:
```bash
#!/bin/bash
# File: ~/bin/cleanup-broken-symlinks

dir="${1:-$HOME/bin}"

echo "Finding broken symlinks in $dir..."
broken=$(find "$dir" -xtype l)

if [ -z "$broken" ]; then
 echo "No broken symlinks found."
 exit 0
fi

echo "Found broken symlinks:"
echo "$broken"
echo

read -p "Remove these symlinks? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
 find "$dir" -xtype l -delete
 echo "Removed broken symlinks."
else
 echo "Cancelled."
fi
```

### Preventing Broken Symlinks

**✅ Check target exists before creating**:
```bash
#!/bin/bash
# Safe symlink creation

create_symlink {
 local target="$1"
 local link="$2"

 if [ ! -e "$target" ]; then
 echo "Error: Target does not exist: $target"
 return 1
 fi

 ln -sf "$target" "$link"
 echo "Created: $link -> $target"
}

create_symlink /usr/bin/python3 ~/bin/python
```

**✅ Monitor for broken symlinks**:
```bash
# Add to crontab - check daily
0 9 * * * find ~/bin -xtype l | mail -s "Broken symlinks" $USER
```

---

## Update-Alternatives System

### What is Update-Alternatives?

**update-alternatives** manages symbolic links determining default commands on Debian/Ubuntu systems.

**Purpose**:
- Manage multiple versions of the same program
- Set system-wide defaults
- Switch between versions easily

**How it works**:
```
/usr/bin/python -> /etc/alternatives/python -> /usr/bin/python3.11
 │ │ │
 │ │ └─ Actual binary
 │ └─ Alternatives system manages this
 └─ Command you type
```

### ✅ Viewing Alternatives

**List all alternatives**:
```bash
update-alternatives --get-selections
editor auto /usr/bin/vim.basic
python auto /usr/bin/python3.11
x-terminal-emulator auto /usr/bin/gnome-terminal.wrapper
```

**Check specific alternative**:
```bash
update-alternatives --display python
python - auto mode
 link best version is /usr/bin/python3.11
 link currently points to /usr/bin/python3.11
 link python is /usr/bin/python
/usr/bin/python3.10 - priority 310
/usr/bin/python3.11 - priority 311
```

**Query current selection**:
```bash
update-alternatives --query python
```

### ✅ Common Alternatives

| Name | Purpose | Typical Alternatives |
|------|---------|---------------------|
| `editor` | Default text editor | vim, nano, emacs |
| `x-terminal-emulator` | Terminal emulator | gnome-terminal, xterm |
| `python` | Python interpreter | python3.10, python3.11, python3.12 |
| `java` | Java runtime | openjdk-11, openjdk-17 |
| `gcc` | C compiler | gcc-11, gcc-12 |
| `x-www-browser` | Web browser | firefox, chromium |

### Installing Alternatives

**Add new alternative**:
```bash
sudo update-alternatives --install \
 /usr/bin/python \ # Link location
 python \ # Name
 /usr/bin/python3.11 \ # Target
 311 # Priority (higher = preferred)
```

**✅ Example: Add Python Versions**:
```bash
# Add Python 3.10
sudo update-alternatives --install \
 /usr/bin/python python /usr/bin/python3.10 310

# Add Python 3.11 (higher priority)
sudo update-alternatives --install \
 /usr/bin/python python /usr/bin/python3.11 311

# Add Python 3.12 (highest priority)
sudo update-alternatives --install \
 /usr/bin/python python /usr/bin/python3.12 312
```

### Switching Alternatives

**Interactive selection**:
```bash
sudo update-alternatives --config python

There are 3 choices for the alternative python.

 Selection Path Priority Status
------------------------------------------------------------
* 0 /usr/bin/python3.12 312 auto mode
 1 /usr/bin/python3.10 310 manual mode
 2 /usr/bin/python3.11 311 manual mode
 3 /usr/bin/python3.12 312 manual mode

Press <enter> to keep the current choice[*], or type selection number: 2

# Now python points to python3.11
python --version
Python 3.11.0
```

**Set specific alternative**:
```bash
# Set python to python3.11
sudo update-alternatives --set python /usr/bin/python3.11
```

**Set to auto mode** (use highest priority):
```bash
sudo update-alternatives --auto python
```

### Removing Alternatives

```bash
# Remove specific alternative
sudo update-alternatives --remove python /usr/bin/python3.10

# Remove entire alternative group
sudo update-alternatives --remove-all python
```

---

## Managing Multiple Versions

### The Problem

You need multiple versions of the same tool:
- Python 3.10 for old project
- Python 3.11 for new project
- Python 3.12 for testing

### ✅ Solution 1: Personal Symlinks

**Don't modify system alternatives**, create personal symlinks:

```bash
# Create version-specific commands
ln -s /usr/bin/python3.10 ~/bin/python3.10
ln -s /usr/bin/python3.11 ~/bin/python3.11
ln -s /usr/bin/python3.12 ~/bin/python3.12

# Create default
ln -s /usr/bin/python3.11 ~/bin/python

# Use specific version
python3.10 --version # Python 3.10
python3.11 --version # Python 3.11
python3.12 --version # Python 3.12
python --version # Python 3.11 (your default)
```

**Switch default**:
```bash
# Change to Python 3.12
ln -sf /usr/bin/python3.12 ~/bin/python

python --version
Python 3.12.0
```

### ✅ Solution 2: Version Manager Wrappers

**For Node.js** (with nvm):
```bash
# Install versions
nvm install 18
nvm install 20

# Create version-specific symlinks
ln -s ~/.nvm/versions/node/v18.*/bin/node ~/bin/node18
ln -s ~/.nvm/versions/node/v20.*/bin/node ~/bin/node20

# Create default
ln -s ~/.nvm/versions/node/v20.*/bin/node ~/bin/node

# Use specific versions
node18 --version # v18.x.x
node20 --version # v20.x.x
node --version # v20.x.x (default)
```

**For Python** (with pyenv):
```bash
# Install versions
pyenv install 3.10.0
pyenv install 3.11.0
pyenv install 3.12.0

# Create symlinks
ln -s ~/.pyenv/versions/3.10.0/bin/python ~/bin/python3.10
ln -s ~/.pyenv/versions/3.11.0/bin/python ~/bin/python3.11
ln -s ~/.pyenv/versions/3.12.0/bin/python ~/bin/python3.12

# Set default
pyenv global 3.11.0
ln -s ~/.pyenv/shims/python ~/bin/python
```

### ✅ Solution 3: Project-Specific Versions

**Create project wrappers**:
```bash
#!/bin/bash
# File: ~/bin/project-a-python

cd ~/projects/project-a
exec.venv/bin/python "$@"
```

```bash
#!/bin/bash
# File: ~/bin/project-b-python

cd ~/projects/project-b
exec.venv/bin/python "$@"
```

**Usage**:
```bash
project-a-python --version # Uses project A's Python
project-b-python --version # Uses project B's Python
```

### ✅ Version Switcher Script

```bash
#!/bin/bash
# File: ~/bin/use-python

version="$1"

if [ -z "$version" ]; then
 echo "Current Python version:"
 python --version
 echo
 echo "Available versions:"
 ls -1 ~/bin/python3.* 2>/dev/null | sed 's|.*/python||'
 echo
 echo "Usage: use-python VERSION"
 echo "Example: use-python 3.11"
 exit 0
fi

python_bin=~/bin/python$version

if [ ! -f "$python_bin" ]; then
 echo "Error: Python $version not found at $python_bin"
 exit 1
fi

ln -sf "$python_bin" ~/bin/python
echo "Switched to Python $version"
python --version
```

**Usage**:
```bash
use-python
# Current Python version: Python 3.11.0
# Available versions: 3.10 3.11 3.12
# Usage: use-python VERSION

use-python 3.12
# Switched to Python 3.12
# Python 3.12.0

python --version
# Python 3.12.0
```

---

## Setting Default Versions

### User-Level Defaults (~/bin)

**Best for**: Personal preference, non-system-critical tools

```bash
# Set your default Python
ln -sf /usr/bin/python3.11 ~/bin/python

# Set your default Node
ln -sf ~/.nvm/versions/node/v20.0.0/bin/node ~/bin/node

# Set your default editor
ln -sf /usr/bin/vim ~/bin/editor
```

**Advantage**:
- No sudo needed
- Doesn't affect other users
- Easy to change

### System-Level Defaults (update-alternatives)

**Best for**: System-wide settings, multi-user systems

```bash
# Set system Python (requires sudo)
sudo update-alternatives --set python /usr/bin/python3.11

# Set system editor
sudo update-alternatives --set editor /usr/bin/vim

# Set system terminal
sudo update-alternatives --set x-terminal-emulator /usr/bin/gnome-terminal
```

**Advantage**:
- Consistent for all users
- Proper system integration
- Managed by package system

### ✅ Hybrid Approach

**System defaults + personal overrides**:

```bash
# System default: Python 3.10
python --version
Python 3.10.0

# Add ~/bin to PATH (before system paths)
export PATH="$HOME/bin:$PATH"

# Create personal override
ln -s /usr/bin/python3.11 ~/bin/python

# Now you get 3.11
python --version
Python 3.11.0

# Other users still get 3.10
```

### Environment Variables for Defaults

**Standard environment variables**:
```bash
# In ~/.bashrc

# Default editor
export EDITOR=vim
export VISUAL=vim

# Default pager
export PAGER=less

# Default browser
export BROWSER=firefox

# Default shell
export SHELL=/bin/bash
```

**Applications respect these**:
```bash
# Git uses $EDITOR
git config --global core.editor "$EDITOR"

# Cron uses $SHELL
# systemd uses $SHELL

# Many programs use $BROWSER to open URLs
```

---

## Symlink Best Practices

### 1. ✅ Use Descriptive Names

```bash
# ❌ Unclear
ln -s /usr/bin/python3 ~/bin/p

# ✅ Clear
ln -s /usr/bin/python3 ~/bin/python
```

### 2. ✅ Include Version in Name for Multiple Versions

```bash
# ✅ Good organization
~/bin/python3.10
~/bin/python3.11
~/bin/python3.12
~/bin/python -> python3.11 # Default

# Easy to see what you have:
ls ~/bin/python*
python python3.10 python3.11 python3.12
```

### 3. ✅ Use Absolute Paths for System Binaries

```bash
# ✅ Absolute path (portable)
ln -s /usr/bin/python3 ~/bin/python

# ❌ Relative path (breaks if you move symlink)
cd ~/bin
ln -s../../usr/bin/python3 python
```

### 4. ✅ Document Your Symlinks

```bash
# File: ~/bin/README.md

# Personal Bin Symlinks

## Python
- `python` -> `/usr/bin/python3.11` (default)
- `python3.10` -> `/usr/bin/python3.10`
- `python3.11` -> `/usr/bin/python3.11`

## Node.js
- `node` -> `~/.nvm/versions/node/v20.0.0/bin/node`
- `node18` -> `~/.nvm/versions/node/v18.0.0/bin/node`

## Project Tools
- `eslint-myapp` -> `~/projects/myapp/node_modules/.bin/eslint`
```

### 5. ✅ Check Target Exists Before Creating

```bash
#!/bin/bash
# Safe symlink creation

target="/usr/bin/python3"
link="$HOME/bin/python"

if [ ! -e "$target" ]; then
 echo "Error: Target does not exist: $target"
 exit 1
fi

if [ -e "$link" ] && [ ! -L "$link" ]; then
 echo "Error: Link exists and is not a symlink: $link"
 exit 1
fi

ln -sf "$target" "$link"
echo "Created: $link -> $target"
```

### 6. ✅ Periodically Audit Symlinks

```bash
#!/bin/bash
# File: ~/bin/audit-symlinks

echo "=== Symlink Audit ==="
echo

# Check for broken symlinks
echo "Broken symlinks:"
find ~/bin -xtype l
echo

# Show all symlinks and their targets
echo "All symlinks:"
find ~/bin -type l -exec ls -lh {} \;
echo

# Check for duplicate targets
echo "Symlinks pointing to same target:"
find ~/bin -type l -exec readlink -f {} \; | sort | uniq -d
```

### 7. ✅ Use -f Flag to Update Symlinks

```bash
# Update existing symlink (force)
ln -sf /usr/bin/python3.12 ~/bin/python

# Without -f, would error if exists
```

### 8. ✅ Avoid Circular Symlinks

```bash
# ❌ Circular reference
ln -s ~/bin/b ~/bin/a
ln -s ~/bin/a ~/bin/b

./a # Error: Too many levels of symbolic links

# ✅ Avoid this entirely
```

---

## Common Symlink Mistakes

### Mistake 1: Trailing Slash on Directory Symlinks

```bash
# Create directory symlink
ln -s ~/projects/myapp ~/myapp

# ❌ WRONG - deletes target contents!
rm -rf ~/myapp/

# ✅ CORRECT - removes only symlink
rm ~/myapp
```

### Mistake 2: Relative Paths in Wrong Directory

```bash
# ❌ Wrong - creates broken link
cd ~/bin
ln -s python3 /usr/bin/python
# Creates: /usr/bin/python -> python3 (looking for /usr/bin/python3 - wait, this works!)
# But confusing!

# ✅ Correct - explicit absolute path
ln -s /usr/bin/python3 ~/bin/python
```

### Mistake 3: Not Using -f Flag When Updating

```bash
# Create symlink
ln -s /usr/bin/python3.10 ~/bin/python

# Try to update
ln -s /usr/bin/python3.11 ~/bin/python
# ln: failed to create symbolic link 'python': File exists

# ✅ Use -f to force
ln -sf /usr/bin/python3.11 ~/bin/python
```

### Mistake 4: Symlinking Data Files

```bash
# ❌ Don't symlink data that changes
ln -s /var/log/app.log ~/app.log
# If log rotates, symlink breaks

# ✅ Copy or tail instead
cp /var/log/app.log ~/app.log
tail -f /var/log/app.log
```

### Mistake 5: Permissions on Symlinks

```bash
# Symlinks always show rwxrwxrwx
ls -l ~/bin/python
lrwxrwxrwx... -> /usr/bin/python3

# ❌ Can't change symlink permissions
chmod 755 ~/bin/python # Changes TARGET, not symlink!

# Target permissions matter, not symlink
ls -l /usr/bin/python3
-rwxr-xr-x... /usr/bin/python3
```

### Mistake 6: Forgetting -L Flag with find

```bash
# ❌ Finds symlinks, not their targets
find ~/bin -name "python*"
# Only finds ~/bin/python (the symlink)

# ✅ Follow symlinks
find -L ~/bin -name "python*"
# Finds target too
```

---

## Advanced: Alternatives Priority System

### Understanding Priority

**Priority** determines which version is selected in auto mode:
- Higher priority = preferred version
- Auto mode always selects highest priority

```bash
update-alternatives --display python
 /usr/bin/python3.10 - priority 310
 /usr/bin/python3.11 - priority 311 ← Higher priority
 /usr/bin/python3.12 - priority 312 ← Highest, selected in auto
```

### Setting Priorities

**When installing**:
```bash
sudo update-alternatives --install \
 /usr/bin/python \
 python \
 /usr/bin/python3.12 \
 312 # ← Priority
```

**Convention**:
- Use version number as priority (e.g., 310, 311, 312)
- Or significance (e.g., 50, 100, 200)

### Auto vs Manual Mode

**Auto mode**:
- System automatically selects highest priority
- When new higher-priority version installed, switches automatically

```bash
sudo update-alternatives --auto python
# Now uses highest priority (312 - python3.12)
```

**Manual mode**:
- You explicitly select version
- Stays selected even if higher priority installed

```bash
sudo update-alternatives --set python /usr/bin/python3.10
# Stays on 3.10 even if 3.13 installed with priority 313
```

### Alternative Groups

**Slave links** - Related commands that should match:

```bash
# Install python with slave links
sudo update-alternatives --install \
 /usr/bin/python python /usr/bin/python3.11 311 \
 --slave /usr/bin/pip pip /usr/bin/pip3.11 \
 --slave /usr/bin/pydoc pydoc /usr/bin/pydoc3.11

# When you switch python, pip and pydoc switch too!
```

**Check slaves**:
```bash
update-alternatives --display python
...
link python is /usr/bin/python
slave pip is /usr/bin/pip
slave pydoc is /usr/bin/pydoc
...
```

### ✅ Creating Custom Alternative

```bash
#!/bin/bash
# Setup custom alternative

# Install multiple versions
sudo update-alternatives --install \
 /usr/local/bin/myapp myapp /opt/myapp-1.0/bin/myapp 100

sudo update-alternatives --install \
 /usr/local/bin/myapp myapp /opt/myapp-2.0/bin/myapp 200

# Select version
sudo update-alternatives --config myapp

# Use it
myapp --version
```

### Managing Alternatives via Scripts

```bash
#!/bin/bash
# File: ~/bin/setup-python-alternatives

for version in 3.10 3.11 3.12; do
 python_path="/usr/bin/python$version"

 if [ ! -f "$python_path" ]; then
 echo "Python $version not found, skipping"
 continue
 fi

 priority="${version/./}" # 3.10 -> 310

 sudo update-alternatives --install \
 /usr/bin/python \
 python \
 "$python_path" \
 "$priority" \
 --slave /usr/bin/pip pip "/usr/bin/pip$version" \
 --slave /usr/bin/pydoc pydoc "/usr/bin/pydoc$version"

 echo "Installed Python $version with priority $priority"
done

# Set to auto mode
sudo update-alternatives --auto python

echo "Setup complete!"
update-alternatives --display python
```

---

## Quick Reference

### Symlink Commands

```bash
# Create symlink
ln -s target linkname

# Force overwrite
ln -sf target linkname

# Relative symlink
ln -sr target linkname

# Remove symlink
rm linkname
unlink linkname

# Check symlink
ls -l linkname
readlink linkname
readlink -f linkname # Follow to final target

# Find broken symlinks
find ~/bin -xtype l

# Remove broken symlinks
find ~/bin -xtype l -delete
```

### Update-Alternatives Commands

```bash
# List all alternatives
update-alternatives --get-selections

# Display alternative
update-alternatives --display python

# Install alternative
sudo update-alternatives --install /usr/bin/cmd cmd /path/to/cmd priority

# Set alternative (interactive)
sudo update-alternatives --config cmd

# Set alternative (specific)
sudo update-alternatives --set cmd /path/to/cmd

# Auto mode
sudo update-alternatives --auto cmd

# Remove alternative
sudo update-alternatives --remove cmd /path/to/cmd
```

### Best Practices Checklist

- [ ] Use absolute paths for system binaries
- [ ] Use relative paths for project-internal links
- [ ] Check target exists before creating symlink
- [ ] Use -f flag when updating symlinks
- [ ] Remove directory symlinks without trailing slash
- [ ] Document your symlinks
- [ ] Periodically check for broken symlinks
- [ ] Use descriptive names
- [ ] Include version numbers for multiple versions
- [ ] Use update-alternatives for system-wide settings

---

**Series Complete**: You now understand Linux bin directories, shebangs, personal bin setup, permissions, and symlinks management!

**Related Topics**:
- <!-- Link to chapter (see full documentation) --> - Understanding bin directories
- <!-- Link to chapter (see full documentation) --> - System bin directories
- <!-- Link to chapter (see full documentation) --> - User-level bin directories
- <!-- Link to chapter (see full documentation) --> - How PATH search works
