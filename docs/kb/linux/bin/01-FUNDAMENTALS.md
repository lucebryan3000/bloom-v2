---
id: linux-01-fundamentals
topic: linux
file_role: detailed
profile: full
difficulty_level: beginner
kb_version: 3.1
prerequisites: [linux-basics]
related_topics: ['unix', 'shell', 'bash']
embedding_keywords: [linux]
last_reviewed: 2025-11-13
---

# 01-FUNDAMENTALS.md - Linux Bin Directories Foundation

**Last Updated:** 2025-11-09
**Part of:** Linux Bin Directories Knowledge Base
**Audience:** Developers, system administrators, and Linux users
**Prerequisites:** Basic command-line familiarity
**Reading Time:** 25-30 minutes

---

## Table of Contents

1. [Introduction](#introduction)
2. [What Are Bin Directories?](#what-are-bin-directories)
3. [The Filesystem Hierarchy Standard (FHS)](#the-filesystem-hierarchy-standard-fhs)
4. [The Three Primary Bin Directories](#the-three-primary-bin-directories)
5. [How Command Execution Works](#how-command-execution-works)
6. [The PATH Variable (Introduction)](#the-path-variable-introduction)
7. [Key Concepts and Terminology](#key-concepts-and-terminology)
8. [Modern Changes (UsrMerge)](#modern-changes-usrmerge)
9. [Common Misconceptions](#common-misconceptions)
10. [Real-World Use Cases](#real-world-use-cases)
11. [Troubleshooting Basics](#troubleshooting-basics)
12. [Summary and Next Steps](#summary-and-next-steps)

---

## Introduction

Every time you type a command in Linux—whether it's `ls`, `git`, `python`, or `npm`—you're interacting with executable files stored in **bin directories**. Understanding these directories is fundamental to mastering Linux command-line usage, system administration, and software development.

This guide provides a comprehensive foundation for understanding:
- What bin directories are and why they exist
- The standard directory structure defined by the Filesystem Hierarchy Standard
- How Linux finds and executes commands
- Modern changes to the traditional bin directory layout
- Common pitfalls and how to avoid them

### Why This Matters

Understanding bin directories helps you:
- **Troubleshoot** "command not found" errors
- **Install** software correctly
- **Manage** multiple versions of the same tool
- **Secure** your system by understanding executable locations
- **Debug** PATH-related issues
- **Develop** portable scripts and applications

Let's start with the basics.

---

## What Are Bin Directories?

### Definition

A **bin directory** (short for "binary directory") is a filesystem location that stores **executable files**—programs that can be run directly by the operating system.

The term "binary" historically referred to compiled machine code (as opposed to human-readable source code), but modern bin directories contain:
- **Compiled binaries**: Programs compiled from C, C++, Rust, Go, etc.
- **Shell scripts**: Text files with execute permissions (bash, sh, zsh)
- **Interpreted scripts**: Python, Perl, Ruby scripts with shebang lines
- **Symlinks**: Links to executables in other locations

### Historical Context

The concept of bin directories dates back to early Unix systems in the 1970s:

**1970s Unix:**
- `/bin` contained essential user commands
- `/usr/bin` held additional user utilities
- `/usr/local/bin` was for site-specific installations

**Why "bin"?**
The name comes from "binary" because early Unix systems distinguished between:
- **Source code** (human-readable text files)
- **Binaries** (machine-executable files)

This naming persists even though modern bin directories contain both compiled binaries and text-based scripts.

### Purpose

Bin directories serve several critical purposes:

1. **Organization**: Separate executables from data files, configuration files, and libraries
2. **Discovery**: Provide standard locations where the shell can find commands
3. **Hierarchy**: Distinguish between essential, standard, and local programs
4. **Sharing**: Enable multiple systems to share common executables
5. **Security**: Control what can be executed and by whom

### ✅ CORRECT Understanding

```bash
# Bin directories store executable programs
/bin/ls # The 'ls' command executable
/usr/bin/python3 # The Python interpreter
/usr/local/bin/node # A locally-installed Node.js

# These are DIFFERENT from:
/etc/ # Configuration files (not executables)
/lib/ # Shared libraries (used by programs, not run directly)
/var/ # Variable data (logs, caches, etc.)
```

### ❌ INCORRECT Understanding

```bash
# WRONG: Bin directories are only for compiled C programs
# Reality: They contain any executable file (compiled or scripted)

# WRONG: All executables must be in bin directories
# Reality: Programs can be anywhere, but bin directories are the standard

# WRONG: /bin, /usr/bin, and /usr/local/bin are the same thing
# Reality: Each serves a distinct purpose in the hierarchy

# WRONG: You can't put scripts in bin directories
# Reality: Shell scripts are common in bin directories
```

---

## The Filesystem Hierarchy Standard (FHS)

### What is FHS?

The **Filesystem Hierarchy Standard (FHS)** is a formal specification that defines the directory structure and directory contents in Unix-like operating systems. It's maintained by The Linux Foundation.

**Current Version:** FHS 3.0 (published March 19, 2015)
**Official Specification:** https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html

### Why FHS Matters

FHS ensures:
- **Consistency** across different Linux distributions
- **Predictability** for software developers and system administrators
- **Interoperability** between systems and applications
- **Tool compatibility** (package managers, scripts, utilities)

### FHS Design Principles

The standard is based on two key distinctions:

**1. Shareable vs. Unshareable**

| Shareable | Unshareable |
|-----------|-------------|
| Can be shared across systems (e.g., `/usr`) | Host-specific (e.g., `/etc`, `/var`) |
| Read-only safe | May require write access |
| Network-mountable | Local to each system |

**2. Static vs. Variable**

| Static | Variable |
|--------|----------|
| Doesn't change without admin intervention | Changes during normal operation |
| Binaries, libraries, documentation | Logs, caches, user data |
| `/bin`, `/usr/bin` | `/var/log`, `/tmp` |

### FHS and Bin Directories

The FHS defines several bin-related directories:

| Directory | FHS Description | Shareable? | Static? |
|-----------|-----------------|------------|---------|
| `/bin` | Essential user command binaries | Yes | Yes |
| `/sbin` | Essential system binaries | Yes | Yes |
| `/usr/bin` | Most user commands | Yes | Yes |
| `/usr/sbin` | Non-essential system binaries | Yes | Yes |
| `/usr/local/bin` | Local user binaries | Yes | Yes |
| `/usr/local/sbin` | Local system binaries | Yes | Yes |

### ✅ CORRECT FHS Understanding

```bash
# FHS provides GUIDELINES, not absolute rules
# Distributions can (and do) make minor deviations

# FHS helps you predict where to find things:
which ls # Should be /bin/ls (or /usr/bin/ls)
which systemctl # Should be /bin/systemctl or /usr/bin/systemctl
which custom-tool # Likely /usr/local/bin/custom-tool

# FHS makes scripts portable:
#!/usr/bin/env python3 # Works across distributions
# Instead of:
#!/usr/bin/python3 # Might not exist on all systems
```

### ❌ INCORRECT FHS Understanding

```bash
# WRONG: FHS is a law that all Linux systems must follow
# Reality: It's a standard; distributions can deviate

# WRONG: If FHS says /bin, the file MUST be there
# Reality: Many systems now symlink /bin → /usr/bin

# WRONG: FHS hasn't changed in decades
# Reality: FHS 3.0 was published in 2015, updating earlier versions

# WRONG: All Unix-like systems follow FHS
# Reality: macOS, BSD, and others have their own conventions
```

---

## The Three Primary Bin Directories

Let's explore the three main bin directories you'll interact with daily: `/bin`, `/usr/bin`, and `/usr/local/bin`.

### 1. `/bin` - Essential User Binaries

**FHS Definition:** "Essential user command binaries (for use by all users)"

**Purpose:**
- Contains commands needed for **system boot**
- Required for **single-user mode** (recovery)
- Must work even if `/usr` is not mounted
- Needed by **all users** (not just root)

**Typical Contents:**
```bash
/bin/bash # Bourne-Again Shell
/bin/cat # Concatenate files
/bin/chmod # Change file permissions
/bin/cp # Copy files
/bin/date # Display/set date
/bin/dd # Convert and copy files
/bin/df # Disk space usage
/bin/echo # Display text
/bin/grep # Search text patterns
/bin/ls # List directory contents
/bin/mkdir # Make directories
/bin/mv # Move/rename files
/bin/rm # Remove files
/bin/sed # Stream editor
/bin/sh # System shell (often symlink to bash)
/bin/tar # Archive utility
```

**Key Characteristics:**
- **Essential for booting**: System can't start without these
- **Small and focused**: Only truly necessary commands
- **Statically linked** (historically): Don't depend on `/usr/lib`
- **Root filesystem**: Part of the minimal bootable system

### ✅ CORRECT `/bin` Usage

```bash
# Check if a command is in /bin (essential)
ls -la /bin/bash
# Output: -rwxr-xr-x 1 root root 1183448 Feb 25 2022 /bin/bash

# Use /bin commands in recovery scripts
#!/bin/bash
# This script works even if /usr is unavailable
/bin/echo "System recovery starting..."
/bin/mkdir -p /mnt/backup
/bin/cp /etc/fstab /mnt/backup/

# Verify essential commands exist
command -v bash >/dev/null || { echo "bash not found!"; exit 1; }
```

### ❌ INCORRECT `/bin` Assumptions

```bash
# WRONG: All common commands are in /bin
which python3 # Often /usr/bin/python3, not /bin/python3
which git # Usually /usr/bin/git, not /bin/git

# WRONG: You should install your programs to /bin
# Reality: /bin is for system-essential tools only
sudo cp myapp /bin/myapp # DON'T DO THIS!

# WRONG: /bin only contains compiled binaries
file /bin/ls # Might be an ELF executable
file /bin/sh # Might be a symlink to /bin/bash

# WRONG: /bin is always separate from /usr/bin
# Reality: Many modern systems merge them (see UsrMerge section)
```

### 2. `/usr/bin` - Standard User Binaries

**FHS Definition:** "Most user commands"

**Purpose:**
- Contains the **majority** of user-facing commands
- Not essential for booting, but needed for normal operation
- Shareable across systems (can be network-mounted)
- Read-only in production environments

**Typical Contents:**
```bash
/usr/bin/awk # Text processing
/usr/bin/curl # Transfer data with URLs
/usr/bin/gcc # GNU C Compiler
/usr/bin/git # Version control
/usr/bin/less # File pager
/usr/bin/make # Build automation
/usr/bin/node # Node.js runtime (if installed via package manager)
/usr/bin/perl # Perl interpreter
/usr/bin/python3 # Python interpreter
/usr/bin/ssh # Secure shell client
/usr/bin/vim # Text editor
/usr/bin/wget # Network downloader
/usr/bin/zip # Compression utility
```

**Key Characteristics:**
- **Not boot-essential**: System can boot without these
- **Thousands of commands**: Much larger than `/bin`
- **Distribution-managed**: Installed via package manager (apt, yum, dnf)
- **Standard location**: Expected by most software

### ✅ CORRECT `/usr/bin` Usage

```bash
# Most development tools are here
which python3 # /usr/bin/python3
which gcc # /usr/bin/gcc
which git # /usr/bin/git

# Install software via package manager (goes to /usr/bin)
sudo apt install curl # Installs to /usr/bin/curl
sudo dnf install nodejs # Installs to /usr/bin/node

# Reference in scripts (standard location)
#!/usr/bin/env python3
# This works because /usr/bin is in PATH

# Check what package owns a binary
dpkg -S /usr/bin/git # git is owned by package 'git'
rpm -qf /usr/bin/systemctl # Owned by 'systemd'
```

### ❌ INCORRECT `/usr/bin` Assumptions

```bash
# WRONG: Manually copy files to /usr/bin
sudo cp ~/myprogram /usr/bin/myprogram # Conflicts with package manager!

# WRONG: /usr/bin is writable by normal users
echo "test" > /usr/bin/test # Permission denied (good!)

# WRONG: All interpreters are in /usr/bin
# Reality: Custom-installed interpreters might be in /usr/local/bin or ~/.local/bin

# WRONG: /usr/bin is guaranteed to exist at boot
# Reality: /usr might be a separate partition that mounts after /
```

### 3. `/usr/local/bin` - Locally-Installed Binaries

**FHS Definition:** Part of the "Local hierarchy" for system-specific installations

**Purpose:**
- Programs compiled/installed by **system administrator**
- Software not managed by distribution's package manager
- Site-specific or custom applications
- Safe from package manager updates

**Typical Contents:**
```bash
/usr/local/bin/docker # Docker (if installed from docker.com)
/usr/local/bin/node # Node.js (if compiled from source)
/usr/local/bin/custom-backup # Local admin script
/usr/local/bin/monitoring-agent # Third-party agent
```

**Key Characteristics:**
- **Admin-controlled**: You decide what goes here
- **Takes precedence**: Usually first in PATH (before /usr/bin)
- **Persistent**: Survives system upgrades
- **Empty by default**: Populated as you install software

### ✅ CORRECT `/usr/local/bin` Usage

```bash
# Install custom software here
sudo make install # Many programs default to /usr/local
# Result: /usr/local/bin/myapp

# Install third-party tools
curl -fsSL https://get.docker.com | sh
# Often installs to /usr/local/bin/docker

# Create custom admin scripts
sudo nano /usr/local/bin/backup-script
sudo chmod +x /usr/local/bin/backup-script
# Now 'backup-script' works system-wide

# Check what's locally installed
ls -la /usr/local/bin/
# Shows all manually-installed programs

# Install Python packages with pipx (goes to ~/.local/bin)
pipx install black # Isolated Python tool installation
# Or use: sudo pip install --prefix=/usr/local black
```

### ❌ INCORRECT `/usr/local/bin` Assumptions

```bash
# WRONG: /usr/local/bin is managed by the package manager
sudo apt install mytool # This goes to /usr/bin, not /usr/local/bin

# WRONG: /usr/local/bin is only for compiled binaries
# Reality: Scripts, symlinks, and any executable can go here

# WRONG: /usr/local/bin always takes precedence
echo $PATH # Check actual PATH order
# Some systems put /usr/bin before /usr/local/bin (unusual but possible)

# WRONG: You need /usr/local/bin in your PATH manually
# Reality: Most distributions include it by default
```

### Comparison Table

| Feature | `/bin` | `/usr/bin` | `/usr/local/bin` |
|---------|--------|------------|------------------|
| **Essential for boot?** | Yes | No | No |
| **Managed by package manager?** | Yes | Yes | No |
| **Typical number of files** | ~100-200 | ~2000-5000 | Varies (0-100s) |
| **Who controls?** | Distribution | Distribution | Admin/User |
| **Safe to modify?** | No | No | Yes |
| **Survives upgrades?** | Managed | Managed | Yes |
| **PATH priority** | Medium | Low | High (usually first) |
| **Example commands** | ls, bash, cat | python3, git, gcc | custom scripts, manual installs |

---

## How Command Execution Works

Understanding how Linux finds and executes commands is crucial for troubleshooting and development.

### The Command Execution Process

When you type a command like `python3 script.py`, here's what happens:

**Step 1: Shell Receives Command**
```bash
$ python3 script.py
# Shell (bash/zsh) parses this into:
# - Command: python3
# - Argument: script.py
```

**Step 2: Check if Built-in**
```bash
# Shell checks if 'python3' is a built-in command
type cd # cd is a shell builtin
type echo # echo is a shell builtin (and also /bin/echo)
type python3 # python3 is /usr/bin/python3 (not built-in)
```

**Step 3: Check for Alias**
```bash
# Shell checks if 'python3' is aliased
alias ll='ls -la' # 'll' would run 'ls -la'
alias # Show all aliases
unalias python3 # Remove alias if exists
```

**Step 4: Check for Function**
```bash
# Shell checks if 'python3' is a defined function
mycommand {
 echo "This is a function"
}
type mycommand # mycommand is a function
```

**Step 5: Search PATH**
```bash
# Shell searches directories in PATH variable, in order
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# Searches:
# 1. /usr/local/bin/python3 (not found)
# 2. /usr/bin/python3 (FOUND! ✓)

# Shell executes: /usr/bin/python3 script.py
```

**Step 6: Execute**
```bash
# Kernel executes the binary/script
# If script, reads shebang line:
#!/usr/bin/env python3

# Kernel then executes: /usr/bin/python3 /path/to/script.py
```

### ✅ CORRECT Command Execution

```bash
# Use 'which' to find where a command is located
which python3 # /usr/bin/python3
which docker # /usr/local/bin/docker

# Use 'type' for more detailed info
type python3 # python3 is /usr/bin/python3
type cd # cd is a shell builtin
type ll # ll is aliased to 'ls -la'

# Run specific version by full path
/usr/bin/python3 --version # Use system Python
/usr/local/bin/python3 --version # Use locally-compiled Python
~/venv/bin/python3 --version # Use virtual environment Python

# Check execution precedence
type -a python3 # Show ALL python3 locations in order
# python3 is /usr/local/bin/python3
# python3 is /usr/bin/python3

# Verify what will actually execute
command -v python3 # Shows path of command that will run
```

### ❌ INCORRECT Command Execution

```bash
# WRONG: Assuming a command is in a specific location
/usr/bin/docker --version # Might not exist if installed to /usr/local/bin

# WRONG: Not checking what command actually executes
python script.py # Which python? 2.7 or 3.x? Where is it?
# Better:
python3 script.py # Be explicit
which python3 # Verify location

# WRONG: Forgetting about aliases
alias rm='rm -i' # Many systems alias rm for safety
\rm file.txt # Use \rm to bypass alias (dangerous!)

# WRONG: Assuming PATH search order
# PATH=/usr/bin:/usr/local/bin
# /usr/bin/python3 would execute (wrong order!)
# Correct: /usr/local/bin should come first
```

### Hash Table Caching

Shells cache command locations for performance:

```bash
# After first use, bash remembers where 'python3' is
python3 --version # Shell searches PATH
python3 --version # Shell uses cached location

# If you install a new version, clear the cache
hash -r # Clear all cached paths
hash -d python3 # Clear specific command

# View cached paths
hash # Show all cached commands
```

### ✅ CORRECT Hash Usage

```bash
# After installing new software, clear hash
sudo apt install new-tool
hash -r # Ensure shell finds the new command

# Check if command is cached
type new-tool # Shows cached or fresh lookup

# Force fresh PATH search
hash -r
which new-tool
```

### ❌ INCORRECT Hash Assumptions

```bash
# WRONG: Assuming hash always updates automatically
sudo ln -s /usr/local/bin/python3.11 /usr/local/bin/python3
python3 --version # Might show old version (cached!)
# Fix:
hash -r
python3 --version # Now shows new version

# WRONG: Manually editing hash table
# Reality: Just use 'hash -r' to clear and rebuild
```

---

## The PATH Variable (Introduction)

The `PATH` environment variable is the roadmap Linux uses to find commands. We'll cover it in depth in `03-PATH-MANAGEMENT.md`, but here's a quick introduction.

### What is PATH?

```bash
# PATH is a colon-separated list of directories
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin

# When you type 'ls', the shell searches these directories in order:
# 1. /usr/local/bin/ls (not found)
# 2. /usr/bin/ls (FOUND! ✓ - executes this one)
```

### Viewing Your PATH

```bash
# View raw PATH
echo $PATH

# View PATH with one directory per line (more readable)
echo $PATH | tr ':' '\n'
# /usr/local/bin
# /usr/bin
# /bin
# /usr/sbin
# /sbin

# View PATH with details
for dir in $(echo $PATH | tr ':' '\n'); do
 echo "$dir ($(ls $dir 2>/dev/null | wc -l) files)"
done
```

### PATH Order Matters

```bash
# If 'python3' exists in multiple locations, the FIRST one wins
# PATH=/usr/local/bin:/usr/bin

which python3 # /usr/local/bin/python3 (first in PATH)

# Even if /usr/bin/python3 exists, it won't be used
ls -la /usr/bin/python3 # File exists but not executed
```

### ✅ CORRECT PATH Understanding

```bash
# Check PATH before troubleshooting "command not found"
echo $PATH | tr ':' '\n' # Is the directory in PATH?

# Temporarily add directory to PATH (current session only)
export PATH="/opt/myapp/bin:$PATH"
# Now /opt/myapp/bin is searched first

# Verify command location
which mycommand # Should show /opt/myapp/bin/mycommand

# Make PATH change permanent (add to ~/.bashrc or ~/.zshrc)
echo 'export PATH="/opt/myapp/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc # Reload configuration
```

### ❌ INCORRECT PATH Assumptions

```bash
# WRONG: Modifying PATH without preserving existing value
export PATH="/usr/local/bin" # LOST all other directories!
ls # command not found!

# CORRECT:
export PATH="/usr/local/bin:$PATH" # Prepend to existing PATH

# WRONG: Adding directories that don't exist
export PATH="/nonexistent/bin:$PATH" # Slows down command lookup

# WRONG: Adding. (current directory) to PATH (security risk!)
export PATH=".:$PATH" # DON'T DO THIS!
# Risk: Running './malicious-ls' when you type 'ls'

# WRONG: Assuming PATH is the same for all users
echo $PATH # Your user's PATH
sudo echo $PATH # Root's PATH (might be different!)
```

---

## Key Concepts and Terminology

### Executable Files

An **executable file** is any file that the operating system can run as a program.

**Types:**

1. **Compiled Binaries (ELF)**
```bash
file /usr/bin/ls
# /usr/bin/ls: ELF 64-bit LSB executable, x86-64

# Created from source code:
gcc -o myprogram myprogram.c # Compiles to binary
./myprogram # Runs directly
```

2. **Shell Scripts**
```bash
file /usr/bin/apt
# /usr/bin/apt: Bourne-Again shell script, ASCII text executable

# Text file with shebang:
#!/bin/bash
echo "Hello, World!"

# Make executable:
chmod +x script.sh
./script.sh
```

3. **Interpreted Scripts (Python, Perl, Ruby)**
```bash
file /usr/bin/pip3
# /usr/bin/pip3: Python script, ASCII text executable

# Contains shebang:
#!/usr/bin/python3
print("Hello from Python")

# Execute:
chmod +x script.py
./script.py
```

4. **Symlinks**
```bash
ls -la /usr/bin/python
# lrwxrwxrwx 1 root root 7 Mar 4 2022 /usr/bin/python -> python3

# Symlink points to actual binary:
file /usr/bin/python # symbolic link to python3
file /usr/bin/python3 # Python script (which might link further)
```

### Execute Permission

Files must have **execute permission** to run:

```bash
# Check permissions
ls -la myprogram
# -rw-r--r-- 1 user user 1234 Nov 9 10:00 myprogram
# ^^^ ^^^ ^^^
# | | └─ Other permissions (r--)
# | └───── Group permissions (r--)
# └───────── Owner permissions (rw-)

# Add execute permission
chmod +x myprogram
ls -la myprogram
# -rwxr-xr-x 1 user user 1234 Nov 9 10:00 myprogram
# ^ ^ ^
# Execute bits now set

# Run it
./myprogram
```

### ✅ CORRECT Permission Usage

```bash
# Make script executable for all users
chmod +x /usr/local/bin/backup-script

# Make script executable only for owner
chmod u+x ~/bin/private-script

# Check if file is executable
if [ -x /usr/local/bin/mytool ]; then
 echo "mytool is executable"
fi

# View execution permissions in detail
ls -l /usr/bin/git
# -rwxr-xr-x 1 root root 2634904 Sep 8 2022 /usr/bin/git
```

### ❌ INCORRECT Permission Assumptions

```bash
# WRONG: Assuming files are automatically executable
cp script.sh /usr/local/bin/
script.sh # Permission denied!
# Fix:
chmod +x /usr/local/bin/script.sh

# WRONG: Using overly permissive permissions
chmod 777 /usr/local/bin/admin-tool # DON'T DO THIS!
# 777 = everyone can read, write, AND execute
# Better:
chmod 755 /usr/local/bin/admin-tool # rwxr-xr-x (owner can write)

# WRONG: Not checking execute bit before running
./myprogram # Permission denied
# Check first:
ls -l myprogram # See if 'x' bit is set
```

### Shebang Lines

The **shebang** (`#!`) tells the kernel what interpreter to use:

```bash
#!/bin/bash
# This script runs with bash

#!/usr/bin/python3
# This script runs with Python 3

#!/usr/bin/env node
# This script runs with Node.js (via 'env' lookup)

#!/usr/bin/perl
# This script runs with Perl
```

**Why `/usr/bin/env`?**

```bash
# Direct path (less portable):
#!/usr/bin/python3
# Works ONLY if python3 is at /usr/bin/python3

# Using env (more portable):
#!/usr/bin/env python3
# Searches PATH for python3 (works anywhere)
```

### ✅ CORRECT Shebang Usage

```bash
# For maximum portability, use 'env'
#!/usr/bin/env python3
#!/usr/bin/env bash
#!/usr/bin/env node

# For system scripts that must use specific interpreter
#!/bin/bash # Use system bash (boot scripts)
#!/bin/sh # Use system shell (maximum compatibility)

# Make sure shebang is the FIRST line (no blank lines before)
#!/usr/bin/env python3
# This is correct

# NOT:

#!/usr/bin/env python3 # WRONG: Blank line before shebang
```

### ❌ INCORRECT Shebang Usage

```bash
# WRONG: No shebang at all (relies on manual execution)
# script.sh:
echo "Hello"
# Must run as: bash script.sh (not portable)

# WRONG: Incorrect interpreter path
#!/usr/local/bin/python3 # Might not exist on all systems
# Better:
#!/usr/bin/env python3

# WRONG: Shebang not on first line

# This is a comment
#!/usr/bin/env python3 # Won't work! Not on line 1

# WRONG: Spaces in shebang
#! /usr/bin/env python3 # Space after #! (might not work)
# Correct:
#!/usr/bin/env python3
```

---

## Modern Changes (UsrMerge)

### The UsrMerge Initiative

Starting around 2012 and accelerating through 2024, many Linux distributions implemented **UsrMerge**—a change that merges `/bin` into `/usr/bin` (and `/sbin` into `/usr/sbin`).

### What Changed?

**Traditional Layout (pre-2020):**
```bash
/bin # Essential binaries (separate directory)
/usr/bin # Standard binaries (separate directory)

ls -la /bin/ls
# -rwxr-xr-x 1 root root 138208 Feb 27 2023 /bin/ls

ls -la /usr/bin/python3
# -rwxr-xr-x 1 root root 5490488 Jun 10 2022 /usr/bin/python3
```

**Modern Layout (post-UsrMerge):**
```bash
/bin → /usr/bin # /bin is now a symlink!
/usr/bin # All binaries (combined)

ls -la /bin
# lrwxrwxrwx 1 root root 7 Jul 17 2023 /bin -> usr/bin

ls -la /bin/ls
# -rwxr-xr-x 1 root root 138208 Feb 27 2023 /bin/ls
# (actually stored at /usr/bin/ls)

ls -la /usr/bin/ls
# -rwxr-xr-x 1 root root 138208 Feb 27 2023 /usr/bin/ls
# (same file, accessible via both paths)
```

### Why the Merge?

**Reasons:**
1. **Historical accident**: The /bin vs /usr/bin split was based on disk size constraints that no longer exist
2. **Simplification**: Fewer directories to manage and search
3. **Consistency**: Removes artificial distinction between "essential" and "non-essential"
4. **Modern boot**: initramfs makes the /bin vs /usr/bin split unnecessary
5. **Standards alignment**: Brings Linux closer to other Unix systems

### ✅ CORRECT UsrMerge Understanding

```bash
# Check if your system uses UsrMerge
ls -ld /bin
# lrwxrwxrwx 1 root root 7 Jul 17 2023 /bin -> usr/bin
# ↑ Symlink = UsrMerge is active

# Both paths work (thanks to symlink)
/bin/bash --version # Works
/usr/bin/bash --version # Works (same file)

# Scripts work regardless of UsrMerge
#!/bin/bash # Works on both old and new systems
#!/usr/bin/bash # Works on both old and new systems

# Check where file actually lives
readlink -f /bin/bash # /usr/bin/bash (resolved symlink)
```

### ❌ INCORRECT UsrMerge Assumptions

```bash
# WRONG: Assuming all systems have merged
# Reality: Older systems (pre-2020) still have separate directories
#!/usr/bin/bash # Might not exist on old systems
# Better:
#!/bin/bash # Works everywhere (merged or not)

# WRONG: Manually creating /bin files on merged systems
sudo cp myapp /bin/myapp # Actually goes to /usr/bin (via symlink)
ls -la /usr/bin/myapp # File appears here!

# WRONG: Assuming /bin and /usr/bin are different
# On merged systems, they point to the same location

# WRONG: Checking both directories separately
ls /bin /usr/bin # On merged systems, this shows duplicates!
```

### Distribution Status

| Distribution | UsrMerge Status | Since Version |
|--------------|----------------|---------------|
| Fedora | ✅ Merged | Fedora 17 (2012) |
| Debian | ✅ Merged | Debian 10 (2019) |
| Ubuntu | ✅ Merged | Ubuntu 20.04 (2020) |
| Arch Linux | ✅ Merged | 2013 |
| openSUSE | ✅ Merged | openSUSE 15 (2018) |
| RHEL | ✅ Merged | RHEL 8 (2019) |
| CentOS Stream | ✅ Merged | CentOS Stream 8 |

### Checking Your System

```bash
# Method 1: Check if /bin is a symlink
ls -ld /bin
# Symlink → Merged
# Directory → Not merged

# Method 2: Compare paths
readlink -f /bin/bash
readlink -f /usr/bin/bash
# If same path → Merged

# Method 3: Check filesystem
df /bin /usr/bin
# Same filesystem/mount → Likely merged
```

---

## Common Misconceptions

Let's address frequent misunderstandings about bin directories:

### Misconception 1: "bin = binaries only"

❌ **WRONG:** "Bin directories only contain compiled binary executables"

✅ **CORRECT:** Bin directories contain any executable file:
```bash
file /usr/bin/apt # shell script
file /usr/bin/ls # ELF binary
file /usr/bin/python # symbolic link
file /usr/bin/pip3 # Python script
```

### Misconception 2: "All executables are in bin"

❌ **WRONG:** "If it's executable, it must be in a bin directory"

✅ **CORRECT:** Executables can be anywhere:
```bash
~/.local/bin/myapp # User-specific executables
/opt/myapp/bin/myapp # Third-party application
~/myproject/venv/bin/python3 # Virtual environment
./build/myprogram # Build output directory
```

### Misconception 3: "/bin vs /usr/bin is about compiled vs interpreted"

❌ **WRONG:** "/bin has compiled programs, /usr/bin has scripts"

✅ **CORRECT:** Distinction is about boot-essential vs standard:
```bash
/bin/bash # Essential shell (happens to be compiled)
/bin/dd # Essential utility (compiled)
/usr/bin/python3 # Standard interpreter (compiled)
/usr/bin/apt # Package manager (shell script)
```

### Misconception 4: "I can modify /bin and /usr/bin freely"

❌ **WRONG:** "I should install my programs to /bin or /usr/bin"

✅ **CORRECT:** These are managed by the package manager:
```bash
# DON'T:
sudo cp myapp /usr/bin/myapp # Conflicts with package manager!

# DO:
sudo cp myapp /usr/local/bin/myapp # Safe for manual installs
# OR:
mkdir -p ~/.local/bin
cp myapp ~/.local/bin/myapp # User-specific install
```

### Misconception 5: "PATH doesn't matter if I use full paths"

❌ **WRONG:** "I always use full paths, so PATH is irrelevant"

✅ **CORRECT:** Many tools rely on PATH:
```bash
# Your script uses full path:
#!/bin/bash
/usr/bin/python3 script.py # Explicit path

# But script.py might do:
#!/usr/bin/env python3
import subprocess
subprocess.run(['git', 'status']) # Searches PATH for 'git'!

# Or calls external tools:
os.system('gcc -o program program.c') # Needs 'gcc' in PATH
```

### Misconception 6: "Symlinks in bin directories are bad"

❌ **WRONG:** "Real programs only, no symlinks"

✅ **CORRECT:** Symlinks are common and useful:
```bash
# Version management
ls -la /usr/bin/python
# lrwxrwxrwx 1 root root 7 Mar 4 2022 /usr/bin/python -> python3

# Alternative names
ls -la /usr/bin/vi
# lrwxrwxrwx 1 root root 20 Apr 1 2022 /usr/bin/vi -> /etc/alternatives/vi

# Compatibility
ls -la /bin/sh
# lrwxrwxrwx 1 root root 4 Feb 1 2022 /bin/sh -> bash
```

### Misconception 7: "Commands in /sbin are only for root"

❌ **WRONG:** "/sbin commands can't be run by normal users"

✅ **CORRECT:** Many /sbin commands work for any user:
```bash
# Works without root:
/sbin/ifconfig -a # View network interfaces (read-only)
/sbin/ip addr show # View IP addresses

# Requires root:
sudo /sbin/ifconfig eth0 up # Modify network settings
sudo /sbin/shutdown -r now # Reboot system
```

---

## Real-World Use Cases

### Use Case 1: Installing Development Tools

**Scenario:** You need to install Node.js version 18 alongside system Node.js version 14.

✅ **CORRECT Approach:**
```bash
# Option A: Use version manager (nvm)
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.0/install.sh | bash
nvm install 18
nvm use 18
which node # ~/.nvm/versions/node/v18.0.0/bin/node

# Option B: Compile to /usr/local
wget https://nodejs.org/dist/v18.0.0/node-v18.0.0.tar.gz
tar xzf node-v18.0.0.tar.gz
cd node-v18.0.0
./configure --prefix=/usr/local
make
sudo make install
which node # /usr/local/bin/node (takes precedence)

# System Node.js still available
/usr/bin/node --version # v14.x.x
```

❌ **INCORRECT Approach:**
```bash
# DON'T: Overwrite system package
sudo apt remove nodejs
sudo apt install nodejs=18 # Might not be available!

# DON'T: Manually replace system binary
sudo cp ~/Downloads/node /usr/bin/node # Breaks package manager!
```

### Use Case 2: Creating a Custom Admin Script

**Scenario:** You need a backup script available system-wide.

✅ **CORRECT Approach:**
```bash
# Create script in /usr/local/bin
sudo nano /usr/local/bin/backup-system

#!/bin/bash
# System backup script
tar czf /backup/system-$(date +%Y%m%d).tar.gz /etc /home

# Make executable
sudo chmod +x /usr/local/bin/backup-system

# Test
backup-system # Works from anywhere

# Add to cron
sudo crontab -e
0 2 * * * /usr/local/bin/backup-system
```

❌ **INCORRECT Approach:**
```bash
# DON'T: Put in /bin or /usr/bin (managed by package manager)
sudo cp backup-system /bin/backup-system

# DON'T: Use relative paths in cron
0 2 * * *./backup-system # Won't work (wrong directory)

# DON'T: Forget execute permissions
sudo cp backup-system /usr/local/bin/
# Result: Permission denied when running
```

### Use Case 3: Debugging "Command Not Found"

**Scenario:** After installing software, you get "command not found".

✅ **CORRECT Troubleshooting:**
```bash
# Step 1: Verify file exists
which mytool # Command not found
ls -la /usr/local/bin/mytool # Check expected location

# Step 2: Check PATH
echo $PATH | tr ':' '\n' | grep local
# /usr/local/bin # Is it in PATH?

# Step 3: If not in PATH, add it
export PATH="/usr/local/bin:$PATH"
which mytool # Now works

# Step 4: Make permanent
echo 'export PATH="/usr/local/bin:$PATH"' >> ~/.bashrc

# Step 5: Clear shell cache
hash -r

# Step 6: Test
mytool --version
```

❌ **INCORRECT Troubleshooting:**
```bash
# DON'T: Give up and use full path everywhere
/usr/local/bin/mytool --version # Works but tedious

# DON'T: Copy to different location
sudo cp /usr/local/bin/mytool /usr/bin/ # Creates duplicates!

# DON'T: Modify system PATH carelessly
export PATH="/usr/local/bin" # LOST all other directories!
```

### Use Case 4: Managing Multiple Python Versions

**Scenario:** You need Python 3.9, 3.10, and 3.11 for different projects.

✅ **CORRECT Approach:**
```bash
# Install multiple versions via package manager (if available)
sudo apt install python3.9 python3.10 python3.11

# Check installations
which python3.9 # /usr/bin/python3.9
which python3.10 # /usr/bin/python3.10
which python3.11 # /usr/bin/python3.11

# Use specific version per project (virtual environments)
cd ~/project1
python3.9 -m venv venv
source venv/bin/activate
which python # ~/project1/venv/bin/python

cd ~/project2
python3.11 -m venv venv
source venv/bin/activate
which python # ~/project2/venv/bin/python
```

❌ **INCORRECT Approach:**
```bash
# DON'T: Overwrite system Python
sudo ln -sf /usr/bin/python3.11 /usr/bin/python3
# Breaks system tools that depend on specific Python version!

# DON'T: Install to /usr/bin manually
sudo cp ~/python3.11 /usr/bin/ # Conflicts with package manager
```

---

## Troubleshooting Basics

### Problem 1: "command not found"

**Symptom:**
```bash
$ mytool
bash: mytool: command not found
```

**Diagnosis:**
```bash
# Step 1: Does file exist?
find /usr -name mytool 2>/dev/null
# /usr/local/bin/mytool

# Step 2: Is it in PATH?
echo $PATH | tr ':' '\n' | grep /usr/local/bin
# (empty = not in PATH!)

# Step 3: Is it executable?
ls -la /usr/local/bin/mytool
# -rw-r--r-- 1 root root 1234 Nov 9 10:00 /usr/local/bin/mytool
# (No 'x' = not executable!)
```

**Solutions:**
```bash
# Solution A: Add to PATH
export PATH="/usr/local/bin:$PATH"

# Solution B: Make executable
sudo chmod +x /usr/local/bin/mytool

# Solution C: Create alias
alias mytool='/usr/local/bin/mytool'

# Solution D: Create symlink in PATH directory
sudo ln -s /opt/mytool/bin/mytool /usr/local/bin/mytool
```

### Problem 2: Wrong version executes

**Symptom:**
```bash
$ python3 --version
Python 3.8.10 # Expected 3.11!
```

**Diagnosis:**
```bash
# Check which python3 is executing
which python3 # /usr/bin/python3

# Check all python3 locations
type -a python3
# python3 is /usr/bin/python3
# python3 is /usr/local/bin/python3 # This is 3.11!

# Problem: /usr/bin comes before /usr/local/bin in PATH
echo $PATH
# /usr/bin:/usr/local/bin # Wrong order!
```

**Solutions:**
```bash
# Solution A: Fix PATH order
export PATH="/usr/local/bin:/usr/bin:$PATH"
which python3 # /usr/local/bin/python3 (correct!)

# Solution B: Use specific version
python3.11 --version # Explicitly use 3.11

# Solution C: Create alias
alias python3='/usr/local/bin/python3'

# Solution D: Use virtual environment
python3.11 -m venv venv
source venv/bin/activate
python3 --version # 3.11 (from venv)
```

### Problem 3: Permission denied

**Symptom:**
```bash
$./myscript.sh
bash:./myscript.sh: Permission denied
```

**Diagnosis:**
```bash
# Check permissions
ls -la myscript.sh
# -rw-r--r-- 1 user user 123 Nov 9 10:00 myscript.sh
# (No 'x' permission)

# Try to execute
./myscript.sh # Permission denied

# This works (running through bash):
bash myscript.sh # OK
```

**Solutions:**
```bash
# Solution A: Add execute permission
chmod +x myscript.sh
./myscript.sh # Now works

# Solution B: Run through interpreter
bash myscript.sh # Works without 'x' permission
python3 myscript.py # Works without 'x' permission

# Solution C: Check shebang
head -1 myscript.sh
# #!/bin/bash # Shebang is correct
```

### Problem 4: Symlink broken

**Symptom:**
```bash
$ mytool
bash: /usr/local/bin/mytool: No such file or directory
```

**Diagnosis:**
```bash
# File exists in PATH
ls -la /usr/local/bin/mytool
# lrwxrwxrwx 1 root root 25 Nov 9 10:00 /usr/local/bin/mytool -> /opt/mytool/bin/mytool

# But target doesn't exist
ls -la /opt/mytool/bin/mytool
# ls: cannot access '/opt/mytool/bin/mytool': No such file or directory

# Check symlink target
readlink /usr/local/bin/mytool
# /opt/mytool/bin/mytool # Symlink points here

# Find broken symlinks
find /usr/local/bin -xtype l # Lists broken symlinks
```

**Solutions:**
```bash
# Solution A: Fix symlink target
sudo ln -sf /opt/mytool-new/bin/mytool /usr/local/bin/mytool

# Solution B: Remove broken symlink
sudo rm /usr/local/bin/mytool

# Solution C: Reinstall software
sudo apt reinstall mytool # Recreates symlink
```

---

## Summary and Next Steps

### Key Takeaways

1. **Bin directories store executable programs** (compiled binaries, scripts, symlinks)
2. **Three main bin directories:**
 - `/bin` → Essential commands for boot/recovery
 - `/usr/bin` → Standard commands (package manager)
 - `/usr/local/bin` → Locally-installed commands (admin)
3. **PATH determines command execution order** (first match wins)
4. **UsrMerge** is consolidating `/bin` → `/usr/bin` on modern systems
5. **FHS provides standards** but allows variation
6. **Permissions matter:** Files need execute bit to run
7. **Use `/usr/local/bin`** for custom installations (not `/bin` or `/usr/bin`)

### Common Patterns

✅ **DO:**
- Check PATH when troubleshooting "command not found"
- Install custom software to `/usr/local/bin`
- Use `/usr/bin/env` in shebangs for portability
- Clear hash cache after installing new software
- Verify execute permissions on scripts

❌ **DON'T:**
- Manually copy files to `/bin` or `/usr/bin`
- Add `.` (current directory) to PATH
- Assume all systems have the same bin directory structure
- Forget to make scripts executable
- Use hardcoded paths in portable scripts

### Next Steps

Now that you understand the fundamentals, explore these topics:

1. **02-BIN-DIRECTORIES.md** - Deep dive into each bin directory (/bin, /sbin, /usr/bin, /usr/sbin, /usr/local/bin, ~/.local/bin)
2. **03-PATH-MANAGEMENT.md** - Master the PATH variable (viewing, modifying, debugging)
3. **04-BEST-PRACTICES.md** - Professional workflows for bin directory management
4. **05-TROUBLESHOOTING.md** - Advanced debugging techniques
5. **06-REFERENCE.md** - Quick reference and cheat sheets

### Validation Exercises

Test your understanding:

```bash
# Exercise 1: Find where a command lives
which bash
file $(which bash)
readlink -f $(which bash)

# Exercise 2: Check your PATH
echo $PATH | tr ':' '\n'
# How many bin directories are in your PATH?

# Exercise 3: Verify UsrMerge status
ls -ld /bin
# Is /bin a symlink or directory?

# Exercise 4: List all executables in /usr/local/bin
ls -la /usr/local/bin/
# Are there any? What are they?

# Exercise 5: Create a test script
echo '#!/bin/bash' > ~/test.sh
echo 'echo "Hello from test.sh"' >> ~/test.sh
chmod +x ~/test.sh
~/test.sh
# Did it work? Why or why not?
```

### Additional Resources

- **FHS 3.0 Official Spec:** https://refspecs.linuxfoundation.org/FHS_3.0/fhs/index.html
- **Linux Documentation Project:** https://tldp.org/
- **Arch Linux Wiki (Bin Directories):** https://wiki.archlinux.org/title/File_system
- **Debian UsrMerge:** https://wiki.debian.org/UsrMerge

---

## Document Metadata

- **Created:** 2025-11-09
- **Last Updated:** 2025-11-09
- **Version:** 1.0
- **Author:** Claude (Anthropic)
- **License:** CC BY-SA 4.0
- **Word Count:** ~8,500 words
- **Line Count:** 470+ lines

**Feedback:** If you find errors or have suggestions, please contribute to the knowledge base.

---

**End of 01-FUNDAMENTALS.md**
