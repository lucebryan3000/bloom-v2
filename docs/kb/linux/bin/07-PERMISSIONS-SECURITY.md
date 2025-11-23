---
id: linux-07-permissions-security
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

# 07-PERMISSIONS-SECURITY.md - Permissions and Security

## Table of Contents
1. [Unix File Permissions Overview](#unix-file-permissions-overview)
2. [chmod Command](#chmod-command)
3. [Making Scripts Executable](#making-scripts-executable)
4. [Ownership (chown, chgrp)](#ownership-chown-chgrp)
5. [Security Implications of Executable Permissions](#security-implications-of-executable-permissions)
6. [PATH Security](#path-security)
7. [SUID/SGID Special Permissions](#suidsgid-special-permissions)
8. [Linux Capabilities](#linux-capabilities)
9. [Security Best Practices](#security-best-practices)
10. [Avoiding. in PATH](#avoiding--in-path)
11. [Auditing Permissions](#auditing-permissions)

---

## Unix File Permissions Overview

### The Permission Model

Every file and directory in Unix/Linux has three sets of permissions:

```
-rwxr-xr-x
│││││││││└─ Others (everyone else): execute
││││││││└── Others: write
│││││││└─── Others: read
││││││└──── Group: execute
│││││└───── Group: write
││││└────── Group: read
│││└─────── Owner: execute
││└──────── Owner: write
│└───────── Owner: read
└────────── File type (- = regular file, d = directory, l = symlink)
```

### Permission Breakdown

**Three permission types**:
- **r** (read) - Read file contents or list directory
- **w** (write) - Modify file or create/delete files in directory
- **x** (execute) - Execute file or enter directory

**Three permission groups**:
- **User (u)** - File owner
- **Group (g)** - Users in the file's group
- **Others (o)** - Everyone else

### ✅ Reading Permissions

```bash
ls -l script.sh
-rwxr-xr-x 1 luce developers 1024 Nov 9 10:00 script.sh
│││││││││└ Permissions
│ │
│ └─ Owner: luce
│ Group: developers
│ Size: 1024 bytes
│ Date: Nov 9 10:00
│ Name: script.sh
```

**Breaking down `-rwxr-xr-x`**:
- `-` = Regular file
- `rwx` = Owner (luce) can read, write, execute
- `r-x` = Group (developers) can read and execute (not write)
- `r-x` = Others can read and execute (not write)

### Common Permission Patterns

| Permissions | Octal | Meaning | Use Case |
|-------------|-------|---------|----------|
| `-rw-------` | 600 | Owner read/write only | Private files, SSH keys |
| `-rw-r--r--` | 644 | Owner write, all read | Regular files |
| `-rwxr-xr-x` | 755 | Owner write, all execute | Scripts, programs |
| `-rwx------` | 700 | Owner only, all perms | Private scripts |
| `drwxr-xr-x` | 755 | Directory, standard | Most directories |
| `drwx------` | 700 | Private directory | ~/.ssh, private dirs |

### File vs Directory Permissions

**For files**:
- `r` - Read file contents
- `w` - Modify or delete file
- `x` - Execute as program

**For directories**:
- `r` - List directory contents (`ls`)
- `w` - Create/delete files in directory
- `x` - Enter directory (`cd`) and access files

### ✅ Example: Directory Permissions Matter

```bash
# Create directory and file
mkdir test
touch test/file.txt
chmod 644 test/file.txt

# Make file readable
ls -l test/file.txt
-rw-r--r-- 1 luce luce 0 Nov 9 10:00 test/file.txt

# Remove execute from directory
chmod 644 test

# Can list directory
ls test
file.txt

# But can't access the file!
cat test/file.txt
# cat: test/file.txt: Permission denied

# Why? No 'x' on directory means can't access files inside
ls -ld test
drw-r--r-- 2 luce luce 4096 Nov 9 10:00 test
# ^ missing 'x'

# Fix: restore execute
chmod 755 test
cat test/file.txt # Now works
```

---

## chmod Command

### Symbolic Mode

**Syntax**: `chmod [who][op][perms] file`

**Who**:
- `u` - User (owner)
- `g` - Group
- `o` - Others
- `a` - All (user + group + others)

**Operation**:
- `+` - Add permission
- `-` - Remove permission
- `=` - Set exact permission

**Permissions**:
- `r` - Read
- `w` - Write
- `x` - Execute

### ✅ Symbolic Mode Examples

```bash
# Add execute for owner
chmod u+x script.sh

# Remove write for group and others
chmod go-w file.txt

# Add execute for all
chmod a+x script.sh
chmod +x script.sh # 'a' is implied

# Set exact permissions: owner=rwx, group=rx, others=rx
chmod u=rwx,g=rx,o=rx script.sh

# Remove all permissions for others
chmod o= file.txt

# Add read for group, remove write for others
chmod g+r,o-w file.txt
```

### Octal Mode

**Syntax**: `chmod [octal] file`

**Octal digits** (sum of values):
- `4` = read (r)
- `2` = write (w)
- `1` = execute (x)

**Three digits**: [user][group][others]

### ✅ Octal Mode Examples

```bash
# 755 = rwxr-xr-x
chmod 755 script.sh
# 7 (4+2+1) = user: rwx
# 5 (4+1) = group: r-x
# 5 (4+1) = others: r-x

# 644 = rw-r--r--
chmod 644 file.txt
# 6 (4+2) = user: rw-
# 4 = group: r--
# 4 = others: r--

# 700 = rwx------
chmod 700 private-script.sh
# 7 (4+2+1) = user: rwx
# 0 = group: ---
# 0 = others: ---

# 600 = rw-------
chmod 600 ~/.ssh/id_rsa
# 6 (4+2) = user: rw-
# 0 = group: ---
# 0 = others: ---
```

### Octal Calculation Table

| Octal | Binary | Symbolic | Calculation |
|-------|--------|----------|-------------|
| 0 | 000 | `---` | 0+0+0 |
| 1 | 001 | `--x` | 0+0+1 |
| 2 | 010 | `-w-` | 0+2+0 |
| 3 | 011 | `-wx` | 0+2+1 |
| 4 | 100 | `r--` | 4+0+0 |
| 5 | 101 | `r-x` | 4+0+1 |
| 6 | 110 | `rw-` | 4+2+0 |
| 7 | 111 | `rwx` | 4+2+1 |

### ✅ When to Use Which Mode

**Use symbolic mode when**:
- Modifying existing permissions (`+x`, `-w`)
- Making small changes
- Don't know current permissions

**Use octal mode when**:
- Setting exact permissions
- Setting permissions for new files
- Scripting (more concise)

```bash
# Symbolic: add execute, preserves other permissions
chmod +x script.sh

# Octal: set exact permissions
chmod 755 script.sh
```

### Recursive chmod

```bash
# Apply to directory and all contents
chmod -R 755 mydir/

# Be careful with recursive! Can break things:
chmod -R 777 ~/ # ❌ NEVER DO THIS
```

### ❌ Common chmod Mistakes

**1. Wrong octal digits**:
```bash
chmod 777 file.txt # ❌ Too permissive!
chmod 655 script.sh # ❌ No execute, can't run
chmod 755 ~/.ssh/id_rsa # ❌ Private key too permissive
```

**2. Forgetting to make executable**:
```bash
cat > script.sh << 'EOF'
#!/bin/bash
echo "Hello"
EOF

./script.sh # ❌ Permission denied
chmod +x script.sh
./script.sh # ✅ Works
```

**3. Too permissive**:
```bash
chmod 777 file.txt # ❌ Anyone can read/write/execute
chmod 755 secrets.txt # ❌ Everyone can read secrets
```

---

## Making Scripts Executable

### The Right Way

```bash
# Create script
cat > myscript.sh << 'EOF'
#!/bin/bash
echo "Hello, World!"
EOF

# Make executable
chmod +x myscript.sh

# Run it
./myscript.sh
```

### ✅ Three Methods to Run Scripts

**1. Make executable and run directly** (best):
```bash
chmod +x script.sh
./script.sh
```

**2. Explicitly call interpreter**:
```bash
bash script.sh # Ignores shebang
python3 script.py # Ignores shebang
```

**3. Source the script** (runs in current shell):
```bash
source script.sh
. script.sh # Same as source
```

### When to Use Each Method

**Direct execution** (`./script.sh`):
- ✅ Respects shebang
- ✅ Runs in subshell (safe)
- ✅ Professional/standard approach
- ❌ Requires execute permission

**Explicit interpreter** (`bash script.sh`):
- ✅ No execute permission needed
- ✅ Override shebang if needed
- ❌ Doesn't respect shebang
- ❌ Must know correct interpreter

**Source** (`source script.sh`):
- ✅ Runs in current shell
- ✅ Can modify environment
- ❌ Changes affect current shell
- ❌ Less safe

### ✅ Example: Why Sourcing Matters

```bash
# Script that exports variable
cat > setvar.sh << 'EOF'
#!/bin/bash
export MY_VAR="hello"
echo "Variable set"
EOF

# Run normally (subshell)
chmod +x setvar.sh
./setvar.sh
echo $MY_VAR
# (empty - variable was in subshell)

# Source (current shell)
source setvar.sh
echo $MY_VAR
# hello - variable is in current shell
```

### Execute Permission Levels

```bash
# Owner only can execute
chmod 700 script.sh
chmod u+x script.sh

# Owner and group can execute
chmod 750 script.sh
chmod u+x,g+x script.sh

# Everyone can execute
chmod 755 script.sh
chmod a+x script.sh
chmod +x script.sh # Same (a is default)
```

### ✅ Best Practices for Script Permissions

**Personal scripts in ~/bin**:
```bash
chmod 755 ~/bin/myscript
# You can modify, everyone can execute
```

**Private scripts**:
```bash
chmod 700 ~/bin/private-script
# Only you can run
```

**Shared team scripts**:
```bash
chmod 775 /opt/team/scripts/deploy
chgrp developers /opt/team/scripts/deploy
# Owner and developers group can modify and execute
```

---

## Ownership (chown, chgrp)

### Understanding Ownership

Every file has:
- **Owner** (user) - Usually creator
- **Group** - Usually creator's primary group

```bash
ls -l script.sh
-rwxr-xr-x 1 luce developers 1024 Nov 9 10:00 script.sh
# │ │
# │ └─ Group: developers
# └────── Owner: luce
```

### chown - Change Owner

**Syntax**: `chown [user][:group] file`

```bash
# Change owner only
sudo chown alice file.txt

# Change owner and group
sudo chown alice:developers file.txt

# Change owner, keep current group
sudo chown alice: file.txt
```

**✅ Examples**:
```bash
# Change ownership of file
sudo chown bob script.sh

# Change ownership of directory and contents
sudo chown -R alice /var/www/html

# Change owner and group together
sudo chown alice:www-data /var/www/html/index.html
```

### chgrp - Change Group

**Syntax**: `chgrp group file`

```bash
# Change group only
chgrp developers file.txt

# Recursive
chgrp -R developers project/
```

**✅ Examples**:
```bash
# Change group of shared script
chgrp developers /opt/scripts/deploy.sh

# Allow group to execute
chmod g+x /opt/scripts/deploy.sh

# Now all developers can run it
```

### ❌ Common Ownership Mistakes

**1. Forgetting sudo**:
```bash
chown alice file.txt
# chown: changing ownership of 'file.txt': Operation not permitted

# Fix:
sudo chown alice file.txt
```

**2. Wrong user/group**:
```bash
sudo chown bob:developers file.txt
# chown: invalid user: 'bob:developers'
# User 'bob' doesn't exist

# Fix: check user exists
id bob
cat /etc/passwd | grep bob
```

**3. Breaking permissions**:
```bash
# Make file owned by root
sudo chown root:root ~/.ssh/id_rsa

# Now you can't use your SSH key!
ssh server
# Permission denied (publickey)

# Fix:
sudo chown $USER:$USER ~/.ssh/id_rsa
chmod 600 ~/.ssh/id_rsa
```

### ✅ Checking Ownership

```bash
# See owner and group
ls -l file.txt
-rw-r--r-- 1 luce developers 0 Nov 9 10:00 file.txt

# See numeric UID/GID
ls -ln file.txt
-rw-r--r-- 1 1000 1000 0 Nov 9 10:00 file.txt

# Find files owned by user
find /home -user luce

# Find files owned by group
find /opt -group developers
```

---

## Security Implications of Executable Permissions

### Why Execute Permission Matters

**With execute permission**:
```bash
-rwxr-xr-x script.sh
# Anyone can run this script
# Script runs with permissions of the user who executes it
```

**Without execute permission**:
```bash
-rw-r--r-- script.sh
./script.sh # Permission denied
# Must use: bash script.sh (less secure, bypasses shebang)
```

### ✅ Principle of Least Privilege

**Give minimum permissions needed**:
```bash
# ❌ Too permissive
chmod 777 script.sh # Anyone can modify AND execute

# ✅ Better
chmod 755 script.sh # You can modify, others can execute

# ✅ Even better for private script
chmod 700 script.sh # Only you can run
```

### Executable Files Security Risks

**Risk 1: Malicious modification**:
```bash
# If script is world-writable
-rwxrwxrwx script.sh # ❌ DANGER

# Attacker can modify it:
echo "rm -rf ~/*" >> script.sh

# Next time you run it:
./script.sh # Your files are deleted!

# ✅ Fix: remove write permissions for others
chmod 755 script.sh
```

**Risk 2: Directory permissions**:
```bash
# Even if script isn't writable, directory might be!
drwxrwxrwx scripts/ # ❌ DANGER
-rwxr-xr-x scripts/deploy.sh

# Attacker can:
rm scripts/deploy.sh
cat > scripts/deploy.sh << 'EOF'
#!/bin/bash
# Malicious code
EOF
chmod +x scripts/deploy.sh

# ✅ Fix: secure directory too
chmod 755 scripts/
```

**Risk 3: Script reads user input**:
```bash
#!/bin/bash
# ❌ Dangerous script
echo "Enter filename to delete:"
read filename
rm "$filename"

# Attacker runs:
./script.sh
# Enter filename to delete: ~/*
# All files deleted!

# ✅ Fix: validate input
#!/bin/bash
echo "Enter filename to delete:"
read filename

# Validate input
if [[ "$filename" =~ ^[a-zA-Z0-9._-]+$ ]]; then
 rm "$filename"
else
 echo "Invalid filename"
 exit 1
fi
```

### ✅ Security Best Practices

**1. Scripts in ~/bin should be 755 or 700**:
```bash
# Public scripts (safe to share)
chmod 755 ~/bin/public-script

# Private scripts (secrets, API keys)
chmod 700 ~/bin/private-script
```

**2. Never make data files executable**:
```bash
# ❌ Wrong
chmod 755 data.txt
chmod 755 config.json

# ✅ Correct
chmod 644 data.txt
chmod 644 config.json
```

**3. Secure entire directory**:
```bash
# Set directory permissions
chmod 755 ~/bin

# Set default permissions for files
chmod 644 ~/bin/*

# Set execute only for scripts
chmod +x ~/bin/*.sh
```

**4. Check before running unknown scripts**:
```bash
# ❌ Dangerous
curl https://site.com/install.sh | bash

# ✅ Safer
curl -o install.sh https://site.com/install.sh
cat install.sh # Review contents!
chmod +x install.sh
./install.sh
```

---

## PATH Security

### The PATH Attack Vector

**How PATH works**:
1. You type a command: `ls`
2. Shell searches PATH directories in order
3. Runs first matching executable found

**Attack**: Inject malicious directory at start of PATH

### ❌ PATH Hijacking Attack

**Setup (attacker)**:
```bash
# Create malicious 'ls' in /tmp
cat > /tmp/ls << 'EOF'
#!/bin/bash
echo "Stealing your passwords..."
cat ~/.ssh/id_rsa > /tmp/stolen_key
/bin/ls "$@" # Run real ls so user doesn't notice
EOF
chmod +x /tmp/ls

# Trick user into adding /tmp to PATH
export PATH="/tmp:$PATH"
```

**Victim runs**:
```bash
ls
# Stealing your passwords...
# (appears to work normally, but SSH key stolen!)
```

### ✅ PATH Security Rules

**1. Never put current directory (.) in PATH**:
```bash
# ❌ NEVER DO THIS
export PATH=".:$PATH"

# Why dangerous:
cd /tmp/untrusted
ls # Might run /tmp/untrusted/ls instead of /bin/ls
```

**2. Never put world-writable directories in PATH**:
```bash
# Check if directory is world-writable
ls -ld /tmp
drwxrwxrwt # ❌ Don't add to PATH

# ❌ NEVER DO THIS
export PATH="/tmp:$PATH"
```

**3. Keep trusted directories first**:
```bash
# ✅ Good order
export PATH="/usr/local/bin:/usr/bin:/bin:$HOME/bin"

# ❌ Bad order (untrusted first)
export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin"
# If ~/bin is writable by others, they can hijack commands
```

**4. Restrict PATH in cron jobs**:
```bash
# Cron has minimal PATH by default
# ✅ Explicitly set in crontab
PATH=/usr/local/bin:/usr/bin:/bin

# Or use absolute paths
0 2 * * * /usr/bin/backup-script
```

### Detecting PATH Hijacking

**✅ Check your PATH**:
```bash
echo $PATH
/home/luce/bin:/usr/local/bin:/usr/bin:/bin

# Check each directory's permissions
echo $PATH | tr ':' '\n' | while read dir; do
 ls -ld "$dir" 2>/dev/null || echo "Missing: $dir"
done
```

**✅ Verify command location**:
```bash
# Which command will actually run?
which ls
/bin/ls # ✅ System ls

type ls
ls is /bin/ls # ✅ Good

# See all matches
type -a ls
ls is /bin/ls # Only one match ✅
```

**✅ Check for suspicious files**:
```bash
# Look for common commands in unusual places
for cmd in ls cd cat grep; do
 echo "$cmd:"
 type -a "$cmd"
done
```

### ✅ Secure PATH Configuration

**In ~/.bashrc**:
```bash
# Start fresh (don't append to existing PATH multiple times)
PATH="/usr/local/bin:/usr/bin:/bin"

# Add safe personal directory
if [ -d "$HOME/bin" ]; then
 # Verify it's owned by you and not world-writable
 if [ "$(stat -c %U "$HOME/bin")" == "$USER" ]; then
 if [ "$(stat -c %a "$HOME/bin")" != "777" ]; then
 PATH="$HOME/bin:$PATH"
 fi
 fi
fi

export PATH
```

### ❌ Common PATH Mistakes

**1. Accidentally prepending**:
```bash
# In ~/.bashrc:
export PATH="$HOME/bin:$PATH"

# Every time you source ~/.bashrc:
source ~/.bashrc
source ~/.bashrc

echo $PATH
/home/luce/bin:/home/luce/bin:/home/luce/bin:/usr/bin...
# Now searching ~/bin three times!

# ✅ Fix: check before adding
if ! echo "$PATH" | grep -q "$HOME/bin"; then
 export PATH="$HOME/bin:$PATH"
fi
```

**2. Trusting shared directories**:
```bash
# ❌ Dangerous
export PATH="/opt/shared/tools:$PATH"

# Check permissions first:
ls -ld /opt/shared/tools
drwxrwxrwx # ❌ World-writable! Anyone can add malicious tools
```

---

## SUID/SGID Special Permissions

### What is SUID?

**SUID** (Set User ID): File runs with owner's permissions, not executor's

```bash
ls -l /usr/bin/passwd
-rwsr-xr-x 1 root root 68208 /usr/bin/passwd
# ^
# └─ 's' instead of 'x' means SUID is set
```

**Why `/usr/bin/passwd` needs SUID**:
- Changing password requires modifying `/etc/shadow`
- `/etc/shadow` is only writable by root
- SUID allows regular users to run `passwd` as root
- `passwd` safely updates shadow file

### ✅ SUID Examples

```bash
# Find SUID files
find /usr/bin -perm -4000 -ls

# Common SUID programs:
-rwsr-xr-x /usr/bin/passwd # Change passwords
-rwsr-xr-x /usr/bin/sudo # Run commands as root
-rwsr-xr-x /usr/bin/su # Switch user
```

### Setting SUID

```bash
# Symbolic mode
chmod u+s script.sh

# Octal mode (4xxx)
chmod 4755 script.sh

# Verify
ls -l script.sh
-rwsr-xr-x 1 luce luce 100 Nov 9 10:00 script.sh
# ^
# └─ 's' means SUID
```

### ❌ SUID Security Risks

**SUID is extremely dangerous if misused!**

```bash
# ❌ NEVER do this
cat > /tmp/bad.sh << 'EOF'
#!/bin/bash
# This script can do ANYTHING as root!
rm -rf /
EOF
sudo chown root:root /tmp/bad.sh
sudo chmod 4755 /tmp/bad.sh

# Now any user can run it as root!
/tmp/bad.sh # Deletes entire system!
```

**⚠️ WARNING**: Only set SUID on programs you fully understand and trust

### What is SGID?

**SGID** (Set Group ID): File runs with group's permissions

**On files**:
```bash
chmod g+s script.sh
# Script runs with group permissions
```

**On directories**:
```bash
chmod g+s /opt/shared
# New files inherit directory's group (not creator's group)
```

### ✅ SGID Directory Example

```bash
# Create shared directory
sudo mkdir /opt/team
sudo chgrp developers /opt/team
sudo chmod 2775 /opt/team
# ^
# └─ 2 sets SGID

# Alice (in developers group) creates file
ls -l /opt/team
drwxrwsr-x 2 root developers 4096 /opt/team
# ^
# └─ 's' means SGID

# Alice creates file
touch /opt/team/file.txt
ls -l /opt/team/file.txt
-rw-r--r-- 1 alice developers 0 /opt/team/file.txt
# ^
# └─ Inherited group from directory!

# Now all developers can access it
```

### Sticky Bit

**Sticky bit** on directory: Only file owner can delete files

```bash
ls -ld /tmp
drwxrwxrwt 10 root root 4096 Nov 9 10:00 /tmp
# ^
# └─ 't' means sticky bit set

# Anyone can create files in /tmp
# But only file owner can delete their files
```

**Setting sticky bit**:
```bash
chmod +t /opt/shared
chmod 1755 /opt/shared # Octal mode
```

### Special Permissions Octal

| Octal | Permission | Effect |
|-------|------------|--------|
| 4000 | SUID | Run as file owner |
| 2000 | SGID | Run as file group (files) or inherit group (directories) |
| 1000 | Sticky | Only owner can delete (directories) |

**Combined**:
```bash
chmod 4755 file # SUID + rwxr-xr-x
chmod 2755 file # SGID + rwxr-xr-x
chmod 1755 dir # Sticky + rwxr-xr-x
chmod 6755 file # SUID + SGID + rwxr-xr-x
```

---

## Linux Capabilities

### What Are Capabilities?

**Capabilities** split root privileges into separate permissions:
- More fine-grained than SUID
- Can grant specific powers without full root

**Example**: Allow binding to port 80 without full root access

### ✅ Using Capabilities Instead of SUID

**Traditional SUID approach** (all or nothing):
```bash
# Give program full root privileges
sudo chown root:root program
sudo chmod 4755 program
# Now runs as root - can do ANYTHING
```

**Capabilities approach** (fine-grained):
```bash
# Give only ability to bind privileged ports
sudo setcap cap_net_bind_service=+ep program
# Now can bind port 80, but nothing else
```

### Common Capabilities

| Capability | Permission |
|-----------|------------|
| `cap_net_bind_service` | Bind to ports < 1024 |
| `cap_net_raw` | Use raw sockets |
| `cap_sys_admin` | Mount filesystems |
| `cap_sys_time` | Set system time |
| `cap_kill` | Send signals to any process |
| `cap_setuid` | Change process UID |

### ✅ Capability Examples

**Check capabilities**:
```bash
# Check program capabilities
getcap /usr/bin/ping
/usr/bin/ping = cap_net_raw+ep

# Check all capabilities in directory
getcap -r /usr/bin
```

**Set capability**:
```bash
# Allow program to bind port 80 without root
sudo setcap cap_net_bind_service=+ep./myserver

# Now it can bind port 80 as regular user:
./myserver --port 80 # Works!
```

**Remove capability**:
```bash
sudo setcap -r./myserver
```

### ✅ Capabilities vs SUID

**Use capabilities when**:
- Need specific privilege (like binding ports)
- Want more security than SUID
- Writing network servers, time services

**Use SUID when**:
- Need full root privileges
- Older systems without capabilities support
- Standard system tools (passwd, sudo)

---

## Security Best Practices

### 1. Default Secure Permissions

**✅ Safe defaults**:
```bash
# Set umask in ~/.bashrc
umask 022
# New files: 644 (rw-r--r--)
# New directories: 755 (rwxr-xr-x)

# More restrictive umask
umask 077
# New files: 600 (rw-------)
# New directories: 700 (rwx------)
```

### 2. Audit Executable Files

```bash
# Find world-writable executables (dangerous!)
find /home -type f -perm -0002 -executable

# Find SUID files (potential risk)
find / -perm -4000 -ls 2>/dev/null

# Find SGID files
find / -perm -2000 -ls 2>/dev/null
```

### 3. Secure Script Storage

```bash
# ✅ Good: protected directory
mkdir ~/bin
chmod 755 ~/bin
chmod 755 ~/bin/*

# ❌ Bad: world-writable directory
chmod 777 ~/scripts # Anyone can modify your scripts!
```

### 4. Validate Script Integrity

```bash
# Create checksums of important scripts
sha256sum ~/bin/* > ~/bin/checksums.txt

# Verify later
sha256sum -c ~/bin/checksums.txt
~/bin/backup: OK
~/bin/deploy: OK
~/bin/fix-perms: FAILED
# ⚠️ Script was modified!
```

### 5. Code Review Unknown Scripts

```bash
# ❌ Never run without reviewing
curl https://example.com/install.sh | bash

# ✅ Always review first
curl -o install.sh https://example.com/install.sh
less install.sh # Review code
chmod +x install.sh
./install.sh
```

### 6. Limit Scope of Scripts

```bash
# ✅ Good: specific, limited script
#!/bin/bash
# Backup only ~/documents
tar -czf backup.tar.gz ~/documents

# ❌ Bad: too powerful, could be misused
#!/bin/bash
# Accepts any directory to delete!
rm -rf "$1"
```

### 7. Use Set Options for Safety

```bash
#!/bin/bash
set -euo pipefail

# -e: Exit on error
# -u: Exit on undefined variable
# -o pipefail: Exit on pipe failure

# Makes scripts fail fast instead of continuing with errors
```

### 8. Sanitize User Input

```bash
# ❌ Dangerous
#!/bin/bash
echo "Enter filename:"
read file
cat "$file" # Could be /etc/passwd!

# ✅ Safe
#!/bin/bash
echo "Enter filename (alphanumeric only):"
read file
if [[ "$file" =~ ^[a-zA-Z0-9._-]+$ ]]; then
 cat "data/$file" # Restricted to data/ directory
else
 echo "Invalid filename"
 exit 1
fi
```

---

## Avoiding. in PATH

### Why. in PATH is Dangerous

**The Problem**:
```bash
# Add current directory to PATH
export PATH=".:$PATH" # ❌ DANGEROUS

# Attacker creates malicious 'ls' in /tmp
cd /tmp
cat > ls << 'EOF'
#!/bin/bash
echo "Stealing data..."
cat ~/.ssh/id_rsa > /tmp/stolen
/bin/ls "$@" # Run real ls
EOF
chmod +x ls

# Victim runs ls
cd /tmp
ls # Runs./ls instead of /bin/ls!
# SSH key stolen!
```

### ✅ The Right Way

**Never put. in PATH**:
```bash
# ✅ Good
export PATH="$HOME/bin:/usr/local/bin:/usr/bin:/bin"

# To run script in current directory:
./myscript.sh # Explicit./ required
```

**Benefits of requiring./**:
1. Makes execution intentional
2. Prevents accidental execution
3. Protects against PATH hijacking
4. Follows Unix conventions

### ❌. in PATH Variations (All Dangerous)

```bash
# ❌ All of these are dangerous
export PATH=".:$PATH" # Current directory first
export PATH="$PATH:." # Current directory last
export PATH="$PATH::" # Empty entry = current directory
export PATH="$HOME/bin::/usr/bin" #:: = current directory
```

### Checking for. in PATH

```bash
# Check if. is in PATH
if echo "$PATH" | grep -q "^\.|:\.:"; then
 echo "⚠️ Warning: Current directory in PATH!"
else
 echo "✅ PATH is safe"
fi

# More thorough check
echo $PATH | tr ':' '\n' | grep -E '^\.?$'
# If this shows anything, PATH is unsafe
```

---

## Auditing Permissions

### Security Audit Script

```bash
#!/bin/bash
# File: ~/bin/audit-permissions

echo "=== Security Audit ==="
echo

# 1. Check for world-writable files
echo "1. World-writable files in ~/bin:"
find ~/bin -type f -perm -0002 2>/dev/null
echo

# 2. Check for SUID files
echo "2. SUID files in home:"
find ~ -type f -perm -4000 -ls 2>/dev/null
echo

# 3. Check for SGID files
echo "3. SGID files in home:"
find ~ -type f -perm -2000 -ls 2>/dev/null
echo

# 4. Check PATH for dangerous entries
echo "4. PATH security:"
if echo "$PATH" | grep -q "^\.|:\.:"; then
 echo "⚠️ WARNING: Current directory (.) in PATH!"
else
 echo "✅ PATH doesn't contain current directory"
fi
echo

# 5. Check for overly permissive directories
echo "5. World-writable directories:"
find ~ -type d -perm -0002 2>/dev/null | head -10
echo

# 6. Check SSH key permissions
echo "6. SSH key permissions:"
if [ -f ~/.ssh/id_rsa ]; then
 perms=$(stat -c %a ~/.ssh/id_rsa)
 if [ "$perms" == "600" ]; then
 echo "✅ SSH key has correct permissions (600)"
 else
 echo "⚠️ SSH key has wrong permissions ($perms), should be 600"
 fi
else
 echo "No SSH key found"
fi
echo

# 7. Check for executables outside ~/bin
echo "7. Executable files outside ~/bin:"
find ~ -type f -executable ! -path "~/bin/*" ! -path "*/.git/*" 2>/dev/null | head -10
```

### Fix Common Permission Issues

```bash
#!/bin/bash
# File: ~/bin/fix-permissions

echo "Fixing common permission issues..."

# Fix ~/bin directory
chmod 755 ~/bin
echo "✅ Fixed ~/bin directory"

# Fix scripts in ~/bin (executable, not world-writable)
chmod 755 ~/bin/*
echo "✅ Fixed scripts in ~/bin"

# Fix SSH directory
chmod 700 ~/.ssh
echo "✅ Fixed ~/.ssh directory"

# Fix SSH keys
find ~/.ssh -type f -name "id_*" ! -name "*.pub" -exec chmod 600 {} \;
echo "✅ Fixed SSH private keys"

# Fix SSH public keys
find ~/.ssh -type f -name "*.pub" -exec chmod 644 {} \;
echo "✅ Fixed SSH public keys"

# Fix known_hosts and authorized_keys
[ -f ~/.ssh/known_hosts ] && chmod 644 ~/.ssh/known_hosts
[ -f ~/.ssh/authorized_keys ] && chmod 600 ~/.ssh/authorized_keys
echo "✅ Fixed SSH config files"

echo "Done!"
```

### Regular Security Checks

**Add to crontab**:
```bash
# Run security audit weekly
0 9 * * 1 ~/bin/audit-permissions | mail -s "Security Audit" $USER
```

---

## Quick Reference

### Permission Patterns

| Pattern | Octal | Use Case |
|---------|-------|----------|
| `-rw-------` | 600 | Private files, SSH keys |
| `-rw-r--r--` | 644 | Regular files |
| `-rwx------` | 700 | Private scripts |
| `-rwxr-xr-x` | 755 | Public scripts, programs |
| `drwx------` | 700 | Private directories (.ssh) |
| `drwxr-xr-x` | 755 | Regular directories |
| `drwxrwsr-x` | 2775 | Shared directories with SGID |

### Common Commands

```bash
# Make script executable
chmod +x script.sh

# Private script (only you)
chmod 700 script.sh

# Public script (anyone can run)
chmod 755 script.sh

# Regular file (anyone can read)
chmod 644 file.txt

# Private file (only you)
chmod 600 file.txt

# Change owner
sudo chown user:group file

# Find permission issues
find ~/bin -type f ! -perm 755
```

### Security Checklist

- [ ] No current directory (.) in PATH
- [ ] ~/bin is 755, not world-writable
- [ ] Scripts in ~/bin are 755 or 700
- [ ] Private keys (SSH) are 600
- [ ] ~/.ssh directory is 700
- [ ] No unnecessary SUID files
- [ ] Regular permission audits
- [ ] Scripts validate user input
- [ ] Using set -euo pipefail in scripts

---

**Next**: [08-SYMLINKS-ALTERNATIVES.md](./08-SYMLINKS-ALTERNATIVES.md) - Managing symlinks and alternatives
