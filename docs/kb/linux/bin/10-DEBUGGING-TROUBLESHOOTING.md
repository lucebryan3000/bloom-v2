---
id: linux-10-debugging-troubleshooting
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

# Debugging and Troubleshooting Binary Issues

**Part of Linux Bin Directories Knowledge Base**

## Table of Contents
1. [Overview](#overview)
2. [Command Not Found Errors](#command-not-found-errors)
3. [Permission Denied Errors](#permission-denied-errors)
4. [Bad Interpreter Errors](#bad-interpreter-errors)
5. [Wrong Version Executing](#wrong-version-executing)
6. [Text File Busy Errors](#text-file-busy-errors)
7. [Cannot Execute Binary File](#cannot-execute-binary-file)
8. [Debugging Tools](#debugging-tools)
9. [PATH Debugging](#path-debugging)
10. [Command Hash Issues](#command-hash-issues)
11. [Script Debugging](#script-debugging)
12. [Common Issues Reference](#common-issues-reference)

---

## Overview

Binary execution problems are among the most common issues in Linux. This guide provides systematic troubleshooting approaches for every major error type.

### Troubleshooting Methodology

1. **Identify the exact error message**
2. **Check the basics** (PATH, permissions, file existence)
3. **Use diagnostic tools** (which, file, ldd)
4. **Isolate the problem** (binary vs environment)
5. **Apply targeted fix**
6. **Verify solution**

---

## Command Not Found Errors

### Error Message

```bash
# ❌ Classic error
$ mybinary
bash: mybinary: command not found
```

### Troubleshooting Workflow

#### Step 1: Verify File Exists

```bash
# ✅ Check if binary exists
ls -la /usr/bin/mybinary
ls -la /usr/local/bin/mybinary
ls -la ~/bin/mybinary

# ✅ Search for it
find /usr -name mybinary 2>/dev/null
locate mybinary # If updatedb has been run
```

**If file doesn't exist**: Install it or check if it's in a different location.

#### Step 2: Check PATH

```bash
# ✅ Display current PATH
echo $PATH
# /usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin

# ✅ Check if binary's directory is in PATH
which mybinary # Returns nothing if not in PATH

# ❌ Binary exists but not in PATH
ls -la /opt/myapp/bin/mybinary # Exists
which mybinary # command not found

# ✅ Solution: Add to PATH
export PATH="/opt/myapp/bin:$PATH"
```

#### Step 3: Check for Typos

```bash
# ❌ Common mistakes
$ pytohn script.py
bash: pytohn: command not found

# ✅ Use tab completion
$ pyth<TAB>
# Expands to: python3

# ✅ Check available commands
compgen -c | grep python
# python3
# python3.10
# python3.11
```

#### Step 4: Check Shell Function/Alias Override

```bash
# ✅ Check if it's an alias
alias mybinary
# alias mybinary='echo "This is an alias"'

# ✅ Check if it's a function
declare -f mybinary

# ✅ Bypass alias/function temporarily
\mybinary # Run actual binary, not alias
command mybinary # Run actual command
```

#### Step 5: Check Executable Bit

```bash
# ❌ File exists but not executable
$ ls -la /usr/local/bin/mybinary
-rw-r--r-- 1 root root 12345 Nov 9 10:00 /usr/local/bin/mybinary

# ✅ Make it executable
sudo chmod +x /usr/local/bin/mybinary

# ✅ Now it works
$ mybinary
```

### Common Scenarios

#### Scenario 1: Just Installed Software

```bash
# ❌ Installed but command not found
sudo apt install nodejs
node --version
# bash: node: command not found

# ✅ Check if it installed with different name
which nodejs # /usr/bin/nodejs (old Debian/Ubuntu)

# ✅ Solution: Create symlink
sudo ln -s /usr/bin/nodejs /usr/bin/node

# ✅ Or: Use alternatives
sudo update-alternatives --install /usr/bin/node node /usr/bin/nodejs 1
```

#### Scenario 2: Custom Installation

```bash
# ❌ Compiled from source, installed to non-standard location
./configure --prefix=/opt/myapp
make && sudo make install
myapp
# bash: myapp: command not found

# ✅ Check installation directory
ls -la /opt/myapp/bin/
# -rwxr-xr-x 1 root root 98765 Nov 9 10:00 myapp

# ✅ Solution 1: Use full path
/opt/myapp/bin/myapp

# ✅ Solution 2: Add to PATH (session)
export PATH="/opt/myapp/bin:$PATH"

# ✅ Solution 3: Add to PATH (permanent)
echo 'export PATH="/opt/myapp/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Scenario 3: User-Specific Installation

```bash
# ❌ Installed to user directory, but not in PATH
pip install --user mypackage
mytool
# bash: mytool: command not found

# ✅ Check user bin directory
ls -la ~/.local/bin/mytool
# -rwxr-xr-x 1 user user 5432 Nov 9 10:00 /home/user/.local/bin/mytool

# ✅ Add user bin to PATH
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc
```

#### Scenario 4: Shell Refresh Needed

```bash
# ❌ Just installed, but shell hasn't refreshed
sudo apt install mycmd
mycmd
# bash: mycmd: command not found

# ✅ Refresh shell's command cache
hash -r # bash/zsh
rehash # zsh

# ✅ Or: Open new shell
exec bash
```

---

## Permission Denied Errors

### Error Message

```bash
# ❌ Permission denied
$./script.sh
bash:./script.sh: Permission denied
```

### Troubleshooting Workflow

#### Step 1: Check Permissions

```bash
# ✅ Check file permissions
ls -la script.sh
# -rw-r--r-- 1 user user 156 Nov 9 10:00 script.sh
# No 'x' = not executable

# ✅ Make executable
chmod +x script.sh
# -rwxr-xr-x 1 user user 156 Nov 9 10:00 script.sh
```

#### Step 2: Check Ownership

```bash
# ❌ File owned by another user
ls -la /usr/local/bin/mytool
# -rwx------ 1 otheruser otheruser 12345 Nov 9 10:00 /usr/local/bin/mytool
# Only otheruser can execute

# ✅ Solution 1: Change ownership
sudo chown $USER:$USER /usr/local/bin/mytool

# ✅ Solution 2: Add group permissions
sudo chmod 750 /usr/local/bin/mytool # Owner + group can execute
sudo chgrp mygroup /usr/local/bin/mytool
```

#### Step 3: Check Mount Options

```bash
# ❌ Filesystem mounted with noexec
mount | grep /home
# /dev/sda1 on /home type ext4 (rw,noexec,relatime)

# ✅ Remount without noexec (temporary)
sudo mount -o remount,exec /home

# ✅ Fix permanently in /etc/fstab
# Change:
# /dev/sda1 /home ext4 defaults,noexec 0 2
# To:
# /dev/sda1 /home ext4 defaults 0 2
```

#### Step 4: Check SELinux/AppArmor

```bash
# ✅ Check SELinux status
getenforce
# Enforcing

# ✅ Check SELinux context
ls -Z /usr/local/bin/mybinary
# -rwxr-xr-x. root root unconfined_u:object_r:user_home_t:s0 mybinary

# ✅ Fix SELinux context
sudo restorecon -v /usr/local/bin/mybinary
# OR
sudo chcon -t bin_t /usr/local/bin/mybinary

# ✅ Check AppArmor status
sudo aa-status

# ✅ Temporarily disable for testing
sudo aa-complain /usr/bin/mybinary
```

### Common Scenarios

#### Scenario 1: Downloaded Script

```bash
# ❌ Downloaded script not executable
wget https://example.com/install.sh
./install.sh
# bash:./install.sh: Permission denied

# ✅ Make executable and run
chmod +x install.sh
./install.sh
```

#### Scenario 2: Copied from Windows

```bash
# ❌ Copied from NTFS/FAT32 filesystem
cp /mnt/usb/script.sh.
./script.sh
# bash:./script.sh: Permission denied

# ✅ Check permissions
ls -la script.sh
# -rw-r--r-- 1 user user 256 Nov 9 10:00 script.sh

# ✅ Fix
chmod +x script.sh
```

#### Scenario 3: Sudo Required

```bash
# ❌ System binary requires root
/usr/sbin/iptables -L
# bash: /usr/sbin/iptables: Permission denied

# ✅ Run with sudo
sudo /usr/sbin/iptables -L
```

---

## Bad Interpreter Errors

### Error Message

```bash
# ❌ Bad interpreter
$./script.sh
bash:./script.sh: /bin/bash: bad interpreter: No such file or directory
```

### Troubleshooting Workflow

#### Step 1: Check Shebang

```bash
# ✅ View the shebang line
head -n 1 script.sh
# #!/bin/bash

# ✅ Check if interpreter exists
ls -la /bin/bash
# -rwxr-xr-x 1 root root 1234567 Jan 1 2024 /bin/bash
```

#### Step 2: Common Shebang Issues

```bash
# ❌ Wrong path
#!/usr/bin/python
# But Python is at /usr/bin/python3

# ✅ Solution 1: Fix shebang
#!/usr/bin/python3

# ✅ Solution 2: Use env for portability
#!/usr/bin/env python3

# ❌ Windows line endings
$ cat -A script.sh
#!/bin/bash^M$
echo "Hello"^M$

# ✅ Remove Windows line endings
dos2unix script.sh
# OR
sed -i 's/\r$//' script.sh
```

#### Step 3: Check Interpreter Installation

```bash
# ❌ Interpreter not installed
#!/usr/bin/python3
# python3: No such file or directory

# ✅ Find where Python is installed
which python3
whereis python3

# ✅ If not installed
sudo apt install python3

# ✅ If installed elsewhere, use env
#!/usr/bin/env python3
```

### Common Scenarios

#### Scenario 1: Script from Different Distribution

```bash
# ❌ Script expects bash at /bin/bash
# But your system has it at /usr/bin/bash

# ✅ Solution 1: Create symlink
sudo ln -s /usr/bin/bash /bin/bash

# ✅ Solution 2: Use env
sed -i '1s|^#!/bin/bash|#!/usr/bin/env bash|' script.sh
```

#### Scenario 2: Python 2 vs Python 3

```bash
# ❌ Script uses Python 2 shebang
#!/usr/bin/python

# ✅ Check what 'python' is
ls -la /usr/bin/python
# lrwxrwxrwx 1 root root 7 Nov 9 10:00 /usr/bin/python -> python3

# ✅ Or: Update script for Python 3
sed -i '1s|python|python3|' script.py
```

#### Scenario 3: Custom Interpreter Path

```bash
# ❌ Node.js at non-standard location
#!/usr/local/bin/node

# ✅ Find actual location
which node
# /usr/bin/node

# ✅ Update shebang
#!/usr/bin/env node
```

---

## Wrong Version Executing

### Problem: Unexpected Version Runs

```bash
# ❌ Expecting Python 3.11, but getting 3.9
$ python3 --version
Python 3.9.2

# But you installed 3.11:
$ /usr/local/bin/python3.11 --version
Python 3.11.0
```

### Troubleshooting Workflow

#### Step 1: Check Which Binary Executes

```bash
# ✅ Find what 'python3' resolves to
which python3
# /usr/bin/python3

# ✅ Check if it's a symlink
ls -la /usr/bin/python3
# lrwxrwxrwx 1 root root 9 Nov 9 10:00 /usr/bin/python3 -> python3.9

# ✅ See all Python binaries
ls -la /usr/bin/python* /usr/local/bin/python*
```

#### Step 2: Check PATH Order

```bash
# ✅ Display PATH
echo $PATH
# /usr/local/bin:/usr/bin:/bin

# First match wins:
# /usr/local/bin/python3 (if exists) executes BEFORE
# /usr/bin/python3
```

#### Step 3: Check Alternatives

```bash
# ✅ Check if alternatives system is managing it
update-alternatives --display python3

# ✅ Change alternative
sudo update-alternatives --config python3
```

### Common Scenarios

#### Scenario 1: Multiple Installations

```bash
# ❌ Both system and custom Python installed
/usr/bin/python3 # 3.9 (system)
/usr/local/bin/python3 # 3.11 (custom)

# ✅ Solution 1: Adjust PATH
export PATH="/usr/local/bin:$PATH"

# ✅ Solution 2: Use specific version
python3.11 script.py

# ✅ Solution 3: Create alias
alias python3='/usr/local/bin/python3.11'
```

#### Scenario 2: Virtual Environment

```bash
# ❌ Expecting system Python but venv is active
$ which python
/home/user/venv/bin/python

# ✅ Deactivate venv
deactivate

# ✅ Or: Use absolute path
/usr/bin/python3 script.py
```

#### Scenario 3: Hash Cache

```bash
# ❌ Upgraded binary but old version still runs
which python3
# /usr/local/bin/python3

python3 --version
# Python 3.9.2 (old version!)

# ✅ Clear shell's hash cache
hash -r # bash
rehash # zsh

python3 --version
# Python 3.11.0 (new version)
```

---

## Text File Busy Errors

### Error Message

```bash
# ❌ Cannot modify running binary
$ sudo cp newbinary /usr/bin/mybinary
cp: cannot create regular file '/usr/bin/mybinary': Text file busy
```

### Troubleshooting Workflow

#### Step 1: Check Running Processes

```bash
# ✅ Find processes using the binary
lsof /usr/bin/mybinary
# COMMAND PID USER FD TYPE DEVICE SIZE/OFF NODE NAME
# mybinary 1234 user txt REG 8,1 12345 98765 /usr/bin/mybinary

# ✅ Or use fuser
fuser /usr/bin/mybinary
# /usr/bin/mybinary: 1234
```

#### Step 2: Stop Processes

```bash
# ✅ Kill the process
kill 1234

# ✅ Or: Kill all processes using file
fuser -k /usr/bin/mybinary

# ✅ Force kill if needed
kill -9 1234
```

#### Step 3: Update Binary

```bash
# ✅ Method 1: Remove then copy
sudo rm /usr/bin/mybinary
sudo cp newbinary /usr/bin/mybinary

# ✅ Method 2: Move aside, then copy
sudo mv /usr/bin/mybinary /usr/bin/mybinary.old
sudo cp newbinary /usr/bin/mybinary

# ✅ Method 3: Use install command
sudo install -m 755 newbinary /usr/bin/mybinary
```

### Common Scenarios

#### Scenario 1: Updating System Service

```bash
# ❌ Service is running
sudo systemctl status myservice
# Active: active (running)

sudo cp newbinary /usr/bin/myservice
# cp: Text file busy

# ✅ Stop service first
sudo systemctl stop myservice
sudo cp newbinary /usr/bin/myservice
sudo systemctl start myservice
```

#### Scenario 2: Updating Shell Binary

```bash
# ❌ Trying to update bash while using it
sudo cp newbash /bin/bash
# cp: Text file busy

# ✅ Solution: Use different shell temporarily
sudo sh -c 'cp newbash /bin/bash'
```

---

## Cannot Execute Binary File

### Error Message

```bash
# ❌ Wrong architecture
$./mybinary
bash:./mybinary: cannot execute binary file: Exec format error
```

### Troubleshooting Workflow

#### Step 1: Check File Type

```bash
# ✅ Check what kind of file it is
file mybinary
# mybinary: ELF 64-bit LSB executable, x86-64, version 1 (SYSV)

# ✅ Check system architecture
uname -m
# x86_64

# ❌ Mismatch example
file mybinary
# mybinary: ELF 32-bit LSB executable, ARM
uname -m
# x86_64 ← Can't run ARM binary on x86
```

#### Step 2: Check for Script Issues

```bash
# ✅ If it's supposed to be a script
file script.sh
# script.sh: ASCII text

# ✅ Check shebang
head -n 1 script.sh
# #!/bin/bash

# ✅ Make sure it's executable
chmod +x script.sh
```

#### Step 3: Check Dependencies

```bash
# ✅ Check required libraries (for ELF binaries)
ldd mybinary
# linux-vdso.so.1 => (0x00007ffd5e3f7000)
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6 (0x00007f8b5e3f7000)
# /lib64/ld-linux-x86-64.so.2 (0x00007f8b5e7f9000)

# ❌ Missing library
ldd mybinary
# libmissing.so.1 => not found
```

### Common Scenarios

#### Scenario 1: Downloaded Wrong Architecture

```bash
# ❌ Downloaded ARM binary on x86 system
wget https://example.com/tool-arm64
chmod +x tool-arm64
./tool-arm64
# bash: cannot execute binary file

# ✅ Download correct architecture
wget https://example.com/tool-amd64
chmod +x tool-amd64
./tool-amd64 # Works
```

#### Scenario 2: 32-bit Binary on 64-bit System

```bash
# ❌ 32-bit binary on 64-bit system without multilib
file mybinary
# mybinary: ELF 32-bit LSB executable

./mybinary
# bash: cannot execute binary file

# ✅ Install 32-bit compatibility libraries
sudo apt install libc6:i386 # Debian/Ubuntu
sudo dnf install glibc.i686 # RHEL/Fedora

./mybinary # Now works
```

#### Scenario 3: Script Without Shebang

```bash
# ❌ Script file without shebang
cat script
# echo "Hello"

./script
# bash:./script: cannot execute binary file

# ✅ Add shebang
echo '#!/bin/bash' | cat - script > temp && mv temp script
chmod +x script
./script
# Hello
```

---

## Debugging Tools

### which - Find Command Location

```bash
# ✅ Basic usage
which python3
# /usr/bin/python3

# ✅ Show all matches in PATH
which -a python3
# /usr/bin/python3
# /usr/local/bin/python3

# ❌ Doesn't find aliases/functions
alias myalias='echo test'
which myalias
# (no output)
```

### type - Comprehensive Command Info

```bash
# ✅ Shows command type
type python3
# python3 is /usr/bin/python3

type ls
# ls is aliased to `ls --color=auto'

type cd
# cd is a shell builtin

# ✅ Show all definitions
type -a python3
# python3 is /usr/bin/python3
# python3 is /usr/local/bin/python3
```

### whereis - Find Binary, Source, and Manual

```bash
# ✅ Find all related files
whereis python3
# python3: /usr/bin/python3 /usr/lib/python3 /etc/python3 /usr/share/man/man1/python3.1.gz

# ✅ Only binaries
whereis -b python3
# python3: /usr/bin/python3

# ✅ Only manuals
whereis -m python3
# python3: /usr/share/man/man1/python3.1.gz
```

### command -v - POSIX-Compliant Check

```bash
# ✅ Portable way to check if command exists
if command -v python3 >/dev/null 2>&1; then
 echo "Python 3 is installed"
fi

# ✅ Get path
command -v python3
# /usr/bin/python3
```

### file - Identify File Type

```bash
# ✅ Check file type
file /usr/bin/python3
# /usr/bin/python3: ELF 64-bit LSB executable

file script.sh
# script.sh: Bourne-Again shell script, ASCII text executable

file /usr/bin/node
# /usr/bin/node: symbolic link to../lib/nodejs/bin/node

# ✅ Follow symlinks
file -L /usr/bin/node
# /usr/bin/node: ELF 64-bit LSB executable
```

### ldd - List Dynamic Dependencies

```bash
# ✅ Show required libraries
ldd /usr/bin/python3
# linux-vdso.so.1 => (0x00007ffd...)
# libpython3.10.so.1.0 => /lib/x86_64-linux-gnu/libpython3.10.so.1.0
# libc.so.6 => /lib/x86_64-linux-gnu/libc.so.6
# /lib64/ld-linux-x86-64.so.2

# ❌ Missing dependency
ldd mybinary
# libmissing.so.1 => not found

# ⚠️ Never run ldd on untrusted binaries
# Use objdump instead:
objdump -p mybinary | grep NEEDED
```

### strace - Trace System Calls

```bash
# ✅ See what a command is doing
strace -e trace=open,openat ls
# Shows all file open operations

# ✅ Trace specific system calls
strace -e trace=execve mybinary
# Shows all programs executed

# ✅ Save to file
strace -o trace.log mybinary

# ✅ Trace running process
strace -p 1234 # PID
```

### ltrace - Library Call Tracer

```bash
# ✅ Trace library calls
ltrace mybinary

# ✅ Trace specific library
ltrace -l libmylibrary.so mybinary

# ✅ Count calls
ltrace -c mybinary
```

---

## PATH Debugging

### Check Current PATH

```bash
# ✅ Display PATH with line breaks
echo $PATH | tr ':' '\n'
# /usr/local/bin
# /usr/bin
# /bin
# /usr/local/sbin
# /usr/sbin
# /sbin

# ✅ Number the directories
echo $PATH | tr ':' '\n' | nl
# 1 /usr/local/bin
# 2 /usr/bin
# 3 /bin
```

### Test PATH Resolution

```bash
# ✅ See which binary will execute
type -a python3
# python3 is /usr/local/bin/python3
# python3 is /usr/bin/python3

# ✅ Test specific PATH
env PATH=/usr/bin:/bin which python3
# /usr/bin/python3
```

### Find All Binaries in PATH

```bash
# ✅ List all executables in PATH
for dir in $(echo $PATH | tr ':' '\n'); do
 ls -la "$dir" 2>/dev/null | grep -v '^d'
done

# ✅ Find specific pattern
for dir in $(echo $PATH | tr ':' '\n'); do
 find "$dir" -maxdepth 1 -name 'python*' 2>/dev/null
done
```

### Debug PATH Issues

```bash
# ✅ Check if directory is in PATH
echo $PATH | grep -q "/opt/myapp/bin" && echo "Found" || echo "Not found"

# ✅ See PATH modification history
# Add to ~/.bashrc:
export PROMPT_COMMAND='echo "PATH modified: $PATH" >> ~/path_log.txt'

# ✅ Find duplicate entries in PATH
echo $PATH | tr ':' '\n' | sort | uniq -d
```

---

## Command Hash Issues

### Understanding Command Hashing

```bash
# ✅ Shells cache command locations for performance
type -a python3
# python3 is hashed (/usr/bin/python3)

# ✅ View hash table
hash
# hits command
# 5 /usr/bin/python3
# 2 /usr/bin/ls
```

### Clearing Hash Cache

```bash
# ✅ Clear all hashes
hash -r # bash/zsh

# ✅ Clear specific command
hash -d python3

# ✅ Verify it's cleared
hash
# (empty or without python3)
```

### Common Hash Problems

```bash
# ❌ Upgraded binary but old version runs
sudo apt upgrade python3
python3 --version
# Python 3.9.0 (old version cached)

# ✅ Clear hash
hash -r
python3 --version
# Python 3.11.0 (new version)
```

---

## Script Debugging

### Bash Debug Mode

```bash
# ✅ Run script with debug output
bash -x script.sh
# + echo 'Starting script'
# Starting script
# + command1
# + command2

# ✅ Enable debug mode within script
#!/bin/bash
set -x # Enable debug
# commands here
set +x # Disable debug
```

### Error Checking

```bash
# ✅ Exit on error
#!/bin/bash
set -e # Exit immediately if command fails

# ✅ Exit on undefined variable
set -u # Exit if using undefined variable

# ✅ Pipe failure detection
set -o pipefail # Exit if any command in pipe fails

# ✅ Combined (common practice)
set -euo pipefail
```

### Verbose Mode

```bash
# ✅ Print commands before execution
bash -v script.sh

# ✅ In script
#!/bin/bash
set -v
```

---

## Common Issues Reference

### Issue 1: Command Not Found After Installation

**Symptoms**: Just installed package, command not found

**Solutions**:
```bash
# 1. Refresh shell
hash -r
# 2. Check PATH
which newcommand
# 3. Restart shell
exec bash
```

### Issue 2: Permission Denied on Executable File

**Symptoms**: File is executable but still permission denied

**Solutions**:
```bash
# 1. Check mount options
mount | grep noexec
# 2. Check SELinux
getenforce
# 3. Check AppArmor
sudo aa-status
```

### Issue 3: Wrong Shebang

**Symptoms**: Bad interpreter error

**Solutions**:
```bash
# 1. Use env for portability
#!/usr/bin/env python3
# 2. Check interpreter exists
which python3
# 3. Remove Windows line endings
dos2unix script.sh
```

### Issue 4: Library Not Found

**Symptoms**: error while loading shared libraries

**Solutions**:
```bash
# 1. Check dependencies
ldd mybinary
# 2. Update library cache
sudo ldconfig
# 3. Add library path
export LD_LIBRARY_PATH=/path/to/libs:$LD_LIBRARY_PATH
```

### Issue 5: Multiple Versions Conflict

**Symptoms**: Wrong version executes

**Solutions**:
```bash
# 1. Use full path
/usr/local/bin/python3.11
# 2. Use alternatives
sudo update-alternatives --config python3
# 3. Adjust PATH order
export PATH="/usr/local/bin:$PATH"
```

This comprehensive troubleshooting guide provides systematic approaches to diagnose and fix the most common binary execution issues on Linux systems.
